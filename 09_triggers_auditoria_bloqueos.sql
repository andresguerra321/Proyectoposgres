-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 09_triggers_auditoria_bloqueos.sql
-- Fase: 9. Automatización con Triggers (Auditoría, Multi-Tenancy y Bloqueos)
-- =============================================================================

-- =============================================================================
-- 1. TRIGGER: Validación de Integridad Multi-Tenant en Documentos
-- =============================================================================
-- Regla de Negocio Crítica:
-- Garantiza que una persona NO pueda elaborar o aprobar documentos de otra empresa.
CREATE OR REPLACE FUNCTION fn_trg_validar_multitenant_documento()
RETURNS TRIGGER AS $$
DECLARE
    v_persona_empresa_id INT;
BEGIN
    -- Validar que la persona que elabora pertenece al mismo tenant
    SELECT empresa_id INTO v_persona_empresa_id
    FROM personas
    WHERE id = NEW.elaborado_por_id;

    IF v_persona_empresa_id IS DISTINCT FROM NEW.empresa_id THEN
        RAISE EXCEPTION 'VIOLACIÓN DE SEGURIDAD MULTI-TENANT: El trabajador (ID %) pertenece a la empresa #% y no puede registrar documentos en la empresa #%.',
            NEW.elaborado_por_id, v_persona_empresa_id, NEW.empresa_id;
    END IF;

    -- Validar aprobador si está presente
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


-- =============================================================================
-- 2. TRIGGER: Verificación de Bloqueos Activos antes de Modificar Documentos
-- =============================================================================
-- Si un usuario intenta actualizar un documento que tiene un bloqueo activo
-- asignado a otra persona, la transacción se revierte inmediatamente.
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
        -- Si el bloqueo pertenece a otra persona distinta al editor
        IF r_bloqueo.persona_id IS DISTINCT FROM NEW.elaborado_por_id THEN
            RAISE EXCEPTION 'DOCUMENTO BLOQUEADO: El documento #% está bloqueado por "%" hasta %. Intente más tarde.',
                OLD.id, r_bloqueo.usuario, r_bloqueo.expira_en;
        END IF;
    END IF;

    -- Actualizar marca de tiempo
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_verificar_bloqueo_edicion ON documentos_empresa;

CREATE TRIGGER trg_verificar_bloqueo_edicion
BEFORE UPDATE ON documentos_empresa
FOR EACH ROW
EXECUTE FUNCTION fn_trg_verificar_bloqueo_edicion();
