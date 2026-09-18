-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 10_consultas_reportes.sql
-- Fase: 10. Batería de Consultas Analíticas, Agrupaciones, Vistas y Reportes PHVA
-- Motor: PostgreSQL 14+
-- Cumplimiento: Requerimientos de Secciones 1, 2, 3 y 4 de Examen.md
-- =============================================================================

-- =============================================================================
-- 0. VISTAS DE COMPATIBILIDAD CONCEPTUAL (Opcional para pruebas)
-- =============================================================================
CREATE OR REPLACE VIEW tenants AS SELECT * FROM empresas;
CREATE OR REPLACE VIEW persons AS SELECT * FROM personas;
CREATE OR REPLACE VIEW countries AS SELECT * FROM paises;
CREATE OR REPLACE VIEW departments AS SELECT * FROM departamentos;
CREATE OR REPLACE VIEW municipalities AS SELECT * FROM municipios;
CREATE OR REPLACE VIEW positions AS SELECT * FROM cargos;
CREATE OR REPLACE VIEW tenant_sizes AS SELECT * FROM tamanos_empresa;
CREATE OR REPLACE VIEW type_system_sst AS SELECT * FROM sistemas_gestion;
CREATE OR REPLACE VIEW formats_sst AS SELECT * FROM formatos;
CREATE OR REPLACE VIEW editing_locks AS SELECT * FROM bloqueos_recursos;


-- =============================================================================
-- SECCIÓN 1: CONSULTAS SQL BÁSICAS (1 A 15)
-- =============================================================================

-- 1.1 Consultar todos los registros almacenados en la tabla tenants
SELECT * FROM empresas;

-- 1.2 Consultar nombre, correo de contacto y teléfono de las organizaciones
SELECT 
    razon_social AS nombre_organizacion,
    email_contacto,
    telefono
FROM empresas;

-- 1.3 Listar las personas registradas mostrando sus nombres, apellidos y correo electrónico
SELECT 
    nombres,
    apellidos,
    email
FROM personas;

-- 1.4 Consultar personas cuyo estado se encuentre activo
SELECT 
    id,
    tipo_documento,
    numero_documento,
    nombres || ' ' || apellidos AS nombre_completo,
    email,
    telefono,
    activo
FROM personas
WHERE activo = TRUE;

-- 1.5 Obtener organizaciones cuyo nombre contenga una palabra clave (ej. 'Logística')
SELECT 
    id AS tenant_id,
    nit || '-' || dv AS identificacion_fiscal,
    razon_social,
    nombre_comercial,
    sector_economico,
    email_contacto
FROM empresas
WHERE razon_social ILIKE '%Logística%' 
   OR nombre_comercial ILIKE '%Logística%';

-- 1.6 Listar todos los países almacenados ordenados alfabéticamente por nombre
SELECT 
    id,
    codigo_iso,
    nombre
FROM paises
ORDER BY nombre ASC;

-- 1.7 Consultar departamentos o regiones de un país determinado (ej. 'COL')
SELECT 
    d.id,
    d.codigo_dane,
    d.nombre AS departamento,
    p.nombre AS pais
FROM departamentos d
JOIN paises p ON d.pais_id = p.id
WHERE p.codigo_iso = 'COL'
ORDER BY d.nombre ASC;

-- 1.8 Listar municipios o ciudades de un departamento específico (ej. 'Antioquia')
SELECT 
    m.id,
    m.codigo_dane,
    m.nombre AS municipio,
    d.nombre AS departamento
FROM municipios m
JOIN departamentos d ON m.departamento_id = d.id
WHERE d.nombre ILIKE 'Antioquia'
ORDER BY m.nombre ASC;

-- 1.9 Consultar todos los cargos registrados ordenándolos por descripción
SELECT 
    id,
    empresa_id,
    nombre AS cargo,
    descripcion,
    nivel_jerarquico,
    expuesto_riesgo_vial,
    activo
FROM cargos
ORDER BY descripcion ASC NULLS LAST;

-- 1.10 Consultar personas que pertenezcan a una organización determinada (ej. tenant_id = 1)
SELECT 
    id,
    nombres || ' ' || apellidos AS nombre_completo,
    tipo_documento,
    numero_documento,
    email,
    cargo_id,
    empresa_id AS tenant_id
FROM personas
WHERE empresa_id = 1;

-- 1.11 Obtener las organizaciones actualmente activas dentro del sistema
SELECT 
    id,
    nit || '-' || dv AS nit,
    razon_social,
    sector_economico,
    clase_riesgo_arl,
    activo
FROM empresas
WHERE activo = TRUE;

-- 1.12 Identificar organizaciones registradas dentro de un período según fecha de creación
SELECT 
    id,
    razon_social,
    email_contacto,
    created_at
FROM empresas
WHERE created_at BETWEEN '2024-01-01 00:00:00' AND '2026-12-31 23:59:59'
ORDER BY created_at DESC;

-- 1.13 Listar los diferentes tamaños de empresa almacenados
SELECT 
    id,
    codigo,
    nombre,
    descripcion,
    min_trabajadores,
    max_trabajadores
FROM tamanos_empresa
ORDER BY min_trabajadores ASC;

-- 1.14 Consultar los diferentes tipos de sistemas de gestión registrados
SELECT 
    id,
    codigo,
    nombre,
    descripcion,
    marco_normativo_principal,
    activo
FROM sistemas_gestion;

-- 1.15 Listar módulos registrados mostrando título, descripción y orden de presentación
SELECT 
    m.id AS modulo_id,
    m.codigo,
    m.nombre AS titulo,
    m.descripcion,
    m.peso_porcentaje,
    ep.nombre AS etapa_phva,
    ep.orden_secuencia AS orden_presentacion
FROM modulos m
JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
ORDER BY ep.orden_secuencia ASC, m.id ASC;


-- =============================================================================
-- SECCIÓN 2: CONSULTAS SQL INTERMEDIAS (1 A 20)
-- =============================================================================

-- 2.1 Personas registradas con nombre completo y nombre de su organización
SELECT 
    p.id AS persona_id,
    p.nombres || ' ' || p.apellidos AS nombre_completo,
    p.email,
    e.razon_social AS organizacion
FROM personas p
JOIN empresas e ON p.empresa_id = e.id
ORDER BY e.razon_social, nombre_completo;

-- 2.2 Persona junto con el cargo que desempeña dentro de su organización
SELECT 
    p.nombres || ' ' || p.apellidos AS nombre_completo,
    c.nombre AS cargo,
    c.nivel_jerarquico,
    e.razon_social AS organizacion
FROM personas p
JOIN cargos c ON p.cargo_id = c.id
JOIN empresas e ON p.empresa_id = e.id
ORDER BY e.razon_social, c.nombre;

-- 2.3 Organización junto con el tamaño de empresa asignado
SELECT 
    e.id AS tenant_id,
    e.nit || '-' || e.dv AS nit,
    e.razon_social AS organizacion,
    te.nombre AS tamano_empresa,
    te.min_trabajadores,
    te.max_trabajadores
FROM empresas e
JOIN tamanos_empresa te ON e.tamano_id = te.id;

-- 2.4 Organización con ciudad, departamento y país de registro
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    e.direccion_principal,
    m.nombre AS ciudad_municipio,
    d.nombre AS departamento,
    p.nombre AS pais
FROM empresas e
JOIN municipios m ON e.municipio_id = m.id
JOIN departamentos d ON m.departamento_id = d.id
JOIN paises p ON d.pais_id = p.id;

-- 2.5 Cuántas personas se encuentran registradas en cada organización
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    COUNT(p.id) AS total_personas
FROM empresas e
LEFT JOIN personas p ON e.id = p.empresa_id
GROUP BY e.id, e.razon_social
ORDER BY total_personas DESC;

-- 2.6 Organizaciones que tengan más de una cantidad de personas registradas (ej. > 1)
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    COUNT(p.id) AS total_personas
FROM empresas e
JOIN personas p ON e.id = p.empresa_id
GROUP BY e.id, e.razon_social
HAVING COUNT(p.id) > 1
ORDER BY total_personas DESC;

-- 2.7 Módulos habilitados para cada organización
SELECT 
    e.razon_social AS organizacion,
    sg.nombre AS sistema,
    m.codigo AS codigo_modulo,
    m.nombre AS modulo,
    ep.nombre AS etapa_phva
FROM empresas e
JOIN sistemas_empresa se ON e.id = se.empresa_id AND se.estado = 'ACTIVO'
JOIN sistemas_gestion sg ON se.sistema_id = sg.id
JOIN modulos m ON sg.id = m.sistema_id AND m.activo = TRUE
JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
ORDER BY e.razon_social, sg.nombre, ep.orden_secuencia;

-- 2.8 Cuántos módulos tiene habilitados cada organización
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    COUNT(m.id) AS total_modulos_habilitados
FROM empresas e
JOIN sistemas_empresa se ON e.id = se.empresa_id AND se.estado = 'ACTIVO'
JOIN modulos m ON se.sistema_id = m.sistema_id AND m.activo = TRUE
GROUP BY e.id, e.razon_social
ORDER BY total_modulos_habilitados DESC;

-- 2.9 Sistemas SST habilitados para cada organización
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    sg.codigo AS codigo_sistema,
    sg.nombre AS sistema_gestion,
    se.estado,
    se.fecha_implementacion
FROM empresas e
JOIN sistemas_empresa se ON e.id = se.empresa_id
JOIN sistemas_gestion sg ON se.sistema_id = sg.id
ORDER BY e.razon_social, sg.nombre;

-- 2.10 Módulos existentes junto con el sistema SST al cual pertenecen
SELECT 
    m.id AS modulo_id,
    m.codigo AS modulo_codigo,
    m.nombre AS modulo_nombre,
    sg.codigo AS sistema_codigo,
    sg.nombre AS sistema_nombre,
    m.peso_porcentaje
FROM modulos m
JOIN sistemas_gestion sg ON m.sistema_id = sg.id
ORDER BY sg.nombre, m.codigo;

-- 2.11 Formatos registrados mostrando el módulo al cual pertenece cada uno
SELECT 
    f.id AS formato_id,
    f.codigo AS formato_codigo,
    f.nombre AS formato_nombre,
    f.tipo_formato,
    f.frecuencia_sugerida,
    m.nombre AS modulo_asociado
FROM formatos f
JOIN modulos m ON f.modulo_id = m.id
ORDER BY m.nombre, f.nombre;

-- 2.12 Cuántos formatos se encuentran asociados a cada módulo
SELECT 
    m.id AS modulo_id,
    m.codigo AS modulo_codigo,
    m.nombre AS modulo,
    COUNT(f.id) AS total_formatos
FROM modulos m
LEFT JOIN formatos f ON m.id = f.modulo_id
GROUP BY m.id, m.codigo, m.nombre
ORDER BY total_formatos DESC, m.nombre;

-- 2.13 Plantillas asignadas a cada organización mediante documentos_empresa
SELECT 
    e.razon_social AS organizacion,
    p.codigo AS plantilla_codigo,
    p.titulo AS plantilla_titulo,
    de.codigo_documento,
    de.version,
    de.estado AS estado_documento
FROM empresas e
JOIN documentos_empresa de ON e.id = de.empresa_id
JOIN plantillas p ON de.plantilla_id = p.id
ORDER BY e.razon_social, p.codigo;

-- 2.14 Plantilla asignada indicando organización, sistema SST y etapa PHVA
SELECT 
    e.razon_social AS organizacion,
    p.codigo AS plantilla_codigo,
    p.titulo AS plantilla_titulo,
    sg.nombre AS sistema_gestion,
    ep.nombre AS etapa_phva,
    de.estado AS estado_documento
FROM empresas e
JOIN documentos_empresa de ON e.id = de.empresa_id
JOIN plantillas p ON de.plantilla_id = p.id
JOIN modulos m ON p.modulo_id = m.id
JOIN sistemas_gestion sg ON m.sistema_id = sg.id
JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
ORDER BY e.razon_social, ep.orden_secuencia;

-- 2.15 Cuántas plantillas tiene asignada cada organización
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    COUNT(de.id) AS total_plantillas_asignadas
FROM empresas e
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
GROUP BY e.id, e.razon_social
ORDER BY total_plantillas_asignadas DESC;

-- 2.16 Organizaciones que actualmente no tengan personas registradas (LEFT JOIN)
SELECT 
    e.id AS tenant_id,
    e.nit || '-' || e.dv AS nit,
    e.razon_social,
    e.email_contacto
FROM empresas e
LEFT JOIN personas p ON e.id = p.empresa_id
WHERE p.id IS NULL;

-- 2.17 Módulos que todavía no hayan sido asignados a ninguna organización activa
SELECT 
    m.id AS modulo_id,
    m.codigo,
    m.nombre AS modulo,
    sg.nombre AS sistema
FROM modulos m
JOIN sistemas_gestion sg ON m.sistema_id = sg.id
WHERE m.sistema_id NOT IN (
    SELECT DISTINCT se.sistema_id 
    FROM sistemas_empresa se 
    WHERE se.estado = 'ACTIVO'
);

-- 2.18 Etapas PHVA mostrando el número de plantillas asociadas
SELECT 
    ep.id AS etapa_id,
    ep.codigo,
    ep.nombre AS etapa_phva,
    COUNT(p.id) AS total_plantillas
FROM etapas_phva ep
LEFT JOIN modulos m ON ep.id = m.etapa_phva_id
LEFT JOIN plantillas p ON m.id = p.modulo_id AND p.activo = TRUE
GROUP BY ep.id, ep.codigo, ep.nombre, ep.orden_secuencia
ORDER BY ep.orden_secuencia;

-- 2.19 Cuántas organizaciones se encuentran registradas en cada municipio o ciudad
SELECT 
    m.id AS municipio_id,
    m.nombre AS municipio,
    d.nombre AS departamento,
    COUNT(e.id) AS total_organizaciones
FROM municipios m
JOIN departamentos d ON m.departamento_id = d.id
LEFT JOIN empresas e ON m.id = e.municipio_id
GROUP BY m.id, m.nombre, d.nombre
ORDER BY total_organizaciones DESC, m.nombre ASC;

-- 2.20 Cargos existentes en cada organización y personas que los ocupan
SELECT 
    e.razon_social AS organizacion,
    c.nombre AS cargo,
    c.nivel_jerarquico,
    COUNT(p.id) AS personas_en_cargo
FROM cargos c
JOIN empresas e ON c.empresa_id = e.id
LEFT JOIN personas p ON c.id = p.cargo_id
GROUP BY e.razon_social, c.id, c.nombre, c.nivel_jerarquico
ORDER BY e.razon_social, personas_en_cargo DESC, c.nombre;


-- =============================================================================
-- SECCIÓN 3: CONSULTAS SQL AVANZADAS (1 A 25)
-- =============================================================================

-- 3.1 Organización con mayor cantidad de personas registradas
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    COUNT(p.id) AS total_personas
FROM empresas e
JOIN personas p ON e.id = p.empresa_id
GROUP BY e.id, e.razon_social
ORDER BY total_personas DESC
LIMIT 1;

-- 3.2 Organizaciones con cantidad de personas superior al promedio general
WITH conteo_personas AS (
    SELECT empresa_id, COUNT(*) AS num_personas
    FROM personas
    GROUP BY empresa_id
)
SELECT 
    e.id AS tenant_id,
    e.razon_social,
    cp.num_personas
FROM empresas e
JOIN conteo_personas cp ON e.id = cp.empresa_id
WHERE cp.num_personas > (SELECT AVG(num_personas) FROM conteo_personas);

-- 3.3 Organizaciones con todos los módulos existentes para un sistema (ej. 'SST')
SELECT 
    e.id AS tenant_id,
    e.razon_social
FROM empresas e
JOIN sistemas_empresa se ON e.id = se.empresa_id AND se.estado = 'ACTIVO'
JOIN sistemas_gestion sg ON se.sistema_id = sg.id AND sg.codigo = 'SST'
WHERE (
    SELECT COUNT(*) 
    FROM modulos m 
    WHERE m.sistema_id = sg.id AND m.activo = TRUE
) = (
    SELECT COUNT(DISTINCT m.id)
    FROM modulos m
    JOIN plantillas p ON m.id = p.modulo_id
    JOIN documentos_empresa de ON p.id = de.plantilla_id AND de.empresa_id = e.id
    WHERE m.sistema_id = sg.id
);

-- 3.4 Organizaciones con al menos un módulo configurado pero sin plantillas asignadas
SELECT DISTINCT 
    e.id AS tenant_id,
    e.razon_social
FROM empresas e
JOIN sistemas_empresa se ON e.id = se.empresa_id AND se.estado = 'ACTIVO'
WHERE NOT EXISTS (
    SELECT 1 
    FROM documentos_empresa de 
    WHERE de.empresa_id = e.id
);

-- 3.5 Organizaciones con plantillas en todas las 4 etapas PHVA disponibles
SELECT 
    e.id AS tenant_id,
    e.razon_social
FROM empresas e
JOIN documentos_empresa de ON e.id = de.empresa_id
JOIN plantillas p ON de.plantilla_id = p.id
JOIN modulos m ON p.modulo_id = m.id
JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
GROUP BY e.id, e.razon_social
HAVING COUNT(DISTINCT ep.id) = (SELECT COUNT(*) FROM etapas_phva);

-- 3.6 Cantidad de plantillas asignadas por organización discriminadas por etapa PHVA
SELECT 
    e.razon_social AS organizacion,
    ep.nombre AS etapa_phva,
    COUNT(de.id) AS total_plantillas
FROM empresas e
CROSS JOIN etapas_phva ep
LEFT JOIN modulos m ON ep.id = m.etapa_phva_id
LEFT JOIN plantillas p ON m.id = p.modulo_id
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id AND p.id = de.plantilla_id
GROUP BY e.id, e.razon_social, ep.id, ep.nombre, ep.orden_secuencia
ORDER BY e.razon_social, ep.orden_secuencia;

-- 3.7 Columnas independientes para Planear, Hacer, Verificar y Actuar (Pivot)
SELECT 
    e.razon_social AS organizacion,
    COUNT(de.id) FILTER (WHERE ep.codigo = 'P') AS total_planear,
    COUNT(de.id) FILTER (WHERE ep.codigo = 'H') AS total_hacer,
    COUNT(de.id) FILTER (WHERE ep.codigo = 'V') AS total_verificar,
    COUNT(de.id) FILTER (WHERE ep.codigo = 'A') AS total_actuar,
    COUNT(de.id) AS gran_total
FROM empresas e
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
LEFT JOIN plantillas p ON de.plantilla_id = p.id
LEFT JOIN modulos m ON p.modulo_id = m.id
LEFT JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
GROUP BY e.id, e.razon_social
ORDER BY e.razon_social;

-- 3.8 Porcentaje que representa cada etapa PHVA sobre el total de plantillas asignadas
WITH conteo_etapas AS (
    SELECT 
        e.id AS empresa_id,
        e.razon_social,
        ep.nombre AS etapa_phva,
        COUNT(de.id) AS total_etapa
    FROM empresas e
    JOIN documentos_empresa de ON e.id = de.empresa_id
    JOIN plantillas p ON de.plantilla_id = p.id
    JOIN modulos m ON p.modulo_id = m.id
    JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
    GROUP BY e.id, e.razon_social, ep.id, ep.nombre
)
SELECT 
    empresa_id,
    razon_social,
    etapa_phva,
    total_etapa,
    ROUND(
        (total_etapa::numeric / NULLIF(SUM(total_etapa) OVER (PARTITION BY empresa_id), 0)) * 100, 
        2
    ) AS porcentaje_representado
FROM conteo_etapas
ORDER BY razon_social, etapa_phva;

-- 3.9 Etapa PHVA con mayor cantidad de plantillas asignadas dentro de cada empresa
WITH ranking_etapas AS (
    SELECT 
        e.razon_social AS organizacion,
        ep.nombre AS etapa_phva,
        COUNT(de.id) AS cantidad_plantillas,
        DENSE_RANK() OVER (PARTITION BY e.id ORDER BY COUNT(de.id) DESC) AS posicion_ranking
    FROM empresas e
    JOIN documentos_empresa de ON e.id = de.empresa_id
    JOIN plantillas p ON de.plantilla_id = p.id
    JOIN modulos m ON p.modulo_id = m.id
    JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
    GROUP BY e.id, e.razon_social, ep.id, ep.nombre
)
SELECT organizacion, etapa_phva, cantidad_plantillas
FROM ranking_etapas
WHERE posicion_ranking = 1;

-- 3.10 Porcentaje de documentos finalizados frente al total de documentos
SELECT 
    e.id AS empresa_id,
    e.razon_social AS organizacion,
    COUNT(de.id) AS total_documentos,
    COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END) AS documentos_finalizados,
    COALESCE(ROUND(
        (COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END)::numeric / NULLIF(COUNT(de.id), 0)) * 100, 
        2
    ), 0.00) AS porcentaje_finalizados
FROM empresas e
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
GROUP BY e.id, e.razon_social
ORDER BY porcentaje_finalizados DESC;

-- 3.11 Organizaciones con porcentaje de cumplimiento por debajo del promedio general
WITH metricas_tenant AS (
    SELECT 
        e.id,
        e.razon_social,
        COALESCE(ROUND(
            (COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END)::numeric / NULLIF(COUNT(de.id), 0)) * 100, 
            2
        ), 0.00) AS porcentaje_cumplimiento
    FROM empresas e
    LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
    GROUP BY e.id, e.razon_social
)
SELECT id, razon_social, porcentaje_cumplimiento
FROM metricas_tenant
WHERE porcentaje_cumplimiento < (SELECT AVG(porcentaje_cumplimiento) FROM metricas_tenant);

-- 3.12 Clasificación de organizaciones según cumplimiento con expresión CASE
SELECT 
    e.razon_social AS organizacion,
    COALESCE(ROUND(
        (COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END)::numeric / NULLIF(COUNT(de.id), 0)) * 100, 
        2
    ), 0.00) AS pct_cumplimiento,
    CASE 
        WHEN (COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END)::numeric / NULLIF(COUNT(de.id), 0)) >= 0.80 THEN 'ALTO'
        WHEN (COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END)::numeric / NULLIF(COUNT(de.id), 0)) >= 0.50 THEN 'MEDIO'
        ELSE 'BAJO'
    END AS categoria_cumplimiento
FROM empresas e
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
GROUP BY e.id, e.razon_social
ORDER BY pct_cumplimiento DESC;

-- 3.13 Ranking de organizaciones según cumplimiento con función de ventana
SELECT 
    e.razon_social AS organizacion,
    COALESCE(ROUND(
        (COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END)::numeric / NULLIF(COUNT(de.id), 0)) * 100, 
        2
    ), 0.00) AS pct_cumplimiento,
    DENSE_RANK() OVER (
        ORDER BY COALESCE(ROUND(
            (COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END)::numeric / NULLIF(COUNT(de.id), 0)) * 100, 
            2
        ), 0.00) DESC
    ) AS puesto_ranking
FROM empresas e
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
GROUP BY e.id, e.razon_social;

-- 3.14 Porcentaje de cumplimiento y diferencia respecto al promedio general
WITH consolidado AS (
    SELECT 
        e.razon_social,
        COALESCE(ROUND(
            (COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END)::numeric / NULLIF(COUNT(de.id), 0)) * 100, 
            2
        ), 0.00) AS pct_cumplimiento
    FROM empresas e
    LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
    GROUP BY e.id, e.razon_social
)
SELECT 
    razon_social,
    pct_cumplimiento,
    ROUND(AVG(pct_cumplimiento) OVER (), 2) AS promedio_sistema,
    ROUND(pct_cumplimiento - AVG(pct_cumplimiento) OVER (), 2) AS delta_vs_promedio
FROM consolidado;

-- 3.15 Cantidad acumulada de documentos finalizados por organización (Window SUM)
WITH docs_por_empresa AS (
    SELECT 
        e.id,
        e.razon_social,
        COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END) AS finalizados
    FROM empresas e
    LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
    GROUP BY e.id, e.razon_social
)
SELECT 
    id,
    razon_social,
    finalizados,
    SUM(finalizados) OVER (
        ORDER BY id 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS acumulado_documentos_aprobados
FROM docs_por_empresa;

-- 3.16 Organizaciones en el mismo municipio con diferente tamaño empresarial
SELECT 
    e1.razon_social AS organizacion_a,
    te1.nombre AS tamano_a,
    e2.razon_social AS organizacion_b,
    te2.nombre AS tamano_b,
    m.nombre AS municipio_compartido
FROM empresas e1
JOIN empresas e2 ON e1.municipio_id = e2.municipio_id AND e1.id < e2.id
JOIN tamanos_empresa te1 ON e1.tamano_id = te1.id
JOIN tamanos_empresa te2 ON e2.tamano_id = te2.id
JOIN municipios m ON e1.municipio_id = m.id
WHERE e1.tamano_id <> e2.tamano_id;

-- 3.17 Personas cuyo cargo supera el promedio de ocupación de su empresa
WITH conteo_cargos AS (
    SELECT empresa_id, cargo_id, COUNT(*) AS total_ocupantes
    FROM personas
    GROUP BY empresa_id, cargo_id
),
promedios_tenant AS (
    SELECT empresa_id, AVG(total_ocupantes) AS promedio_ocupacion
    FROM conteo_cargos
    GROUP BY empresa_id
)
SELECT 
    p.nombres || ' ' || p.apellidos AS persona,
    c.nombre AS cargo,
    e.razon_social AS organizacion,
    cc.total_ocupantes,
    ROUND(pt.promedio_ocupacion, 2) AS promedio_organizacion
FROM personas p
JOIN cargos c ON p.cargo_id = c.id
JOIN empresas e ON p.empresa_id = e.id
JOIN conteo_cargos cc ON p.empresa_id = cc.empresa_id AND p.cargo_id = cc.cargo_id
JOIN promedios_tenant pt ON p.empresa_id = pt.empresa_id
WHERE cc.total_ocupantes > pt.promedio_ocupacion;

-- 3.18 CTE para personas por organización y filtro sobre el promedio
WITH cte_conteo_personas AS (
    SELECT 
        e.id AS empresa_id,
        e.razon_social,
        COUNT(p.id) AS total_personas
    FROM empresas e
    LEFT JOIN personas p ON e.id = p.empresa_id
    GROUP BY e.id, e.razon_social
),
cte_promedio_general AS (
    SELECT AVG(total_personas) AS promedio_personas FROM cte_conteo_personas
)
SELECT 
    cp.empresa_id,
    cp.razon_social,
    cp.total_personas,
    ROUND(pg.promedio_personas, 2) AS promedio_general
FROM cte_conteo_personas cp, cte_promedio_general pg
WHERE cp.total_personas > pg.promedio_personas;

-- 3.19 CTE para consolidar cantidad de módulos, plantillas y personas
WITH cte_personas AS (
    SELECT empresa_id, COUNT(*) AS cantidad_personas 
    FROM personas 
    GROUP BY empresa_id
),
cte_modulos AS (
    SELECT se.empresa_id, COUNT(m.id) AS cantidad_modulos
    FROM sistemas_empresa se
    JOIN modulos m ON se.sistema_id = m.sistema_id AND m.activo = TRUE
    WHERE se.estado = 'ACTIVO'
    GROUP BY se.empresa_id
),
cte_documentos AS (
    SELECT empresa_id, COUNT(*) AS cantidad_documentos
    FROM documentos_empresa
    GROUP BY empresa_id
)
SELECT 
    e.id AS empresa_id,
    e.razon_social,
    COALESCE(cp.cantidad_personas, 0) AS total_personas,
    COALESCE(cm.cantidad_modulos, 0) AS total_modulos_activos,
    COALESCE(cd.cantidad_documentos, 0) AS total_plantillas_documentos
FROM empresas e
LEFT JOIN cte_personas cp ON e.id = cp.empresa_id
LEFT JOIN cte_modulos cm ON e.id = cm.empresa_id
LEFT JOIN cte_documentos cd ON e.id = cd.empresa_id
ORDER BY e.razon_social;

-- 3.20 Organizaciones sin alguna etapa PHVA configurada en sus plantillas
SELECT 
    e.id AS empresa_id,
    e.razon_social,
    ep.codigo AS codigo_etapa,
    ep.nombre AS etapa_faltante
FROM empresas e
CROSS JOIN etapas_phva ep
WHERE NOT EXISTS (
    SELECT 1
    FROM documentos_empresa de
    JOIN plantillas p ON de.plantilla_id = p.id
    JOIN modulos m ON p.modulo_id = m.id
    WHERE de.empresa_id = e.id AND m.etapa_phva_id = ep.id
)
ORDER BY e.razon_social, ep.orden_secuencia;

-- 3.21 Última fecha de actualización documental por organización
SELECT 
    e.id AS empresa_id,
    e.razon_social,
    MAX(de.updated_at) AS ultima_actualizacion_documental
FROM empresas e
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
GROUP BY e.id, e.razon_social
ORDER BY ultima_actualizacion_documental DESC NULLS LAST;

-- 3.22 Organizaciones con registros documentales pendientes
SELECT 
    empresa_id,
    razon_social,
    sistema_codigo,
    etapa_phva,
    plantillas_requeridas,
    documentos_aprobados,
    (plantillas_requeridas - documentos_aprobados) AS pendientes,
    porcentaje_cumplimiento_etapa
FROM vw_cumplimiento_documental_tenant
WHERE (plantillas_requeridas - documentos_aprobados) > 0
ORDER BY razon_social, sistema_codigo;

-- 3.23 Informe consolidado por organización (total, aprobados, borrador, pendientes, %)
SELECT 
    e.id AS empresa_id,
    e.razon_social,
    COUNT(de.id) AS total_documentos,
    COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END) AS finalizados,
    COUNT(CASE WHEN de.estado = 'BORRADOR' THEN 1 END) AS en_borrador,
    COUNT(CASE WHEN de.estado = 'EN_REVISION' THEN 1 END) AS en_revision,
    COUNT(CASE WHEN de.estado IN ('BORRADOR', 'EN_REVISION') THEN 1 END) AS pendientes,
    COALESCE(ROUND(
        (COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END)::numeric / NULLIF(COUNT(de.id), 0)) * 100, 
        2
    ), 0.00) AS porcentaje_cumplimiento
FROM empresas e
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
GROUP BY e.id, e.razon_social
ORDER BY porcentaje_cumplimiento DESC;

-- 3.24 Comparar porcentaje de cumplimiento SST y PESV con brecha > 10%
WITH cumplimiento_sistemas AS (
    SELECT 
        empresa_id,
        razon_social,
        COALESCE(AVG(porcentaje_cumplimiento_etapa) FILTER (WHERE sistema_codigo = 'SST'), 0.00) AS pct_sst,
        COALESCE(AVG(porcentaje_cumplimiento_etapa) FILTER (WHERE sistema_codigo = 'PESV'), 0.00) AS pct_pesv
    FROM vw_cumplimiento_documental_tenant
    GROUP BY empresa_id, razon_social
)
SELECT 
    empresa_id,
    razon_social,
    ROUND(pct_sst, 2) AS pct_sst,
    ROUND(pct_pesv, 2) AS pct_pesv,
    ROUND(ABS(pct_sst - pct_pesv), 2) AS brecha_diferencia
FROM cumplimiento_sistemas
WHERE ABS(pct_sst - pct_pesv) > 10.00;

-- 3.25 Vista que consolida personas, módulos, plantillas y sistemas
CREATE OR REPLACE VIEW vw_capacidades_consolidadas_tenant AS
SELECT 
    e.id AS empresa_id,
    e.razon_social,
    COUNT(DISTINCT p.id) AS total_personas,
    COUNT(DISTINCT se.sistema_id) AS total_sistemas_activos,
    COUNT(DISTINCT m.id) AS total_modulos_activos,
    COUNT(DISTINCT de.id) AS total_documentos_gestionados
FROM empresas e
LEFT JOIN personas p ON e.id = p.empresa_id
LEFT JOIN sistemas_empresa se ON e.id = se.empresa_id AND se.estado = 'ACTIVO'
LEFT JOIN modulos m ON se.sistema_id = m.sistema_id AND m.activo = TRUE
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
GROUP BY e.id, e.razon_social;


-- =============================================================================
-- SECCIÓN 4: VISTAS Y VISTAS MATERIALIZADAS (1 A 8)
-- =============================================================================

-- 4.1 Vista vw_tenant_persons: organizaciones con personas y cargos
CREATE OR REPLACE VIEW vw_tenant_persons AS
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    p.id AS persona_id,
    p.tipo_documento,
    p.numero_documento,
    p.nombres || ' ' || p.apellidos AS nombre_completo,
    p.email,
    c.nombre AS cargo,
    c.nivel_jerarquico,
    p.activo AS persona_activa
FROM empresas e
JOIN personas p ON e.id = p.empresa_id
JOIN cargos c ON p.cargo_id = c.id;

-- 4.2 Vista de consolidación geográfica de organizaciones
CREATE OR REPLACE VIEW vw_tenant_geografia AS
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    e.direccion_principal,
    m.codigo_dane AS dane_municipio,
    m.nombre AS municipio,
    d.codigo_dane AS dane_departamento,
    d.nombre AS departamento,
    p.codigo_iso AS iso_pais,
    p.nombre AS pais
FROM empresas e
JOIN municipios m ON e.municipio_id = m.id
JOIN departamentos d ON m.departamento_id = d.id
JOIN paises p ON d.pais_id = p.id;

-- 4.3 Vista de módulos habilitados por organización y sistema
CREATE OR REPLACE VIEW vw_tenant_modulos_habilitados AS
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    sg.codigo AS codigo_sistema,
    sg.nombre AS sistema_gestion,
    m.id AS modulo_id,
    m.codigo AS codigo_modulo,
    m.nombre AS nombre_modulo,
    ep.nombre AS etapa_phva,
    m.peso_porcentaje
FROM empresas e
JOIN sistemas_empresa se ON e.id = se.empresa_id AND se.estado = 'ACTIVO'
JOIN sistemas_gestion sg ON se.sistema_id = sg.id
JOIN modulos m ON sg.id = m.sistema_id AND m.activo = TRUE
JOIN etapas_phva ep ON m.etapa_phva_id = ep.id;

-- 4.4 Vista de cantidad de plantillas asociadas por organización y etapa PHVA
CREATE OR REPLACE VIEW vw_tenant_plantillas_por_etapa AS
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    ep.codigo AS etapa_codigo,
    ep.nombre AS etapa_phva,
    COUNT(de.id) AS total_plantillas
FROM empresas e
CROSS JOIN etapas_phva ep
LEFT JOIN modulos m ON ep.id = m.etapa_phva_id
LEFT JOIN plantillas p ON m.id = p.modulo_id
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id AND p.id = de.plantilla_id
GROUP BY e.id, e.razon_social, ep.id, ep.codigo, ep.nombre, ep.orden_secuencia;

-- 4.5 Vista de total de personas existentes por organización y cargo
CREATE OR REPLACE VIEW vw_personas_por_organizacion_cargo AS
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    c.id AS cargo_id,
    c.nombre AS cargo,
    c.nivel_jerarquico,
    COUNT(p.id) AS total_personas
FROM cargos c
JOIN empresas e ON c.empresa_id = e.id
LEFT JOIN personas p ON c.id = p.cargo_id
GROUP BY e.id, e.razon_social, c.id, c.nombre, c.nivel_jerarquico;

-- 4.6 Vista materializada que consolida documentos y porcentaje de cumplimiento
DROP MATERIALIZED VIEW IF EXISTS vm_resumen_documental_cumplimiento;

CREATE MATERIALIZED VIEW vm_resumen_documental_cumplimiento AS
SELECT 
    e.id AS tenant_id,
    e.nit || '-' || e.dv AS nit,
    e.razon_social AS organizacion,
    COUNT(de.id) AS total_documentos,
    COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END) AS documentos_finalizados,
    COUNT(CASE WHEN de.estado IN ('BORRADOR', 'EN_REVISION') THEN 1 END) AS documentos_pendientes,
    COALESCE(ROUND(
        (COUNT(CASE WHEN de.estado = 'APROBADO' THEN 1 END)::numeric / NULLIF(COUNT(de.id), 0)) * 100, 
        2
    ), 0.00) AS porcentaje_cumplimiento,
    CURRENT_TIMESTAMP AS ultima_generacion
FROM empresas e
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
GROUP BY e.id, e.nit, e.dv, e.razon_social;

-- 4.7 Actualizar vista materializada con REFRESH MATERIALIZED VIEW
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_vm_resumen_tenant ON vm_resumen_documental_cumplimiento(tenant_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY vm_resumen_documental_cumplimiento;

-- 4.8 Índices para optimizar consultas en la vista materializada
CREATE INDEX IF NOT EXISTS idx_vm_resumen_cumplimiento 
ON vm_resumen_documental_cumplimiento(porcentaje_cumplimiento DESC);

CREATE INDEX IF NOT EXISTS idx_vm_resumen_organizacion 
ON vm_resumen_documental_cumplimiento(organizacion);
