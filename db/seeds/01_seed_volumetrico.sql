\set ON_ERROR_STOP on
\echo '01_seed_volumetrico.sql - expansion masiva controlada sobre seed canonico'
SET client_min_messages TO warning;

BEGIN;

-- ============================================================
-- POLITICA: Ver docs/validacion/POLITICA_CRONOLOGIA_DATOS_SINTETICOS.md
-- Vuelos futuros : 2026-04-01 a 2026-06-30  (status SCHEDULED)
-- Reservas futuras: booked_at entre 2026-01-10 y 2026-03-18
-- Personas       : 300 adultos colombianos (UUID 90000000-...)
-- Clientes       : 250 de esas personas    (UUID 93000000-...)
-- Reservas       : 20 CONFIRMED             (UUID A7000000-...)
-- ============================================================

-- ============================================================
-- PARTE 1: VUELOS FUTUROS Q2 2026
-- FY120  BOG → MDE  diario  (HK-5500)   91 vuelos
-- FY220  BOG → MIA  miercoles (HK-7870) 13 vuelos
-- FY712  MIA → MAD  miercoles (HK-7870) 13 vuelos  (cont. FY220)
-- ============================================================

INSERT INTO public.flight (
  airline_id, aircraft_id, flight_status_id, flight_number, service_date
)
SELECT
  al.airline_id,
  a.aircraft_id,
  fs.flight_status_id,
  'FY120',
  d.service_date::date
FROM generate_series(
  '2026-04-01'::date,
  '2026-06-30'::date,
  '1 day'::interval
) AS d(service_date)
JOIN public.airline al        ON al.airline_code         = 'FLY'
JOIN public.aircraft a        ON a.registration_number   = 'HK-5500'
JOIN public.flight_status fs  ON fs.status_code          = 'SCHEDULED'
ON CONFLICT (airline_id, flight_number, service_date) DO NOTHING;

-- Miercoles Q2: 01-apr, 08-apr, 15-apr, 22-apr, 29-apr,
--               06-may, 13-may, 20-may, 27-may,
--               03-jun, 10-jun, 17-jun, 24-jun
INSERT INTO public.flight (
  airline_id, aircraft_id, flight_status_id, flight_number, service_date
)
SELECT
  al.airline_id,
  a.aircraft_id,
  fs.flight_status_id,
  seed.fn,
  seed.service_date
FROM (
  SELECT
    fn,
    d.service_date::date AS service_date
  FROM generate_series(
    '2026-04-01'::date,
    '2026-06-30'::date,
    '7 day'::interval
  ) AS d(service_date)
  CROSS JOIN (VALUES ('FY220'), ('FY712')) AS t(fn)
  WHERE EXTRACT(DOW FROM d.service_date) = 3   -- miercoles
) AS seed
JOIN public.airline al        ON al.airline_code         = 'FLY'
JOIN public.aircraft a        ON a.registration_number   = 'HK-7870'
JOIN public.flight_status fs  ON fs.status_code          = 'SCHEDULED'
ON CONFLICT (airline_id, flight_number, service_date) DO NOTHING;

-- ============================================================
-- SEGMENTOS DE VUELO
-- FY120: BOG 09:00-05 → MDE 10:05-05  (65 min)
-- FY220: BOG 08:00-05 → MIA 12:15-04  (arribo local en EDT)
-- FY712: MIA 16:00-04 → MAD 05:45+01  (conexion con FY220)
-- ============================================================

INSERT INTO public.flight_segment (
  flight_id, origin_airport_id, destination_airport_id,
  segment_number,
  scheduled_departure_at,
  scheduled_arrival_at
)
SELECT
  f.flight_id,
  ao.airport_id,
  ad.airport_id,
  1,
  (f.service_date::timestamp + INTERVAL '9 hours')  AT TIME ZONE 'America/Bogota',
  (f.service_date::timestamp + INTERVAL '10 hours 5 minutes') AT TIME ZONE 'America/Bogota'
FROM public.flight f
JOIN public.airline al ON al.airline_id = f.airline_id AND al.airline_code = 'FLY'
JOIN public.airport ao ON ao.iata_code = 'BOG'
JOIN public.airport ad ON ad.iata_code = 'MDE'
WHERE f.flight_number = 'FY120'
  AND f.service_date BETWEEN '2026-04-01' AND '2026-06-30'
ON CONFLICT (flight_id, segment_number) DO NOTHING;

INSERT INTO public.flight_segment (
  flight_id, origin_airport_id, destination_airport_id,
  segment_number,
  scheduled_departure_at,
  scheduled_arrival_at
)
SELECT
  f.flight_id,
  ao.airport_id,
  ad.airport_id,
  1,
  (f.service_date::timestamp + INTERVAL '8 hours')  AT TIME ZONE 'America/Bogota',
  (f.service_date::timestamp + INTERVAL '12 hours 15 minutes') AT TIME ZONE 'America/New_York'
FROM public.flight f
JOIN public.airline al ON al.airline_id = f.airline_id AND al.airline_code = 'FLY'
JOIN public.airport ao ON ao.iata_code = 'BOG'
JOIN public.airport ad ON ad.iata_code = 'MIA'
WHERE f.flight_number = 'FY220'
  AND f.service_date BETWEEN '2026-04-01' AND '2026-06-30'
ON CONFLICT (flight_id, segment_number) DO NOTHING;

INSERT INTO public.flight_segment (
  flight_id, origin_airport_id, destination_airport_id,
  segment_number,
  scheduled_departure_at,
  scheduled_arrival_at
)
SELECT
  f.flight_id,
  ao.airport_id,
  ad.airport_id,
  1,
  -- sale MIA 16:00 EDT (UTC-4)
  (f.service_date::timestamp + INTERVAL '20 hours') AT TIME ZONE 'UTC',
  -- llega MAD 05:45 CET (UTC+1) del dia siguiente
  (f.service_date::timestamp + INTERVAL '1 day 4 hours 45 minutes') AT TIME ZONE 'UTC'
FROM public.flight f
JOIN public.airline al ON al.airline_id = f.airline_id AND al.airline_code = 'FLY'
JOIN public.airport ao ON ao.iata_code = 'MIA'
JOIN public.airport ad ON ad.iata_code = 'MAD'
WHERE f.flight_number = 'FY712'
  AND f.service_date BETWEEN '2026-04-01' AND '2026-06-30'
ON CONFLICT (flight_id, segment_number) DO NOTHING;

-- ============================================================
-- PARTE 2: PERSONAS EN MASA (300 adultos colombianos)
-- UUID pattern: 90000000-0000-0000-0000-XXXXXXXXXXXX
-- Nombres ciclicos para variedad controlada
-- ============================================================

INSERT INTO public.person (
  person_id, person_type_id, nationality_country_id,
  first_name, last_name, birth_date, gender_code
)
SELECT
  ('90000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  pt.person_type_id,
  c.country_id,
  (ARRAY[
    'Ana','Carlos','Maria','Jorge','Laura',
    'David','Sofia','Andres','Valentina','Felipe',
    'Camila','Sebastian','Isabella','Daniel','Natalia',
    'Ricardo','Alejandra','Juan','Paula','Luis'
  ])[((g.i - 1) % 20) + 1],
  (ARRAY[
    'Garcia','Mendoza','Torres','Ramirez','Lopez',
    'Hernandez','Martinez','Gonzalez','Rodriguez','Perez',
    'Sanchez','Flores','Morales','Jimenez','Castro',
    'Ortiz','Ruiz','Reyes','Cruz','Vargas'
  ])[((g.i - 1) % 20) + 1],
  -- distribucion de fechas de nacimiento 1960-1999
  DATE '1960-01-01' + ((g.i * 47) % 14600) * INTERVAL '1 day',
  CASE WHEN (g.i % 2) = 0 THEN 'M' ELSE 'F' END
FROM generate_series(1, 300) AS g(i)
JOIN public.person_type pt ON pt.type_code = 'ADULT'
JOIN public.country c      ON c.iso_alpha2  = 'CO'
ON CONFLICT (person_id) DO NOTHING;

-- ============================================================
-- DOCUMENTOS: NID por cada persona volumetrica
-- Numero unico: 'VCC' + lpad(i,7,'0')
-- ============================================================

INSERT INTO public.person_document (
  person_document_id, person_id, document_type_id,
  issuing_country_id, document_number
)
SELECT
  ('91000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('90000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  dt.document_type_id,
  c.country_id,
  'VCC' || lpad(g.i::text, 7, '0')
FROM generate_series(1, 300) AS g(i)
JOIN public.document_type dt ON dt.type_code  = 'NID'
JOIN public.country c        ON c.iso_alpha2  = 'CO'
ON CONFLICT (person_document_id) DO NOTHING;

-- ============================================================
-- CONTACTOS: un email por persona volumetrica
-- ============================================================

INSERT INTO public.person_contact (
  person_contact_id, person_id, contact_type_id,
  contact_value, is_primary
)
SELECT
  ('92000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('90000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ct.contact_type_id,
  'vol.' || lpad(g.i::text, 6, '0') || '@flymail.co',
  true
FROM generate_series(1, 300) AS g(i)
JOIN public.contact_type ct ON ct.type_code = 'EMAIL'
ON CONFLICT (person_contact_id) DO NOTHING;

-- ============================================================
-- CLIENTES: 250 de las 300 personas volumetricas
-- Categoria distribuida: REG(60%), SILV(25%), GOLD(10%), CORP(5%)
-- UUID: 93000000-0000-0000-0000-XXXXXXXXXXXX
-- ============================================================

INSERT INTO public.customer (
  customer_id, airline_id, person_id,
  customer_category_id, customer_since
)
SELECT
  ('93000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  al.airline_id,
  ('90000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  cc.customer_category_id,
  DATE '2024-01-01' + ((g.i * 3) % 450) * INTERVAL '1 day'
FROM generate_series(1, 250) AS g(i)
JOIN public.airline al ON al.airline_code = 'FLY'
JOIN public.customer_category cc ON cc.category_code = (
  CASE
    WHEN (g.i % 20) = 0 THEN 'CORP'
    WHEN (g.i % 10) IN (1,2) THEN 'GOLD'
    WHEN (g.i % 4)  IN (1,2) THEN 'SILV'
    ELSE 'REG'
  END
)
ON CONFLICT (airline_id, person_id) DO NOTHING;

-- ============================================================
-- LOYALTY ACCOUNTS: una por cliente volumetrico
-- UUID: 94000000-0000-0000-0000-XXXXXXXXXXXX
-- Numero: FLY-VOL-XXXXXXXX
-- ============================================================

INSERT INTO public.loyalty_account (
  loyalty_account_id, customer_id, loyalty_program_id,
  account_number, opened_at
)
SELECT
  ('94000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('93000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  lp.loyalty_program_id,
  'FLY-VOL-' || lpad(g.i::text, 8, '0'),
  DATE '2024-01-01' + ((g.i * 3) % 450) * INTERVAL '1 day'
FROM generate_series(1, 250) AS g(i)
JOIN public.loyalty_program lp ON lp.program_code = 'FLY_MILES'
ON CONFLICT (account_number) DO NOTHING;

-- ============================================================
-- LOYALTY ACCOUNT TIERS: tier activo por cuenta
-- Distribucion: BRONZE(60%), SILVER(30%), GOLD(10%)
-- UUID: 95000000-0000-0000-0000-XXXXXXXXXXXX
-- ============================================================

INSERT INTO public.loyalty_account_tier (
  loyalty_account_tier_id, loyalty_account_id, loyalty_tier_id,
  assigned_at, expires_at
)
SELECT
  ('95000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('94000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  lt.loyalty_tier_id,
  DATE '2024-06-01' + ((g.i * 7) % 200) * INTERVAL '1 day',
  TIMESTAMPTZ '2026-12-31 23:59:59-05'
FROM generate_series(1, 250) AS g(i)
JOIN public.loyalty_tier lt ON lt.tier_code = (
  CASE
    WHEN (g.i % 10) = 0 THEN 'GOLD'
    WHEN (g.i % 10) IN (1,2,3) THEN 'SILVER'
    ELSE 'BRONZE'
  END
)
  AND lt.loyalty_program_id = (
    SELECT lp.loyalty_program_id FROM public.loyalty_program lp
    WHERE lp.program_code = 'FLY_MILES'
  )
ON CONFLICT (loyalty_account_id, assigned_at) DO NOTHING;

-- ============================================================
-- MILLAS HISTORICAS: saldo inicial por cliente volumetrico
-- EARN simbolico para reflejar historial de viajes pasados
-- UUID: 96000000-0000-0000-0000-XXXXXXXXXXXX
-- ============================================================

INSERT INTO public.miles_transaction (
  miles_transaction_id, loyalty_account_id,
  transaction_type, miles_delta, occurred_at, reference_code, notes
)
SELECT
  ('96000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('94000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  'EARN',
  -- saldo inicial entre 500 y 75000 segun patron
  500 + ((g.i * 313) % 74500),
  TIMESTAMPTZ '2025-01-01 00:00:00-05' + ((g.i * 5) % 365) * INTERVAL '1 day',
  'HIST-SALDO-INICIAL-' || lpad(g.i::text, 6, '0'),
  'Saldo historico inicial cargado en seed volumetrico'
FROM generate_series(1, 250) AS g(i)
ON CONFLICT (miles_transaction_id) DO NOTHING;

-- ============================================================
-- PARTE 3: 20 RESERVAS FUTURAS CONFIRMADAS
-- Vuelo FY120 BOG→MDE en fechas distribuidas Q2 2026
-- booked_at: 2026-01-10 a 2026-03-08  (IE-005: antes de fecha base 2026-03-19)
-- Clientes: personas volumetricas 1..20
-- Fare: FLY-BOGMDE-YB-2026  (COP 310,000)
-- Total con tasas: COP 359,600
-- ============================================================

INSERT INTO public.reservation (
  reservation_id, booked_by_customer_id, reservation_status_id,
  sale_channel_id, reservation_code, booked_at, expires_at, notes
)
SELECT
  ('A7000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('93000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  rs.reservation_status_id,
  sc.sale_channel_id,
  'RES-VOL-' || lpad(g.i::text, 6, '0'),
  -- booked_at entre 2026-01-10 y 2026-03-08 (IE-005: antes de fecha base 2026-03-19)
  DATE '2026-01-10' + (g.i - 1) * 3 * INTERVAL '1 day',
  NULL::timestamptz,
  'Reserva volumetrica FY120 BOG-MDE pasajero ' || g.i
FROM generate_series(1, 20) AS g(i)
JOIN public.reservation_status rs ON rs.status_code  = 'CONFIRMED'
JOIN public.sale_channel sc        ON sc.channel_code = (
  CASE WHEN (g.i % 3) = 0 THEN 'MOBILE_APP'
       WHEN (g.i % 3) = 1 THEN 'WEB'
       ELSE 'CALL_CENTER'
  END
)
ON CONFLICT (reservation_code) DO NOTHING;

-- ============================================================
-- PASAJEROS DE LAS 20 RESERVAS VOLUMETRICAS
-- ============================================================

INSERT INTO public.reservation_passenger (
  reservation_passenger_id, reservation_id, person_id,
  passenger_sequence_no, passenger_type
)
SELECT
  ('A8000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('A7000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('90000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  1,
  'ADULT'
FROM generate_series(1, 20) AS g(i)
ON CONFLICT (reservation_id, person_id) DO NOTHING;

-- ============================================================
-- VENTAS DE LAS 20 RESERVAS VOLUMETRICAS
-- ============================================================

INSERT INTO public.sale (
  sale_id, reservation_id, currency_id,
  sale_code, sold_at, external_reference
)
SELECT
  ('A9000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('A7000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  cu.currency_id,
  'SAL-VOL-' || lpad(g.i::text, 6, '0'),
  -- sold 5 min despues de la reserva
  (DATE '2026-01-10' + (g.i - 1) * 3 * INTERVAL '1 day')
    + INTERVAL '5 minutes',
  'EXT-VOL-' || lpad(g.i::text, 6, '0')
FROM generate_series(1, 20) AS g(i)
JOIN public.currency cu ON cu.iso_currency_code = 'COP'
ON CONFLICT (sale_code) DO NOTHING;

-- ============================================================
-- TIQUETES (status ISSUED — vuelo futuro)
-- ============================================================

INSERT INTO public.ticket (
  ticket_id, sale_id, reservation_passenger_id,
  fare_id, ticket_status_id, ticket_number, issued_at
)
SELECT
  ('AA000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('A9000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('A8000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  f.fare_id,
  ts.ticket_status_id,
  'TKT-VOL-' || lpad(g.i::text, 6, '0'),
  (DATE '2026-01-10' + (g.i - 1) * 3 * INTERVAL '1 day')
    + INTERVAL '7 minutes'
FROM generate_series(1, 20) AS g(i)
JOIN public.fare f              ON f.fare_code    = 'FLY-BOGMDE-YB-2026'
JOIN public.ticket_status ts    ON ts.status_code = 'ISSUED'
ON CONFLICT (ticket_number) DO NOTHING;

-- ============================================================
-- SEGMENTOS DE TIQUETE: cada tiquete a FY120 en su fecha
-- ============================================================

INSERT INTO public.ticket_segment (
  ticket_segment_id, ticket_id, flight_segment_id,
  segment_sequence_no, fare_basis_code
)
SELECT
  ('AB000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('AA000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  fs.flight_segment_id,
  1,
  'YB'
FROM generate_series(1, 20) AS g(i)
-- vuelo FY120 en la fecha correspondiente
JOIN public.flight f  ON f.flight_number = 'FY120'
                     AND f.service_date   = (DATE '2026-04-06' + (g.i - 1) * 3)
JOIN public.airline al ON al.airline_id   = f.airline_id AND al.airline_code = 'FLY'
JOIN public.flight_segment fs ON fs.flight_id = f.flight_id AND fs.segment_number = 1
ON CONFLICT (ticket_segment_id) DO NOTHING;

-- ============================================================
-- PAGOS (AUTHORIZED — pendiente captura en vuelo futuro)
-- ============================================================

INSERT INTO public.payment (
  payment_id, sale_id, payment_status_id, payment_method_id,
  currency_id, payment_reference, amount, authorized_at
)
SELECT
  ('AC000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('A9000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ps.payment_status_id,
  pm.payment_method_id,
  cu.currency_id,
  'PAY-VOL-' || lpad(g.i::text, 6, '0'),
  359600.00,
  (DATE '2026-01-10' + (g.i - 1) * 3 * INTERVAL '1 day')
    + INTERVAL '6 minutes'
FROM generate_series(1, 20) AS g(i)
JOIN public.payment_status ps ON ps.status_code = 'AUTHORIZED'
JOIN public.payment_method pm ON pm.method_code = (
  CASE WHEN (g.i % 3) = 0 THEN 'DEBIT_CARD'
       WHEN (g.i % 3) = 1 THEN 'CREDIT_CARD'
       ELSE 'WALLET'
  END
)
JOIN public.currency cu ON cu.iso_currency_code = 'COP'
ON CONFLICT (payment_reference) DO NOTHING;

-- ============================================================
-- TRANSACCIONES DE PAGO (AUTH para vuelos futuros)
-- ============================================================

INSERT INTO public.payment_transaction (
  payment_transaction_id, payment_id,
  transaction_reference, transaction_type,
  transaction_amount, processed_at, provider_message
)
SELECT
  ('AD000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('AC000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  'TXN-VOL-AUTH-' || lpad(g.i::text, 6, '0'),
  'AUTH',
  359600.00,
  (DATE '2026-01-10' + (g.i - 1) * 3 * INTERVAL '1 day')
    + INTERVAL '6 minutes 5 seconds',
  'Autorizacion aprobada para vuelo futuro FY120.'
FROM generate_series(1, 20) AS g(i)
ON CONFLICT (transaction_reference) DO NOTHING;

-- ============================================================
-- FACTURAS
-- ============================================================

INSERT INTO public.invoice (
  invoice_id, sale_id, invoice_status_id, currency_id,
  invoice_number, issued_at, due_at, notes
)
SELECT
  ('AE000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ('A9000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  ist.invoice_status_id,
  cu.currency_id,
  'INV-VOL-2026-' || lpad(g.i::text, 4, '0'),
  (DATE '2026-01-10' + (g.i - 1) * 3 * INTERVAL '1 day')
    + INTERVAL '8 minutes',
  (DATE '2026-01-10' + (g.i - 1) * 3 * INTERVAL '1 day')
    + INTERVAL '8 minutes',
  'Factura reserva volumetrica FY120 BOG-MDE'
FROM generate_series(1, 20) AS g(i)
JOIN public.invoice_status ist ON ist.status_code      = 'ISSUED'
JOIN public.currency cu        ON cu.iso_currency_code = 'COP'
ON CONFLICT (invoice_number) DO NOTHING;

-- ============================================================
-- LINEAS DE FACTURA (3 lineas por factura: base + 2 tasas)
-- ============================================================

-- Linea 1: tarifa base
INSERT INTO public.invoice_line (
  invoice_line_id, invoice_id, tax_id,
  line_number, line_description, quantity, unit_price
)
SELECT
  ('AF000000-0000-0000-0000-' || lpad(((g.i - 1) * 3 + 1)::text, 12, '0'))::uuid,
  ('AE000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  NULL::uuid,
  1,
  'Tarifa base Economy YB BOG-MDE',
  1.00,
  310000.00
FROM generate_series(1, 20) AS g(i)
ON CONFLICT (invoice_id, line_number) DO NOTHING;

-- Linea 2: tasa aeroportuaria 12 %
INSERT INTO public.invoice_line (
  invoice_line_id, invoice_id, tax_id,
  line_number, line_description, quantity, unit_price
)
SELECT
  ('AF000000-0000-0000-0000-' || lpad(((g.i - 1) * 3 + 2)::text, 12, '0'))::uuid,
  ('AE000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  tx.tax_id,
  2,
  'Tasa aeroportuaria 12 %',
  1.00,
  37200.00
FROM generate_series(1, 20) AS g(i)
JOIN public.tax tx ON tx.tax_code = 'AIRPORT_FEE'
ON CONFLICT (invoice_id, line_number) DO NOTHING;

-- Linea 3: tasa de seguridad 4 %
INSERT INTO public.invoice_line (
  invoice_line_id, invoice_id, tax_id,
  line_number, line_description, quantity, unit_price
)
SELECT
  ('AF000000-0000-0000-0000-' || lpad(((g.i - 1) * 3 + 3)::text, 12, '0'))::uuid,
  ('AE000000-0000-0000-0000-' || lpad(g.i::text, 12, '0'))::uuid,
  tx.tax_id,
  3,
  'Tasa de seguridad 4 %',
  1.00,
  12400.00
FROM generate_series(1, 20) AS g(i)
JOIN public.tax tx ON tx.tax_code = 'SECURITY_FEE'
ON CONFLICT (invoice_id, line_number) DO NOTHING;

-- ============================================================
-- PARTE 4: EXPANSION VOLUMETRICA DEL FLUJO DE VIAJE (TRAMO A)
-- Objetivo: cerrar gap de volumen en entidades transaccionales
-- y de viaje sin inflar catalogos cerrados.
-- ============================================================

DROP TABLE IF EXISTS tmp_vol2_map;
CREATE TEMP TABLE tmp_vol2_map (
  seq_no                 integer PRIMARY KEY,
  customer_seq           integer NOT NULL,
  flight_segment_id      uuid    NOT NULL,
  scheduled_departure_at timestamptz NOT NULL,
  scheduled_arrival_at   timestamptz NOT NULL
) ON COMMIT DROP;

WITH flight_pool AS (
  SELECT
    fs.flight_segment_id,
    fs.scheduled_departure_at,
    fs.scheduled_arrival_at,
    row_number() OVER (
      ORDER BY f.service_date, f.flight_number, fs.segment_number, fs.flight_segment_id
    ) AS rn
  FROM public.flight_segment fs
  JOIN public.flight f ON f.flight_id = fs.flight_id
  JOIN public.airline al ON al.airline_id = f.airline_id
  WHERE al.airline_code = 'FLY'
    AND f.flight_number = 'FY120'
    AND f.service_date BETWEEN DATE '2026-04-01' AND DATE '2026-06-30'
),
flight_pool_total AS (
  SELECT count(*)::integer AS cnt FROM flight_pool
)
INSERT INTO tmp_vol2_map (
  seq_no, customer_seq, flight_segment_id,
  scheduled_departure_at, scheduled_arrival_at
)
SELECT
  g.i AS seq_no,
  ((g.i - 1) % 250) + 1 AS customer_seq,
  fp.flight_segment_id,
  fp.scheduled_departure_at,
  fp.scheduled_arrival_at
FROM generate_series(1, 1200) AS g(i)
CROSS JOIN flight_pool_total fpt
JOIN flight_pool fp
  ON fp.rn = ((g.i - 1) % fpt.cnt) + 1;

-- ============================================================
-- BLOQUE COMERCIAL VOLUMETRICO (1200 reservas adicionales)
-- ============================================================

INSERT INTO public.reservation (
  reservation_id, booked_by_customer_id, reservation_status_id,
  sale_channel_id, reservation_code, booked_at, expires_at, notes
)
SELECT
  ('B7000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('93000000-0000-0000-0000-' || lpad(m.customer_seq::text, 12, '0'))::uuid,
  rs.reservation_status_id,
  sc.sale_channel_id,
  'RES-VOL2-' || lpad(m.seq_no::text, 6, '0'),
  TIMESTAMPTZ '2026-01-02 08:00:00-05'
    + ((m.seq_no * 5) % 70) * INTERVAL '1 day'
    + ((m.seq_no * 11) % 600) * INTERVAL '1 minute',
  NULL::timestamptz,
  'Reserva volumetrica extendida FY120 BOG-MDE'
FROM tmp_vol2_map m
JOIN public.reservation_status rs ON rs.status_code = 'CONFIRMED'
JOIN public.sale_channel sc ON sc.channel_code = (
  CASE
    WHEN (m.seq_no % 4) = 0 THEN 'WEB'
    WHEN (m.seq_no % 4) = 1 THEN 'MOBILE_APP'
    WHEN (m.seq_no % 4) = 2 THEN 'CALL_CENTER'
    ELSE 'AIRPORT_COUNTER'
  END
)
ON CONFLICT (reservation_code) DO NOTHING;

INSERT INTO public.reservation_passenger (
  reservation_passenger_id, reservation_id, person_id,
  passenger_sequence_no, passenger_type
)
SELECT
  ('B8000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('B7000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('90000000-0000-0000-0000-' || lpad(m.customer_seq::text, 12, '0'))::uuid,
  1,
  'ADULT'
FROM tmp_vol2_map m
ON CONFLICT (reservation_id, person_id) DO NOTHING;

INSERT INTO public.sale (
  sale_id, reservation_id, currency_id,
  sale_code, sold_at, external_reference
)
SELECT
  ('B9000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('B7000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  cu.currency_id,
  'SAL-VOL2-' || lpad(m.seq_no::text, 6, '0'),
  (TIMESTAMPTZ '2026-01-02 08:00:00-05'
    + ((m.seq_no * 5) % 70) * INTERVAL '1 day'
    + ((m.seq_no * 11) % 600) * INTERVAL '1 minute')
    + INTERVAL '5 minutes',
  'EXT-VOL2-' || lpad(m.seq_no::text, 6, '0')
FROM tmp_vol2_map m
JOIN public.currency cu ON cu.iso_currency_code = 'COP'
ON CONFLICT (sale_code) DO NOTHING;

INSERT INTO public.ticket (
  ticket_id, sale_id, reservation_passenger_id,
  fare_id, ticket_status_id, ticket_number, issued_at
)
SELECT
  ('BA000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('B9000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('B8000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  f.fare_id,
  ts.ticket_status_id,
  'TKT-VOL2-' || lpad(m.seq_no::text, 6, '0'),
  (TIMESTAMPTZ '2026-01-02 08:00:00-05'
    + ((m.seq_no * 5) % 70) * INTERVAL '1 day'
    + ((m.seq_no * 11) % 600) * INTERVAL '1 minute')
    + INTERVAL '7 minutes'
FROM tmp_vol2_map m
JOIN public.fare f ON f.fare_code = 'FLY-BOGMDE-YB-2026'
JOIN public.ticket_status ts ON ts.status_code = 'ISSUED'
ON CONFLICT (ticket_number) DO NOTHING;

INSERT INTO public.payment (
  payment_id, sale_id, payment_status_id, payment_method_id,
  currency_id, payment_reference, amount, authorized_at
)
SELECT
  ('C1000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('B9000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ps.payment_status_id,
  pm.payment_method_id,
  cu.currency_id,
  'PAY-VOL2-' || lpad(m.seq_no::text, 6, '0'),
  359600.00,
  (TIMESTAMPTZ '2026-01-02 08:00:00-05'
    + ((m.seq_no * 5) % 70) * INTERVAL '1 day'
    + ((m.seq_no * 11) % 600) * INTERVAL '1 minute')
    + INTERVAL '6 minutes'
FROM tmp_vol2_map m
JOIN public.payment_status ps ON ps.status_code = 'AUTHORIZED'
JOIN public.payment_method pm ON pm.method_code = (
  CASE
    WHEN (m.seq_no % 3) = 0 THEN 'DEBIT_CARD'
    WHEN (m.seq_no % 3) = 1 THEN 'CREDIT_CARD'
    ELSE 'WALLET'
  END
)
JOIN public.currency cu ON cu.iso_currency_code = 'COP'
ON CONFLICT (payment_reference) DO NOTHING;

INSERT INTO public.payment_transaction (
  payment_transaction_id, payment_id,
  transaction_reference, transaction_type,
  transaction_amount, processed_at, provider_message
)
SELECT
  ('C2000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('C1000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  'TXN-VOL2-AUTH-' || lpad(m.seq_no::text, 6, '0'),
  'AUTH',
  359600.00,
  (TIMESTAMPTZ '2026-01-02 08:00:00-05'
    + ((m.seq_no * 5) % 70) * INTERVAL '1 day'
    + ((m.seq_no * 11) % 600) * INTERVAL '1 minute')
    + INTERVAL '6 minutes 5 seconds',
  'Autorizacion aprobada para reserva volumetrica extendida.'
FROM tmp_vol2_map m
ON CONFLICT (transaction_reference) DO NOTHING;

INSERT INTO public.payment_transaction (
  payment_transaction_id, payment_id,
  transaction_reference, transaction_type,
  transaction_amount, processed_at, provider_message
)
SELECT
  ('C7000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('C1000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  'TXN-VOL2-CAP-' || lpad(m.seq_no::text, 6, '0'),
  'CAPTURE',
  359600.00,
  (TIMESTAMPTZ '2026-01-02 08:00:00-05'
    + ((m.seq_no * 5) % 70) * INTERVAL '1 day'
    + ((m.seq_no * 11) % 600) * INTERVAL '1 minute')
    + INTERVAL '6 minutes 45 seconds',
  'Captura realizada en ventana de conciliacion.'
FROM tmp_vol2_map m
WHERE m.seq_no <= 300
ON CONFLICT (transaction_reference) DO NOTHING;

UPDATE public.payment p
SET payment_status_id = ps.payment_status_id,
    updated_at = now()
FROM public.payment_status ps
WHERE ps.status_code = 'CAPTURED'
  AND p.payment_reference LIKE 'PAY-VOL2-%'
  AND substring(p.payment_reference FROM '([0-9]{6})$')::integer <= 300;

INSERT INTO public.invoice (
  invoice_id, sale_id, invoice_status_id, currency_id,
  invoice_number, issued_at, due_at, notes
)
SELECT
  ('C3000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('B9000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ist.invoice_status_id,
  cu.currency_id,
  'INV-VOL2-2026-' || lpad(m.seq_no::text, 6, '0'),
  (TIMESTAMPTZ '2026-01-02 08:00:00-05'
    + ((m.seq_no * 5) % 70) * INTERVAL '1 day'
    + ((m.seq_no * 11) % 600) * INTERVAL '1 minute')
    + INTERVAL '8 minutes',
  (TIMESTAMPTZ '2026-01-02 08:00:00-05'
    + ((m.seq_no * 5) % 70) * INTERVAL '1 day'
    + ((m.seq_no * 11) % 600) * INTERVAL '1 minute')
    + INTERVAL '8 minutes',
  'Factura reserva volumetrica extendida FY120 BOG-MDE'
FROM tmp_vol2_map m
JOIN public.invoice_status ist ON ist.status_code = 'ISSUED'
JOIN public.currency cu ON cu.iso_currency_code = 'COP'
ON CONFLICT (invoice_number) DO NOTHING;

INSERT INTO public.invoice_line (
  invoice_line_id, invoice_id, tax_id,
  line_number, line_description, quantity, unit_price
)
SELECT
  ('C4000000-0000-0000-0000-' || lpad(((m.seq_no - 1) * 3 + 1)::text, 12, '0'))::uuid,
  ('C3000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  NULL::uuid,
  1,
  'Tarifa base Economy YB BOG-MDE',
  1.00,
  310000.00
FROM tmp_vol2_map m
ON CONFLICT (invoice_id, line_number) DO NOTHING;

INSERT INTO public.invoice_line (
  invoice_line_id, invoice_id, tax_id,
  line_number, line_description, quantity, unit_price
)
SELECT
  ('C4000000-0000-0000-0000-' || lpad(((m.seq_no - 1) * 3 + 2)::text, 12, '0'))::uuid,
  ('C3000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  tx.tax_id,
  2,
  'Tasa aeroportuaria 12 %',
  1.00,
  37200.00
FROM tmp_vol2_map m
JOIN public.tax tx ON tx.tax_code = 'AIRPORT_FEE'
ON CONFLICT (invoice_id, line_number) DO NOTHING;

INSERT INTO public.invoice_line (
  invoice_line_id, invoice_id, tax_id,
  line_number, line_description, quantity, unit_price
)
SELECT
  ('C4000000-0000-0000-0000-' || lpad(((m.seq_no - 1) * 3 + 3)::text, 12, '0'))::uuid,
  ('C3000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  tx.tax_id,
  3,
  'Tasa de seguridad 4 %',
  1.00,
  12400.00
FROM tmp_vol2_map m
JOIN public.tax tx ON tx.tax_code = 'SECURITY_FEE'
ON CONFLICT (invoice_id, line_number) DO NOTHING;

-- ============================================================
-- BLOQUE OPERACIONAL DE VIAJE VOLUMETRICO
-- ============================================================

INSERT INTO public.ticket_segment (
  ticket_segment_id, ticket_id, flight_segment_id,
  segment_sequence_no, fare_basis_code
)
SELECT
  ('BB000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('BA000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  m.flight_segment_id,
  1,
  'YB'
FROM tmp_vol2_map m
ON CONFLICT (ticket_segment_id) DO NOTHING;

WITH seat_pool AS (
  SELECT
    fs.flight_segment_id,
    acs.aircraft_seat_id,
    row_number() OVER (
      PARTITION BY fs.flight_segment_id
      ORDER BY acs.seat_row_number, acs.seat_column_code
    ) AS seat_slot
  FROM public.flight_segment fs
  JOIN public.flight f ON f.flight_id = fs.flight_id
  JOIN public.airline al ON al.airline_id = f.airline_id
  JOIN public.aircraft a ON a.aircraft_id = f.aircraft_id
  JOIN public.aircraft_cabin acb ON acb.aircraft_id = a.aircraft_id
  JOIN public.aircraft_seat acs ON acs.aircraft_cabin_id = acb.aircraft_cabin_id
  WHERE al.airline_code = 'FLY'
    AND f.flight_number = 'FY120'
    AND f.service_date BETWEEN DATE '2026-04-01' AND DATE '2026-06-30'
),
ticket_slot AS (
  SELECT
    m.seq_no,
    m.flight_segment_id,
    row_number() OVER (
      PARTITION BY m.flight_segment_id
      ORDER BY m.seq_no
    ) AS seat_slot
  FROM tmp_vol2_map m
)
INSERT INTO public.seat_assignment (
  seat_assignment_id, ticket_segment_id, flight_segment_id,
  aircraft_seat_id, assigned_at, assignment_source
)
SELECT
  ('BC000000-0000-0000-0000-' || lpad(ts.seq_no::text, 12, '0'))::uuid,
  ('BB000000-0000-0000-0000-' || lpad(ts.seq_no::text, 12, '0'))::uuid,
  ts.flight_segment_id,
  sp.aircraft_seat_id,
  (TIMESTAMPTZ '2026-01-02 08:00:00-05'
    + ((ts.seq_no * 5) % 70) * INTERVAL '1 day'
    + ((ts.seq_no * 11) % 600) * INTERVAL '1 minute')
    + INTERVAL '12 minutes',
  CASE
    WHEN (ts.seq_no % 9) = 0 THEN 'CUSTOMER'
    WHEN (ts.seq_no % 5) = 0 THEN 'MANUAL'
    ELSE 'AUTO'
  END
FROM ticket_slot ts
JOIN seat_pool sp
  ON sp.flight_segment_id = ts.flight_segment_id
 AND sp.seat_slot = ts.seat_slot
ON CONFLICT (ticket_segment_id) DO NOTHING;

INSERT INTO public.baggage (
  baggage_id, ticket_segment_id,
  baggage_tag, baggage_type, baggage_status, weight_kg, checked_at
)
SELECT
  ('BD000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('BB000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  'BAG-VOL2-' || lpad(m.seq_no::text, 6, '0'),
  'CHECKED',
  CASE WHEN (m.seq_no % 8) = 0 THEN 'LOADED' ELSE 'REGISTERED' END,
  (12 + ((m.seq_no * 7) % 18))::numeric(6,2),
  m.scheduled_departure_at - INTERVAL '2 hours 35 minutes'
FROM tmp_vol2_map m
WHERE m.seq_no <= 1050
ON CONFLICT (baggage_tag) DO NOTHING;

INSERT INTO public.check_in (
  check_in_id, ticket_segment_id, check_in_status_id,
  boarding_group_id, checked_in_by_user_id, checked_in_at
)
SELECT
  ('BE000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('BB000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  cis.check_in_status_id,
  bg.boarding_group_id,
  ua.user_account_id,
  m.scheduled_departure_at - INTERVAL '2 hours 20 minutes'
    + ((m.seq_no % 15) * INTERVAL '1 minute')
FROM tmp_vol2_map m
JOIN public.check_in_status cis ON cis.status_code = 'COMPLETED'
JOIN public.boarding_group bg ON bg.group_code = (
  CASE
    WHEN (m.seq_no % 4) = 0 THEN 'PRIORITY'
    WHEN (m.seq_no % 4) = 1 THEN 'A'
    WHEN (m.seq_no % 4) = 2 THEN 'B'
    ELSE 'C'
  END
)
JOIN public.user_account ua ON ua.username = 'patricia.vargas'
WHERE m.seq_no <= 1100
ON CONFLICT (ticket_segment_id) DO NOTHING;

INSERT INTO public.boarding_pass (
  boarding_pass_id, check_in_id,
  boarding_pass_code, barcode_value, issued_at
)
SELECT
  ('BF000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('BE000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  'BP-VOL2-' || lpad(m.seq_no::text, 6, '0'),
  'BCVOL2' || lpad(m.seq_no::text, 10, '0'),
  m.scheduled_departure_at - INTERVAL '2 hours 15 minutes'
    + ((m.seq_no % 15) * INTERVAL '1 minute')
FROM tmp_vol2_map m
WHERE m.seq_no <= 1100
ON CONFLICT (boarding_pass_code) DO NOTHING;

WITH gate_pool AS (
  SELECT
    bg.boarding_gate_id,
    row_number() OVER (ORDER BY bg.gate_code) AS gate_slot
  FROM public.boarding_gate bg
  JOIN public.terminal t ON t.terminal_id = bg.terminal_id
  JOIN public.airport ap ON ap.airport_id = t.airport_id
  WHERE ap.iata_code = 'BOG'
    AND t.terminal_code = 'T1'
    AND bg.gate_code IN ('A12', 'A18')
)
INSERT INTO public.boarding_validation (
  boarding_validation_id, boarding_pass_id, boarding_gate_id,
  validated_by_user_id, validated_at, validation_result, notes
)
SELECT
  ('C0000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('BF000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  gp.boarding_gate_id,
  ua.user_account_id,
  m.scheduled_departure_at - INTERVAL '50 minutes'
    + ((m.seq_no % 10) * INTERVAL '10 seconds'),
  CASE WHEN (m.seq_no % 40) = 0 THEN 'MANUAL_REVIEW' ELSE 'APPROVED' END,
  CASE
    WHEN (m.seq_no % 40) = 0 THEN 'Revision manual aleatoria para control de seguridad.'
    ELSE 'Validacion operacional volumetrica en puerta.'
  END
FROM tmp_vol2_map m
JOIN gate_pool gp ON gp.gate_slot = ((m.seq_no - 1) % 2) + 1
JOIN public.user_account ua ON ua.username = 'patricia.vargas'
WHERE m.seq_no <= 1100
ON CONFLICT (boarding_validation_id) DO NOTHING;

-- ============================================================
-- ESCENARIO CONTROLADO DE REFUNDS
-- ============================================================

INSERT INTO public.refund (
  refund_id, payment_id, refund_reference, amount,
  requested_at, processed_at, refund_reason
)
SELECT
  ('C5000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('C1000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  'RFD-VOL2-' || lpad(m.seq_no::text, 6, '0'),
  359600.00,
  (TIMESTAMPTZ '2026-01-02 08:00:00-05'
    + ((m.seq_no * 5) % 70) * INTERVAL '1 day'
    + ((m.seq_no * 11) % 600) * INTERVAL '1 minute')
    + INTERVAL '2 days',
  (TIMESTAMPTZ '2026-01-02 08:00:00-05'
    + ((m.seq_no * 5) % 70) * INTERVAL '1 day'
    + ((m.seq_no * 11) % 600) * INTERVAL '1 minute')
    + INTERVAL '2 days 2 hours',
  'Reembolso parcial por cancelacion voluntaria anticipada.'
FROM tmp_vol2_map m
WHERE m.seq_no <= 120
ON CONFLICT (refund_reference) DO NOTHING;

INSERT INTO public.payment_transaction (
  payment_transaction_id, payment_id,
  transaction_reference, transaction_type,
  transaction_amount, processed_at, provider_message
)
SELECT
  ('C6000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('C1000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  'TXN-VOL2-RFD-' || lpad(m.seq_no::text, 6, '0'),
  'REFUND',
  359600.00,
  (TIMESTAMPTZ '2026-01-02 08:00:00-05'
    + ((m.seq_no * 5) % 70) * INTERVAL '1 day'
    + ((m.seq_no * 11) % 600) * INTERVAL '1 minute')
    + INTERVAL '2 days 2 hours 2 minutes',
  'Reembolso emitido y conciliado.'
FROM tmp_vol2_map m
WHERE m.seq_no <= 120
ON CONFLICT (transaction_reference) DO NOTHING;

UPDATE public.payment p
SET payment_status_id = ps.payment_status_id,
    updated_at = now()
FROM public.payment_status ps
WHERE ps.status_code = 'REFUNDED'
  AND p.payment_reference LIKE 'PAY-VOL2-%'
  AND substring(p.payment_reference FROM '([0-9]{6})$')::integer <= 120;

-- ============================================================
-- MILLAS ADICIONALES VOLUMETRICAS
-- ============================================================

INSERT INTO public.miles_transaction (
  miles_transaction_id, loyalty_account_id,
  transaction_type, miles_delta, occurred_at, reference_code, notes
)
SELECT
  ('C8000000-0000-0000-0000-' || lpad(m.seq_no::text, 12, '0'))::uuid,
  ('94000000-0000-0000-0000-' || lpad(m.customer_seq::text, 12, '0'))::uuid,
  'EARN',
  250 + ((m.seq_no * 29) % 1400),
  TIMESTAMPTZ '2025-01-05 00:00:00-05' + ((m.seq_no * 2) % 330) * INTERVAL '1 day',
  'VOL2-EARN-' || lpad(m.seq_no::text, 6, '0'),
  'Acreditacion historica adicional de millas (tramo volumetrico extendido).'
FROM tmp_vol2_map m
ON CONFLICT (miles_transaction_id) DO NOTHING;

COMMIT;
