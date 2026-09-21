-- =============================================================================
-- PROYECTO: GESTIÓN DE SST Y PESV EN POSTGRESQL (MULTI-TENANT)
-- Archivo: 08_funciones_procedimientos.sql
-- Fase: 8. Programación Procedural en PL/pgSQL (Funciones y Procedimientos)
-- Motor: PostgreSQL 14+
-- Cumplimiento: Requerimientos de Secciones 5 y 6 de Examen.md
-- =============================================================================

-- =============================================================================
-- PARTE 0: PROCEDIMIENTOS Y FUNCIONES BASE DE INFRAESTRUCTURA
-- =============================================================================

-- 0.1 PROCEDIMIENTO: Onboarding Transaccional de Nueva Empresa (Tenant)
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
    SELECT id INTO v_tamano_id FROM tamanos_empresa WHERE codigo = p_tamano_codigo;
    IF v_tamano_id IS NULL THEN
        RAISE EXCEPTION 'El código de tamaño de empresa "%" no es válido.', p_tamano_codigo;
    END IF;

    INSERT INTO empresas (
        nit, dv, razon_social, sector_economico, clase_riesgo_arl, 
        tamano_id, municipio_id, direccion_principal, telefono, email_contacto
    ) VALUES (
        p_nit, p_dv, p_razon_social, p_sector, p_clase_riesgo, 
        v_tamano_id, p_municipio_id, p_direccion, p_telefono, p_email
    ) RETURNING id INTO v_nueva_empresa_id;

    INSERT INTO sedes_empresa (empresa_id, nombre, direccion, municipio_id, es_principal)
    VALUES (v_nueva_empresa_id, 'Sede Principal - ' || p_razon_social, p_direccion, p_municipio_id, TRUE);

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

    RAISE NOTICE 'Empresa "%" (ID: %) registrada con éxito con sus sedes y sistemas.',
        p_razon_social, v_nueva_empresa_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al registrar la empresa: %', SQLERRM;
END;
$$;


-- 0.2 PROCEDIMIENTO: Adquirir Bloqueo de Recurso (Control de Concurrencia)
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
    SELECT b.id, b.persona_id, b.expira_en, p.nombres || ' ' || p.apellidos AS usuario_bloqueador
    INTO r_bloqueo
    FROM bloqueos_recursos b
    JOIN personas p ON b.persona_id = p.id
    WHERE b.tipo_recurso = p_tipo_recurso
      AND b.recurso_id = p_recurso_id
      AND b.activo = TRUE;

    IF FOUND THEN
        IF r_bloqueo.expira_en < CURRENT_TIMESTAMP THEN
            UPDATE bloqueos_recursos SET activo = FALSE WHERE id = r_bloqueo.id;
        ELSIF r_bloqueo.persona_id = p_persona_id THEN
            UPDATE bloqueos_recursos 
            SET expira_en = CURRENT_TIMESTAMP + (p_duracion_minutos || ' minutes')::interval
            WHERE id = r_bloqueo.id;
            
            RAISE NOTICE 'Bloqueo extendido por % minutos más para el recurso #%.', p_duracion_minutos, p_recurso_id;
            RETURN;
        ELSE
            RAISE EXCEPTION 'RECURSO BLOQUEADO: El % #% está siendo editado por "%" hasta %.',
                p_tipo_recurso, p_recurso_id, r_bloqueo.usuario_bloqueador, r_bloqueo.expira_en;
        END IF;
    END IF;

    INSERT INTO bloqueos_recursos (
        empresa_id, tipo_recurso, recurso_id, persona_id, expira_en, activo
    ) VALUES (
        p_empresa_id, p_tipo_recurso, p_recurso_id, p_persona_id,
        CURRENT_TIMESTAMP + (p_duracion_minutos || ' minutes')::interval, TRUE
    );

    RAISE NOTICE 'Bloqueo adquirido exitosamente para el % #% por % minutos.',
        p_tipo_recurso, p_recurso_id, p_duracion_minutos;
END;
$$;


-- 0.3 PROCEDIMIENTO: Liberar Bloqueo de Recurso
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
        RAISE NOTICE 'Bloqueo del % #% liberado.', p_tipo_recurso, p_recurso_id;
    ELSE
        RAISE NOTICE 'Aviso: No había ningún bloqueo activo bajo su usuario para este recurso.';
    END IF;
END;
$$;


-- 0.4 FUNCIÓN: Calcular y Consolidar Calificación de Autoevaluación
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
    SELECT COALESCE(SUM(puntaje_asignado), 0.00)
    INTO v_total_puntos
    FROM detalles_autoevaluacion
    WHERE autoevaluacion_id = p_autoevaluacion_id
      AND cumple = TRUE;

    IF v_total_puntos < 60.00 THEN
        v_valoracion := 'CRITICO';
    ELSIF v_total_puntos BETWEEN 60.00 AND 85.00 THEN
        v_valoracion := 'MODERADAMENTE_ACEPTABLE';
    ELSE
        v_valoracion := 'ACEPTABLE';
    END IF;

    UPDATE autoevaluaciones_empresa
    SET puntaje_obtenido = v_total_puntos,
        porcentaje_cumplimiento = v_total_puntos,
        valoracion_cualitativa = v_valoracion
    WHERE id = p_autoevaluacion_id;

    RETURN v_total_puntos;
END;
$$;


-- =============================================================================
-- PARTE 1: SECCIÓN 5 DEL EXAMEN - PROCEDIMIENTOS ALMACENADOS (1 A 15)
-- =============================================================================

-- 5.1 Registrar una nueva organización validando que no exista NIT duplicado
CREATE OR REPLACE PROCEDURE sp_registrar_organizacion(
    p_nit VARCHAR(20),
    p_dv CHAR(1),
    p_razon_social VARCHAR(150),
    p_sector VARCHAR(100),
    p_clase_riesgo SMALLINT,
    p_tamano_id INT,
    p_municipio_id INT,
    p_direccion VARCHAR(150),
    p_email VARCHAR(100),
    p_telefono VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM empresas WHERE nit = p_nit) THEN
        RAISE EXCEPTION 'La organización con NIT % ya se encuentra registrada en el sistema.', p_nit;
    END IF;

    INSERT INTO empresas (
        nit, dv, razon_social, sector_economico, clase_riesgo_arl,
        tamano_id, municipio_id, direccion_principal, email_contacto, telefono
    ) VALUES (
        p_nit, p_dv, p_razon_social, p_sector, p_clase_riesgo,
        p_tamano_id, p_municipio_id, p_direccion, p_email, p_telefono
    );

    RAISE NOTICE 'Organización "%" registrada exitosamente.', p_razon_social;
END;
$$;


-- 5.2 Registrar una nueva persona y asociarla a una organización y a un cargo
CREATE OR REPLACE PROCEDURE sp_registrar_persona(
    p_empresa_id INT,
    p_tipo_doc VARCHAR(10),
    p_num_doc VARCHAR(20),
    p_nombres VARCHAR(80),
    p_apellidos VARCHAR(80),
    p_email VARCHAR(100),
    p_telefono VARCHAR(30),
    p_cargo_id INT,
    p_rol_sistema_id INT,
    p_fecha_ingreso DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cargos WHERE id = p_cargo_id AND empresa_id = p_empresa_id) THEN
        RAISE EXCEPTION 'El cargo ID % no pertenece a la organización ID %.', p_cargo_id, p_empresa_id;
    END IF;

    IF EXISTS (SELECT 1 FROM personas WHERE empresa_id = p_empresa_id AND tipo_documento = p_tipo_doc AND numero_documento = p_num_doc) THEN
        RAISE EXCEPTION 'Ya existe una persona registrada con documento % % en esta empresa.', p_tipo_doc, p_num_doc;
    END IF;

    INSERT INTO personas (
        empresa_id, tipo_documento, numero_documento, nombres, apellidos,
        email, telefono, cargo_id, rol_sistema_id, fecha_ingreso
    ) VALUES (
        p_empresa_id, p_tipo_doc, p_num_doc, p_nombres, p_apellidos,
        p_email, p_telefono, p_cargo_id, p_rol_sistema_id, p_fecha_ingreso
    );

    RAISE NOTICE 'Persona "% %" registrada con éxito.', p_nombres, p_apellidos;
END;
$$;


-- 5.3 Cambiar el estado de una organización entre activa e inactiva
CREATE OR REPLACE PROCEDURE sp_cambiar_estado_organizacion(
    p_empresa_id INT,
    p_nuevo_estado BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE empresas
    SET activo = p_nuevo_estado,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_empresa_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la organización con ID %.', p_empresa_id;
    END IF;

    RAISE NOTICE 'Estado de la organización ID % actualizado a: %.', p_empresa_id, p_nuevo_estado;
END;
$$;


-- 5.4 Asignar un módulo determinado a una organización evitando asignaciones duplicadas
CREATE OR REPLACE PROCEDURE sp_asignar_modulo_organizacion(
    p_empresa_id INT,
    p_sistema_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM sistemas_empresa WHERE empresa_id = p_empresa_id AND sistema_id = p_sistema_id) THEN
        RAISE NOTICE 'El sistema ID % ya se encuentra asignado a la empresa ID %.', p_sistema_id, p_empresa_id;
    ELSE
        INSERT INTO sistemas_empresa (empresa_id, sistema_id, estado, fecha_implementacion)
        VALUES (p_empresa_id, p_sistema_id, 'ACTIVO', CURRENT_DATE);
        RAISE NOTICE 'Sistema ID % asignado exitosamente a la empresa ID %.', p_sistema_id, p_empresa_id;
    END IF;
END;
$$;


-- 5.5 Habilitar un sistema SST para una organización determinada
CREATE OR REPLACE PROCEDURE sp_habilitar_sistema_sst(
    p_empresa_id INT,
    p_codigo_sistema VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sistema_id INT;
BEGIN
    SELECT id INTO v_sistema_id FROM sistemas_gestion WHERE codigo = p_codigo_sistema;
    IF v_sistema_id IS NULL THEN
        RAISE EXCEPTION 'El sistema con código "%" no existe.', p_codigo_sistema;
    END IF;

    INSERT INTO sistemas_empresa (empresa_id, sistema_id, estado)
    VALUES (p_empresa_id, v_sistema_id, 'ACTIVO')
    ON CONFLICT (empresa_id, sistema_id) 
    DO UPDATE SET estado = 'ACTIVO';

    RAISE NOTICE 'Sistema % habilitado para la empresa ID %.', p_codigo_sistema, p_empresa_id;
END;
$$;


-- 5.6 Asignar una plantilla a una organización indicando sistema, etapa y formato correspondiente
CREATE OR REPLACE PROCEDURE sp_asignar_plantilla_organizacion(
    p_empresa_id INT,
    p_plantilla_id INT,
    p_elaborado_por_id INT,
    p_codigo_doc VARCHAR(50),
    p_titulo VARCHAR(180)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM documentos_empresa WHERE empresa_id = p_empresa_id AND plantilla_id = p_plantilla_id) THEN
        RAISE NOTICE 'La plantilla % ya está asignada a la empresa %.', p_plantilla_id, p_empresa_id;
    ELSE
        INSERT INTO documentos_empresa (
            empresa_id, plantilla_id, codigo_documento, titulo,
            version, estado, elaborado_por_id, fecha_elaboracion
        ) VALUES (
            p_empresa_id, p_plantilla_id, p_codigo_doc, p_titulo,
            1, 'BORRADOR', p_elaborado_por_id, CURRENT_DATE
        );
        RAISE NOTICE 'Plantilla % asignada como documento "%".', p_plantilla_id, p_titulo;
    END IF;
END;
$$;


-- 5.7 Cambiar el cargo de una persona dentro de una organización
CREATE OR REPLACE PROCEDURE sp_cambiar_cargo_persona(
    p_persona_id INT,
    p_nuevo_cargo_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_empresa_persona INT;
    v_empresa_cargo INT;
BEGIN
    SELECT empresa_id INTO v_empresa_persona FROM personas WHERE id = p_persona_id;
    SELECT empresa_id INTO v_empresa_cargo FROM cargos WHERE id = p_nuevo_cargo_id;

    IF v_empresa_persona IS NULL THEN
        RAISE EXCEPTION 'La persona ID % no existe.', p_persona_id;
    END IF;

    IF v_empresa_persona <> v_empresa_cargo THEN
        RAISE EXCEPTION 'El nuevo cargo no pertenece a la misma empresa de la persona.';
    END IF;

    UPDATE personas SET cargo_id = p_nuevo_cargo_id WHERE id = p_persona_id;
    RAISE NOTICE 'Cargo de la persona ID % actualizado exitosamente.', p_persona_id;
END;
$$;


-- 5.8 Trasladar una persona de una organización a otra
CREATE OR REPLACE PROCEDURE sp_trasladar_persona(
    p_persona_id INT,
    p_nueva_empresa_id INT,
    p_nuevo_cargo_id INT,
    p_nueva_sede_id INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cargos WHERE id = p_nuevo_cargo_id AND empresa_id = p_nueva_empresa_id) THEN
        RAISE EXCEPTION 'El cargo ID % no pertenece a la nueva empresa ID %.', p_nuevo_cargo_id, p_nueva_empresa_id;
    END IF;

    UPDATE personas
    SET empresa_id = p_nueva_empresa_id,
        cargo_id = p_nuevo_cargo_id,
        sede_id = p_nueva_sede_id
    WHERE id = p_persona_id;

    RAISE NOTICE 'Persona ID % trasladada satisfactoriamente a la empresa ID %.', p_persona_id, p_nueva_empresa_id;
END;
$$;


-- 5.9 Deshabilitar todos los módulos asociados a una organización que haya sido marcada como inactiva
CREATE OR REPLACE PROCEDURE sp_deshabilitar_modulos_empresa_inactiva(
    p_empresa_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_activa BOOLEAN;
BEGIN
    SELECT activo INTO v_activa FROM empresas WHERE id = p_empresa_id;
    
    IF v_activa = TRUE THEN
        RAISE NOTICE 'La empresa ID % continúa activa. No se suspendieron módulos.', p_empresa_id;
        RETURN;
    END IF;

    UPDATE sistemas_empresa
    SET estado = 'SUSPENDIDO'
    WHERE empresa_id = p_empresa_id;

    RAISE NOTICE 'Todos los sistemas de la empresa inactiva ID % fueron suspendidos.', p_empresa_id;
END;
$$;


-- 5.10 Eliminar de manera controlada una asignación de módulo validando registros dependientes
CREATE OR REPLACE PROCEDURE sp_eliminar_asignacion_modulo(
    p_empresa_id INT,
    p_sistema_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_docs_asociados INT;
BEGIN
    SELECT COUNT(de.id) INTO v_docs_asociados
    FROM documentos_empresa de
    JOIN plantillas p ON de.plantilla_id = p.id
    JOIN modulos m ON p.modulo_id = m.id
    WHERE de.empresa_id = p_empresa_id AND m.sistema_id = p_sistema_id;

    IF v_docs_asociados > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar la asignación: existen % documentos generados vinculados al sistema.', v_docs_asociados;
    END IF;

    DELETE FROM sistemas_empresa 
    WHERE empresa_id = p_empresa_id AND sistema_id = p_sistema_id;

    RAISE NOTICE 'Asignación del sistema ID % eliminada correctamente para la empresa ID %.', p_sistema_id, p_empresa_id;
END;
$$;


-- 5.11 Determinar el número total de plantillas asociadas a una organización y mostrarlo mediante RAISE NOTICE
CREATE OR REPLACE PROCEDURE sp_contar_plantillas_organizacion(
    p_empresa_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
    v_nombre VARCHAR(150);
BEGIN
    SELECT razon_social INTO v_nombre FROM empresas WHERE id = p_empresa_id;
    SELECT COUNT(*) INTO v_total FROM documentos_empresa WHERE empresa_id = p_empresa_id;

    RAISE NOTICE 'La organización "%" (ID: %) tiene % plantilla(s)/documento(s) asignados.',
        v_nombre, p_empresa_id, v_total;
END;
$$;


-- 5.12 Determinar el porcentaje de cumplimiento documental de una organización
CREATE OR REPLACE PROCEDURE sp_calcular_cumplimiento_organizacion(
    p_empresa_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
    v_finalizados INT;
    v_pct NUMERIC(5, 2);
BEGIN
    SELECT COUNT(*), COUNT(CASE WHEN estado = 'APROBADO' THEN 1 END)
    INTO v_total, v_finalizados
    FROM documentos_empresa
    WHERE empresa_id = p_empresa_id;

    IF v_total = 0 THEN
        v_pct := 0.00;
    ELSE
        v_pct := ROUND((v_finalizados::numeric / v_total) * 100, 2);
    END IF;

    RAISE NOTICE 'Empresa ID % -> Total: %, Finalizados: %, Cumplimiento: % %',
        p_empresa_id, v_total, v_finalizados, v_pct, '%';
END;
$$;


-- 5.13 Determinar la cantidad de documentos correspondientes a una etapa PHVA para una organización
CREATE OR REPLACE PROCEDURE sp_contar_documentos_etapa(
    p_empresa_id INT,
    p_codigo_etapa CHAR(1)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_conteo INT;
    v_etapa_nombre VARCHAR(30);
BEGIN
    SELECT nombre INTO v_etapa_nombre FROM etapas_phva WHERE codigo = p_codigo_etapa;
    
    SELECT COUNT(de.id) INTO v_conteo
    FROM documentos_empresa de
    JOIN plantillas p ON de.plantilla_id = p.id
    JOIN modulos m ON p.modulo_id = m.id
    JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
    WHERE de.empresa_id = p_empresa_id AND ep.codigo = p_codigo_etapa;

    RAISE NOTICE 'Etapa "%" (%): % documentos para la empresa ID %.',
        v_etapa_nombre, p_codigo_etapa, v_conteo, p_empresa_id;
END;
$$;


-- 5.14 Modificar simultáneamente datos de contacto de una organización y registrar fecha de actualización
CREATE OR REPLACE PROCEDURE sp_actualizar_contacto_organizacion(
    p_empresa_id INT,
    p_nuevo_email VARCHAR(100),
    p_nuevo_telefono VARCHAR(30),
    p_nueva_direccion VARCHAR(150)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE empresas
    SET email_contacto = p_nuevo_email,
        telefono = p_nuevo_telefono,
        direccion_principal = p_nueva_direccion,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_empresa_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la empresa con ID %.', p_empresa_id;
    END IF;

    RAISE NOTICE 'Datos de contacto y updated_at modificados con éxito para la empresa ID %.', p_empresa_id;
END;
$$;


-- 5.15 Asignar plantilla con manejo de excepciones para controlar errores
CREATE OR REPLACE PROCEDURE sp_asignar_plantilla_segura(
    p_empresa_id INT,
    p_plantilla_id INT,
    p_elaborado_por_id INT,
    p_codigo_doc VARCHAR(50),
    p_titulo VARCHAR(180)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO documentos_empresa (
        empresa_id, plantilla_id, codigo_documento, titulo,
        version, estado, elaborado_por_id, fecha_elaboracion
    ) VALUES (
        p_empresa_id, p_plantilla_id, p_codigo_doc, p_titulo,
        1, 'BORRADOR', p_elaborado_por_id, CURRENT_DATE
    );
    
    RAISE NOTICE 'Asignación procesada exitosamente.';
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Error controlado: La plantilla o código "%" ya existe para la empresa.', p_codigo_doc;
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Error controlado: La empresa, plantilla o persona especificada no existe.';
    WHEN OTHERS THEN
        RAISE NOTICE 'Ocurrió una excepción imprevista: % (Código SQL: %)', SQLERRM, SQLSTATE;
END;
$$;


-- =============================================================================
-- PARTE 2: SECCIÓN 6 DEL EXAMEN - FUNCIONES ALMACENADAS (1 A 8)
-- =============================================================================

-- 6.1 Recibe el ID de una organización y retorna la cantidad total de personas asociadas
CREATE OR REPLACE FUNCTION fn_total_personas_tenant(p_empresa_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
BEGIN
    SELECT COUNT(*) INTO v_total FROM personas WHERE empresa_id = p_empresa_id;
    RETURN v_total;
END;
$$;


-- 6.2 Recibe el ID de una organización y retorna su porcentaje de cumplimiento documental
CREATE OR REPLACE FUNCTION fn_porcentaje_cumplimiento_tenant(p_empresa_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
    v_aprobados INT;
BEGIN
    SELECT COUNT(*), COUNT(CASE WHEN estado = 'APROBADO' THEN 1 END)
    INTO v_total, v_aprobados
    FROM documentos_empresa
    WHERE empresa_id = p_empresa_id;

    IF v_total = 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND((v_aprobados::numeric / v_total) * 100, 2);
END;
$$;


-- 6.3 Determina si una organización tiene habilitado un módulo específico y retorna booleano
CREATE OR REPLACE FUNCTION fn_tiene_modulo_habilitado(
    p_empresa_id INT,
    p_codigo_modulo VARCHAR(30)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_existe BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM sistemas_empresa se
        JOIN modulos m ON se.sistema_id = m.sistema_id
        WHERE se.empresa_id = p_empresa_id 
          AND se.estado = 'ACTIVO'
          AND m.codigo = p_codigo_modulo
          AND m.activo = TRUE
    ) INTO v_existe;

    RETURN v_existe;
END;
$$;


-- 6.4 Recibe el ID de una persona y retorna su nombre completo
CREATE OR REPLACE FUNCTION fn_nombre_completo_persona(p_persona_id INT)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombre VARCHAR(200);
BEGIN
    SELECT nombres || ' ' || apellidos INTO v_nombre
    FROM personas
    WHERE id = p_persona_id;

    RETURN COALESCE(v_nombre, 'Persona no encontrada');
END;
$$;


-- 6.5 Retorna la cantidad de plantillas existentes para una organización y una etapa PHVA
CREATE OR REPLACE FUNCTION fn_plantillas_por_etapa(
    p_empresa_id INT,
    p_codigo_etapa CHAR(1)
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_conteo INT;
BEGIN
    SELECT COUNT(de.id) INTO v_conteo
    FROM documentos_empresa de
    JOIN plantillas p ON de.plantilla_id = p.id
    JOIN modulos m ON p.modulo_id = m.id
    JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
    WHERE de.empresa_id = p_empresa_id AND ep.codigo = p_codigo_etapa;

    RETURN COALESCE(v_conteo, 0);
END;
$$;


-- 6.6 Función tabular que retorna todos los módulos habilitados para una organización
CREATE OR REPLACE FUNCTION fn_modulos_habilitados_tenant(p_empresa_id INT)
RETURNS TABLE (
    modulo_id INT,
    codigo_modulo VARCHAR(30),
    nombre_modulo VARCHAR(120),
    sistema_gestion VARCHAR(100),
    etapa_phva VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.codigo,
        m.nombre,
        sg.nombre,
        ep.nombre
    FROM sistemas_empresa se
    JOIN sistemas_gestion sg ON se.sistema_id = sg.id
    JOIN modulos m ON sg.id = m.sistema_id
    JOIN etapas_phva ep ON m.etapa_phva_id = ep.id
    WHERE se.empresa_id = p_empresa_id 
      AND se.estado = 'ACTIVO'
      AND m.activo = TRUE
    ORDER BY ep.orden_secuencia, m.id;
END;
$$;


-- 6.7 Función tabular que retorna las personas pertenecientes a una organización junto con sus cargos
CREATE OR REPLACE FUNCTION fn_personas_cargos_tenant(p_empresa_id INT)
RETURNS TABLE (
    persona_id INT,
    documento VARCHAR(35),
    nombre_completo VARCHAR(165),
    email VARCHAR(100),
    cargo VARCHAR(100),
    nivel_jerarquico VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.tipo_documento || ' ' || p.numero_documento,
        (p.nombres || ' ' || p.apellidos)::VARCHAR(165),
        p.email,
        c.nombre,
        c.nivel_jerarquico
    FROM personas p
    JOIN cargos c ON p.cargo_id = c.id
    WHERE p.empresa_id = p_empresa_id
    ORDER BY c.nombre, p.apellidos;
END;
$$;


-- 6.8 Clasifica el nivel de cumplimiento de una organización como bajo, medio o alto según porcentaje
CREATE OR REPLACE FUNCTION fn_clasificar_cumplimiento(p_porcentaje NUMERIC)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_porcentaje IS NULL OR p_porcentaje < 60.00 THEN
        RETURN 'BAJO';
    ELSIF p_porcentaje BETWEEN 60.00 AND 84.99 THEN
        RETURN 'MEDIO';
    ELSE
        RETURN 'ALTO';
    END IF;
END;
$$;
