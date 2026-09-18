-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 07_vistas_indicadores_phva.sql
-- Fase: 7. Vistas Especializadas e Indicadores de Avance PHVA
-- =============================================================================

-- 1. Vista Resumen de Organizaciones y Sistemas Habilitados
CREATE OR REPLACE VIEW vw_empresas_resumen_sistemas AS
SELECT 
    e.id AS empresa_id,
    e.nit || '-' || e.dv AS identificacion_tributaria,
    e.razon_social,
    e.sector_economico,
    e.clase_riesgo_arl AS riesgo_arl,
    te.nombre AS categoria_tamano,
    m.nombre AS municipio_sede,
    d.nombre AS departamento,
    COUNT(DISTINCT s.id) AS total_sedes,
    COALESCE(SUM(s.numero_trabajadores_sede), 0) AS total_trabajadores_censados,
    STRING_AGG(DISTINCT sg.codigo, ', ') AS sistemas_activos
FROM empresas e
JOIN tamanos_empresa te ON e.tamano_id = te.id
JOIN municipios m ON e.municipio_id = m.id
JOIN departamentos d ON m.departamento_id = d.id
LEFT JOIN sedes_empresa s ON e.id = s.empresa_id AND s.activo = TRUE
LEFT JOIN sistemas_empresa se ON e.id = se.empresa_id AND se.estado = 'ACTIVO'
LEFT JOIN sistemas_gestion sg ON se.sistema_id = sg.id
GROUP BY e.id, e.nit, e.dv, e.razon_social, e.sector_economico, e.clase_riesgo_arl, te.nombre, m.nombre, d.nombre;


-- 2. Vista de Avance Documental por Etapa del Ciclo PHVA
CREATE OR REPLACE VIEW vw_cumplimiento_documental_tenant AS
SELECT 
    e.id AS empresa_id,
    e.razon_social,
    sg.codigo AS sistema_codigo,
    ep.codigo AS etapa_codigo,
    ep.nombre AS etapa_phva,
    COUNT(DISTINCT p.id) AS plantillas_requeridas,
    COUNT(DISTINCT CASE WHEN de.estado = 'APROBADO' THEN de.id END) AS documentos_aprobados,
    COUNT(DISTINCT CASE WHEN de.estado = 'BORRADOR' THEN de.id END) AS documentos_en_borrador,
    COUNT(DISTINCT CASE WHEN de.estado = 'EN_REVISION' THEN de.id END) AS documentos_en_revision,
    ROUND(
        (COUNT(DISTINCT CASE WHEN de.estado = 'APROBADO' THEN de.id END)::numeric / 
        NULLIF(COUNT(DISTINCT p.id), 0)) * 100, 2
    ) AS porcentaje_cumplimiento_etapa
FROM empresas e
CROSS JOIN sistemas_gestion sg
JOIN etapas_phva ep ON TRUE
LEFT JOIN modulos mo ON sg.id = mo.sistema_id AND ep.id = mo.etapa_phva_id
LEFT JOIN plantillas p ON mo.id = p.modulo_id AND p.activo = TRUE
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id AND p.id = de.plantilla_id
GROUP BY e.id, e.razon_social, sg.codigo, ep.codigo, ep.nombre, ep.orden_secuencia
ORDER BY e.id, sg.codigo, ep.orden_secuencia;


-- 3. Vista Materializada: Tablero Consolidado de Cumplimiento PHVA (Optimización BI)
-- Las vistas materializadas persisten físicamente los datos calculados para tableros rápidos
DROP MATERIALIZED VIEW IF EXISTS mv_indicadores_cumplimiento_phva;

CREATE MATERIALIZED VIEW mv_indicadores_cumplimiento_phva AS
SELECT 
    e.id AS empresa_id,
    e.nit,
    e.razon_social,
    e.sector_economico,
    COUNT(DISTINCT p.id) AS total_plantillas_sistema,
    COUNT(DISTINCT CASE WHEN de.estado = 'APROBADO' THEN de.id END) AS total_documentos_aprobados,
    COALESCE(ROUND(
        (COUNT(DISTINCT CASE WHEN de.estado = 'APROBADO' THEN de.id END)::numeric / 
        NULLIF(COUNT(DISTINCT p.id), 0)) * 100, 2
    ), 0.00) AS porcentaje_cumplimiento_global,
    CASE 
        WHEN (COUNT(DISTINCT CASE WHEN de.estado = 'APROBADO' THEN de.id END)::numeric / NULLIF(COUNT(DISTINCT p.id), 0)) >= 0.85 THEN 'CUMPLIMIENTO_ALTO'
        WHEN (COUNT(DISTINCT CASE WHEN de.estado = 'APROBADO' THEN de.id END)::numeric / NULLIF(COUNT(DISTINCT p.id), 0)) >= 0.60 THEN 'CUMPLIMIENTO_MEDIO'
        ELSE 'EN_RIESGO_CRITICO'
    END AS estado_alerta_cumplimiento,
    CURRENT_TIMESTAMP AS fecha_corte_calculo
FROM empresas e
LEFT JOIN sistemas_empresa se ON e.id = se.empresa_id AND se.estado = 'ACTIVO'
LEFT JOIN modulos mo ON se.sistema_id = mo.sistema_id
LEFT JOIN plantillas p ON mo.id = p.modulo_id AND p.activo = TRUE
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id AND p.id = de.plantilla_id
GROUP BY e.id, e.nit, e.razon_social, e.sector_economico;

-- Índice único en la vista materializada para permitir REFRESH CONCURRENTLY
CREATE UNIQUE INDEX idx_mv_indicadores_empresa ON mv_indicadores_cumplimiento_phva(empresa_id);

-- Procedimiento auxiliar para refrescar los indicadores de la vista materializada
CREATE OR REPLACE PROCEDURE sp_refrescar_indicadores_phva()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_indicadores_cumplimiento_phva;
    RAISE NOTICE 'Vista materializada mv_indicadores_cumplimiento_phva refrescada exitosamente a las %.', CURRENT_TIMESTAMP;
END;
$$;
