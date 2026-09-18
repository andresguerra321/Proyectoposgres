# 🚀 Banco de Consultas, Procedimientos, Funciones y Triggers Resueltos
## Proyecto: Gestión de SST y PESV en PostgreSQL (Multi-Tenant)

Este documento contiene la **solución completa y lista para ejecutar** de cada uno de los ejercicios y consultas planteados en el archivo [consultas.md](file:///c:/Users/andre/OneDrive/Escritorio/proyectos/proyecto/consultas.md).

---

## 📑 Tabla de Contenido

0. [Script de Compatibilidad de Nombres (Recomendado para pruebas)](#0-script-de-compatibilidad-de-nombres)
1. [Consultas SQL Básicas (1 a 15)](#1-consultas-sql-básicas)
2. [Consultas SQL Intermedias (1 a 20)](#2-consultas-sql-intermedias)
3. [Consultas SQL Avanzadas (1 a 25)](#3-consultas-sql-avanzadas)
4. [Consultas Orientadas a Vistas y Vistas Materializadas (1 a 8)](#4-consultas-orientadas-a-vistas-y-vistas-materializadas)
5. [Procedimientos Almacenados (1 a 15)](#5-procedimientos-almacenados)
6. [Funciones Almacenadas (1 a 8)](#6-funciones-almacenadas)
7. [Triggers de Automatización y Reglas de Negocio (1 a 15)](#7-triggers)

---

## 0. Script de Compatibilidad de Nombres

El enunciado de `consultas.md` utiliza ocasionalmente nombres en inglés o conceptuales (`tenants`, `persons`, `positions`, `tenant_sizes`, `type_system_sst`, `formats_sst`, `editing_locks`). Si deseas ejecutar consultas usando directamente esos nombres o los nombres en español del DDL (`empresas`, `personas`, `cargos`, etc.), ejecuta este bloque una sola vez:

```sql
-- Vistas de alias y compatibilidad conceptual
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
```

---

## 1. Consultas SQL Básicas

### Consulta 1.1
**Enunciado:** Consultar todos los registros almacenados en la tabla `tenants`, mostrando la información disponible de cada organización registrada en el sistema.
```sql
SELECT * FROM empresas;
-- O utilizando la vista de compatibilidad:
-- SELECT * FROM tenants;
```
* **Explicación:** Recupera la totalidad de atributos y tuplas de las organizaciones registradas en la plataforma.

---

### Consulta 1.2
**Enunciado:** Consultar el nombre, correo de contacto y teléfono de todas las organizaciones registradas en la tabla `tenants`.
```sql
SELECT 
    razon_social AS nombre_organizacion,
    email_contacto,
    telefono
FROM empresas;
```
* **Explicación:** Proyecta únicamente las columnas de contacto institucional de cada tenant.

---

### Consulta 1.3
**Enunciado:** Listar las personas registradas en la tabla `persons`, mostrando sus nombres, apellidos y correo electrónico.
```sql
SELECT 
    nombres,
    apellidos,
    email
FROM personas;
```
* **Explicación:** Consulta de proyección simple sobre la tabla `personas` (o `persons`).

---

### Consulta 1.4
**Enunciado:** Consultar las personas cuyo estado se encuentre activo dentro de la plataforma.
```sql
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
```
* **Explicación:** Filtra los registros mediante el predicado booleano `activo = TRUE`.

---

### Consulta 1.5
**Enunciado:** Obtener las organizaciones cuyo nombre contenga una determinada palabra proporcionada como criterio de búsqueda.
```sql
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
```
* **Explicación:** Utiliza el operador insensible a mayúsculas/minúsculas `ILIKE` con comodines `%` para buscar coincidencias parciales.

---

### Consulta 1.6
**Enunciado:** Listar todos los países almacenados en la tabla `countries`, ordenándolos alfabéticamente por nombre.
```sql
SELECT 
    id,
    codigo_iso,
    nombre
FROM paises
ORDER BY nombre ASC;
```
* **Explicación:** Ordenamiento lexicográfico ascendente con `ORDER BY nombre ASC`.

---

### Consulta 1.7
**Enunciado:** Consultar los departamentos o regiones pertenecientes a un país determinado.
```sql
SELECT 
    d.id,
    d.codigo_dane,
    d.nombre AS departamento,
    p.nombre AS pais
FROM departamentos d
JOIN paises p ON d.pais_id = p.id
WHERE p.codigo_iso = 'COL'
ORDER BY d.nombre ASC;
```
* **Explicación:** Filtra departamentos por el código ISO o identificador del país padre.

---

### Consulta 1.8
**Enunciado:** Listar los municipios o ciudades correspondientes a un departamento o región específica.
```sql
SELECT 
    m.id,
    m.codigo_dane,
    m.nombre AS municipio,
    d.nombre AS departamento
FROM municipios m
JOIN departamentos d ON m.departamento_id = d.id
WHERE d.nombre ILIKE 'Antioquia'
ORDER BY m.nombre ASC;
```
* **Explicación:** Recupera municipios asociándolos a su departamento mediante clave foránea.

---

### Consulta 1.9
**Enunciado:** Consultar todos los cargos registrados en la tabla `positions`, ordenándolos por descripción.
```sql
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
```
* **Explicación:** Ordena por la columna `descripcion`, colocando valores nulos al final.

---

### Consulta 1.10
**Enunciado:** Consultar las personas que pertenezcan a una organización determinada mediante su identificador `tenant_id`.
```sql
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
```
* **Explicación:** Aplica el filtro multi-tenant `empresa_id = :id_deseado`.

---

### Consulta 1.11
**Enunciado:** Obtener las organizaciones que actualmente se encuentren habilitadas o activas dentro del sistema.
```sql
SELECT 
    id,
    nit || '-' || dv AS nit,
    razon_social,
    sector_economico,
    clase_riesgo_arl,
    activo
FROM empresas
WHERE activo = TRUE;
```
* **Explicación:** Filtra empresas en operación con estado habilitado.

---

### Consulta 1.12
**Enunciado:** Identificar las organizaciones que hayan sido registradas dentro de un período determinado utilizando la fecha de creación.
```sql
SELECT 
    id,
    razon_social,
    email_contacto,
    created_at
FROM empresas
WHERE created_at >= '2024-01-01 00:00:00' 
  AND created_at <= '2026-12-31 23:59:59'
ORDER BY created_at DESC;
```
* **Explicación:** Delimita el rango de fechas de auditoría con operadores de comparación o `BETWEEN`.

---

### Consulta 1.13
**Enunciado:** Listar los diferentes tamaños de empresa almacenados en la tabla `tenant_sizes`.
```sql
SELECT 
    id,
    codigo,
    nombre,
    descripcion,
    min_trabajadores,
    max_trabajadores
FROM tamanos_empresa
ORDER BY min_trabajadores ASC;
```
* **Explicación:** Consulta del catálogo normativo de clasificación empresarial (Res. 0312).

---

### Consulta 1.14
**Enunciado:** Consultar los diferentes tipos de sistemas SST registrados en la tabla `type_system_sst`.
```sql
SELECT 
    id,
    codigo,
    nombre,
    descripcion,
    marco_normativo_principal,
    activo
FROM sistemas_gestion;
```
* **Explicación:** Lista los sistemas parametrizados (`SST`, `PESV`, etc.).

---

### Consulta 1.15
**Enunciado:** Listar los módulos registrados en el sistema mostrando su título, descripción y orden de presentación.
```sql
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
```
* **Explicación:** Relaciona el módulo con el orden secuencial del ciclo PHVA (1 a 4).

---

## 2. Consultas SQL Intermedias

### Consulta 2.1
**Enunciado:** Consultar todas las personas registradas, mostrando el nombre completo de la persona y el nombre de la organización a la cual pertenece.
```sql
SELECT 
    p.id AS persona_id,
    p.nombres || ' ' || p.apellidos AS nombre_completo,
    p.email,
    e.razon_social AS organizacion
FROM personas p
JOIN empresas e ON p.empresa_id = e.id
ORDER BY e.razon_social, nombre_completo;
```

---

### Consulta 2.2
**Enunciado:** Consultar cada persona junto con el cargo que desempeña dentro de su organización.
```sql
SELECT 
    p.nombres || ' ' || p.apellidos AS nombre_completo,
    c.nombre AS cargo,
    c.nivel_jerarquico,
    e.razon_social AS organizacion
FROM personas p
JOIN cargos c ON p.cargo_id = c.id
JOIN empresas e ON p.empresa_id = e.id
ORDER BY e.razon_social, c.nombre;
```

---

### Consulta 2.3
**Enunciado:** Mostrar cada organización junto con el tamaño de empresa que tiene asignado.
```sql
SELECT 
    e.id AS tenant_id,
    e.nit || '-' || e.dv AS nit,
    e.razon_social AS organizacion,
    te.nombre AS tamano_empresa,
    te.min_trabajadores,
    te.max_trabajadores
FROM empresas e
JOIN tamanos_empresa te ON e.tamano_id = te.id;
```

---

### Consulta 2.4
**Enunciado:** Consultar cada organización mostrando la ciudad, departamento o región y país donde se encuentra registrada.
```sql
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
```

---

### Consulta 2.5
**Enunciado:** Determinar cuántas personas se encuentran registradas en cada organización.
```sql
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    COUNT(p.id) AS total_personas
FROM empresas e
LEFT JOIN personas p ON e.id = p.empresa_id
GROUP BY e.id, e.razon_social
ORDER BY total_personas DESC;
```

---

### Consulta 2.6
**Enunciado:** Identificar las organizaciones que tengan más de una cantidad determinada de personas registradas (ej. más de 1 colaborador).
```sql
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    COUNT(p.id) AS total_personas
FROM empresas e
JOIN personas p ON e.id = p.empresa_id
GROUP BY e.id, e.razon_social
HAVING COUNT(p.id) > 1
ORDER BY total_personas DESC;
```

---

### Consulta 2.7
**Enunciado:** Consultar los módulos habilitados para cada organización mediante la relación existente en `tenant_modules`.
```sql
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
```

---

### Consulta 2.8
**Enunciado:** Determinar cuántos módulos tiene habilitados cada organización.
```sql
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    COUNT(m.id) AS total_modulos_habilitados
FROM empresas e
JOIN sistemas_empresa se ON e.id = se.empresa_id AND se.estado = 'ACTIVO'
JOIN modulos m ON se.sistema_id = m.sistema_id AND m.activo = TRUE
GROUP BY e.id, e.razon_social
ORDER BY total_modulos_habilitados DESC;
```

---

### Consulta 2.9
**Enunciado:** Consultar los sistemas SST habilitados para cada organización utilizando las tablas `tenantsystems` y `type_system_sst`.
```sql
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
```

---

### Consulta 2.10
**Enunciado:** Mostrar los módulos existentes junto con el sistema SST al cual pertenecen.
```sql
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
```

---

### Consulta 2.11
**Enunciado:** Consultar los formatos registrados en `formats_sst`, mostrando el módulo al cual pertenece cada formato.
```sql
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
```

---

### Consulta 2.12
**Enunciado:** Determinar cuántos formatos se encuentran asociados a cada módulo.
```sql
SELECT 
    m.id AS modulo_id,
    m.codigo AS modulo_codigo,
    m.nombre AS modulo,
    COUNT(f.id) AS total_formatos
FROM modulos m
LEFT JOIN formatos f ON m.id = f.modulo_id
GROUP BY m.id, m.codigo, m.nombre
ORDER BY total_formatos DESC, m.nombre;
```

---

### Consulta 2.13
**Enunciado:** Consultar las plantillas asignadas a cada organización mediante la tabla `tenanttemplates` (`documentos_empresa`).
```sql
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
```

---

### Consulta 2.14
**Enunciado:** Mostrar cada plantilla asignada indicando la organización, el sistema SST y la etapa PHVA relacionada.
```sql
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
```

---

### Consulta 2.15
**Enunciado:** Determinar cuántas plantillas tiene asignada cada organización.
```sql
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    COUNT(de.id) AS total_plantillas_asignadas
FROM empresas e
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
GROUP BY e.id, e.razon_social
ORDER BY total_plantillas_asignadas DESC;
```

---

### Consulta 2.16
**Enunciado:** Consultar las organizaciones que actualmente no tengan personas registradas utilizando una combinación externa entre `tenants` y `persons`.
```sql
SELECT 
    e.id AS tenant_id,
    e.nit || '-' || e.dv AS nit,
    e.razon_social,
    e.email_contacto
FROM empresas e
LEFT JOIN personas p ON e.id = p.empresa_id
WHERE p.id IS NULL;
```

---

### Consulta 2.17
**Enunciado:** Identificar los módulos que todavía no hayan sido asignados a ninguna organización.
```sql
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
```

---

### Consulta 2.18
**Enunciado:** Consultar las etapas PHVA mostrando el número de plantillas que se encuentran asociadas a cada una.
```sql
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
```

---

### Consulta 2.19
**Enunciado:** Determinar cuántas organizaciones se encuentran registradas en cada municipio o ciudad.
```sql
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
```

---

### Consulta 2.20
**Enunciado:** Consultar los cargos existentes en cada organización y determinar cuántas personas ocupan cada cargo.
```sql
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
```

---

## 3. Consultas SQL Avanzadas

### Consulta 3.1
**Enunciado:** Identificar la organización que tenga la mayor cantidad de personas registradas, mostrando el nombre de la organización y el número total de personas asociadas.
```sql
SELECT 
    e.id AS tenant_id,
    e.razon_social AS organizacion,
    COUNT(p.id) AS total_personas
FROM empresas e
JOIN personas p ON e.id = p.empresa_id
GROUP BY e.id, e.razon_social
ORDER BY total_personas DESC
LIMIT 1;
```

---

### Consulta 3.2
**Enunciado:** Consultar las organizaciones cuya cantidad de personas registradas sea superior al promedio general de personas por organización.
```sql
WITH conteo_personas AS (
    SELECT 
        empresa_id, 
        COUNT(*) AS num_personas
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
```

---

### Consulta 3.3
**Enunciado:** Identificar las organizaciones que tengan habilitados todos los módulos existentes para un sistema SST determinado (ej. sistema 'SST').
```sql
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
```

---

### Consulta 3.4
**Enunciado:** Determinar las organizaciones que tengan al menos un módulo configurado pero que todavía no tengan plantillas asignadas.
```sql
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
```

---

### Consulta 3.5
**Enunciado:** Consultar las organizaciones que tengan plantillas asociadas a todas las etapas PHVA disponibles en el sistema (4 etapas: Planear, Hacer, Verificar, Actuar).
```sql
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
```

---

### Consulta 3.6
**Enunciado:** Calcular la cantidad de plantillas asignadas a cada organización discriminadas por etapa PHVA.
```sql
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
```

---

### Consulta 3.7
**Enunciado:** Construir una consulta que presente en columnas independientes la cantidad de plantillas correspondientes a Planear, Hacer, Verificar y Actuar para cada organización (Pivot).
```sql
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
```

---

### Consulta 3.8
**Enunciado:** Determinar el porcentaje que representa cada etapa PHVA sobre el total de plantillas asignadas a una organización.
```sql
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
```

---

### Consulta 3.9
**Enunciado:** Identificar la etapa PHVA que tenga la mayor cantidad de plantillas asignadas dentro de cada organización.
```sql
WITH ranking_etapas AS (
    SELECT 
        e.razon_social AS organizacion,
        ep.nombre AS etapa_phva,
        COUNT(de.id) AS cantidad_plantillas,
        DENSE_RANK() OVER (
            PARTITION BY e.id 
            ORDER BY COUNT(de.id) DESC
        ) AS posicion_ranking
    FROM empresas e
    JOIN documentos_empresa de ON e.id = de.empresa_id
    JOIN plantillas p ON de.plantilla_id = p.id
    JOIN modulos m ON p.modulo_id = m.id
    JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
    GROUP BY e.id, e.razon_social, ep.id, ep.nombre
)
SELECT 
    organizacion,
    etapa_phva,
    cantidad_plantillas
FROM ranking_etapas
WHERE posicion_ranking = 1;
```

---

### Consulta 3.10
**Enunciado:** Calcular el porcentaje de documentos finalizados frente al total de documentos asociados a cada organización utilizando la información disponible en las vistas de resumen.
```sql
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
```

---

### Consulta 3.11
**Enunciado:** Determinar las organizaciones cuyo porcentaje de cumplimiento documental se encuentre por debajo del promedio general del sistema.
```sql
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
SELECT 
    id,
    razon_social,
    porcentaje_cumplimiento
FROM metricas_tenant
WHERE porcentaje_cumplimiento < (SELECT AVG(porcentaje_cumplimiento) FROM metricas_tenant);
```

---

### Consulta 3.12
**Enunciado:** Clasificar las organizaciones según su porcentaje de cumplimiento, estableciendo categorías como bajo, medio y alto mediante una expresión `CASE`.
```sql
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
```

---

### Consulta 3.13
**Enunciado:** Generar un ranking de organizaciones de acuerdo con su porcentaje de cumplimiento documental utilizando funciones de ventana.
```sql
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
```

---

### Consulta 3.14
**Enunciado:** Mostrar para cada organización su porcentaje de cumplimiento y la diferencia existente respecto al promedio general de cumplimiento.
```sql
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
```

---

### Consulta 3.15
**Enunciado:** Determinar la cantidad acumulada de documentos finalizados por organización utilizando una función de ventana.
```sql
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
```

---

### Consulta 3.16
**Enunciado:** Identificar las organizaciones que compartan el mismo municipio pero tengan diferente tamaño empresarial.
```sql
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
```

---

### Consulta 3.17
**Enunciado:** Encontrar las personas cuyo cargo sea utilizado por más personas que el promedio de ocupación de los cargos dentro de su organización.
```sql
WITH conteo_cargos AS (
    SELECT 
        empresa_id,
        cargo_id,
        COUNT(*) AS total_ocupantes
    FROM personas
    GROUP BY empresa_id, cargo_id
),
promedios_tenant AS (
    SELECT 
        empresa_id,
        AVG(total_ocupantes) AS promedio_ocupacion
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
```

---

### Consulta 3.18
**Enunciado:** Utilizar una expresión común de tabla, `CTE`, para calcular inicialmente la cantidad de personas por organización y posteriormente seleccionar únicamente las organizaciones que superen el promedio.
```sql
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
```

---

### Consulta 3.19
**Enunciado:** Utilizar un `CTE` para consolidar la cantidad de módulos, plantillas y personas correspondientes a cada organización.
```sql
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
```

---

### Consulta 3.20
**Enunciado:** Determinar las organizaciones que no tengan configurada alguna etapa PHVA requerida dentro de sus plantillas.
```sql
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
```

---

### Consulta 3.21
**Enunciado:** Consultar la última fecha de actualización registrada para cada organización considerando sus plantillas asociadas.
```sql
SELECT 
    e.id AS empresa_id,
    e.razon_social,
    MAX(de.updated_at) AS ultima_actualizacion_documental
FROM empresas e
LEFT JOIN documentos_empresa de ON e.id = de.empresa_id
GROUP BY e.id, e.razon_social
ORDER BY ultima_actualizacion_documental DESC NULLS LAST;
```

---

### Consulta 3.22
**Enunciado:** Determinar cuáles organizaciones presentan registros documentales pendientes utilizando las vistas `vm_template_pesv_docs_summary` y `vm_template_sst_docs_summary` (en el modelo: `vw_cumplimiento_documental_tenant`).
```sql
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
```

---

### Consulta 3.23
**Enunciado:** Generar un informe consolidado que muestre por organización el total de documentos, documentos finalizados, documentos en borrador, documentos no iniciados, documentos pendientes y porcentaje de cumplimiento.
```sql
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
```

---

### Consulta 3.24
**Enunciado:** Comparar el porcentaje de cumplimiento SST y PESV de cada organización, identificando aquellas en las cuales exista una diferencia superior a un valor establecido (ej. brecha > 10%).
```sql
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
```

---

### Consulta 3.25
**Enunciado:** Construir una vista que consolide la cantidad de personas, módulos, plantillas y sistemas habilitados para cada organización.
```sql
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

-- Para probarla:
SELECT * FROM vw_capacidades_consolidadas_tenant;
```

---

## 4. Consultas Orientadas a Vistas y Vistas Materializadas

### Vista 4.1
**Enunciado:** Crear una vista denominada `vw_tenant_persons` que permita consultar las organizaciones junto con sus personas y cargos asociados.
```sql
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

-- Prueba:
SELECT * FROM vw_tenant_persons;
```

---

### Vista 4.2
**Enunciado:** Crear una vista que consolide la información geográfica de las organizaciones incluyendo municipio, departamento o región y país.
```sql
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

-- Prueba:
SELECT * FROM vw_tenant_geografia;
```

---

### Vista 4.3
**Enunciado:** Crear una vista que muestre los módulos habilitados para cada organización y el sistema SST al cual pertenecen.
```sql
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

-- Prueba:
SELECT * FROM vw_tenant_modulos_habilitados;
```

---

### Vista 4.4
**Enunciado:** Crear una vista que presente la cantidad total de plantillas asociadas a cada organización y etapa PHVA.
```sql
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
GROUP BY e.id, e.razon_social, ep.id, ep.codigo, ep.nombre, ep.orden_secuencia
ORDER BY e.razon_social, ep.orden_secuencia;

-- Prueba:
SELECT * FROM vw_tenant_plantillas_por_etapa;
```

---

### Vista 4.5
**Enunciado:** Crear una vista que permita consultar el total de personas existentes por organización y cargo.
```sql
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

-- Prueba:
SELECT * FROM vw_personas_por_organizacion_cargo;
```

---

### Vista 4.6
**Enunciado:** Crear una vista materializada que consolide el número total de documentos, documentos finalizados, documentos pendientes y porcentaje de cumplimiento por organización.
```sql
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

-- Crear índice único requerido para refresh concurrente:
CREATE UNIQUE INDEX uq_idx_vm_resumen_tenant ON vm_resumen_documental_cumplimiento(tenant_id);

-- Prueba:
SELECT * FROM vm_resumen_documental_cumplimiento;
```

---

### Vista 4.7
**Enunciado:** Actualizar una vista materializada mediante `REFRESH MATERIALIZED VIEW` y verificar que los valores consolidados reflejen los últimos cambios.
```sql
-- Refresco convencional:
REFRESH MATERIALIZED VIEW vm_resumen_documental_cumplimiento;

-- O con opción concurrente (sin bloquear lecturas concurrentes):
REFRESH MATERIALIZED VIEW CONCURRENTLY vm_resumen_documental_cumplimiento;

-- Verificación:
SELECT * FROM vm_resumen_documental_cumplimiento;
```

---

### Vista 4.8
**Enunciado:** Analizar qué columnas de la vista materializada deberían contar con índices para optimizar las consultas de seguimiento por organización.
```sql
-- Índice para filtrado y ordenamiento por porcentaje de avance (dashboard de líderes):
CREATE INDEX idx_vm_resumen_cumplimiento 
ON vm_resumen_documental_cumplimiento(porcentaje_cumplimiento DESC);

-- Índice para búsqueda por NIT o Razón Social:
CREATE INDEX idx_vm_resumen_organizacion 
ON vm_resumen_documental_cumplimiento(organizacion);
```
* **Análisis:** Indexar `porcentaje_cumplimiento` acelera los filtros de empresas en estado crítico (`< 60%`), y el índice sobre `organizacion` optimiza búsquedas tipo autocompletado en el front-end.

---

## 5. Procedimientos Almacenados

### Procedimiento 5.1
**Enunciado:** Desarrollar un procedimiento almacenado que permita registrar una nueva organización, validando previamente que no exista otra organización con los mismos datos de identificación.
```sql
CREATE OR REPLACE PROCEDURE sp_registrar_organizacion(
    p_nit VARCHAR(20),
    p_dv CHAR(1),
    p_razon_social VARCHAR(150),
    p_sector VARCHAR(100),
    p_clase_riesgo SMALLINT,
    p_tamano_id INT,
    p_municipio_id INT,
    p_direccion VARCHAR(150),
    p_email VARCHAR(100),
    p_telefono VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar si ya existe el NIT
    IF EXISTS (SELECT 1 FROM empresas WHERE nit = p_nit) THEN
        RAISE EXCEPTION 'La organización con NIT % ya se encuentra registrada en el sistema.', p_nit;
    END IF;

    INSERT INTO empresas (
        nit, dv, razon_social, sector_economico, clase_riesgo_arl,
        tamano_id, municipio_id, direccion_principal, email_contacto, telefono
    ) VALUES (
        p_nit, p_dv, p_razon_social, p_sector, p_clase_riesgo,
        p_tamano_id, p_municipio_id, p_direccion, p_email, p_telefono
    );

    RAISE NOTICE 'Organización "%" registrada exitosamente.', p_razon_social;
END;
$$;

-- Prueba de llamada:
-- CALL sp_registrar_organizacion('900999888', '5', 'Servicios Integrales SAS', 'Servicios', 1::smallint, 1, 1, 'Calle 100 # 15-20', 'info@servicios.com', '6015554433');
```

---

### Procedimiento 5.2
**Enunciado:** Desarrollar un procedimiento almacenado que permita registrar una nueva persona y asociarla a una organización y a un cargo determinado.
```sql
CREATE OR REPLACE PROCEDURE sp_registrar_persona(
    p_empresa_id INT,
    p_tipo_doc VARCHAR(10),
    p_num_doc VARCHAR(20),
    p_nombres VARCHAR(80),
    p_apellidos VARCHAR(80),
    p_email VARCHAR(100),
    p_telefono VARCHAR(30),
    p_cargo_id INT,
    p_rol_sistema_id INT,
    p_fecha_ingreso DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar que el cargo pertenezca a la empresa
    IF NOT EXISTS (SELECT 1 FROM cargos WHERE id = p_cargo_id AND empresa_id = p_empresa_id) THEN
        RAISE EXCEPTION 'El cargo ID % no pertenece a la organización ID %.', p_cargo_id, p_empresa_id;
    END IF;

    -- Validar documento duplicado en la misma empresa
    IF EXISTS (SELECT 1 FROM personas WHERE empresa_id = p_empresa_id AND tipo_documento = p_tipo_doc AND numero_documento = p_num_doc) THEN
        RAISE EXCEPTION 'Ya existe una persona registrada con documento % % en esta empresa.', p_tipo_doc, p_num_doc;
    END IF;

    INSERT INTO personas (
        empresa_id, tipo_documento, numero_documento, nombres, apellidos,
        email, telefono, cargo_id, rol_sistema_id, fecha_ingreso
    ) VALUES (
        p_empresa_id, p_tipo_doc, p_num_doc, p_nombres, p_apellidos,
        p_email, p_telefono, p_cargo_id, p_rol_sistema_id, p_fecha_ingreso
    );

    RAISE NOTICE 'Persona "% %" registrada con éxito.', p_nombres, p_apellidos;
END;
$$;
```

---

### Procedimiento 5.3
**Enunciado:** Desarrollar un procedimiento almacenado que permita cambiar el estado de una organización entre activa e inactiva.
```sql
CREATE OR REPLACE PROCEDURE sp_cambiar_estado_organizacion(
    p_empresa_id INT,
    p_nuevo_estado BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE empresas
    SET activo = p_nuevo_estado,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_empresa_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la organización con ID %.', p_empresa_id;
    END IF;

    RAISE NOTICE 'Estado de la organización ID % actualizado a: %.', p_empresa_id, p_nuevo_estado;
END;
$$;

-- Prueba:
-- CALL sp_cambiar_estado_organizacion(1, TRUE);
```

---

### Procedimiento 5.4
**Enunciado:** Desarrollar un procedimiento almacenado que permita asignar un módulo determinado a una organización evitando asignaciones duplicadas.
```sql
CREATE OR REPLACE PROCEDURE sp_asignar_sistema_modulo_empresa(
    p_empresa_id INT,
    p_sistema_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM sistemas_empresa WHERE empresa_id = p_empresa_id AND sistema_id = p_sistema_id) THEN
        RAISE NOTICE 'El sistema ID % ya se encuentra asignado a la empresa ID %.', p_sistema_id, p_empresa_id;
    ELSE
        INSERT INTO sistemas_empresa (empresa_id, sistema_id, estado, fecha_implementacion)
        VALUES (p_empresa_id, p_sistema_id, 'ACTIVO', CURRENT_DATE);
        RAISE NOTICE 'Sistema ID % asignado exitosamente a la empresa ID %.', p_sistema_id, p_empresa_id;
    END IF;
END;
$$;
```

---

### Procedimiento 5.5
**Enunciado:** Desarrollar un procedimiento almacenado que permita habilitar un sistema SST para una organización determinada.
```sql
CREATE OR REPLACE PROCEDURE sp_habilitar_sistema_sst(
    p_empresa_id INT,
    p_codigo_sistema VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sistema_id INT;
BEGIN
    SELECT id INTO v_sistema_id FROM sistemas_gestion WHERE codigo = p_codigo_sistema;
    IF v_sistema_id IS NULL THEN
        RAISE EXCEPTION 'El sistema con código "%" no existe.', p_codigo_sistema;
    END IF;

    INSERT INTO sistemas_empresa (empresa_id, sistema_id, estado)
    VALUES (p_empresa_id, v_sistema_id, 'ACTIVO')
    ON CONFLICT (empresa_id, sistema_id) 
    DO UPDATE SET estado = 'ACTIVO';

    RAISE NOTICE 'Sistema % habilitado para la empresa ID %.', p_codigo_sistema, p_empresa_id;
END;
$$;
```

---

### Procedimiento 5.6
**Enunciado:** Desarrollar un procedimiento almacenado que permita asignar una plantilla a una organización indicando sistema, etapa PHVA y formato correspondiente.
```sql
CREATE OR REPLACE PROCEDURE sp_asignar_plantilla_empresa(
    p_empresa_id INT,
    p_plantilla_id INT,
    p_elaborado_por_id INT,
    p_codigo_doc VARCHAR(50),
    p_titulo VARCHAR(180)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM documentos_empresa WHERE empresa_id = p_empresa_id AND plantilla_id = p_plantilla_id) THEN
        RAISE NOTICE 'La plantilla % ya está instanciada para la empresa %.', p_plantilla_id, p_empresa_id;
    ELSE
        INSERT INTO documentos_empresa (
            empresa_id, plantilla_id, codigo_documento, titulo,
            version, estado, elaborado_por_id, fecha_elaboracion
        ) VALUES (
            p_empresa_id, p_plantilla_id, p_codigo_doc, p_titulo,
            1, 'BORRADOR', p_elaborado_por_id, CURRENT_DATE
        );
        RAISE NOTICE 'Plantilla % asignada como documento "%".', p_plantilla_id, p_titulo;
    END IF;
END;
$$;
```

---

### Procedimiento 5.7
**Enunciado:** Desarrollar un procedimiento almacenado que permita cambiar el cargo de una persona dentro de una organización.
```sql
CREATE OR REPLACE PROCEDURE sp_cambiar_cargo_persona(
    p_persona_id INT,
    p_nuevo_cargo_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_empresa_persona INT;
    v_empresa_cargo INT;
BEGIN
    SELECT empresa_id INTO v_empresa_persona FROM personas WHERE id = p_persona_id;
    SELECT empresa_id INTO v_empresa_cargo FROM cargos WHERE id = p_nuevo_cargo_id;

    IF v_empresa_persona IS NULL THEN
        RAISE EXCEPTION 'La persona ID % no existe.', p_persona_id;
    END IF;

    IF v_empresa_persona <> v_empresa_cargo THEN
        RAISE EXCEPTION 'El nuevo cargo no pertenece a la misma empresa de la persona.';
    END IF;

    UPDATE personas SET cargo_id = p_nuevo_cargo_id WHERE id = p_persona_id;
    RAISE NOTICE 'Cargo de la persona ID % actualizado exitosamente.', p_persona_id;
END;
$$;
```

---

### Procedimiento 5.8
**Enunciado:** Desarrollar un procedimiento almacenado que permita trasladar una persona de una organización a otra, actualizando las relaciones necesarias.
```sql
CREATE OR REPLACE PROCEDURE sp_trasladar_persona(
    p_persona_id INT,
    p_nueva_empresa_id INT,
    p_nuevo_cargo_id INT,
    p_nueva_sede_id INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar que el nuevo cargo pertenezca a la nueva empresa
    IF NOT EXISTS (SELECT 1 FROM cargos WHERE id = p_nuevo_cargo_id AND empresa_id = p_nueva_empresa_id) THEN
        RAISE EXCEPTION 'El cargo ID % no pertenece a la nueva empresa ID %.', p_nuevo_cargo_id, p_nueva_empresa_id;
    END IF;

    UPDATE personas
    SET empresa_id = p_nueva_empresa_id,
        cargo_id = p_nuevo_cargo_id,
        sede_id = p_nueva_sede_id
    WHERE id = p_persona_id;

    RAISE NOTICE 'Persona ID % trasladada satisfactoriamente a la empresa ID %.', p_persona_id, p_nueva_empresa_id;
END;
$$;
```

---

### Procedimiento 5.9
**Enunciado:** Desarrollar un procedimiento almacenado que permita deshabilitar todos los módulos asociados a una organización que haya sido marcada como inactiva.
```sql
CREATE OR REPLACE PROCEDURE sp_deshabilitar_sistemas_empresa_inactiva(
    p_empresa_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_activa BOOLEAN;
BEGIN
    SELECT activo INTO v_activa FROM empresas WHERE id = p_empresa_id;
    
    IF v_activa = TRUE THEN
        RAISE NOTICE 'La empresa ID % continúa activa. No se deshabilitaron sistemas.', p_empresa_id;
        RETURN;
    END IF;

    UPDATE sistemas_empresa
    SET estado = 'SUSPENDIDO'
    WHERE empresa_id = p_empresa_id;

    RAISE NOTICE 'Todos los sistemas de la empresa inactiva ID % fueron suspendidos.', p_empresa_id;
END;
$$;
```

---

### Procedimiento 5.10
**Enunciado:** Desarrollar un procedimiento almacenado que permita eliminar de manera controlada una asignación de módulo, validando previamente que no existan registros dependientes que impidan la operación.
```sql
CREATE OR REPLACE PROCEDURE sp_eliminar_asignacion_sistema(
    p_empresa_id INT,
    p_sistema_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_docs_asociados INT;
BEGIN
    -- Validar si existen documentos generados en módulos de este sistema
    SELECT COUNT(de.id) INTO v_docs_asociados
    FROM documentos_empresa de
    JOIN plantillas p ON de.plantilla_id = p.id
    JOIN modulos m ON p.modulo_id = m.id
    WHERE de.empresa_id = p_empresa_id AND m.sistema_id = p_sistema_id;

    IF v_docs_asociados > 0 THEN
        RAISE EXCEPTION 'No se puede desvincular el sistema: existen % documentos generados.', v_docs_asociados;
    END IF;

    DELETE FROM sistemas_empresa 
    WHERE empresa_id = p_empresa_id AND sistema_id = p_sistema_id;

    RAISE NOTICE 'Asignación del sistema ID % eliminada correctamente para la empresa ID %.', p_sistema_id, p_empresa_id;
END;
$$;
```

---

### Procedimiento 5.11
**Enunciado:** Desarrollar un procedimiento almacenado que determine el número total de plantillas asociadas a una organización y muestre el resultado mediante `RAISE NOTICE`.
```sql
CREATE OR REPLACE PROCEDURE sp_contar_plantillas_organizacion(
    p_empresa_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
    v_nombre VARCHAR(150);
BEGIN
    SELECT razon_social INTO v_nombre FROM empresas WHERE id = p_empresa_id;
    SELECT COUNT(*) INTO v_total FROM documentos_empresa WHERE empresa_id = p_empresa_id;

    RAISE NOTICE '📋 La organización "%" (ID: %) tiene % plantilla(s)/documento(s) asignados.',
        v_nombre, p_empresa_id, v_total;
END;
$$;

-- Prueba:
CALL sp_contar_plantillas_organizacion(1);
```

---

### Procedimiento 5.12
**Enunciado:** Desarrollar un procedimiento almacenado que determine el porcentaje de cumplimiento documental de una organización a partir de sus documentos finalizados y pendientes.
```sql
CREATE OR REPLACE PROCEDURE sp_calcular_cumplimiento_organizacion(
    p_empresa_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
    v_finalizados INT;
    v_pct NUMERIC(5, 2);
BEGIN
    SELECT COUNT(*), COUNT(CASE WHEN estado = 'APROBADO' THEN 1 END)
    INTO v_total, v_finalizados
    FROM documentos_empresa
    WHERE empresa_id = p_empresa_id;

    IF v_total = 0 THEN
        v_pct := 0.00;
    ELSE
        v_pct := ROUND((v_finalizados::numeric / v_total) * 100, 2);
    END IF;

    RAISE NOTICE '📊 Empresa ID % -> Total: %, Finalizados: %, Cumplimiento: % %',
        p_empresa_id, v_total, v_finalizados, v_pct, '%';
END;
$$;

-- Prueba:
CALL sp_calcular_cumplimiento_organizacion(1);
```

---

### Procedimiento 5.13
**Enunciado:** Desarrollar un procedimiento almacenado que reciba una organización y una etapa PHVA y determine la cantidad de documentos correspondientes a dicha etapa.
```sql
CREATE OR REPLACE PROCEDURE sp_contar_documentos_etapa(
    p_empresa_id INT,
    p_codigo_etapa CHAR(1)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_conteo INT;
    v_etapa_nombre VARCHAR(30);
BEGIN
    SELECT nombre INTO v_etapa_nombre FROM etapas_phva WHERE codigo = p_codigo_etapa;
    
    SELECT COUNT(de.id) INTO v_conteo
    FROM documentos_empresa de
    JOIN plantillas p ON de.plantilla_id = p.id
    JOIN modulos m ON p.modulo_id = m.id
    JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
    WHERE de.empresa_id = p_empresa_id AND ep.codigo = p_codigo_etapa;

    RAISE NOTICE 'Etapa "%" (%): % documentos para la empresa ID %.',
        v_etapa_nombre, p_codigo_etapa, v_conteo, p_empresa_id;
END;
$$;

-- Prueba:
CALL sp_contar_documentos_etapa(1, 'P');
```

---

### Procedimiento 5.14
**Enunciado:** Desarrollar un procedimiento almacenado que permita modificar simultáneamente los datos de contacto de una organización y registre la fecha de actualización correspondiente.
```sql
CREATE OR REPLACE PROCEDURE sp_actualizar_contacto_organizacion(
    p_empresa_id INT,
    p_nuevo_email VARCHAR(100),
    p_nuevo_telefono VARCHAR(30),
    p_nueva_direccion VARCHAR(150)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE empresas
    SET email_contacto = p_nuevo_email,
        telefono = p_nuevo_telefono,
        direccion_principal = p_nueva_direccion,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_empresa_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la empresa con ID %.', p_empresa_id;
    END IF;

    RAISE NOTICE 'Datos de contacto y updated_at modificados con éxito para la empresa ID %.', p_empresa_id;
END;
$$;
```

---

### Procedimiento 5.15
**Enunciado:** Desarrollar un procedimiento con manejo de excepciones para asignar plantillas controlando cualquier error de integridad referencial o duplicidad.
```sql
CREATE OR REPLACE PROCEDURE sp_asignar_plantilla_segura(
    p_empresa_id INT,
    p_plantilla_id INT,
    p_elaborado_por_id INT,
    p_codigo_doc VARCHAR(50),
    p_titulo VARCHAR(180)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO documentos_empresa (
        empresa_id, plantilla_id, codigo_documento, titulo,
        version, estado, elaborado_por_id, fecha_elaboracion
    ) VALUES (
        p_empresa_id, p_plantilla_id, p_codigo_doc, p_titulo,
        1, 'BORRADOR', p_elaborado_por_id, CURRENT_DATE
    );
    
    RAISE NOTICE 'Asignación procesada exitosamente.';
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Error controlado: La plantilla o código "%" ya existe para la empresa.', p_codigo_doc;
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Error controlado: La empresa, plantilla o persona especificada no existe.';
    WHEN OTHERS THEN
        RAISE NOTICE 'Ocurrió una excepción imprevista: % (Código SQL: %)', SQLERRM, SQLSTATE;
END;
$$;
```

---

## 6. Funciones Almacenadas

### Función 6.1
**Enunciado:** Implementar una función que reciba el identificador de una organización y retorne la cantidad total de personas asociadas.
```sql
CREATE OR REPLACE FUNCTION fn_total_personas_tenant(p_empresa_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
BEGIN
    SELECT COUNT(*) INTO v_total FROM personas WHERE empresa_id = p_empresa_id;
    RETURN v_total;
END;
$$;

-- Prueba:
SELECT fn_total_personas_tenant(1);
```

---

### Función 6.2
**Enunciado:** Implementar una función que reciba el identificador de una organización y retorne su porcentaje de cumplimiento documental.
```sql
CREATE OR REPLACE FUNCTION fn_porcentaje_cumplimiento_tenant(p_empresa_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
    v_aprobados INT;
BEGIN
    SELECT COUNT(*), COUNT(CASE WHEN estado = 'APROBADO' THEN 1 END)
    INTO v_total, v_aprobados
    FROM documentos_empresa
    WHERE empresa_id = p_empresa_id;

    IF v_total = 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND((v_aprobados::numeric / v_total) * 100, 2);
END;
$$;

-- Prueba:
SELECT fn_porcentaje_cumplimiento_tenant(1) AS porcentaje;
```

---

### Función 6.3
**Enunciado:** Implementar una función que determine si una organización tiene habilitado un módulo específico y retorne un valor booleano.
```sql
CREATE OR REPLACE FUNCTION fn_tiene_modulo_habilitado(
    p_empresa_id INT,
    p_codigo_modulo VARCHAR(30)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_existe BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM sistemas_empresa se
        JOIN modulos m ON se.sistema_id = m.sistema_id
        WHERE se.empresa_id = p_empresa_id 
          AND se.estado = 'ACTIVO'
          AND m.codigo = p_codigo_modulo
          AND m.activo = TRUE
    ) INTO v_existe;

    RETURN v_existe;
END;
$$;

-- Prueba:
SELECT fn_tiene_modulo_habilitado(1, 'SST_P_POLITICA');
```

---

### Función 6.4
**Enunciado:** Implementar una función que reciba el identificador de una persona y retorne su nombre completo.
```sql
CREATE OR REPLACE FUNCTION fn_nombre_completo_persona(p_persona_id INT)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombre VARCHAR(200);
BEGIN
    SELECT nombres || ' ' || apellidos INTO v_nombre
    FROM personas
    WHERE id = p_persona_id;

    RETURN COALESCE(v_nombre, 'Persona no encontrada');
END;
$$;

-- Prueba:
SELECT fn_nombre_completo_persona(1);
```

---

### Función 6.5
**Enunciado:** Implementar una función que retorne la cantidad de plantillas existentes para una organización y una etapa PHVA determinada.
```sql
CREATE OR REPLACE FUNCTION fn_plantillas_por_etapa(
    p_empresa_id INT,
    p_codigo_etapa CHAR(1)
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_conteo INT;
BEGIN
    SELECT COUNT(de.id) INTO v_conteo
    FROM documentos_empresa de
    JOIN plantillas p ON de.plantilla_id = p.id
    JOIN modulos m ON p.modulo_id = m.id
    JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
    WHERE de.empresa_id = p_empresa_id AND ep.codigo = p_codigo_etapa;

    RETURN COALESCE(v_conteo, 0);
END;
$$;

-- Prueba:
SELECT fn_plantillas_por_etapa(1, 'P');
```

---

### Función 6.6
**Enunciado:** Implementar una función tabular que retorne todos los módulos habilitados para una organización.
```sql
CREATE OR REPLACE FUNCTION fn_modulos_habilitados_tenant(p_empresa_id INT)
RETURNS TABLE (
    modulo_id INT,
    codigo_modulo VARCHAR(30),
    nombre_modulo VARCHAR(120),
    sistema_gestion VARCHAR(100),
    etapa_phva VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.codigo,
        m.nombre,
        sg.nombre,
        ep.nombre
    FROM sistemas_empresa se
    JOIN sistemas_gestion sg ON se.sistema_id = sg.id
    JOIN modulos m ON sg.id = m.sistema_id
    JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
    WHERE se.empresa_id = p_empresa_id 
      AND se.estado = 'ACTIVO'
      AND m.activo = TRUE
    ORDER BY ep.orden_secuencia, m.id;
END;
$$;

-- Prueba:
SELECT * FROM fn_modulos_habilitados_tenant(1);
```

---

### Función 6.7
**Enunciado:** Implementar una función tabular que retorne las personas pertenecientes a una organización junto con sus respectivos cargos.
```sql
CREATE OR REPLACE FUNCTION fn_personas_cargos_tenant(p_empresa_id INT)
RETURNS TABLE (
    persona_id INT,
    documento VARCHAR(35),
    nombre_completo VARCHAR(165),
    email VARCHAR(100),
    cargo VARCHAR(100),
    nivel_jerarquico VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.tipo_documento || ' ' || p.numero_documento,
        (p.nombres || ' ' || p.apellidos)::VARCHAR(165),
        p.email,
        c.nombre,
        c.nivel_jerarquico
    FROM personas p
    JOIN cargos c ON p.cargo_id = c.id
    WHERE p.empresa_id = p_empresa_id
    ORDER BY c.nombre, p.apellidos;
END;
$$;

-- Prueba:
SELECT * FROM fn_personas_cargos_tenant(1);
```

---

### Función 6.8
**Enunciado:** Implementar una función que clasifique el nivel de cumplimiento de una organización como bajo, medio o alto según el porcentaje calculado.
```sql
CREATE OR REPLACE FUNCTION fn_clasificar_cumplimiento(p_porcentaje NUMERIC)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_porcentaje IS NULL OR p_porcentaje < 60.00 THEN
        RETURN 'BAJO';
    ELSIF p_porcentaje BETWEEN 60.00 AND 84.99 THEN
        RETURN 'MEDIO';
    ELSE
        RETURN 'ALTO';
    END IF;
END;
$$;

-- Prueba:
SELECT 
    razon_social,
    fn_porcentaje_cumplimiento_tenant(id) AS pct,
    fn_clasificar_cumplimiento(fn_porcentaje_cumplimiento_tenant(id)) AS clasificacion
FROM empresas;
```

---

## 7. Triggers

### Trigger 7.1
**Enunciado:** Implementar un trigger que actualice automáticamente el campo `updated_at` cada vez que se modifique un registro de la tabla `tenants` (`empresas`).
```sql
CREATE OR REPLACE FUNCTION fn_trg_actualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_actualizar_updated_at_empresas ON empresas;

CREATE TRIGGER trg_actualizar_updated_at_empresas
BEFORE UPDATE ON empresas
FOR EACH ROW
EXECUTE FUNCTION fn_trg_actualizar_updated_at();
```

---

### Trigger 7.2
**Enunciado:** Implementar un trigger que actualice automáticamente el campo `updated_at` cuando se modifique información de una persona.
```sql
-- Si la tabla personas no tiene columna updated_at, la adicionamos:
ALTER TABLE personas ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

DROP TRIGGER IF EXISTS trg_actualizar_updated_at_personas ON personas;

CREATE TRIGGER trg_actualizar_updated_at_personas
BEFORE UPDATE ON personas
FOR EACH ROW
EXECUTE FUNCTION fn_trg_actualizar_updated_at();
```

---

### Trigger 7.3
**Enunciado:** Implementar un trigger que impida registrar una persona en una organización que se encuentre inactiva.
```sql
CREATE OR REPLACE FUNCTION fn_trg_validar_persona_empresa_activa()
RETURNS TRIGGER AS $$
DECLARE
    v_activa BOOLEAN;
BEGIN
    SELECT activo INTO v_activa FROM empresas WHERE id = NEW.empresa_id;
    
    IF v_activa IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'Operación denegada: La empresa ID % está INACTIVA y no puede registrar nuevos colaboradores.', NEW.empresa_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_persona_empresa_activa ON personas;

CREATE TRIGGER trg_validar_persona_empresa_activa
BEFORE INSERT ON personas
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validar_persona_empresa_activa();
```

---

### Trigger 7.4
**Enunciado:** Implementar un trigger que impida asignar un módulo a una organización cuando dicho módulo ya se encuentre previamente asignado.
```sql
CREATE OR REPLACE FUNCTION fn_trg_impedir_modulo_duplicado()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM sistemas_empresa 
        WHERE empresa_id = NEW.empresa_id 
          AND sistema_id = NEW.sistema_id
          AND id <> COALESCE(NEW.id, -1)
    ) THEN
        RAISE EXCEPTION 'El sistema/módulo ya se encuentra asignado a esta organización.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_impedir_modulo_duplicado ON sistemas_empresa;

CREATE TRIGGER trg_impedir_modulo_duplicado
BEFORE INSERT ON sistemas_empresa
FOR EACH ROW
EXECUTE FUNCTION fn_trg_impedir_modulo_duplicado();
```

---

### Trigger 7.5
**Enunciado:** Implementar un trigger que impida asignar plantillas a organizaciones cuyo estado se encuentre inactivo.
```sql
CREATE OR REPLACE FUNCTION fn_trg_impedir_plantilla_empresa_inactiva()
RETURNS TRIGGER AS $$
DECLARE
    v_activa BOOLEAN;
BEGIN
    SELECT activo INTO v_activa FROM empresas WHERE id = NEW.empresa_id;
    IF v_activa IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'No se pueden generar o asignar plantillas a una empresa inactiva (ID %).', NEW.empresa_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_impedir_plantilla_empresa_inactiva ON documentos_empresa;

CREATE TRIGGER trg_impedir_plantilla_empresa_inactiva
BEFORE INSERT ON documentos_empresa
FOR EACH ROW
EXECUTE FUNCTION fn_trg_impedir_plantilla_empresa_inactiva();
```

---

### Trigger 7.6
**Enunciado:** Implementar un trigger que valide que una persona únicamente pueda ser asociada a un cargo perteneciente a la misma organización.
```sql
CREATE OR REPLACE FUNCTION fn_trg_validar_cargo_misma_empresa()
RETURNS TRIGGER AS $$
DECLARE
    v_empresa_cargo INT;
BEGIN
    SELECT empresa_id INTO v_empresa_cargo FROM cargos WHERE id = NEW.cargo_id;
    
    IF v_empresa_cargo IS DISTINCT FROM NEW.empresa_id THEN
        RAISE EXCEPTION 'Inconsistencia Multi-Tenant: El cargo ID % pertenece a la empresa ID %, no a la empresa ID %.',
            NEW.cargo_id, v_empresa_cargo, NEW.empresa_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_cargo_misma_empresa ON personas;

CREATE TRIGGER trg_validar_cargo_misma_empresa
BEFORE INSERT OR UPDATE ON personas
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validar_cargo_misma_empresa();
```

---

### Trigger 7.7
**Enunciado:** Implementar un trigger que registre automáticamente la fecha de actualización cuando se produzca una modificación en una plantilla asignada a una organización.
```sql
CREATE OR REPLACE FUNCTION fn_trg_actualizar_fecha_plantilla()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_actualizar_fecha_plantilla ON documentos_empresa;

CREATE TRIGGER trg_actualizar_fecha_plantilla
BEFORE UPDATE ON documentos_empresa
FOR EACH ROW
EXECUTE FUNCTION fn_trg_actualizar_fecha_plantilla();
```

---

### Trigger 7.8
**Enunciado:** Implementar un trigger que impida eliminar una organización cuando todavía existan personas asociadas a ella.
```sql
CREATE OR REPLACE FUNCTION fn_trg_impedir_eliminar_empresa_con_personas()
RETURNS TRIGGER AS $$
DECLARE
    v_personas_activas INT;
BEGIN
    SELECT COUNT(*) INTO v_personas_activas FROM personas WHERE empresa_id = OLD.id;
    
    IF v_personas_activas > 0 THEN
        RAISE EXCEPTION 'Violación de integridad: No se puede eliminar la empresa "%" porque tiene % colaborador(es) asociado(s).',
            OLD.razon_social, v_personas_activas;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_impedir_eliminar_empresa_con_personas ON empresas;

CREATE TRIGGER trg_impedir_eliminar_empresa_con_personas
BEFORE DELETE ON empresas
FOR EACH ROW
EXECUTE FUNCTION fn_trg_impedir_eliminar_empresa_con_personas();
```

---

### Trigger 7.9
**Enunciado:** Implementar un trigger que impida eliminar un sistema SST cuando existan organizaciones que lo estén utilizando.
```sql
CREATE OR REPLACE FUNCTION fn_trg_impedir_eliminar_sistema_en_uso()
RETURNS TRIGGER AS $$
DECLARE
    v_en_uso INT;
BEGIN
    SELECT COUNT(*) INTO v_en_uso FROM sistemas_empresa WHERE sistema_id = OLD.id;
    
    IF v_en_uso > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el sistema "%" (ID %): está activo en % empresa(s).',
            OLD.nombre, OLD.id, v_en_uso;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_impedir_eliminar_sistema_en_uso ON sistemas_gestion;

CREATE TRIGGER trg_impedir_eliminar_sistema_en_uso
BEFORE DELETE ON sistemas_gestion
FOR EACH ROW
EXECUTE FUNCTION fn_trg_impedir_eliminar_sistema_en_uso();
```

---

### Trigger 7.10
**Enunciado:** Implementar un trigger que impida eliminar un módulo cuando dicho módulo esté asignado a una o más organizaciones.
```sql
CREATE OR REPLACE FUNCTION fn_trg_impedir_eliminar_modulo_asignado()
RETURNS TRIGGER AS $$
DECLARE
    v_asignaciones INT;
BEGIN
    SELECT COUNT(*) INTO v_asignaciones 
    FROM plantillas p
    JOIN documentos_empresa de ON p.id = de.plantilla_id
    WHERE p.modulo_id = OLD.id;

    IF v_asignaciones > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el módulo "%": tiene % documentos activos generados en clientes.',
            OLD.nombre, v_asignaciones;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_impedir_eliminar_modulo_asignado ON modulos;

CREATE TRIGGER trg_impedir_eliminar_modulo_asignado
BEFORE DELETE ON modulos
FOR EACH ROW
EXECUTE FUNCTION fn_trg_impedir_eliminar_modulo_asignado();
```

---

### Trigger 7.11
**Enunciado:** Implementar un trigger que valide que el porcentaje de cumplimiento calculado para una organización permanezca dentro del rango comprendido entre 0 y 100.
```sql
CREATE OR REPLACE FUNCTION fn_trg_validar_rango_porcentaje()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.porcentaje_cumplimiento < 0.00 OR NEW.porcentaje_cumplimiento > 100.00 THEN
        RAISE EXCEPTION 'El porcentaje de cumplimiento % es inválido. Debe encontrarse entre 0 y 100.', NEW.porcentaje_cumplimiento;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_rango_porcentaje ON autoevaluaciones_empresa;

CREATE TRIGGER trg_validar_rango_porcentaje
BEFORE INSERT OR UPDATE ON autoevaluaciones_empresa
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validar_rango_porcentaje();
```

---

### Trigger 7.12
**Enunciado:** Implementar un trigger que registre en una tabla de auditoría cualquier modificación realizada sobre los datos principales de una organización.
```sql
-- 1. Tabla de auditoría
CREATE TABLE IF NOT EXISTS auditoria_empresas (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL,
    operacion VARCHAR(10) NOT NULL, -- 'UPDATE', 'DELETE'
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    usuario_db VARCHAR(50) DEFAULT CURRENT_USER,
    fecha_evento TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Función del trigger
CREATE OR REPLACE FUNCTION fn_trg_auditar_modificacion_empresa()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO auditoria_empresas (
        empresa_id, operacion, datos_anteriores, datos_nuevos
    ) VALUES (
        OLD.id,
        TG_OP,
        to_jsonb(OLD),
        to_jsonb(NEW)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auditar_modificacion_empresa ON empresas;

CREATE TRIGGER trg_auditar_modificacion_empresa
AFTER UPDATE ON empresas
FOR EACH ROW
EXECUTE FUNCTION fn_trg_auditar_modificacion_empresa();
```

---

### Trigger 7.13
**Enunciado:** Implementar un trigger de auditoría que almacene el valor anterior y el nuevo valor cuando se modifique el estado de una organización.
```sql
CREATE TABLE IF NOT EXISTS auditoria_estado_empresas (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL,
    estado_anterior BOOLEAN,
    estado_nuevo BOOLEAN,
    usuario VARCHAR(50) DEFAULT CURRENT_USER,
    cambiado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION fn_trg_auditar_cambio_estado()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.activo IS DISTINCT FROM NEW.activo THEN
        INSERT INTO auditoria_estado_empresas (
            empresa_id, estado_anterior, estado_nuevo
        ) VALUES (
            OLD.id, OLD.activo, NEW.activo
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auditar_cambio_estado ON empresas;

CREATE TRIGGER trg_auditar_cambio_estado
AFTER UPDATE OF activo ON empresas
FOR EACH ROW
EXECUTE FUNCTION fn_trg_auditar_cambio_estado();
```

---

### Trigger 7.14
**Enunciado:** Implementar un trigger que registre la fecha y el usuario responsable cuando una plantilla/documento sea modificada.
```sql
CREATE TABLE IF NOT EXISTS auditoria_edicion_documentos (
    id SERIAL PRIMARY KEY,
    documento_id INT NOT NULL,
    empresa_id INT NOT NULL,
    version_editada INT,
    usuario_responsable_id INT,
    fecha_edicion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION fn_trg_auditar_edicion_documento()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO auditoria_edicion_documentos (
        documento_id, empresa_id, version_editada, usuario_responsable_id
    ) VALUES (
        NEW.id, NEW.empresa_id, NEW.version, NEW.elaborado_por_id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auditar_edicion_documento ON documentos_empresa;

CREATE TRIGGER trg_auditar_edicion_documento
AFTER UPDATE ON documentos_empresa
FOR EACH ROW
EXECUTE FUNCTION fn_trg_auditar_edicion_documento();
```

---

### Trigger 7.15
**Enunciado:** Implementar un trigger que elimine o marque como inactivos los bloqueos de edición vencidos almacenados en `editing_locks` (`bloqueos_recursos`).
```sql
CREATE OR REPLACE FUNCTION fn_trg_limpiar_bloqueos_vencidos()
RETURNS TRIGGER AS $$
BEGIN
    -- Desactiva automáticamente cualquier bloqueo expirado para el mismo recurso
    UPDATE bloqueos_recursos
    SET activo = FALSE
    WHERE tipo_recurso = NEW.tipo_recurso
      AND recurso_id = NEW.recurso_id
      AND expira_en <= CURRENT_TIMESTAMP
      AND activo = TRUE;
      
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_limpiar_bloqueos_vencidos ON bloqueos_recursos;

CREATE TRIGGER trg_limpiar_bloqueos_vencidos
BEFORE INSERT ON bloqueos_recursos
FOR EACH ROW
EXECUTE FUNCTION fn_trg_limpiar_bloqueos_vencidos();
```

---
*Fin del banco de consultas. Todas las instrucciones son compatibles con PostgreSQL 14+ y el modelo relacional del repositorio.*
