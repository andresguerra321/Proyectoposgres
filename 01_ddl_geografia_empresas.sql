-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 01_ddl_geografia_empresas.sql
-- Fase: 1. Infraestructura Geográfica y Núcleo Multi-Empresa (Tenants)
-- =============================================================================

-- 1. Catálogo de Países
CREATE TABLE IF NOT EXISTS paises (
    id SERIAL PRIMARY KEY,
    codigo_iso VARCHAR(3) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL
);

-- 2. Catálogo de Departamentos / Estados
CREATE TABLE IF NOT EXISTS departamentos (
    id SERIAL PRIMARY KEY,
    pais_id INT NOT NULL REFERENCES paises(id) ON DELETE RESTRICT,
    codigo_dane VARCHAR(5) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL
);

-- 3. Catálogo de Municipios / Ciudades
CREATE TABLE IF NOT EXISTS municipios (
    id SERIAL PRIMARY KEY,
    departamento_id INT NOT NULL REFERENCES departamentos(id) ON DELETE RESTRICT,
    codigo_dane VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL
);

-- 4. Clasificación de Tamaño de Empresa (Normativa de estándares mínimos)
CREATE TABLE IF NOT EXISTS tamanos_empresa (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE, -- 'MICRO', 'PEQUENA', 'MEDIANA', 'GRANDE'
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    min_trabajadores INT NOT NULL CHECK (min_trabajadores >= 1),
    max_trabajadores INT CHECK (max_trabajadores >= min_trabajadores)
);

-- 5. Entidad Principal Multi-Tenant: EMPRESAS (Organizaciones)
-- Cada registro en esta tabla representa un 'Tenant' independiente en el sistema
CREATE TABLE IF NOT EXISTS empresas (
    id SERIAL PRIMARY KEY,
    nit VARCHAR(20) NOT NULL UNIQUE,
    dv CHAR(1) NOT NULL, -- Dígito de verificación
    razon_social VARCHAR(150) NOT NULL,
    nombre_comercial VARCHAR(150),
    sector_economico VARCHAR(100) NOT NULL,
    clase_riesgo_arl SMALLINT NOT NULL CHECK (clase_riesgo_arl BETWEEN 1 AND 5),
    tamano_id INT NOT NULL REFERENCES tamanos_empresa(id) ON DELETE RESTRICT,
    municipio_id INT NOT NULL REFERENCES municipios(id) ON DELETE RESTRICT,
    direccion_principal VARCHAR(150) NOT NULL,
    telefono VARCHAR(30),
    email_contacto VARCHAR(100) NOT NULL,
    nivel_misionero_pesv VARCHAR(30) CHECK (nivel_misionero_pesv IN ('BASICO', 'ESTANDAR', 'AVANZADO', 'NO_APLICA')),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Sedes Operativas de cada Organización (Relación 1:N por Tenant)
CREATE TABLE IF NOT EXISTS sedes_empresa (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    municipio_id INT NOT NULL REFERENCES municipios(id) ON DELETE RESTRICT,
    es_principal BOOLEAN NOT NULL DEFAULT FALSE,
    numero_trabajadores_sede INT NOT NULL DEFAULT 1 CHECK (numero_trabajadores_sede >= 0),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_empresa_sede UNIQUE (empresa_id, nombre)
);

-- Índices recomendados
CREATE INDEX idx_empresas_nit ON empresas(nit);
CREATE INDEX idx_empresas_tamano ON empresas(tamano_id);
CREATE INDEX idx_sedes_empresa ON sedes_empresa(empresa_id);
