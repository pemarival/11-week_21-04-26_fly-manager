--CONSULTA (INNER JOIN ≥ 5 tablas)

SELECT
    s.sale_code,
    i.invoice_number,
    ist.status_name AS invoice_status,
    il.line_number,
    il.line_description,
    il.quantity,
    il.unit_price,
    t.tax_name,
    c.iso_currency_code AS currency
FROM sale s
INNER JOIN invoice i 
    ON s.sale_id = i.sale_id
INNER JOIN invoice_status ist 
    ON i.invoice_status_id = ist.invoice_status_id
INNER JOIN invoice_line il 
    ON i.invoice_id = il.invoice_id
INNER JOIN tax t 
    ON il.tax_id = t.tax_id
INNER JOIN currency c 
    ON i.currency_id = c.currency_i
    
--TRIGGER AFTER (consistencia factura)

CREATE OR REPLACE FUNCTION fn_update_invoice_timestamp()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE invoice
    SET updated_at = now()
    WHERE invoice_id = NEW.invoice_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_invoice_after_line
AFTER INSERT ON invoice_line
FOR EACH ROW
EXECUTE FUNCTION fn_update_invoice_timestamp();

--PROCEDIMIENTO ALMACENADO
CREATE OR REPLACE PROCEDURE sp_add_invoice_line(
    p_invoice_id uuid,
    p_tax_id uuid,
    p_line_number integer,
    p_description varchar,
    p_quantity numeric,
    p_unit_price numeric
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO invoice_line (
        invoice_line_id,
        invoice_id,
        tax_id,
        line_number,
        line_description,
        quantity,
        unit_price,
        created_at,
        updated_at
    )
    VALUES (
        gen_random_uuid(),
        p_invoice_id,
        p_tax_id,
        p_line_number,
        p_description,
        p_quantity,
        p_unit_price,
        now(),
        now()
    );
END;
$$;

--SCRIPT PARA DISPARAR EL TRIGGER

SELECT invoice_id FROM invoice LIMIT 1;
SELECT tax_id FROM tax LIMIT 1;

INSERT INTO invoice_line (
    invoice_line_id,
    invoice_id,
    tax_id,
    line_number,
    line_description,
    quantity,
    unit_price
)
VALUES (
    gen_random_uuid(),
    (SELECT invoice_id FROM invoice LIMIT 1),
    (SELECT tax_id FROM tax LIMIT 1),
    1,
    'Test service charge',
    2,
    50.00
);

SELECT *
FROM invoice
ORDER BY updated_at DESC
LIMIT 5;

--SCRIPT USANDO EL PROCEDIMIENTO

CALL sp_add_invoice_line(
    (SELECT invoice_id FROM invoice LIMIT 1),
    (SELECT tax_id FROM tax LIMIT 1),
    2,
    'Extra baggage fee',
    1,
    80.00
);

-- Ver líneas
SELECT *
FROM invoice_line
ORDER BY created_at DESC
LIMIT 5;

-- Ver impacto en factura
SELECT *
FROM invoice
ORDER BY updated_at DESC
LIMIT 5;