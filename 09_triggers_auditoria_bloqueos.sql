-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 09_triggers_auditoria_bloqueos.sql
-- Fase: 9. Automatización con Triggers (Auditoría, Multi-Tenancy y Bloqueos)
-- Motor: PostgreSQL 14+
-- Cumplimiento: Requerimientos de Sección 7 de Examen.md
-- =============================================================================

-- =============================================================================
-- PARTE 0: TABLAS DE SOPORTE PARA AUDITORÍA
-- =============================================================================

-- Tabla para auditar modificaciones sobre empresas (Trigger 7.12)
CREATE TABLE IF NOT EXISTS auditoria_empresas (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL,
    operacion VARCHAR(10) NOT NULL,
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    usuario_db VARCHAR(50) DEFAULT CURRENT_USER,
    fecha_evento TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla para auditar cambios de estado activo/inactivo (Trigger 7.13)
CREATE TABLE IF NOT EXISTS auditoria_estado_empresas (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL,
    estado_anterior BOOLEAN,
    estado_nuevo BOOLEAN,
    usuario VARCHAR(50) DEFAULT CURRENT_USER,
    cambiado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla para auditar edición de plantillas/documentos (Trigger 7.14)
CREATE TABLE IF NOT EXISTS auditoria_edicion_documentos (
    id SERIAL PRIMARY KEY,
    documento_id INT NOT NULL,
    empresa_id INT NOT NULL,
    version_editada INT,
    usuario_responsable_id INT,
    fecha_edicion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Columna updated_at en personas para el Trigger 7.2
ALTER TABLE personas ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;


-- =============================================================================
-- PARTE 1: TRIGGERS BASE DE INFRAESTRUCTURA Y CONCURRENCIA
-- =============================================================================

-- 0.1 TRIGGER: Validación de Integridad Multi-Tenant en Documentos
CREATE OR REPLACE FUNCTION fn_trg_validar_multitenant_documento()
RETURNS TRIGGER AS $$
DECLARE
    v_persona_empresa_id INT;
BEGIN
    SELECT empresa_id INTO v_persona_empresa_id
    FROM personas
    WHERE id = NEW.elaborado_por_id;

    IF v_persona_empresa_id IS DISTINCT FROM NEW.empresa_id THEN
        RAISE EXCEPTION 'VIOLACIÓN DE SEGURIDAD MULTI-TENANT: El trabajador (ID %) pertenece a la empresa #% y no puede registrar documentos en la empresa #%.',
            NEW.elaborado_por_id, v_persona_empresa_id, NEW.empresa_id;
    END IF;

    IF NEW.aprobado_por_id IS NOT NULL THEN
        SELECT empresa_id INTO v_persona_empresa_id
        FROM personas
        WHERE id = NEW.aprobado_por_id;

        IF v_persona_empresa_id IS DISTINCT FROM NEW.empresa_id THEN
            RAISE EXCEPTION 'VIOLACIÓN DE SEGURIDAD MULTI-TENANT: El aprobador (ID %) no pertenece a la organización del documento.',
                NEW.aprobado_por_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_multitenant_documento ON documentos_empresa;

CREATE TRIGGER trg_validar_multitenant_documento
BEFORE INSERT OR UPDATE ON documentos_empresa
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validar_multitenant_documento();


-- 0.2 TRIGGER: Verificación de Bloqueos Activos antes de Modificar Documentos
CREATE OR REPLACE FUNCTION fn_trg_verificar_bloqueo_edicion()
RETURNS TRIGGER AS $$
DECLARE
    r_bloqueo RECORD;
BEGIN
    SELECT b.persona_id, b.expira_en, p.nombres || ' ' || p.apellidos AS usuario
    INTO r_bloqueo
    FROM bloqueos_recursos b
    JOIN personas p ON b.persona_id = p.id
    WHERE b.tipo_recurso = 'DOCUMENTO'
      AND b.recurso_id = OLD.id
      AND b.activo = TRUE
      AND b.expira_en > CURRENT_TIMESTAMP;

    IF FOUND THEN
        IF r_bloqueo.persona_id IS DISTINCT FROM NEW.elaborado_por_id THEN
            RAISE EXCEPTION 'DOCUMENTO BLOQUEADO: El documento #% está bloqueado por "%" hasta %. Intente más tarde.',
                OLD.id, r_bloqueo.usuario, r_bloqueo.expira_en;
        END IF;
    END IF;

    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_verificar_bloqueo_edicion ON documentos_empresa;

CREATE TRIGGER trg_verificar_bloqueo_edicion
BEFORE UPDATE ON documentos_empresa
FOR EACH ROW
EXECUTE FUNCTION fn_trg_verificar_bloqueo_edicion();


-- =============================================================================
-- PARTE 2: SECCIÓN 7 DEL EXAMEN - TRIGGERS DE INTEGRIDAD Y NEGOCIO (1 A 15)
-- =============================================================================

-- 7.1 Actualiza automáticamente updated_at en la tabla empresas (tenants)
CREATE OR REPLACE FUNCTION fn_trg_actualizar_updated_at_empresas()
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
EXECUTE FUNCTION fn_trg_actualizar_updated_at_empresas();


-- 7.2 Actualiza automáticamente updated_at cuando se modifique una persona
CREATE OR REPLACE FUNCTION fn_trg_actualizar_updated_at_personas()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_actualizar_updated_at_personas ON personas;

CREATE TRIGGER trg_actualizar_updated_at_personas
BEFORE UPDATE ON personas
FOR EACH ROW
EXECUTE FUNCTION fn_trg_actualizar_updated_at_personas();


-- 7.3 Impide registrar una persona en una organización inactiva
CREATE OR REPLACE FUNCTION fn_trg_validar_persona_empresa_activa()
RETURNS TRIGGER AS $$
DECLARE
    v_activa BOOLEAN;
BEGIN
    SELECT activo INTO v_activa FROM empresas WHERE id = NEW.empresa_id;
    
    IF v_activa IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'Operación denegada: La empresa ID % se encuentra INACTIVA.', NEW.empresa_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_persona_empresa_activa ON personas;

CREATE TRIGGER trg_validar_persona_empresa_activa
BEFORE INSERT ON personas
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validar_persona_empresa_activa();


-- 7.4 Impide asignar un módulo/sistema cuando ya se encuentre asignado
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


-- 7.5 Impide asignar plantillas a organizaciones inactivas
CREATE OR REPLACE FUNCTION fn_trg_impedir_plantilla_empresa_inactiva()
RETURNS TRIGGER AS $$
DECLARE
    v_activa BOOLEAN;
BEGIN
    SELECT activo INTO v_activa FROM empresas WHERE id = NEW.empresa_id;
    IF v_activa IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'No se pueden generar documentos para una empresa inactiva (ID %).', NEW.empresa_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_impedir_plantilla_empresa_inactiva ON documentos_empresa;

CREATE TRIGGER trg_impedir_plantilla_empresa_inactiva
BEFORE INSERT ON documentos_empresa
FOR EACH ROW
EXECUTE FUNCTION fn_trg_impedir_plantilla_empresa_inactiva();


-- 7.6 Valida que una persona solo pueda ser asociada a un cargo de su misma organización
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


-- 7.7 Registra automáticamente fecha de actualización al modificar plantilla asignada
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


-- 7.8 Impide eliminar una organización cuando todavía existan personas asociadas
CREATE OR REPLACE FUNCTION fn_trg_impedir_eliminar_empresa_con_personas()
RETURNS TRIGGER AS $$
DECLARE
    v_personas_activas INT;
BEGIN
    SELECT COUNT(*) INTO v_personas_activas FROM personas WHERE empresa_id = OLD.id;
    
    IF v_personas_activas > 0 THEN
        RAISE EXCEPTION 'Violación de integridad: No se puede eliminar la empresa "%": cuenta con % colaborador(es) asociado(s).',
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


-- 7.9 Impide eliminar un sistema SST cuando existan organizaciones que lo estén utilizando
CREATE OR REPLACE FUNCTION fn_trg_impedir_eliminar_sistema_en_uso()
RETURNS TRIGGER AS $$
DECLARE
    v_en_uso INT;
BEGIN
    SELECT COUNT(*) INTO v_en_uso FROM sistemas_empresa WHERE sistema_id = OLD.id;
    
    IF v_en_uso > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el sistema "%" (ID %): está en uso por % organización(es).',
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


-- 7.10 Impide eliminar un módulo cuando dicho módulo esté asignado a una o más organizaciones
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
        RAISE EXCEPTION 'No se puede eliminar el módulo "%": posee % documentos generados en clientes.',
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


-- 7.11 Valida que el porcentaje de cumplimiento calculado permanezca entre 0 y 100
CREATE OR REPLACE FUNCTION fn_trg_validar_rango_porcentaje()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.porcentaje_cumplimiento < 0.00 OR NEW.porcentaje_cumplimiento > 100.00 THEN
        RAISE EXCEPTION 'Porcentaje inválido (%). El valor debe encontrarse en el rango de 0 a 100.', NEW.porcentaje_cumplimiento;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_rango_porcentaje ON autoevaluaciones_empresa;

CREATE TRIGGER trg_validar_rango_porcentaje
BEFORE INSERT OR UPDATE ON autoevaluaciones_empresa
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validar_rango_porcentaje();


-- 7.12 Registra en tabla de auditoría cualquier modificación en los datos principales de una empresa
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


-- 7.13 Auditoría que almacena el valor anterior y nuevo cuando se modifique el estado de una empresa
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


-- 7.14 Registra fecha y usuario responsable cuando una plantilla/documento sea modificada
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


-- 7.15 Elimina o desactiva bloqueos de edición vencidos en bloqueos_recursos
CREATE OR REPLACE FUNCTION fn_trg_limpiar_bloqueos_vencidos()
RETURNS TRIGGER AS $$
BEGIN
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
