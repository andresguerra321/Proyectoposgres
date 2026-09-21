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

-- 7. Plantillas Documentales Base (Con estructura JSONB)
INSERT INTO plantillas (modulo_id, codigo, titulo, descripcion, version_base, estructura_secciones) VALUES 
(1, 'PLT_POL_SST_01', 'Política de Seguridad y Salud en el Trabajo', 'Plantilla estandarizada según Dec. 1072', '1.0', 
 '[{"seccion": "1. Compromiso Gerencial", "requerido": true}, {"seccion": "2. Alcance", "requerido": true}, {"seccion": "3. Firmas", "requerido": true}]'::jsonb),
(7, 'PLT_PESV_POL_VIAL', 'Política de Seguridad Vial', 'Compromiso institucional de no uso de distractores y límites de velocidad', '1.0',
 '[{"seccion": "1. Declaración", "requerido": true}, {"seccion": "2. Reglas Clave", "requerido": true}]'::jsonb)
ON CONFLICT (codigo) DO NOTHING;

-- 8. Empresas de Demostración (Multi-Tenant)
INSERT INTO empresas (nit, dv, razon_social, nombre_comercial, sector_economico, clase_riesgo_arl, tamano_id, municipio_id, direccion_principal, telefono, email_contacto, nivel_misionero_pesv)
VALUES 
('900123456', '1', 'Transportes & Logística del Valle S.A.S.', 'TransLogística', 'Transporte de Carga Terrestre', 4, 3, 3, 'Calle 15 # 24-80, Zona Industrial', '6023344555', 'contacto@translogistica.com.co', 'AVANZADO'),
('901987654', '3', 'Industrias Metálicas de la Sabana Ltda.', 'MetalSabana', 'Fabricación de Estructuras Metálicas', 5, 2, 1, 'Cra 68 # 12-45', '6017788990', 'gerencia@metalsabana.com', 'NO_APLICA')
ON CONFLICT (nit) DO NOTHING;

-- 9. Sedes por Empresa
INSERT INTO sedes_empresa (empresa_id, nombre, direccion, municipio_id, es_principal, numero_trabajadores_sede)
VALUES 
(1, 'Sede Principal Cali', 'Calle 15 # 24-80', 3, TRUE, 85),
(1, 'Terminal Satélite Medellín', 'Autopista Sur Km 12', 2, FALSE, 25),
(2, 'Planta Industrial Bogotá', 'Cra 68 # 12-45', 1, TRUE, 42)
ON CONFLICT (empresa_id, nombre) DO NOTHING;

-- 10. Habilitación de Sistemas por Tenant
INSERT INTO sistemas_empresa (empresa_id, sistema_id, estado, observaciones)
VALUES 
(1, 1, 'ACTIVO', 'SST obligatorio por tamaño y riesgo IV'),
(1, 2, 'ACTIVO', 'PESV Nivel Avanzado con flota propia de 40 camiones'),
(2, 1, 'ACTIVO', 'SST prioritario por riesgo V (Metalmecánica)')
ON CONFLICT (empresa_id, sistema_id) DO NOTHING;

-- 11. Cargos Organizacionales por Tenant
INSERT INTO cargos (empresa_id, nombre, descripcion, nivel_jerarquico, expuesto_riesgo_vial)
VALUES 
(1, 'Gerente General', 'Representante legal y líder estratégico', 'DIRECTIVO', FALSE),
(1, 'Especialista SST', 'Responsable del diseño e implementación del SG-SST', 'COORDINADOR', FALSE),
(1, 'Conductor de Carga Pesada', 'Operador de tractocamión en ruta intermunicipal', 'OPERATIVO', TRUE),
(2, 'Gerente de Planta', 'Máxima autoridad en planta de producción', 'DIRECTIVO', FALSE),
(2, 'Coordinador SST', 'Encargado del sistema de gestión', 'COORDINADOR', FALSE)
ON CONFLICT (empresa_id, nombre) DO NOTHING;

-- 12. Personas Vinculadas a los Tenants
INSERT INTO personas (empresa_id, tipo_documento, numero_documento, nombres, apellidos, email, telefono, sede_id, cargo_id, rol_sistema_id, fecha_ingreso)
VALUES 
(1, 'CC', '10102020', 'Alejandro', 'Morales Gomez', 'amorales@translogistica.com.co', '3104567890', 1, 2, 2, '2024-01-15'),
(1, 'CC', '10203040', 'Carlos', 'Rios Mendoza', 'crios@translogistica.com.co', '3157891234', 1, 3, 4, '2024-03-01'),
(2, 'CC', '10304050', 'Natalia', 'Vargas Castro', 'nvargas@metalsabana.com', '3201234567', 3, 5, 2, '2023-11-01')
ON CONFLICT (empresa_id, tipo_documento, numero_documento) DO NOTHING;
