-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 04_ddl_plantillas_formatos_evaluaciones.sql
-- Fase: 4. Catálogos Documentales, Formatos Operativos e Instrumentos de Evaluación
-- =============================================================================

-- 1. Plantillas de Documentos Maestros (Políticas, Programas, Procedimientos, Manuales)
CREATE TABLE IF NOT EXISTS plantillas (
    id SERIAL PRIMARY KEY,
    modulo_id INT NOT NULL REFERENCES modulos(id) ON DELETE RESTRICT,
    codigo VARCHAR(30) NOT NULL UNIQUE, -- Ej: 'PLT_POL_SST_01'
    titulo VARCHAR(150) NOT NULL,
    descripcion TEXT,
    version_base VARCHAR(10) NOT NULL DEFAULT '1.0',
    estructura_secciones JSONB NOT NULL DEFAULT '[]'::jsonb, -- Estructura de secciones en formato híbrido
    es_requerido_ley BOOLEAN NOT NULL DEFAULT TRUE,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- 2. Formatos Operativos de Campo (Listas de Chequeo, Inspecciones, Permisos de Trabajo)
CREATE TABLE IF NOT EXISTS formatos (
    id SERIAL PRIMARY KEY,
    modulo_id INT NOT NULL REFERENCES modulos(id) ON DELETE RESTRICT,
    codigo VARCHAR(30) NOT NULL UNIQUE, -- Ej: 'FOR_INSP_VEH_01'
    nombre VARCHAR(120) NOT NULL,
    descripcion TEXT,
    tipo_formato VARCHAR(40) NOT NULL CHECK (tipo_formato IN (
        'LISTA_CHEQUEO', 
        'INSPECCION_LOCATIVA', 
        'PREOPERACIONAL_VEHICULO', 
        'PERMISO_ALTO_RIESGO', 
        'REPORTE_INCIDENTE',
        'ENTREGA_EPP'
    )),
    frecuencia_sugerida VARCHAR(30) CHECK (frecuencia_sugerida IN ('DIARIA', 'SEMANAL', 'MENSUAL', 'TRIMESTRAL', 'ANUAL', 'POR_EVENTO')),
    esquema_campos JSONB NOT NULL DEFAULT '{}'::jsonb, -- Definición de campos del formulario
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3. Instrumentos de Autoevaluación Normativa (Ej: Estándares Mínimos Res. 0312 / Diagnóstico PESV)
CREATE TABLE IF NOT EXISTS instrumentos_evaluacion (
    id SERIAL PRIMARY KEY,
    sistema_id INT NOT NULL REFERENCES sistemas_gestion(id) ON DELETE RESTRICT,
    codigo VARCHAR(30) NOT NULL UNIQUE, -- 'EVAL_MIN_0312', 'DIAG_PESV_40595'
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    normativa_referencia VARCHAR(150) NOT NULL,
    version VARCHAR(10) NOT NULL DEFAULT '1.0',
    puntaje_maximo NUMERIC(5, 2) NOT NULL DEFAULT 100.00,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- 4. Ítems o Criterios de Evaluación Específicos
CREATE TABLE IF NOT EXISTS items_evaluacion (
    id SERIAL PRIMARY KEY,
    instrumento_id INT NOT NULL REFERENCES instrumentos_evaluacion(id) ON DELETE CASCADE,
    modulo_id INT NOT NULL REFERENCES modulos(id) ON DELETE RESTRICT,
    numeral_norma VARCHAR(30) NOT NULL, -- Ej: '1.1.1', '2.1.2'
    criterio TEXT NOT NULL,
    modo_verificacion TEXT NOT NULL,
    peso_porcentaje NUMERIC(5, 2) NOT NULL CHECK (peso_porcentaje > 0),
    aplica_tamano_empresa VARCHAR(30) DEFAULT 'TODOS' CHECK (aplica_tamano_empresa IN ('TODOS', 'MICRO_7', 'PEQUENA_21', 'MEDIANA_GRANDE_60'))
);

-- Índices recomendados
CREATE INDEX idx_plantillas_modulo ON plantillas(modulo_id);
CREATE INDEX idx_formatos_modulo ON formatos(modulo_id);
CREATE INDEX idx_items_instrumento ON items_evaluacion(instrumento_id);
