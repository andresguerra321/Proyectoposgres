-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 08_funciones_procedimientos.sql
-- Fase: 8. Programación Procedural en PL/pgSQL (Funciones y Procedimientos)
-- =============================================================================

-- =============================================================================
-- 1. PROCEDIMIENTO: Onboarding Transaccional de Nueva Empresa (Tenant)
-- =============================================================================
-- Permite registrar una organización, su sede principal y activar sus sistemas
-- en una única transacción atómica.
CREATE OR REPLACE PROCEDURE sp_registrar_empresa_completa(
    p_nit VARCHAR(20),
    p_dv CHAR(1),
    p_razon_social VARCHAR(150),
    p_sector VARCHAR(100),
    p_clase_riesgo SMALLINT,
    p_tamano_codigo VARCHAR(20),
    p_municipio_id INT,
    p_direccion VARCHAR(150),
    p_email VARCHAR(100),
    p_telefono VARCHAR(30),
    p_sistemas_codigos VARCHAR(20)[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tamano_id INT;
    v_nueva_empresa_id INT;
    v_sistema_codigo VARCHAR(20);
    v_sistema_id INT;
BEGIN
    -- 1. Validar el tamaño de la empresa
    SELECT id INTO v_tamano_id FROM tamanos_empresa WHERE codigo = p_tamano_codigo;
    IF v_tamano_id IS NULL THEN
        RAISE EXCEPTION 'El código de tamaño de empresa "%" no es válido.', p_tamano_codigo;
    END IF;

    -- 2. Insertar la empresa (Tenant)
    INSERT INTO empresas (
        nit, dv, razon_social, sector_economico, clase_riesgo_arl, 
        tamano_id, municipio_id, direccion_principal, telefono, email_contacto
    ) VALUES (
        p_nit, p_dv, p_razon_social, p_sector, p_clase_riesgo, 
        v_tamano_id, p_municipio_id, p_direccion, p_telefono, p_email
    ) RETURNING id INTO v_nueva_empresa_id;

    -- 3. Crear automáticamente la Sede Principal
    INSERT INTO sedes_empresa (empresa_id, nombre, direccion, municipio_id, es_principal)
    VALUES (v_nueva_empresa_id, 'Sede Principal - ' || p_razon_social, p_direccion, p_municipio_id, TRUE);

    -- 4. Activar los sistemas de gestión seleccionados
    FOREACH v_sistema_codigo IN ARRAY p_sistemas_codigos
    LOOP
        SELECT id INTO v_sistema_id FROM sistemas_gestion WHERE codigo = v_sistema_codigo;
        
        IF v_sistema_id IS NOT NULL THEN
            INSERT INTO sistemas_empresa (empresa_id, sistema_id, estado, observaciones)
            VALUES (v_nueva_empresa_id, v_sistema_id, 'ACTIVO', 'Habilitado en proceso de onboarding inicial');
        ELSE
            RAISE NOTICE 'Aviso: El sistema "%" no existe y fue omitido.', v_sistema_codigo;
        END IF;
    END LOOP;

    RAISE NOTICE '✅ Empresa "%" (ID: %) registrada con éxito con sus sedes y sistemas.',
        p_razon_social, v_nueva_empresa_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al registrar la empresa: %', SQLERRM;
END;
$$;


-- =============================================================================
-- 2. PROCEDIMIENTO: Adquirir Bloqueo de Recurso (Control de Concurrencia)
-- =============================================================================
-- Evita que dos personas editen un documento o evaluación al mismo tiempo.
CREATE OR REPLACE PROCEDURE sp_adquirir_bloqueo_recurso(
    p_empresa_id INT,
    p_tipo_recurso VARCHAR(50),
    p_recurso_id INT,
    p_persona_id INT,
    p_duracion_minutos INT DEFAULT 15
)
LANGUAGE plpgsql
AS $$
DECLARE
    r_bloqueo RECORD;
BEGIN
    -- 1. Verificar si existe un bloqueo activo
    SELECT b.id, b.persona_id, b.expira_en, p.nombres || ' ' || p.apellidos AS usuario_bloqueador
    INTO r_bloqueo
    FROM bloqueos_recursos b
    JOIN personas p ON b.persona_id = p.id
    WHERE b.tipo_recurso = p_tipo_recurso
      AND b.recurso_id = p_recurso_id
      AND b.activo = TRUE;

    IF FOUND THEN
        -- Si el bloqueo ya expiró, lo desactivamos automáticamente
        IF r_bloqueo.expira_en < CURRENT_TIMESTAMP THEN
            UPDATE bloqueos_recursos SET activo = FALSE WHERE id = r_bloqueo.id;
        ELSIF r_bloqueo.persona_id = p_persona_id THEN
            -- Si es la misma persona, extendemos el tiempo de expiración
            UPDATE bloqueos_recursos 
            SET expira_en = CURRENT_TIMESTAMP + (p_duracion_minutos || ' minutes')::interval
            WHERE id = r_bloqueo.id;
            
            RAISE NOTICE 'Bloqueo extendido por % minutos más para el recurso #%.', p_duracion_minutos, p_recurso_id;
            RETURN;
        ELSE
            -- El recurso está bloqueado por otra persona
            RAISE EXCEPTION 'RECURSO BLOQUEADO: El % #% está siendo editado por "%" hasta %.',
                p_tipo_recurso, p_recurso_id, r_bloqueo.usuario_bloqueador, r_bloqueo.expira_en;
        END IF;
    END IF;

    -- 2. Registrar el nuevo bloqueo activo
    INSERT INTO bloqueos_recursos (
        empresa_id, tipo_recurso, recurso_id, persona_id, expira_en, activo
    ) VALUES (
        p_empresa_id, p_tipo_recurso, p_recurso_id, p_persona_id,
        CURRENT_TIMESTAMP + (p_duracion_minutos || ' minutes')::interval, TRUE
    );

    RAISE NOTICE '✅ Bloqueo adquirido exitosamente para el % #% por % minutos.',
        p_tipo_recurso, p_recurso_id, p_duracion_minutos;
END;
$$;


-- =============================================================================
-- 3. PROCEDIMIENTO: Liberar Bloqueo de Recurso
-- =============================================================================
CREATE OR REPLACE PROCEDURE sp_liberar_bloqueo_recurso(
    p_tipo_recurso VARCHAR(50),
    p_recurso_id INT,
    p_persona_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE bloqueos_recursos
    SET activo = FALSE
    WHERE tipo_recurso = p_tipo_recurso
      AND recurso_id = p_recurso_id
      AND persona_id = p_persona_id
      AND activo = TRUE;

    IF FOUND THEN
        RAISE NOTICE '✅ Bloqueo del % #% liberado.', p_tipo_recurso, p_recurso_id;
    ELSE
        RAISE NOTICE 'Aviso: No había ningún bloqueo activo bajo su usuario para este recurso.';
    END IF;
END;
$$;


-- =============================================================================
-- 4. FUNCIÓN: Calcular y Consolidar Calificación de Autoevaluación
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_calcular_autoevaluacion(
    p_autoevaluacion_id INT
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_puntos NUMERIC(5, 2) := 0.00;
    v_valoracion VARCHAR(30);
BEGIN
    -- Sumar puntos de ítems cumplidos
    SELECT COALESCE(SUM(puntaje_asignado), 0.00)
    INTO v_total_puntos
    FROM detalles_autoevaluacion
    WHERE autoevaluacion_id = p_autoevaluacion_id
      AND cumple = TRUE;

    -- Categorizar según normativa Res. 0312
    IF v_total_puntos < 60.00 THEN
        v_valoracion := 'CRITICO';
    ELSIF v_total_puntos BETWEEN 60.00 AND 85.00 THEN
        v_valoracion := 'MODERADAMENTE_ACEPTABLE';
    ELSE
        v_valoracion := 'ACEPTABLE';
    END IF;

    -- Actualizar cabecera de la evaluación
    UPDATE autoevaluaciones_empresa
    SET puntaje_obtenido = v_total_puntos,
        porcentaje_cumplimiento = v_total_puntos,
        valoracion_cualitativa = v_valoracion
    WHERE id = p_autoevaluacion_id;

    RETURN v_total_puntos;
END;
$$;
