-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 03_ddl_parametrizacion_sst_pesv.sql
-- Fase: 3. Parametrización Maestra de Sistemas de Gestión y Ciclo PHVA
-- =============================================================================

-- 1. Catálogo de Sistemas de Gestión Soportados
CREATE TABLE IF NOT EXISTS sistemas_gestion (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE, -- 'SST', 'PESV', 'AMBIENTAL'
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    marco_normativo_principal VARCHAR(150) NOT NULL, -- Ej: 'Decreto 1072 de 2015 / Res. 0312 de 2019'
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- 2. Las 4 Etapas del Ciclo de Mejora Continua (PHVA)
CREATE TABLE IF NOT EXISTS etapas_phva (
    id SERIAL PRIMARY KEY,
    codigo CHAR(1) NOT NULL UNIQUE, -- 'P', 'H', 'V', 'A'
    nombre VARCHAR(30) NOT NULL,    -- 'Planear', 'Hacer', 'Verificar', 'Actuar'
    descripcion TEXT,
    orden_secuencia SMALLINT NOT NULL UNIQUE CHECK (orden_secuencia BETWEEN 1 AND 4)
);

-- 3. Módulos Funcionales del Sistema (Cruzan Sistema de Gestión con Etapa PHVA)
CREATE TABLE IF NOT EXISTS modulos (
    id SERIAL PRIMARY KEY,
    sistema_id INT NOT NULL REFERENCES sistemas_gestion(id) ON DELETE CASCADE,
    etapa_phva_id INT NOT NULL REFERENCES etapas_phva(id) ON DELETE RESTRICT,
    codigo VARCHAR(30) NOT NULL UNIQUE, -- Ej: 'SST_P_POLITICA', 'PESV_H_VEHICULOS'
    nombre VARCHAR(120) NOT NULL,
    descripcion TEXT,
    peso_porcentaje NUMERIC(5, 2) NOT NULL DEFAULT 1.00 CHECK (peso_porcentaje >= 0),
    es_obligatorio BOOLEAN NOT NULL DEFAULT TRUE,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- 4. Habilitación de Sistemas por Organización (Multi-Tenant)
-- Define qué sistemas de gestión tiene activos cada empresa
CREATE TABLE IF NOT EXISTS sistemas_empresa (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    sistema_id INT NOT NULL REFERENCES sistemas_gestion(id) ON DELETE RESTRICT,
    fecha_implementacion DATE NOT NULL DEFAULT CURRENT_DATE,
    estado VARCHAR(30) NOT NULL DEFAULT 'EN_IMPLEMENTACION' 
        CHECK (estado IN ('EN_IMPLEMENTACION', 'ACTIVO', 'SUSPENDIDO', 'CERTIFICADO')),
    observaciones TEXT,
    CONSTRAINT uq_empresa_sistema UNIQUE (empresa_id, sistema_id)
);

-- Índices recomendados
CREATE INDEX idx_modulos_sistema ON modulos(sistema_id);
CREATE INDEX idx_modulos_etapa ON modulos(etapa_phva_id);
CREATE INDEX idx_sistemas_empresa ON sistemas_empresa(empresa_id);
