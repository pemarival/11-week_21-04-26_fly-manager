--CONSULTA (INNER JOIN ≥ 5 tablas)

SELECT
    s.sale_code,
    r.reservation_code,
    p.payment_reference,
    ps.status_name AS payment_status,
    pm.method_name AS payment_method,
    pt.transaction_reference,
    pt.transaction_type,
    pt.transaction_amount,
    c.iso_currency_code AS currency
FROM sale s
INNER JOIN reservation r 
    ON s.reservation_id = r.reservation_id
INNER JOIN payment p 
    ON s.sale_id = p.sale_id
INNER JOIN payment_status ps 
    ON p.payment_status_id = ps.payment_status_id
INNER JOIN payment_method pm 
    ON p.payment_method_id = pm.payment_method_id
INNER JOIN payment_transaction pt 
    ON p.payment_id = pt.payment_id
INNER JOIN currency c 
    ON p.currency_id = c.currency_id;

--TRIGGER AFTER (automatizar refund)
CREATE OR REPLACE FUNCTION fn_generate_refund()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.transaction_type IN ('REFUND', 'REVERSAL') THEN

        INSERT INTO refund (
            refund_id,
            payment_id,
            refund_reference,
            amount,
            requested_at,
            processed_at,
            refund_reason,
            created_at,
            updated_at
        )
        VALUES (
            gen_random_uuid(),
            NEW.payment_id,
            'RF-' || substr(NEW.transaction_reference, 1, 10),
            NEW.transaction_amount,
            now(),
            now(),
            'Auto-generated from transaction ' || NEW.transaction_type,
            now(),
            now()
        );

    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_generate_refund
AFTER INSERT ON payment_transaction
FOR EACH ROW
EXECUTE FUNCTION fn_generate_refund();

--PROCEDIMIENTO ALMACENADO 
CREATE OR REPLACE PROCEDURE sp_register_payment_transaction(
    p_payment_id uuid,
    p_transaction_type varchar,
    p_transaction_amount numeric,
    p_provider_message text
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO payment_transaction (
        payment_transaction_id,
        payment_id,
        transaction_reference,
        transaction_type,
        transaction_amount,
        processed_at,
        provider_message,
        created_at,
        updated_at
    )
    VALUES (
        gen_random_uuid(),
        p_payment_id,
        'TX-' || substr(gen_random_uuid()::text, 1, 10),
        p_transaction_type,
        p_transaction_amount,
        now(),
        p_provider_message,
        now(),
        now()
    );
END;
$$;

--SCRIPT PARA DISPARAR EL TRIGGER
SELECT payment_id FROM payment LIMIT 1;

INSERT INTO payment_transaction (
    payment_transaction_id,
    payment_id,
    transaction_reference,
    transaction_type,
    transaction_amount,
    processed_at
)
VALUES (
    gen_random_uuid(),
    (SELECT payment_id FROM payment LIMIT 1),
    'TX-TEST-001',
    'REFUND',
    100.00,
    now()
);

SELECT * 
FROM refund
ORDER BY created_at DESC
LIMIT 5;

--SCRIPT USANDO EL PROCEDIMIENTO

CALL sp_register_payment_transaction(
    (SELECT payment_id FROM payment LIMIT 1),
    'REFUND',
    150.00,
    'Customer requested refund'
);