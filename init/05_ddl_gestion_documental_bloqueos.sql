-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 05_ddl_gestion_documental_bloqueos.sql
-- Fase: 5. Gestión Documental por Tenant, Registros Operativos y Concurrencia
-- =============================================================================

-- 1. Documentos Generados y Personalizados por Organización (Multi-Tenant)
CREATE TABLE IF NOT EXISTS documentos_empresa (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    plantilla_id INT NOT NULL REFERENCES plantillas(id) ON DELETE RESTRICT,
    codigo_documento VARCHAR(50) NOT NULL,
    titulo VARCHAR(180) NOT NULL,
    version INT NOT NULL DEFAULT 1 CHECK (version >= 1),
    estado VARCHAR(30) NOT NULL DEFAULT 'BORRADOR' 
        CHECK (estado IN ('BORRADOR', 'EN_REVISION', 'APROBADO', 'OBSOLETO', 'RECHAZADO')),
    contenido_personalizado JSONB NOT NULL DEFAULT '{}'::jsonb, -- Contenido real del documento del cliente
    elaborado_por_id INT NOT NULL REFERENCES personas(id) ON DELETE RESTRICT,
    revisado_por_id INT REFERENCES personas(id) ON DELETE SET NULL,
    aprobado_por_id INT REFERENCES personas(id) ON DELETE SET NULL,
    fecha_elaboracion DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_aprobacion DATE,
    fecha_proxima_revision DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_empresa_documento_version UNIQUE (empresa_id, plantilla_id, version)
);

-- 2. Diligenciamiento de Formatos Operativos (Inspecciones, Preoperacionales, etc.)
CREATE TABLE IF NOT EXISTS registros_formatos (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    formato_id INT NOT NULL REFERENCES formatos(id) ON DELETE RESTRICT,
    sede_id INT REFERENCES sedes_empresa(id) ON DELETE SET NULL,
    persona_registro_id INT NOT NULL REFERENCES personas(id) ON DELETE RESTRICT,
    fecha_registro TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datos_formulario JSONB NOT NULL, -- Respuestas de la inspección o lista de chequeo
    tiene_hallazgos BOOLEAN NOT NULL DEFAULT FALSE,
    estado_seguimiento VARCHAR(30) NOT NULL DEFAULT 'CERRADO' 
        CHECK (estado_seguimiento IN ('ABIERTO', 'EN_PROCESO', 'CERRADO'))
);

-- 3. Evaluaciones Ejecutadas por cada Empresa (Resultados de Autoevaluación)
CREATE TABLE IF NOT EXISTS autoevaluaciones_empresa (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    instrumento_id INT NOT NULL REFERENCES instrumentos_evaluacion(id) ON DELETE RESTRICT,
    evaluador_id INT NOT NULL REFERENCES personas(id) ON DELETE RESTRICT,
    fecha_evaluacion DATE NOT NULL DEFAULT CURRENT_DATE,
    periodo_ano INT NOT NULL CHECK (periodo_ano BETWEEN 2020 AND 2100),
    puntaje_obtenido NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    porcentaje_cumplimiento NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    valoracion_cualitativa VARCHAR(30) 
        CHECK (valoracion_cualitativa IN ('CRITICO', 'MODERADAMENTE_ACEPTABLE', 'ACEPTABLE')),
    CONSTRAINT uq_empresa_instrumento_periodo UNIQUE (empresa_id, instrumento_id, periodo_ano)
);

-- 4. Detalle de Calificación Ítem por Ítem en la Evaluación
CREATE TABLE IF NOT EXISTS detalles_autoevaluacion (
    id SERIAL PRIMARY KEY,
    autoevaluacion_id INT NOT NULL REFERENCES autoevaluaciones_empresa(id) ON DELETE CASCADE,
    item_evaluacion_id INT NOT NULL REFERENCES items_evaluacion(id) ON DELETE RESTRICT,
    cumple BOOLEAN NOT NULL,
    justificacion_no_aplica BOOLEAN NOT NULL DEFAULT FALSE,
    puntaje_asignado NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    evidencia_documento_id INT REFERENCES documentos_empresa(id) ON DELETE SET NULL,
    hallazgo_observacion TEXT,
    plan_accion_propuesto TEXT,
    CONSTRAINT uq_evaluacion_item UNIQUE (autoevaluacion_id, item_evaluacion_id)
);

-- 5. Control de Concurrencia y Bloqueos de Recursos (Locks a Nivel de Aplicación)
-- Previene que dos personas editen el mismo documento simultáneamente
CREATE TABLE IF NOT EXISTS bloqueos_recursos (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    tipo_recurso VARCHAR(50) NOT NULL, -- Ej: 'DOCUMENTO', 'EVALUACION', 'FORMATO'
    recurso_id INT NOT NULL,           -- ID del registro en su respectiva tabla
    persona_id INT NOT NULL REFERENCES personas(id) ON DELETE CASCADE,
    adquirido_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expira_en TIMESTAMP WITH TIME ZONE NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_recurso_bloqueo_activo UNIQUE (tipo_recurso, recurso_id, activo)
);

-- Índices recomendados
CREATE INDEX idx_documentos_empresa ON documentos_empresa(empresa_id);
CREATE INDEX idx_documentos_estado ON documentos_empresa(estado);
CREATE INDEX idx_registros_empresa ON registros_formatos(empresa_id);
CREATE INDEX idx_bloqueos_activos ON bloqueos_recursos(tipo_recurso, recurso_id) WHERE activo = TRUE;
