--REQUERIMIENTO 1 — CONSULTA (INNER JOIN ≥ 5 tablas)
SELECT
    c.customer_id,
    p.first_name || ' ' || p.last_name AS passenger_name,
    la.loyalty_account_id,
    lp.program_name,
    lt.tier_name,
    lat.assigned_at,
    s.sale_id,
    s.sale_date
FROM customer c
INNER JOIN person p 
    ON p.person_id = c.person_id
INNER JOIN loyalty_account la 
    ON la.customer_id = c.customer_id
INNER JOIN loyalty_program lp 
    ON lp.loyalty_program_id = la.loyalty_program_id
INNER JOIN loyalty_account_tier lat 
    ON lat.loyalty_account_id = la.loyalty_account_id
INNER JOIN loyalty_tier lt 
    ON lt.loyalty_tier_id = lat.loyalty_tier_id
INNER JOIN sale s 
    ON s.customer_id = c.customer_id;

--REQUERIMIENTO 2 — TRIGGER AFTER

CREATE OR REPLACE FUNCTION fn_after_miles_transaction_update_tier()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_miles NUMERIC;
    v_new_tier_id UUID;
BEGIN
    -- Calcular total acumulado
    SELECT COALESCE(SUM(mt.miles_amount), 0)
    INTO v_total_miles
    FROM miles_transaction mt
    WHERE mt.loyalty_account_id = NEW.loyalty_account_id;

    -- Determinar nivel (ejemplo simple)
    IF v_total_miles >= 5000 THEN
        SELECT loyalty_tier_id INTO v_new_tier_id
        FROM loyalty_tier
        WHERE tier_name = 'GOLD'
        LIMIT 1;
    ELSIF v_total_miles >= 1000 THEN
        SELECT loyalty_tier_id INTO v_new_tier_id
        FROM loyalty_tier
        WHERE tier_name = 'SILVER'
        LIMIT 1;
    ELSE
        SELECT loyalty_tier_id INTO v_new_tier_id
        FROM loyalty_tier
        WHERE tier_name = 'BASIC'
        LIMIT 1;
    END IF;

    -- Insertar historial de nivel
    INSERT INTO loyalty_account_tier (
        loyalty_account_tier_id,
        loyalty_account_id,
        loyalty_tier_id,
        assigned_at
    )
    VALUES (
        gen_random_uuid(),
        NEW.loyalty_account_id,
        v_new_tier_id,
        now()
    );

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_after_miles_transaction
AFTER INSERT ON miles_transaction
FOR EACH ROW
EXECUTE FUNCTION fn_after_miles_transaction_update_tier();

--REQUERIMIENTO 3 — PROCEDIMIENTO ALMACENADO
CREATE OR REPLACE PROCEDURE sp_register_miles_transaction(
    p_loyalty_account_id UUID,
    p_transaction_type TEXT,
    p_miles NUMERIC,
    p_reference TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO miles_transaction (
        miles_transaction_id,
        loyalty_account_id,
        transaction_type,
        miles_amount,
        transaction_date,
        reference_note
    )
    VALUES (
        gen_random_uuid(),
        p_loyalty_account_id,
        p_transaction_type,
        p_miles,
        now(),
        p_reference
    );
END;
$$;

--SCRIPT PARA DISPARAR EL TRIGGER

-- Obtener cuenta válida
SELECT loyalty_account_id FROM loyalty_account LIMIT 1;

-- Insertar millas
INSERT INTO miles_transaction (
    miles_transaction_id,
    loyalty_account_id,
    transaction_type,
    miles_amount,
    transaction_date
)
VALUES (
    gen_random_uuid(),
    'UUID_AQUI',
    'ACCUMULATION',
    2000,
    now()
);

--SCRIPT PARA USAR EL PROCEDIMIENTO
CALL sp_register_miles_transaction(
    'UUID_AQUI',
    'ACCUMULATION',
    3000,
    'Vuelo internacional'
);

--VALIDACIONES
SELECT *
FROM miles_transaction
WHERE loyalty_account_id = 'UUID_AQUI';

SELECT *
FROM loyalty_account_tier
WHERE loyalty_account_id = 'UUID_AQUI'
ORDER BY assigned_at DESC;