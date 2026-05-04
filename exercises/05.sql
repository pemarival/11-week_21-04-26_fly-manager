--REQUERIMIENTO 1 — CONSULTA (INNER JOIN ≥ 5)
SELECT
    a.aircraft_id,
    a.registration_code,
    al.airline_name,
    am.model_name,
    mf.manufacturer_name,
    mt.maintenance_type_name,
    mp.provider_name,
    me.event_status,
    me.start_date,
    me.end_date
FROM aircraft a
INNER JOIN airline al 
    ON al.airline_id = a.airline_id
INNER JOIN aircraft_model am 
    ON am.aircraft_model_id = a.aircraft_model_id
INNER JOIN aircraft_manufacturer mf 
    ON mf.aircraft_manufacturer_id = am.aircraft_manufacturer_id
INNER JOIN maintenance_event me 
    ON me.aircraft_id = a.aircraft_id
INNER JOIN maintenance_type mt 
    ON mt.maintenance_type_id = me.maintenance_type_id
INNER JOIN maintenance_provider mp 
    ON mp.maintenance_provider_id = me.maintenance_provider_id;

--REQUERIMIENTO 2 — TRIGGER AFTER

CREATE OR REPLACE FUNCTION fn_after_maintenance_event()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Solo actuar cuando el mantenimiento se complete
    IF NEW.event_status = 'COMPLETED' THEN
        
        INSERT INTO maintenance_event (
            maintenance_event_id,
            aircraft_id,
            maintenance_type_id,
            maintenance_provider_id,
            event_status,
            start_date,
            end_date,
            notes
        )
        VALUES (
            gen_random_uuid(),
            NEW.aircraft_id,
            NEW.maintenance_type_id,
            NEW.maintenance_provider_id,
            'CLOSED_LOG',
            now(),
            now(),
            'Evento automático posterior a finalización'
        );

    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_after_maintenance_event
AFTER UPDATE ON maintenance_event
FOR EACH ROW
EXECUTE FUNCTION fn_after_maintenance_event();

--REQUERIMIENTO 3 — PROCEDIMIENTO

CREATE OR REPLACE PROCEDURE sp_register_maintenance_event(
    p_aircraft_id UUID,
    p_maintenance_type_id UUID,
    p_provider_id UUID,
    p_status TEXT,
    p_start_date TIMESTAMP,
    p_notes TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO maintenance_event (
        maintenance_event_id,
        aircraft_id,
        maintenance_type_id,
        maintenance_provider_id,
        event_status,
        start_date,
        notes
    )
    VALUES (
        gen_random_uuid(),
        p_aircraft_id,
        p_maintenance_type_id,
        p_provider_id,
        p_status,
        p_start_date,
        p_notes
    );
END;
$$;


--SCRIPT PARA DISPARAR TRIGGER

-- Buscar evento existente
SELECT maintenance_event_id 
FROM maintenance_event 
LIMIT 1;

-- Simular finalización
UPDATE maintenance_event
SET event_status = 'COMPLETED',
    end_date = now()
WHERE maintenance_event_id = 'UUID_AQUI';

-- SCRIPT PARA USAR PROCEDIMIENTO

CALL sp_register_maintenance_event(
    'AIRCRAFT_UUID',
    'TYPE_UUID',
    'PROVIDER_UUID',
    'IN_PROGRESS',
    now(),
    'Mantenimiento preventivo'
);

--VALIDACIONES
SELECT *
FROM maintenance_event
WHERE aircraft_id = 'AIRCRAFT_UUID'
ORDER BY start_date DESC;

SELECT *
FROM maintenance_event
WHERE notes LIKE '%automático%'
ORDER BY start_date DESC;