-- =============================================================================
-- VISTAS DE COMPATIBILIDAD CONCEPTUAL (Opcionales para soporte de enunciados)
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
