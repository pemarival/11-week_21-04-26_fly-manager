--CONSULTA (INNER JOIN ≥ 5 tablas)
SELECT
    al.name                AS airline,
    f.fare_code            AS fare_code,
    fc.name                AS fare_class,
    ao.name                AS origin_airport,
    ad.name                AS destination_airport,
    c.code                 AS currency,
    r.reservation_code     AS reservation,
    s.sale_code            AS sale,
    t.ticket_number        AS ticket
FROM fare f
INNER JOIN airline al 
    ON al.airline_id = f.airline_id
INNER JOIN fare_class fc 
    ON fc.fare_class_id = f.fare_class_id
INNER JOIN airport ao 
    ON ao.airport_id = f.origin_airport_id
INNER JOIN airport ad 
    ON ad.airport_id = f.destination_airport_id
INNER JOIN currency c 
    ON c.currency_id = f.currency_id
INNER JOIN ticket t 
    ON t.fare_id = f.fare_id
INNER JOIN sale s 
    ON s.sale_id = t.sale_id
INNER JOIN reservation r 
    ON r.reservation_id = s.reservation_id;

--TRIGGER AFTER (evento comercial real)
CREATE OR REPLACE FUNCTION fn_after_ticket_use_fare()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE fare
    SET updated_at = now()
    WHERE fare_id = NEW.fare_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_after_ticket_use_fare
AFTER INSERT ON ticket
FOR EACH ROW
EXECUTE FUNCTION fn_after_ticket_use_fare();

--PROCEDIMIENTO ALMACENADO (publicar tarifa)
CREATE OR REPLACE PROCEDURE sp_create_fare(
    p_airline_id UUID,
    p_origin_airport_id UUID,
    p_destination_airport_id UUID,
    p_fare_class_id UUID,
    p_currency_id UUID,
    p_base_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Validación básica de negocio
    IF p_origin_airport_id = p_destination_airport_id THEN
        RAISE EXCEPTION 'Origen y destino no pueden ser iguales';
    END IF;

    INSERT INTO fare (
        fare_id,
        airline_id,
        origin_airport_id,
        destination_airport_id,
        fare_class_id,
        currency_id,
        base_amount,
        created_at
    )
    VALUES (
        gen_random_uuid(),
        p_airline_id,
        p_origin_airport_id,
        p_destination_airport_id,
        p_fare_class_id,
        p_currency_id,
        p_base_amount,
        now()
    );

END;
$$;

-- SCRIPT PARA DISPARAR EL TRIGGER

-- 1. Obtener datos base
SELECT fare_id FROM fare LIMIT 1;
SELECT sale_id FROM sale LIMIT 1;

-- 2. Insertar ticket (esto dispara el trigger)
INSERT INTO ticket (
    ticket_id,
    sale_id,
    fare_id,
    ticket_number,
    created_at
)
VALUES (
    gen_random_uuid(),
    'SALE_ID_AQUI',
    'FARE_ID_AQUI',
    'TCK-001',
    now()
);

-- 3. Validar efecto del trigger
SELECT fare_id, updated_at
FROM fare
WHERE fare_id = 'FARE_ID_AQUI';

-- SCRIPT PARA USAR EL PROCEDIMIENTO

-- 1. Obtener IDs necesarios
SELECT airline_id FROM airline LIMIT 1;
SELECT airport_id FROM airport LIMIT 2;
SELECT fare_class_id FROM fare_class LIMIT 1;
SELECT currency_id FROM currency LIMIT 1;

-- 2. Ejecutar procedimiento
CALL sp_create_fare(
    'AIRLINE_ID',
    'ORIGIN_AIRPORT_ID',
    'DESTINATION_AIRPORT_ID',
    'FARE_CLASS_ID',
    'CURRENCY_ID',
    350.00
);

-- 3. Validar creación
SELECT *
FROM fare
ORDER BY created_at DESC
LIMIT 1;