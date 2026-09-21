-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 06_poblacion_semilla.sql
-- Fase: 6. Población de Datos Maestros y Semilla Multi-Empresa
-- =============================================================================

-- 1. Geografía Base
INSERT INTO paises (codigo_iso, nombre) VALUES 
('COL', 'Colombia')
ON CONFLICT (codigo_iso) DO NOTHING;

INSERT INTO departamentos (pais_id, codigo_dane, nombre) VALUES 
(1, '11', 'Bogotá D.C.'),
(1, '05', 'Antioquia'),
(1, '76', 'Valle del Cauca')
ON CONFLICT (codigo_dane) DO NOTHING;

INSERT INTO municipios (departamento_id, codigo_dane, nombre) VALUES 
(1, '11001', 'Bogotá D.C.'),
(2, '05001', 'Medellín'),
(3, '76001', 'Cali')
ON CONFLICT (codigo_dane) DO NOTHING;

-- 2. Tamaños de Empresa (Resolución 0312 de 2019)
INSERT INTO tamanos_empresa (codigo, nombre, descripcion, min_trabajadores, max_trabajadores) VALUES 
('MICRO', 'Microempresa (7 Estándares)', 'Empresas de hasta 10 trabajadores con riesgo I, II o III', 1, 10),
('PEQUENA', 'Pequeña Empresa (21 Estándares)', 'Empresas de 11 a 50 trabajadores con riesgo I, II o III', 11, 50),
('MEDIANA_GRANDE', 'Mediana y Grande (60 Estándares)', 'Empresas de más de 50 trabajadores o cualquier tamaño con riesgo IV o V', 51, 999999)
ON CONFLICT (codigo) DO NOTHING;

-- 3. Sistemas de Gestión
INSERT INTO sistemas_gestion (codigo, nombre, descripcion, marco_normativo_principal) VALUES 
('SST', 'Sistema de Gestión de Seguridad y Salud en el Trabajo', 'SG-SST conforme a normativa colombiana', 'Decreto 1072 de 2015 / Res. 0312 de 2019'),
('PESV', 'Plan Estratégico de Seguridad Vial', 'Metodología para el diseño e implementación del PESV', 'Ley 1503 de 2011 / Res. 20223040040595 de 2022')
ON CONFLICT (codigo) DO NOTHING;

-- 4. Las 4 Etapas del Ciclo PHVA
INSERT INTO etapas_phva (codigo, nombre, descripcion, orden_secuencia) VALUES 
('P', 'Planear', 'Fase de diseño, definición de políticas, objetivos, asignación de recursos y evaluación inicial', 1),
('H', 'Hacer', 'Implementación de medidas de prevención, capacitación, gestión de riesgos y programas operativos', 2),
('V', 'Verificar', 'Auditoría, revisión por la alta dirección, inspecciones y medición de indicadores', 3),
('A', 'Actuar', 'Planes de mejora, acciones preventivas y correctivas basadas en hallazgos', 4)
ON CONFLICT (codigo) DO NOTHING;

-- 5. Módulos Estándar por Sistema y Etapa PHVA
INSERT INTO modulos (sistema_id, etapa_phva_id, codigo, nombre, descripcion, peso_porcentaje) VALUES 
-- Módulos SST
(1, 1, 'SST_P_POLITICA', 'Política y Objetivos de SST', 'Definición, firma y divulgación de la política del SG-SST', 15.00),
(1, 1, 'SST_P_EVAL_INICIAL', 'Evaluación Inicial del SG-SST', 'Diagnóstico de estándares mínimos para determinar la línea base', 15.00),
(1, 2, 'SST_H_CAPACITACION', 'Plan de Capacitación y Entrenamiento', 'Ejecución de actividades de formación preventiva para trabajadores', 25.00),
(1, 2, 'SST_H_GESTION_PELIGROS', 'Identificación de Peligros y Valoración de Riesgos (Matriz GTC-45)', 'Control y mitigación en la fuente, medio e individuo', 25.00),
(1, 3, 'SST_V_INDICADORES', 'Medición y Seguimiento de Indicadores', 'Indicadores de estructura, proceso y resultado', 10.00),
(1, 4, 'SST_A_PLAN_MEJORA', 'Planes de Acción y Mejora Continua', 'Tratamiento de no conformidades e investigaciones de accidentes', 10.00),
-- Módulos PESV
(2, 1, 'PESV_P_LIDERAZGO', 'Liderazgo y Comité de Seguridad Vial', 'Compromiso de la alta dirección y conformación del equipo líder vial', 20.00),
(2, 2, 'PESV_H_VEHICULOS', 'Vehículos Seguros e Inspecciones', 'Mantenimiento preventivo y listas de chequeo preoperacional diario', 30.00),
(2, 2, 'PESV_H_CONDUCTORES', 'Conductores y Hábitos Seguros', 'Perfilación de conductores, exámenes médicos y capacitaciones viales', 25.00),
(2, 3, 'PESV_V_AUDITORIA_VIAL', 'Auditoría e Investigación de Siniestros', 'Seguimiento a incidentes viales y auditorías anuales', 15.00),
(2, 4, 'PESV_A_MEJORA_VIAL', 'Mejora Continua del PESV', 'Ajustes metodológicos del plan estratégico', 10.00)
ON CONFLICT (codigo) DO NOTHING;

-- 6. Roles del Sistema
INSERT INTO roles_sistema (codigo, nombre, descripcion) VALUES 
('SUPERADMIN', 'Administrador de Plataforma', 'Acceso global a todos los tenants y parametrizaciones maestras'),
('RESPONSABLE_SST', 'Responsable del SG-SST', 'Líder técnico con licencia en SST para la empresa'),
('LIDER_PESV', 'Líder de Seguridad Vial', 'Coordinador del Plan Estratégico de Seguridad Vial'),
('TRABAJADOR', 'Colaborador Estándar', 'Diligencia formatos preoperacionales y consulta políticas')
ON CONFLICT (codigo) DO NOTHING;

-- 7. Plantillas Documentales Base (Con estructura JSONB en las 4 Fases PHVA)
INSERT INTO plantillas (modulo_id, codigo, titulo, descripcion, version_base, estructura_secciones) VALUES 
-- SST - Planear
(1, 'PLT_POL_SST_01', 'Política de Seguridad y Salud en el Trabajo', 'Plantilla estandarizada según Dec. 1072', '1.0', 
 '[{"seccion": "1. Compromiso Gerencial", "requerido": true}, {"seccion": "2. Alcance", "requerido": true}, {"seccion": "3. Firmas", "requerido": true}]'::jsonb),
-- PESV - Planear
(7, 'PLT_PESV_POL_VIAL', 'Política de Seguridad Vial', 'Compromiso institucional de no uso de distractores y límites de velocidad', '1.0',
 '[{"seccion": "1. Declaración", "requerido": true}, {"seccion": "2. Reglas Clave", "requerido": true}]'::jsonb),
-- SST - Hacer
(3, 'PLT_SST_CAPACITACION', 'Programa de Capacitación en Seguridad y Salud', 'Plan anual de formación preventiva', '1.0',
 '[{"seccion": "1. Cronograma", "requerido": true}, {"seccion": "2. Temas Obligatorios", "requerido": true}]'::jsonb),
(4, 'PLT_SST_MATRIZ_PELIGROS', 'Matriz de Identificación de Peligros y Valoración de Riesgos GTC-45', 'Metodología GTC 45 para valoración de riesgos', '2.0',
 '[{"seccion": "1. Procesos", "requerido": true}, {"seccion": "2. Controles Existentes", "requerido": true}]'::jsonb),
-- SST - Verificar
(5, 'PLT_SST_INDICADORES', 'Ficha Técnica de Indicadores del SG-SST', 'Medición de indicadores de estructura, proceso y resultado', '1.0',
 '[{"seccion": "1. Fórmulas", "requerido": true}, {"seccion": "2. Periodicidad", "requerido": true}]'::jsonb),
-- SST - Actuar
(6, 'PLT_SST_PLAN_MEJORA', 'Procedimiento de Acciones Correctivas y de Mejora Continua', 'Gestión de no conformidades e investigación de incidentes', '1.0',
 '[{"seccion": "1. Análisis de Causa Raíz", "requerido": true}, {"seccion": "2. Plan de Acción", "requerido": true}]'::jsonb),
-- PESV - Hacer
(8, 'PLT_PESV_MANT_VEH', 'Plan de Mantenimiento Preventivo e Inspección de Vehículos', 'Protocolo de revisión técnica y mecánica de flota', '1.0',
 '[{"seccion": "1. Hojas de Vida de Vehículos", "requerido": true}, {"seccion": "2. Frecuencia de Mantenimiento", "requerido": true}]'::jsonb),
-- PESV - Verificar
(10, 'PLT_PESV_AUDITORIA', 'Protocolo de Auditoría Interna de Seguridad Vial', 'Lineamientos para auditoría anual del PESV', '1.0',
 '[{"seccion": "1. Alcance Vial", "requerido": true}, {"seccion": "2. Criterios de Evaluación", "requerido": true}]'::jsonb)
ON CONFLICT (codigo) DO NOTHING;

-- 8. Empresas de Demostración (Multi-Tenant)
-- Empresa 1: Mediana/Grande en Cali (SST + PESV, con empleados y documentos)
-- Empresa 2: Pequeña en Bogotá (Solo SST, con empleados)
-- Empresa 3: Microempresa en Cali (Mismo municipio que Emp 1 pero diferente tamaño, SIN personas para Consulta 2.16 y 3.16)
INSERT INTO empresas (nit, dv, razon_social, nombre_comercial, sector_economico, clase_riesgo_arl, tamano_id, municipio_id, direccion_principal, telefono, email_contacto, nivel_misionero_pesv)
VALUES 
('900123456', '1', 'Transportes & Logística del Valle S.A.S.', 'TransLogística', 'Transporte de Carga Terrestre', 4, 3, 3, 'Calle 15 # 24-80, Zona Industrial', '6023344555', 'contacto@translogistica.com.co', 'AVANZADO'),
('901987654', '3', 'Industrias Metálicas de la Sabana Ltda.', 'MetalSabana', 'Fabricación de Estructuras Metálicas', 5, 2, 1, 'Cra 68 # 12-45', '6017788990', 'gerencia@metalsabana.com', 'NO_APLICA'),
('902112233', '8', 'EcoServicios Ambientales del Valle S.A.S.', 'EcoValle', 'Consultoría y Gestión de Residuos', 2, 1, 3, 'Av 6N # 28-10', '6025556677', 'admin@ecovalle.com', 'NO_APLICA')
ON CONFLICT (nit) DO NOTHING;

-- 9. Sedes por Empresa
INSERT INTO sedes_empresa (empresa_id, nombre, direccion, municipio_id, es_principal, numero_trabajadores_sede)
VALUES 
(1, 'Sede Principal Cali', 'Calle 15 # 24-80', 3, TRUE, 85),
(1, 'Terminal Satélite Medellín', 'Autopista Sur Km 12', 2, FALSE, 25),
(2, 'Planta Industrial Bogotá', 'Cra 68 # 12-45', 1, TRUE, 42),
(3, 'Oficina Administrativa Cali', 'Av 6N # 28-10', 3, TRUE, 5)
ON CONFLICT (empresa_id, nombre) DO NOTHING;

-- 10. Habilitación de Sistemas por Tenant
INSERT INTO sistemas_empresa (empresa_id, sistema_id, estado, observaciones)
VALUES 
(1, 1, 'ACTIVO', 'SST obligatorio por tamaño y riesgo IV'),
(1, 2, 'ACTIVO', 'PESV Nivel Avanzado con flota propia de 40 camiones'),
(2, 1, 'ACTIVO', 'SST prioritario por riesgo V (Metalmecánica)'),
(3, 1, 'ACTIVO', 'SST simplificado para microempresa (7 estándares)')
ON CONFLICT (empresa_id, sistema_id) DO NOTHING;

-- 11. Cargos Organizacionales por Tenant
INSERT INTO cargos (empresa_id, nombre, descripcion, nivel_jerarquico, expuesto_riesgo_vial)
VALUES 
(1, 'Gerente General', 'Representante legal y líder estratégico', 'DIRECTIVO', FALSE),
(1, 'Especialista SST', 'Responsable del diseño e implementación del SG-SST', 'COORDINADOR', FALSE),
(1, 'Conductor de Carga Pesada', 'Operador de tractocamión en ruta intermunicipal', 'OPERATIVO', TRUE),
(2, 'Gerente de Planta', 'Máxima autoridad en planta de producción', 'DIRECTIVO', FALSE),
(2, 'Coordinador SST', 'Encargado del sistema de gestión', 'COORDINADOR', FALSE),
(3, 'Director General', 'Representante legal de microempresa', 'DIRECTIVO', FALSE)
ON CONFLICT (empresa_id, nombre) DO NOTHING;

-- 12. Personas Vinculadas a los Tenants (Empresa 3 queda intencionalmente sin personas)
INSERT INTO personas (empresa_id, tipo_documento, numero_documento, nombres, apellidos, email, telefono, sede_id, cargo_id, rol_sistema_id, fecha_ingreso)
VALUES 
(1, 'CC', '10102020', 'Alejandro', 'Morales Gomez', 'amorales@translogistica.com.co', '3104567890', 1, 2, 2, '2024-01-15'),
(1, 'CC', '10203040', 'Carlos', 'Rios Mendoza', 'crios@translogistica.com.co', '3157891234', 1, 3, 4, '2024-03-01'),
(2, 'CC', '10304050', 'Natalia', 'Vargas Castro', 'nvargas@metalsabana.com', '3201234567', 3, 5, 2, '2023-11-01')
ON CONFLICT (empresa_id, tipo_documento, numero_documento) DO NOTHING;

-- 13. Formatos Operativos (Listas de Chequeo y Preoperacionales)
INSERT INTO formatos (modulo_id, codigo, nombre, descripcion, tipo_formato, frecuencia_sugerida, esquema_campos)
VALUES 
(8, 'FOR_PREOP_VEH_01', 'Inspección Preoperacional Diaria de Vehículos Pesados', 'Revisión obligatoria de frenos, llantas, luces y fluidos', 'PREOPERACIONAL_VEHICULO', 'DIARIA', '{"campos": ["frenos", "luces", "llantas", "documentos"]}'::jsonb),
(4, 'FOR_INSP_LOC_01', 'Inspección Periódica de Instalaciones y Extintores', 'Verificación de condiciones de seguridad locativa', 'INSPECCION_LOCATIVA', 'MENSUAL', '{"campos": ["orden_aseo", "extintores", "salidas_emergencia"]}'::jsonb),
(6, 'FOR_REP_INC_01', 'Formato de Reporte e Investigación de Incidentes', 'Notificación temprana de casi-accidentes laborales', 'REPORTE_INCIDENTE', 'POR_EVENTO', '{"campos": ["fecha_evento", "descripcion", "causas_inmediatas"]}'::jsonb)
ON CONFLICT (codigo) DO NOTHING;

-- 14. Documentos de Empresa (Generación de avance para Indicadores y Vistas PHVA)
INSERT INTO documentos_empresa (empresa_id, plantilla_id, codigo_documento, titulo, version, estado, elaborado_por_id, aprobado_por_id, fecha_elaboracion, fecha_aprobacion)
VALUES 
-- Empresa 1 (TransLogística) - Avance en SST y PESV
(1, 1, 'DOC-TL-SST-001', 'Política de Seguridad y Salud en el Trabajo', 1, 'APROBADO', 1, 2, '2024-01-20', '2024-01-25'),
(1, 3, 'DOC-TL-SST-002', 'Plan Anual de Capacitación 2024', 1, 'APROBADO', 1, 2, '2024-02-01', '2024-02-05'),
(1, 4, 'DOC-TL-SST-003', 'Matriz de Peligros y Valoración de Riesgos', 1, 'APROBADO', 1, 2, '2024-02-10', '2024-02-15'),
(1, 5, 'DOC-TL-SST-004', 'Tablero de Indicadores SG-SST', 1, 'EN_REVISION', 1, NULL, '2024-03-01', NULL),
(1, 6, 'DOC-TL-SST-005', 'Plan de Mejora Continua y Cierre de Hallazgos', 1, 'BORRADOR', 1, NULL, '2024-03-10', NULL),
(1, 2, 'DOC-TL-PESV-001', 'Política Integral de Seguridad Vial', 1, 'APROBADO', 1, 2, '2024-01-22', '2024-01-28'),
(1, 7, 'DOC-TL-PESV-002', 'Programa de Mantenimiento de Tractocamiones', 1, 'APROBADO', 1, 2, '2024-02-12', '2024-02-18'),

-- Empresa 2 (MetalSabana) - Avance Parcial
(2, 1, 'DOC-MS-SST-001', 'Política de Seguridad y Salud en el Trabajo', 1, 'APROBADO', 3, 3, '2024-01-18', '2024-01-22'),
(2, 3, 'DOC-MS-SST-002', 'Programa de Inducción y Entrenamiento Metalmecánico', 1, 'BORRADOR', 3, NULL, '2024-02-20', NULL)
ON CONFLICT (empresa_id, plantilla_id, version) DO NOTHING;

-- 15. Bloqueos de Recursos para Pruebas de Concurrencia
INSERT INTO bloqueos_recursos (empresa_id, tipo_recurso, recurso_id, persona_id, token_bloqueo, expira_en, activo)
VALUES 
-- Bloqueo activo (30 minutos futuros) en documento #4
(1, 'DOCUMENTO', 4, 1, 'token-demo-activo-12345', CURRENT_TIMESTAMP + INTERVAL '30 minutes', TRUE),
-- Bloqueo vencido (15 minutos pasados) en documento #5 para probar el trigger de limpieza
(1, 'DOCUMENTO', 5, 2, 'token-demo-vencido-67890', CURRENT_TIMESTAMP - INTERVAL '15 minutes', TRUE)
ON CONFLICT (tipo_recurso, recurso_id) DO NOTHING;
