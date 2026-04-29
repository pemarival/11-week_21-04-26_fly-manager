\set ON_ERROR_STOP on
\echo '99_validaciones_post_seed.sql - gate canonico y validacion de integridad'
SET client_min_messages TO warning;

-- ============================================================
-- FASE 1: CONTEO GENERAL POR TABLA
-- ============================================================

DROP TABLE IF EXISTS tmp_row_counts;
CREATE TEMP TABLE tmp_row_counts (
  table_name text PRIMARY KEY,
  row_count  bigint NOT NULL
);

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
    ORDER BY table_name
  LOOP
    EXECUTE format(
      'INSERT INTO tmp_row_counts(table_name, row_count) SELECT %L, count(*) FROM public.%I;',
      r.table_name,
      r.table_name
    );
  END LOOP;
END $$;

\echo '== Conteo general por tabla =='
SELECT table_name, row_count
FROM tmp_row_counts
ORDER BY row_count DESC, table_name;

-- ============================================================
-- FASE 2: GATE CANONICO
-- Cada tabla operativa tiene un minimo esperado para el seed
-- canonico. Si alguna queda por debajo, el gate falla.
-- ============================================================

DROP TABLE IF EXISTS tmp_canonical_gate;
CREATE TEMP TABLE tmp_canonical_gate (
  table_name   text    PRIMARY KEY,
  min_expected bigint  NOT NULL,
  gate_note    text    NOT NULL
);

INSERT INTO tmp_canonical_gate (table_name, min_expected, gate_note) VALUES
-- Catalogos cerrados (umbral 1 = al menos existe)
  ('benefit_type',           1, 'Catalogo cerrado'),
  ('boarding_group',         1, 'Catalogo cerrado'),
  ('cabin_class',            1, 'Catalogo cerrado'),
  ('check_in_status',        1, 'Catalogo cerrado'),
  ('contact_type',           1, 'Catalogo cerrado'),
  ('customer_category',      1, 'Catalogo cerrado'),
  ('delay_reason_type',      1, 'Catalogo cerrado'),
  ('document_type',          1, 'Catalogo cerrado'),
  ('flight_status',          1, 'Catalogo cerrado'),
  ('invoice_status',         1, 'Catalogo cerrado'),
  ('maintenance_type',       1, 'Catalogo cerrado'),
  ('payment_method',         1, 'Catalogo cerrado'),
  ('payment_status',         1, 'Catalogo cerrado'),
  ('person_type',            1, 'Catalogo cerrado'),
  ('reservation_status',     1, 'Catalogo cerrado'),
  ('sale_channel',           1, 'Catalogo cerrado'),
  ('security_permission',    1, 'Catalogo cerrado'),
  ('security_role',          1, 'Catalogo cerrado'),
  ('ticket_status',          1, 'Catalogo cerrado'),
  ('user_status',            1, 'Catalogo cerrado'),
-- Maestras operativas (umbral minimo canonico)
  ('aircraft_manufacturer',  3, 'Al menos Airbus, Boeing, Embraer'),
  ('aircraft_model',         3, 'Al menos A320neo, B787-8, E190-E2'),
  ('aircraft',               2, 'Al menos HK-5500 y HK-7870'),
  ('aircraft_cabin',         4, 'Cabinas J+Y por aeronave'),
  ('aircraft_seat',         30, 'Asientos generados por generate_series'),
  ('airline',                1, 'Al menos FLY Airlines'),
  ('airport',                3, 'BOG, MDE, MIA, MAD, MEX'),
  ('boarding_gate',          3, 'Gates por terminal'),
  ('continent',              5, 'Los 7 continentes'),
  ('country',                3, 'Al menos CO, US, ES'),
  ('city',                   3, 'Bogota, Miami, Madrid'),
  ('currency',               3, 'USD, COP, EUR'),
  ('district',               3, 'Distritos de ciudades'),
  ('address',                3, 'Direcciones de aeropuertos'),
  ('exchange_rate',          4, 'Tasas COP/USD y EUR/USD'),
  ('fare',                   3, 'BOG-MAD, BOG-MDE, BOG-MIA'),
  ('fare_class',             2, 'JF Business y YB/YF Economy'),
  ('flight',                 3, 'FY210, FY101, FY305'),
  ('flight_segment',         3, 'Segmentos de vuelos canonicos'),
  ('loyalty_program',        1, 'FLY Miles Program'),
  ('loyalty_tier',           3, 'Bronze, Silver, Gold'),
  ('maintenance_provider',   1, 'Al menos AeroAndes MRO'),
  ('runway',                 3, 'Pistas por aeropuerto'),
  ('state_province',         3, 'Al menos ANT, BOG, FL'),
  ('tax',                    2, 'AIRPORT_FEE y SECURITY_FEE'),
  ('terminal',               3, 'Terminales por aeropuerto'),
  ('time_zone',              3, 'America/Bogota, UTC, Europe/Madrid'),
-- Actores (minimo canonico: 3 pasajeros + 2 empleados)
  ('person',                 5, 'Ana, Carlos, Laura + 2 empleados'),
  ('person_document',        5, 'Un documento por persona'),
  ('person_contact',         5, 'Un contacto por persona'),
  ('user_account',           2, 'diego.ramirez y patricia.vargas'),
  ('user_role',              2, 'SYS_ADMIN y SALES_AGENT'),
  ('role_permission',        5, 'Matriz de permisos por rol'),
-- Clientes y lealtad
  ('customer',               3, 'Ana, Carlos, Laura'),
  ('customer_benefit',       2, 'Beneficios Gold y Silver'),
  ('loyalty_account',        3, 'Una cuenta por cliente'),
  ('loyalty_account_tier',   3, 'Tier activo por cuenta'),
-- Flujo comercial
  ('reservation',            3, 'RES-FY-001, 002, 003'),
  ('reservation_passenger',  3, 'Un pasajero por reserva'),
  ('sale',                   3, 'SAL-20260305, 0310, 0312'),
  ('ticket',                 3, 'TKT-FY-00001, 00002, 00003'),
  ('ticket_segment',         4, 'Ana tiene 2 segmentos'),
  ('seat_assignment',        4, 'Uno por ticket_segment'),
  ('baggage',                2, 'Carlos y Laura con equipaje'),
-- Boarding
  ('check_in',               4, 'Uno por ticket_segment'),
  ('boarding_pass',          4, 'Uno por check_in'),
  ('boarding_validation',    4, 'Uno por boarding_pass'),
-- Pagos y facturacion
  ('payment',                3, 'Un pago por sale'),
  ('payment_transaction',    5, 'AUTH + CAPTURE por pago'),
  ('invoice',                3, 'Una factura por sale'),
  ('invoice_line',           9, 'Tres lineas por factura'),
-- Millas
  ('miles_transaction',      4, 'EARN al arribo de cada segmento');

\echo '== Gate canonico: tablas bajo el minimo esperado =='
SELECT
  cg.table_name,
  cg.min_expected,
  rc.row_count,
  cg.gate_note,
  CASE WHEN rc.row_count >= cg.min_expected THEN 'OK' ELSE 'FALLA' END AS gate_status
FROM tmp_canonical_gate cg
JOIN tmp_row_counts rc ON rc.table_name = cg.table_name
ORDER BY gate_status DESC, cg.table_name;

\echo '== Resumen gate canonico =='
SELECT
  COUNT(*) FILTER (WHERE rc.row_count >= cg.min_expected) AS tablas_ok,
  COUNT(*) FILTER (WHERE rc.row_count < cg.min_expected)  AS tablas_falla,
  COUNT(*)                                                  AS total_validadas
FROM tmp_canonical_gate cg
JOIN tmp_row_counts rc ON rc.table_name = cg.table_name;

DO $$
DECLARE
  v_gate_fallas bigint;
BEGIN
  SELECT count(*)
  INTO v_gate_fallas
  FROM tmp_canonical_gate cg
  JOIN tmp_row_counts rc ON rc.table_name = cg.table_name
  WHERE rc.row_count < cg.min_expected;

  IF v_gate_fallas > 0 THEN
    RAISE EXCEPTION 'Gate canonico fallo: % tablas por debajo del minimo esperado.', v_gate_fallas;
  END IF;
END $$;

-- ============================================================
-- FASE 3: TABLAS SIN DATOS (alerta de vaciado inesperado)
-- ============================================================

\echo '== Tablas sin datos =='
SELECT table_name, row_count
FROM tmp_row_counts
WHERE row_count = 0
ORDER BY table_name;

-- ============================================================
-- FASE 4: COBERTURA DEL FLUJO CRITICO END-TO-END
-- Verifica que el flujo canonico este completo con conteos
-- especificos esperados tras la carga canonica.
-- ============================================================

\echo '== Flujo critico end-to-end =='
SELECT
  entity_name,
  total_rows,
  expected_min,
  CASE WHEN total_rows >= expected_min THEN 'OK' ELSE 'FALLA' END AS status
FROM (
  SELECT 'person'               AS entity_name, count(*)::bigint AS total_rows, 5::bigint  AS expected_min FROM public.person
  UNION ALL
  SELECT 'user_account',        count(*), 2  FROM public.user_account
  UNION ALL
  SELECT 'customer',            count(*), 3  FROM public.customer
  UNION ALL
  SELECT 'loyalty_account',     count(*), 3  FROM public.loyalty_account
  UNION ALL
  SELECT 'loyalty_account_tier',count(*), 3  FROM public.loyalty_account_tier
  UNION ALL
  SELECT 'reservation',         count(*), 3  FROM public.reservation
  UNION ALL
  SELECT 'reservation_passenger',count(*),3  FROM public.reservation_passenger
  UNION ALL
  SELECT 'sale',                count(*), 3  FROM public.sale
  UNION ALL
  SELECT 'ticket',              count(*), 3  FROM public.ticket
  UNION ALL
  SELECT 'ticket_segment',      count(*), 4  FROM public.ticket_segment
  UNION ALL
  SELECT 'seat_assignment',     count(*), 4  FROM public.seat_assignment
  UNION ALL
  SELECT 'baggage',             count(*), 2  FROM public.baggage
  UNION ALL
  SELECT 'check_in',            count(*), 4  FROM public.check_in
  UNION ALL
  SELECT 'boarding_pass',       count(*), 4  FROM public.boarding_pass
  UNION ALL
  SELECT 'boarding_validation', count(*), 4  FROM public.boarding_validation
  UNION ALL
  SELECT 'payment',             count(*), 3  FROM public.payment
  UNION ALL
  SELECT 'payment_transaction', count(*), 5  FROM public.payment_transaction
  UNION ALL
  SELECT 'invoice',             count(*), 3  FROM public.invoice
  UNION ALL
  SELECT 'invoice_line',        count(*), 9  FROM public.invoice_line
  UNION ALL
  SELECT 'miles_transaction',   count(*), 4  FROM public.miles_transaction
) critical_flow
ORDER BY status DESC, entity_name;

-- ============================================================
-- FASE 5: INTEGRIDAD REFERENCIAL SPOT CHECKS
-- Detecta huerfanos en relaciones criticas del flujo.
-- ============================================================

\echo '== Spot check: tickets sin sale valida =='
SELECT count(*) AS orphan_tickets
FROM public.ticket t
LEFT JOIN public.sale s ON s.sale_id = t.sale_id
WHERE s.sale_id IS NULL;

\echo '== Spot check: ticket_segments sin ticket valido =='
SELECT count(*) AS orphan_ticket_segments
FROM public.ticket_segment ts
LEFT JOIN public.ticket t ON t.ticket_id = ts.ticket_id
WHERE t.ticket_id IS NULL;

\echo '== Spot check: seat_assignments sin ticket_segment valido =='
SELECT count(*) AS orphan_seat_assignments
FROM public.seat_assignment sa
LEFT JOIN public.ticket_segment ts ON ts.ticket_segment_id = sa.ticket_segment_id
WHERE ts.ticket_segment_id IS NULL;

\echo '== Spot check: check_ins sin ticket_segment valido =='
SELECT count(*) AS orphan_checkins
FROM public.check_in ci
LEFT JOIN public.ticket_segment ts ON ts.ticket_segment_id = ci.ticket_segment_id
WHERE ts.ticket_segment_id IS NULL;

\echo '== Spot check: boarding_passes sin check_in valido =='
SELECT count(*) AS orphan_boarding_passes
FROM public.boarding_pass bp
LEFT JOIN public.check_in ci ON ci.check_in_id = bp.check_in_id
WHERE ci.check_in_id IS NULL;

\echo '== Spot check: invoices sin sale valida =='
SELECT count(*) AS orphan_invoices
FROM public.invoice inv
LEFT JOIN public.sale s ON s.sale_id = inv.sale_id
WHERE s.sale_id IS NULL;

\echo '== Spot check: invoice_lines sin invoice valida =='
SELECT count(*) AS orphan_invoice_lines
FROM public.invoice_line il
LEFT JOIN public.invoice inv ON inv.invoice_id = il.invoice_id
WHERE inv.invoice_id IS NULL;

\echo '== Spot check: miles_transactions sin loyalty_account valido =='
SELECT count(*) AS orphan_miles
FROM public.miles_transaction mt
LEFT JOIN public.loyalty_account la ON la.loyalty_account_id = mt.loyalty_account_id
WHERE la.loyalty_account_id IS NULL;

-- ============================================================
-- FASE 6: CONSISTENCIA CRONOLOGICA
-- Verifica precedencia de eventos segun la politica IE-005.
-- ============================================================

\echo '== Cronologia: tickets emitidos antes de la reserva (anomalia) =='
SELECT count(*) AS anomaly_count
FROM public.ticket t
JOIN public.sale s         ON s.sale_id         = t.sale_id
JOIN public.reservation r  ON r.reservation_id  = s.reservation_id
WHERE t.issued_at < r.booked_at;

\echo '== Cronologia: pagos autorizados antes de la venta (anomalia) =='
SELECT count(*) AS anomaly_count
FROM public.payment p
JOIN public.sale s ON s.sale_id = p.sale_id
WHERE p.authorized_at < s.sold_at;

\echo '== Cronologia: facturas emitidas antes de la venta (anomalia) =='
SELECT count(*) AS anomaly_count
FROM public.invoice inv
JOIN public.sale s ON s.sale_id = inv.sale_id
WHERE inv.issued_at < s.sold_at;

\echo '== Cronologia: check-in despues de salida real (anomalia) =='
SELECT count(*) AS anomaly_count
FROM public.check_in ci
JOIN public.ticket_segment ts   ON ts.ticket_segment_id = ci.ticket_segment_id
JOIN public.flight_segment fs   ON fs.flight_segment_id = ts.flight_segment_id
WHERE fs.actual_departure_at IS NOT NULL
  AND ci.checked_in_at > fs.actual_departure_at;

-- ============================================================
-- FASE 7: GATE VOLUMETRICO
-- Umbrales aplicables solo a entidades maestras/transaccionales
-- donde escalar es semanticamente valido.
-- ============================================================

DROP TABLE IF EXISTS tmp_volumetric_gate;
CREATE TEMP TABLE tmp_volumetric_gate (
  table_name   text   PRIMARY KEY,
  min_expected bigint NOT NULL,
  gate_note    text   NOT NULL
);

INSERT INTO tmp_volumetric_gate (table_name, min_expected, gate_note) VALUES
  ('person',                300,  'Personas del seed volumetrico inicial + canonico'),
  ('customer',              250,  'Clientes volumetricos iniciales + canonico'),
  ('loyalty_account',       250,  'Una cuenta de lealtad por cliente volumetrico'),
  ('miles_transaction',    1000,  'Escala de millas historicas y operacionales'),
  ('flight',                100,  'Vuelos Q2 2026 mas canonico'),
  ('flight_segment',        100,  'Segmentos de vuelos Q2 2026'),
  ('reservation',          1000,  'Reservas volumetricas extendidas'),
  ('reservation_passenger',1000,  'Un pasajero por reserva volumetrica'),
  ('sale',                 1000,  'Ventas asociadas a reservas volumetricas'),
  ('ticket',               1000,  'Tickets emitidos en volumen'),
  ('ticket_segment',       1000,  'Segmentos de ticket en volumen'),
  ('seat_assignment',      1000,  'Asignaciones de asiento en volumen'),
  ('baggage',              1000,  'Equipaje registrado en volumen'),
  ('check_in',             1000,  'Check-ins operacionales en volumen'),
  ('boarding_pass',        1000,  'Boarding passes en volumen'),
  ('boarding_validation',  1000,  'Validaciones de abordaje en volumen'),
  ('payment',              1000,  'Pagos asociados a ventas volumetricas'),
  ('payment_transaction',  1300,  'AUTH/CAPTURE/REFUND en volumen'),
  ('invoice',              1000,  'Facturas en volumen'),
  ('invoice_line',         3000,  'Tres lineas por factura en volumen'),
  ('refund',                100,  'Escenarios controlados de reembolso');

\echo '== Gate volumetrico: tablas bajo el minimo esperado =='
SELECT
  vg.table_name,
  vg.min_expected,
  rc.row_count,
  vg.gate_note,
  CASE WHEN rc.row_count >= vg.min_expected THEN 'OK' ELSE 'FALLA' END AS gate_status
FROM tmp_volumetric_gate vg
JOIN tmp_row_counts rc ON rc.table_name = vg.table_name
ORDER BY gate_status DESC, vg.table_name;

\echo '== Resumen gate volumetrico =='
SELECT
  COUNT(*) FILTER (WHERE rc.row_count >= vg.min_expected) AS tablas_ok,
  COUNT(*) FILTER (WHERE rc.row_count < vg.min_expected)  AS tablas_falla,
  COUNT(*)                                                  AS total_validadas
FROM tmp_volumetric_gate vg
JOIN tmp_row_counts rc ON rc.table_name = vg.table_name;

\echo '== Spot check: refunds sin payment valido =='
SELECT count(*) AS orphan_refunds
FROM public.refund r
LEFT JOIN public.payment p ON p.payment_id = r.payment_id
WHERE p.payment_id IS NULL;

\echo '== Spot check: transacciones REFUND sin refund asociado =='
SELECT count(*) AS orphan_refund_transactions
FROM public.payment_transaction pt
LEFT JOIN public.refund r
  ON r.payment_id = pt.payment_id
 AND r.refund_reference = ('RFD-VOL2-' || right(pt.transaction_reference, 6))
WHERE pt.transaction_type = 'REFUND'
  AND pt.transaction_reference LIKE 'TXN-VOL2-RFD-%'
  AND r.refund_id IS NULL;

\echo '== Cronologia volumetrica: check-in despues de salida programada (anomalia) =='
SELECT count(*) AS anomaly_count
FROM public.check_in ci
JOIN public.ticket_segment ts ON ts.ticket_segment_id = ci.ticket_segment_id
JOIN public.flight_segment fs ON fs.flight_segment_id = ts.flight_segment_id
WHERE ts.ticket_segment_id::text LIKE 'bb000000%'
  AND ci.checked_in_at >= fs.scheduled_departure_at;

\echo '== Cronologia volumetrica: validacion de boarding despues de salida (anomalia) =='
SELECT count(*) AS anomaly_count
FROM public.boarding_validation bv
JOIN public.boarding_pass bp ON bp.boarding_pass_id = bv.boarding_pass_id
JOIN public.check_in ci ON ci.check_in_id = bp.check_in_id
JOIN public.ticket_segment ts ON ts.ticket_segment_id = ci.ticket_segment_id
JOIN public.flight_segment fs ON fs.flight_segment_id = ts.flight_segment_id
WHERE bp.boarding_pass_code LIKE 'BP-VOL2-%'
  AND bv.validated_at >= fs.scheduled_departure_at;

DO $$
DECLARE
  v_gate_fallas bigint;
BEGIN
  SELECT count(*)
  INTO v_gate_fallas
  FROM tmp_volumetric_gate vg
  JOIN tmp_row_counts rc ON rc.table_name = vg.table_name
  WHERE rc.row_count < vg.min_expected;

  IF v_gate_fallas > 0 THEN
    RAISE EXCEPTION 'Gate volumetrico fallo: % tablas por debajo del minimo esperado.', v_gate_fallas;
  END IF;
END $$;

\echo '== GATE CANONICO Y VOLUMETRICO COMPLETADO =='
