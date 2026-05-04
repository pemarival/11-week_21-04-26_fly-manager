--CONSULTA (INNER JOIN ≥ 5 tablas)

SELECT
    p.person_id,
    pt.name AS person_type,
    dt.name AS document_type,
    pd.document_number,
    ct.name AS contact_type,
    pc.contact_value,
    r.reservation_id,
    rp.passenger_sequence
FROM person p
INNER JOIN person_type pt 
    ON pt.person_type_id = p.person_type_id
INNER JOIN person_document pd 
    ON pd.person_id = p.person_id
INNER JOIN document_type dt 
    ON dt.document_type_id = pd.document_type_id
INNER JOIN person_contact pc 
    ON pc.person_id = p.person_id
INNER JOIN contact_type ct 
    ON ct.contact_type_id = pc.contact_type_id
INNER JOIN reservation_passenger rp 
    ON rp.person_id = p.person_id
INNER JOIN reservation r 
    ON r.reservation_id = rp.reservation_id;

--TRIGGER AFTER (sobre person_contact)
CREATE OR REPLACE FUNCTION fn_ai_person_contact_touch_person()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE person
    SET updated_at = now()
    WHERE person_id = NEW.person_id;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ai_person_contact_touch_person ON person_contact;

CREATE TRIGGER trg_ai_person_contact_touch_person
AFTER INSERT ON person_contact
FOR EACH ROW
EXECUTE FUNCTION fn_ai_person_contact_touch_person();

--PROCEDIMIENTO ALMACENADO

CREATE OR REPLACE PROCEDURE sp_add_person_contact(
    p_person_id uuid,
    p_contact_type_id uuid,
    p_contact_value text
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO person_contact (
        person_contact_id,
        person_id,
        contact_type_id,
        contact_value,
        created_at
    )
    VALUES (
        gen_random_uuid(),
        p_person_id,
        p_contact_type_id,
        p_contact_value,
        now()
    );
END;
$$;

-- SCRIPT PARA DISPARAR EL TRIGGER

-- 1. Obtener datos base
SELECT person_id FROM person LIMIT 1;
SELECT contact_type_id FROM contact_type LIMIT 1;

-- 2. Insertar contacto (dispara trigger)
INSERT INTO person_contact (
    person_contact_id,
    person_id,
    contact_type_id,
    contact_value,
    created_at
)
VALUES (
    gen_random_uuid(),
    'PERSON_ID_AQUI',
    'CONTACT_TYPE_ID_AQUI',
    'correo@test.com',
    now()
);

-- 3. Validar efecto
SELECT person_id, updated_at
FROM person
WHERE person_id = 'PERSON_ID_AQUI';

-- SCRIPT USANDO EL PROCEDIMIENTO
-- 1. Obtener IDs
SELECT person_id FROM person LIMIT 1;
SELECT contact_type_id FROM contact_type LIMIT 1;

-- 2. Ejecutar procedimiento
CALL sp_add_person_contact(
    'PERSON_ID_AQUI',
    'CONTACT_TYPE_ID_AQUI',
    'nuevo@email.com'
);

-- 3. Validar inserción
SELECT *
FROM person_contact
WHERE person_id = 'PERSON_ID_AQUI'
ORDER BY created_at DESC;

-- 4. Validar trigger
SELECT person_id, updated_at
FROM person
WHERE person_id = 'PERSON_ID_AQUI';

--VALIDACIONES CLAVE

SELECT *
FROM person_contact
ORDER BY created_at DESC;

SELECT person_id, updated_at
FROM person
ORDER BY updated_at DESC;