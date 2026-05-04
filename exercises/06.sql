--Consulta con INNER JOIN (mínimo 5 tablas)

SELECT
    al.name                AS airline,
    f.flight_number        AS flight_number,
    f.service_date         AS service_date,
    fs.name                AS flight_status,
    seg.segment_number     AS segment,
    ao.name                AS origin_airport,
    ad.name                AS destination_airport,
    fd.delay_minutes       AS delay_minutes,
    drt.name               AS delay_reason
FROM flight f
INNER JOIN airline al 
    ON f.airline_id = al.airline_id
INNER JOIN flight_status fs 
    ON f.flight_status_id = fs.flight_status_id
INNER JOIN flight_segment seg 
    ON seg.flight_id = f.flight_id
INNER JOIN airport ao 
    ON seg.origin_airport_id = ao.airport_id
INNER JOIN airport ad 
    ON seg.destination_airport_id = ad.airport_id
INNER JOIN flight_delay fd 
    ON fd.flight_segment_id = seg.flight_segment_id
INNER JOIN delay_reason_type drt 
    ON fd.delay_reason_type_id = drt.delay_reason_type_id;

--Trigger AFTER INSERT sobre flight_delay

CREATE OR REPLACE FUNCTION fn_after_insert_flight_delay()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE flight
    SET flight_status_id = (
        SELECT flight_status_id 
        FROM flight_status 
        WHERE name = 'DELAYED'
        LIMIT 1
    )
    WHERE flight_id = (
        SELECT flight_id
        FROM flight_segment
        WHERE flight_segment_id = NEW.flight_segment_id
    );

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_after_insert_flight_delay
AFTER INSERT ON flight_delay
FOR EACH ROW
EXECUTE FUNCTION fn_after_insert_flight_delay();

--Procedimiento almacenado

CREATE OR REPLACE PROCEDURE sp_register_flight_delay(
    p_flight_segment_id UUID,
    p_delay_reason_type_id UUID,
    p_delay_minutes INT,
    p_reported_at TIMESTAMP,
    p_notes TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO flight_delay (
        flight_delay_id,
        flight_segment_id,
        delay_reason_type_id,
        delay_minutes,
        reported_at,
        notes
    )
    VALUES (
        gen_random_uuid(),
        p_flight_segment_id,
        p_delay_reason_type_id,
        p_delay_minutes,
        p_reported_at,
        p_notes
    );
END;
$$;

--Script de prueba del trigger

-- 1. Obtener datos base
SELECT flight_segment_id FROM flight_segment LIMIT 1;
SELECT delay_reason_type_id FROM delay_reason_type LIMIT 1;

-- 2. Insertar demora
INSERT INTO flight_delay (
    flight_delay_id,
    flight_segment_id,
    delay_reason_type_id,
    delay_minutes,
    reported_at,
    notes
)
VALUES (
    gen_random_uuid(),
    'SEGMENT_ID_AQUI',
    'REASON_ID_AQUI',
    45,
    now(),
    'Demora por clima'
);

-- 3. Validar cambio en flight
SELECT f.flight_id, fs.name
FROM flight f
JOIN flight_status fs 
    ON f.flight_status_id = fs.flight_status_id;

--Script de uso del procedimiento

CALL sp_register_flight_delay(
    'SEGMENT_ID_AQUI',
    'REASON_ID_AQUI',
    30,
    now(),
    'Demora operativa'
);

--6. Validación final
-- Ver retraso registrado
SELECT * 
FROM flight_delay
ORDER BY reported_at DESC;

-- Ver estado del vuelo actualizado
SELECT f.flight_number, fs.name
FROM flight f
JOIN flight_status fs 
    ON f.flight_status_id = fs.flight_status_id;