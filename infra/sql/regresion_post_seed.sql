\set ON_ERROR_STOP on
\echo 'regresion_post_seed.sql - validaciones de regresion canonico + volumetrico'
SET client_min_messages TO warning;

DROP TABLE IF EXISTS tmp_regression_checks;
CREATE TEMP TABLE tmp_regression_checks (
  check_name   text PRIMARY KEY,
  actual_value bigint NOT NULL,
  expected_min bigint,
  expected_max bigint,
  check_note   text NOT NULL
);

-- ============================================================
-- UMBRALES BASE (canonico + volumetrico)
-- ============================================================
INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'country_min', count(*), 3, NULL, 'Catalogo base de paises'
FROM public.country;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'airline_min', count(*), 1, NULL, 'Aerolineas base'
FROM public.airline;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'airport_min', count(*), 3, NULL, 'Aeropuertos base'
FROM public.airport;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'reservation_vol', count(*), 1000, NULL, 'Reservas volumetricas'
FROM public.reservation;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'ticket_vol', count(*), 1000, NULL, 'Tickets volumetricos'
FROM public.ticket;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'payment_vol', count(*), 1000, NULL, 'Pagos volumetricos'
FROM public.payment;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'invoice_vol', count(*), 1000, NULL, 'Facturas volumetricas'
FROM public.invoice;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'refund_vol', count(*), 100, NULL, 'Refunds volumetricos'
FROM public.refund;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'boarding_pass_vol', count(*), 1000, NULL, 'Boarding passes volumetricos'
FROM public.boarding_pass;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'boarding_validation_vol', count(*), 1000, NULL, 'Validaciones de abordaje en volumen'
FROM public.boarding_validation;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'payment_tx_vol', count(*), 1300, NULL, 'Transacciones de pago en volumen'
FROM public.payment_transaction;

-- ============================================================
-- CHECKS DE ORFANDAD (deben dar 0)
-- ============================================================
INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'orphan_tickets', count(*), NULL, 0, 'Tickets sin sale valida'
FROM public.ticket t
LEFT JOIN public.sale s ON s.sale_id = t.sale_id
WHERE s.sale_id IS NULL;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'orphan_ticket_segments', count(*), NULL, 0, 'Ticket segments sin ticket valido'
FROM public.ticket_segment ts
LEFT JOIN public.ticket t ON t.ticket_id = ts.ticket_id
WHERE t.ticket_id IS NULL;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'orphan_seat_assignments', count(*), NULL, 0, 'Seat assignments sin ticket segment valido'
FROM public.seat_assignment sa
LEFT JOIN public.ticket_segment ts ON ts.ticket_segment_id = sa.ticket_segment_id
WHERE ts.ticket_segment_id IS NULL;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'orphan_invoices', count(*), NULL, 0, 'Invoices sin sale valida'
FROM public.invoice i
LEFT JOIN public.sale s ON s.sale_id = i.sale_id
WHERE s.sale_id IS NULL;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'orphan_invoice_lines', count(*), NULL, 0, 'Invoice lines sin invoice valida'
FROM public.invoice_line il
LEFT JOIN public.invoice i ON i.invoice_id = il.invoice_id
WHERE i.invoice_id IS NULL;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'orphan_miles', count(*), NULL, 0, 'Miles transactions sin loyalty account'
FROM public.miles_transaction mt
LEFT JOIN public.loyalty_account la ON la.loyalty_account_id = mt.loyalty_account_id
WHERE la.loyalty_account_id IS NULL;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'orphan_refunds', count(*), NULL, 0, 'Refunds sin payment valido'
FROM public.refund r
LEFT JOIN public.payment p ON p.payment_id = r.payment_id
WHERE p.payment_id IS NULL;

-- ============================================================
-- CHECKS CRONOLOGICOS (deben dar 0)
-- ============================================================
INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'anomaly_ticket_before_reservation', count(*), NULL, 0, 'Ticket emitido antes de reserva'
FROM public.ticket t
JOIN public.sale s ON s.sale_id = t.sale_id
JOIN public.reservation r ON r.reservation_id = s.reservation_id
WHERE t.issued_at < r.booked_at;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'anomaly_payment_before_sale', count(*), NULL, 0, 'Pago autorizado antes de venta'
FROM public.payment p
JOIN public.sale s ON s.sale_id = p.sale_id
WHERE p.authorized_at < s.sold_at;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'anomaly_invoice_before_sale', count(*), NULL, 0, 'Factura emitida antes de venta'
FROM public.invoice i
JOIN public.sale s ON s.sale_id = i.sale_id
WHERE i.issued_at < s.sold_at;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'anomaly_checkin_after_departure', count(*), NULL, 0, 'Check-in despues de salida real'
FROM public.check_in ci
JOIN public.ticket_segment ts ON ts.ticket_segment_id = ci.ticket_segment_id
JOIN public.flight_segment fs ON fs.flight_segment_id = ts.flight_segment_id
WHERE fs.actual_departure_at IS NOT NULL
  AND ci.checked_in_at > fs.actual_departure_at;

INSERT INTO tmp_regression_checks (check_name, actual_value, expected_min, expected_max, check_note)
SELECT 'anomaly_boarding_after_departure', count(*), NULL, 0, 'Boarding validation despues de salida programada'
FROM public.boarding_validation bv
JOIN public.boarding_pass bp ON bp.boarding_pass_id = bv.boarding_pass_id
JOIN public.check_in ci ON ci.check_in_id = bp.check_in_id
JOIN public.ticket_segment ts ON ts.ticket_segment_id = ci.ticket_segment_id
JOIN public.flight_segment fs ON fs.flight_segment_id = ts.flight_segment_id
WHERE bp.boarding_pass_code LIKE 'BP-VOL2-%'
  AND bv.validated_at >= fs.scheduled_departure_at;

\echo '== Resultado checks de regresion =='
SELECT
  check_name,
  actual_value,
  expected_min,
  expected_max,
  CASE
    WHEN (expected_min IS NULL OR actual_value >= expected_min)
     AND (expected_max IS NULL OR actual_value <= expected_max)
    THEN 'OK'
    ELSE 'FALLA'
  END AS status,
  check_note
FROM tmp_regression_checks
ORDER BY status DESC, check_name;

\echo '== Resumen regresion =='
SELECT
  COUNT(*) FILTER (
    WHERE (expected_min IS NULL OR actual_value >= expected_min)
      AND (expected_max IS NULL OR actual_value <= expected_max)
  ) AS checks_ok,
  COUNT(*) FILTER (
    WHERE NOT (
      (expected_min IS NULL OR actual_value >= expected_min)
      AND (expected_max IS NULL OR actual_value <= expected_max)
    )
  ) AS checks_falla,
  COUNT(*) AS total_checks
FROM tmp_regression_checks;

DO $$
DECLARE
  v_failed bigint;
BEGIN
  SELECT count(*)
  INTO v_failed
  FROM tmp_regression_checks
  WHERE NOT (
    (expected_min IS NULL OR actual_value >= expected_min)
    AND (expected_max IS NULL OR actual_value <= expected_max)
  );

  IF v_failed > 0 THEN
    RAISE EXCEPTION 'Regresion post-seed fallo: % checks en estado FALLA.', v_failed;
  END IF;
END $$;

\echo '== REGRESION POST-SEED COMPLETADA =='

