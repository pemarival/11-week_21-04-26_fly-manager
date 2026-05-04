--Consulta con INNER JOIN
SELECT
    t.ticket_number                 AS ticket_number,
    ts.segment_sequence             AS ticket_segment,
    f.flight_number                 AS flight_number,
    cc.name                         AS cabin_class,
    s.seat_row                      AS seat_row,
    s.seat_column                   AS seat_column,
    b.baggage_tag                   AS baggage_tag,
    b.baggage_type                  AS baggage_type,
    b.status                        AS baggage_status
FROM ticket t
INNER JOIN ticket_segment ts 
    ON ts.ticket_id = t.ticket_id
INNER JOIN flight_segment fs 
    ON ts.flight_segment_id = fs.flight_segment_id
INNER JOIN flight f 
    ON fs.flight_id = f.flight_id
INNER JOIN seat_assignment sa 
    ON sa.ticket_segment_id = ts.ticket_segment_id
INNER JOIN aircraft_seat s 
    ON sa.aircraft_seat_id = s.aircraft_seat_id
INNER JOIN aircraft_cabin ac 
    ON s.aircraft_cabin_id = ac.aircraft_cabin_id
INNER JOIN cabin_class cc 
    ON ac.cabin_class_id = cc.cabin_class_id
INNER JOIN baggage b 
    ON b.ticket_segment_id = ts.ticket_segment_id;

--Trigger AFTER INSERT

CREATE OR REPLACE FUNCTION fn_after_insert_baggage()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE ticket_segment
    SET updated_at = now()  -- o cualquier campo existente válido
    WHERE ticket_segment_id = NEW.ticket_segment_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_after_insert_baggage
AFTER INSERT ON baggage
FOR EACH ROW
EXECUTE FUNCTION fn_after_insert_baggage();

--Procedimiento almacenado

CREATE OR REPLACE PROCEDURE sp_register_baggage(
    p_ticket_segment_id UUID,
    p_baggage_tag TEXT,
    p_baggage_type TEXT,
    p_status TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO baggage (
        baggage_id,
        ticket_segment_id,
        baggage_tag,
        baggage_type,
        status,
        created_at
    )
    VALUES (
        gen_random_uuid(),
        p_ticket_segment_id,
        p_baggage_tag,
        p_baggage_type,
        p_status,
        now()
    );
END;
$$;

--Script de prueba del trigger

-- 1. Obtener segmento
SELECT ticket_segment_id 
FROM ticket_segment 
LIMIT 1;

-- 2. Insertar equipaje
INSERT INTO baggage (
    baggage_id,
    ticket_segment_id,
    baggage_tag,
    baggage_type,
    status,
    created_at
)
VALUES (
    gen_random_uuid(),
    'SEGMENT_ID_AQUI',
    'BG123456',
    'CHECKED',
    'RECEIVED',
    now()
);

-- 3. Validar efecto del trigger
SELECT *
FROM ticket_segment
WHERE ticket_segment_id = 'SEGMENT_ID_AQUI';

--Script usando el procedimiento
CALL sp_register_baggage(
    'SEGMENT_ID_AQUI',
    'BG999999',
    'CHECKED',
    'RECEIVED'
);

--Validaciones finales

-- Ver equipaje registrado
SELECT *
FROM baggage
ORDER BY created_at DESC;

-- Ver impacto en ticket_segment
SELECT ticket_segment_id, updated_at
FROM ticket_segment
ORDER BY updated_at DESC;