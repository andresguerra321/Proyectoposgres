-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 02_ddl_personas_cargos.sql
-- Fase: 2. Estructura Organizacional, Trabajadores y Responsabilidades
-- =============================================================================

-- 1. Cargos Ocupacionales dentro de cada Organización (Multi-Tenant)
CREATE TABLE IF NOT EXISTS cargos (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    nivel_jerarquico VARCHAR(30) CHECK (nivel_jerarquico IN ('DIRECTIVO', 'COORDINADOR', 'OPERATIVO', 'ADMINISTRATIVO')),
    expuesto_riesgo_vial BOOLEAN NOT NULL DEFAULT FALSE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_empresa_cargo UNIQUE (empresa_id, nombre)
);

-- 2. Roles del Sistema Informático (Perfiles de Acceso)
CREATE TABLE IF NOT EXISTS roles_sistema (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE, -- 'SUPERADMIN', 'RESPONSABLE_SST', 'LIDER_PESV', 'TRABAJADOR', 'AUDITOR'
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

-- 3. Personas / Colaboradores vinculados a cada Empresa (Multi-Tenant)
CREATE TABLE IF NOT EXISTS personas (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    tipo_documento VARCHAR(10) NOT NULL CHECK (tipo_documento IN ('CC', 'CE', 'PA', 'PEP', 'PPT')),
    numero_documento VARCHAR(20) NOT NULL,
    nombres VARCHAR(80) NOT NULL,
    apellidos VARCHAR(80) NOT NULL,
    email VARCHAR(100) NOT NULL,
    telefono VARCHAR(30),
    sede_id INT REFERENCES sedes_empresa(id) ON DELETE SET NULL,
    cargo_id INT NOT NULL REFERENCES cargos(id) ON DELETE RESTRICT,
    rol_sistema_id INT NOT NULL REFERENCES roles_sistema(id) ON DELETE RESTRICT,
    fecha_ingreso DATE NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_empresa_documento UNIQUE (empresa_id, tipo_documento, numero_documento),
    CONSTRAINT uq_empresa_email UNIQUE (empresa_id, email)
);

-- 4. Asignaciones de Responsabilidad en los Comités (COPASST, Vigía, CCL, Comité de Seguridad Vial)
CREATE TABLE IF NOT EXISTS comites_empresa (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    tipo_comite VARCHAR(50) NOT NULL CHECK (tipo_comite IN ('COPASST', 'VIGIA_SST', 'CONVIVENCIA_LABORAL', 'COMITE_SEGURIDAD_VIAL')),
    fecha_conformacion DATE NOT NULL,
    fecha_vencimiento DATE,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS miembros_comite (
    id SERIAL PRIMARY KEY,
    comite_id INT NOT NULL REFERENCES comites_empresa(id) ON DELETE CASCADE,
    persona_id INT NOT NULL REFERENCES personas(id) ON DELETE CASCADE,
    rol_comite VARCHAR(40) NOT NULL CHECK (rol_comite IN ('PRESIDENTE', 'SECRETARIO', 'PRINCIPAL', 'SUPLENTE')),
    representa_a VARCHAR(30) NOT NULL CHECK (representa_a IN ('EMPLEADOR', 'TRABAJADORES')),
    CONSTRAINT uq_comite_persona UNIQUE (comite_id, persona_id)
);

-- Índices recomendados
CREATE INDEX idx_personas_empresa ON personas(empresa_id);
CREATE INDEX idx_personas_cargo ON personas(cargo_id);
CREATE INDEX idx_cargos_empresa ON cargos(empresa_id);
