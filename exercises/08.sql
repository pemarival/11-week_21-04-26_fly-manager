--Consulta con INNER JOIN
SELECT
    p.first_name || ' ' || p.last_name     AS person_name,
    ua.username                            AS username,
    us.name                                AS user_status,
    sr.name                                AS role_name,
    ur.assigned_at                         AS role_assigned_at,
    sp.name                                AS permission_name
FROM person p
INNER JOIN user_account ua 
    ON ua.person_id = p.person_id
INNER JOIN user_status us 
    ON ua.user_status_id = us.user_status_id
INNER JOIN user_role ur 
    ON ur.user_account_id = ua.user_account_id
INNER JOIN security_role sr 
    ON ur.security_role_id = sr.security_role_id
INNER JOIN role_permission rp 
    ON rp.security_role_id = sr.security_role_id
INNER JOIN security_permission sp 
    ON rp.security_permission_id = sp.security_permission_id;

--Trigger AFTER INSERT sobre user_role
CREATE OR REPLACE FUNCTION fn_after_insert_user_role()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE user_account
    SET updated_at = now()
    WHERE user_account_id = NEW.user_account_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_after_insert_user_role
AFTER INSERT ON user_role
FOR EACH ROW
EXECUTE FUNCTION fn_after_insert_user_role();

--Procedimiento almacenado
CREATE OR REPLACE PROCEDURE sp_assign_user_role(
    p_user_account_id UUID,
    p_security_role_id UUID,
    p_assigned_by UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO user_role (
        user_role_id,
        user_account_id,
        security_role_id,
        assigned_by,
        assigned_at
    )
    VALUES (
        gen_random_uuid(),
        p_user_account_id,
        p_security_role_id,
        p_assigned_by,
        now()
    );
END;
$$;

--Script de prueba del trigger
-- 1. Obtener datos
SELECT user_account_id FROM user_account LIMIT 1;
SELECT security_role_id FROM security_role LIMIT 1;

-- 2. Insertar rol directamente
INSERT INTO user_role (
    user_role_id,
    user_account_id,
    security_role_id,
    assigned_by,
    assigned_at
)
VALUES (
    gen_random_uuid(),
    'USER_ID_AQUI',
    'ROLE_ID_AQUI',
    'USER_ID_AQUI',
    now()
);

-- 3. Validar efecto
SELECT user_account_id, updated_at
FROM user_account
WHERE user_account_id = 'USER_ID_AQUI';

--Script usando el procedimiento
CALL sp_assign_user_role(
    'USER_ID_AQUI',
    'ROLE_ID_AQUI',
    'USER_ID_AQUI'
);

--Validaciones
-- Ver roles asignados
SELECT *
FROM user_role
ORDER BY assigned_at DESC;

-- Ver actualización en usuario
SELECT user_account_id, updated_at
FROM user_account
ORDER BY updated_at DESC;