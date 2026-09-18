-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 10_consultas_reportes.sql
-- Fase: 10. Batería de Consultas Analíticas, Agrupaciones y Reportes PHVA
-- =============================================================================

-- =============================================================================
-- 1. Resumen Ejecutivo Multi-Empresa (Tenants)
-- =============================================================================
-- Muestra cada organización con su clase de riesgo, total de sedes y personal
SELECT 
    e.id AS tenant_id,
    e.nit || '-' || e.dv AS nit,
    e.razon_social,
    e.sector_economico,
    e.clase_riesgo_arl,
    te.nombre AS tamano_empresa,
    COUNT(DISTINCT s.id) AS total_sedes,
    COALESCE(SUM(s.numero_trabajadores_sede), 0) AS total_colaboradores,
    STRING_AGG(DISTINCT sg.codigo, ' | ') AS sistemas_gestion_activos
FROM empresas e
JOIN tamanos_empresa te ON e.tamano_id = te.id
LEFT JOIN sedes_empresa s ON e.id = s.empresa_id AND s.activo = TRUE
LEFT JOIN sistemas_empresa se ON e.id = se.empresa_id AND se.estado = 'ACTIVO'
LEFT JOIN sistemas_gestion sg ON se.sistema_id = sg.id
GROUP BY e.id, e.nit, e.dv, e.razon_social, e.sector_economico, e.clase_riesgo_arl, te.nombre
ORDER BY total_colaboradores DESC;


-- =============================================================================
-- 2. Avance Detallado por las 4 Etapas del Ciclo PHVA
-- =============================================================================
-- Permite ver el porcentaje de cumplimiento documental discriminado por Planear, Hacer, Verificar y Actuar
SELECT 
    e.razon_social AS organizacion,
    sg.nombre AS sistema,
    ep.nombre AS etapa_phva,
    COUNT(DISTINCT p.id) AS total_plantillas_exigidas,
    COUNT(DISTINCT CASE WHEN de.estado = 'APROBADO' THEN de.id END) AS documentos_aprobados,
    COUNT(DISTINCT CASE WHEN de.estado = 'BORRADOR' THEN de.id END) AS en_borrador,
    COALESCE(ROUND(
        (COUNT(DISTINCT CASE WHEN de.estado = 'APROBADO' THEN de.id END)::numeric / 
        NULLIF(COUNT(DISTINCT p.id), 0)) * 100, 1
    ), 0.0) AS porcentaje_avance_etapa
FROM empresas e
CROSS JOIN sistemas_gestion sg
JOIN etapas_phva ep ON TRUE
LEFT JOIN modulos m ON sg.id = m.sistema_id AND ep.id = m.etapa_phva_id
LEFT JOIN plantillas p ON m.id = p.modulo_id AND p.activo = TRUE
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id AND p.id = de.plantilla_id
GROUP BY e.id, e.razon_social, sg.id, sg.nombre, ep.id, ep.nombre, ep.orden_secuencia
ORDER BY e.razon_social, sg.nombre, ep.orden_secuencia;


-- =============================================================================
-- 3. Documentos Pendientes de Aprobación por Organización
-- =============================================================================
SELECT 
    de.id AS documento_id,
    e.razon_social AS organizacion,
    de.codigo_documento,
    de.titulo,
    de.version,
    de.estado,
    p_elabo.nombres || ' ' || p_elabo.apellidos AS elaborado_por,
    de.fecha_elaboracion
FROM documentos_empresa de
JOIN empresas e ON de.empresa_id = e.id
JOIN personas p_elabo ON de.elaborado_por_id = p_elabo.id
WHERE de.estado IN ('BORRADOR', 'EN_REVISION')
ORDER BY de.fecha_elaboracion ASC;


-- =============================================================================
-- 4. Monitor de Recursos Bloqueados Actualmente (Control de Concurrencia)
-- =============================================================================
SELECT 
    b.id AS bloqueo_id,
    e.razon_social AS tenant,
    b.tipo_recurso,
    b.recurso_id,
    p.nombres || ' ' || p.apellidos AS usuario_editor,
    b.adquirido_en,
    b.expira_en,
    ROUND(EXTRACT(EPOCH FROM (b.expira_en - CURRENT_TIMESTAMP)) / 60, 1) AS minutos_restantes,
    CASE 
        WHEN b.expira_en < CURRENT_TIMESTAMP THEN 'EXPIRADO'
        ELSE 'BLOQUEO_ACTIVO'
    END AS estado_bloqueo
FROM bloqueos_recursos b
JOIN empresas e ON b.empresa_id = e.id
JOIN personas p ON b.persona_id = p.id
WHERE b.activo = TRUE
ORDER BY b.expira_en ASC;


-- =============================================================================
-- 5. Consulta del Tablero Consolidado (Desde la Vista Materializada)
-- =============================================================================
SELECT 
    nit,
    razon_social,
    sector_economico,
    total_documentos_aprobados || ' de ' || total_plantillas_sistema AS documentos_gestionados,
    porcentaje_cumplimiento_global || '%' AS cumplimiento_total,
    estado_alerta_cumplimiento,
    fecha_corte_calculo
FROM mv_indicadores_cumplimiento_phva
ORDER BY porcentaje_cumplimiento_global DESC;
