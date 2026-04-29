\set ON_ERROR_STOP on
\echo '00_seed_canonico.sql - catalogos raiz y referencia controlada'

BEGIN;

SET client_min_messages TO warning;

INSERT INTO public.aircraft_manufacturer (manufacturer_name)
VALUES
  ('Airbus'),
  ('Antonov'),
  ('ATR'),
  ('Beechcraft'),
  ('Boeing'),
  ('Bombardier'),
  ('COMAC'),
  ('De Havilland Canada'),
  ('Embraer'),
  ('Gulfstream'),
  ('Pilatus'),
  ('Sukhoi')
ON CONFLICT (manufacturer_name) DO NOTHING;

INSERT INTO public.benefit_type (benefit_code, benefit_name, benefit_description)
VALUES
  ('EXTRA_BAG', 'Equipaje adicional', 'Permite transportar equipaje por encima del franquiciado.'),
  ('FAST_TRACK', 'Fast track', 'Permite acceso agilizado a filtros de seguridad cuando aplica.'),
  ('LOUNGE', 'Acceso a lounge', 'Habilita acceso a salas VIP propias o de terceros.'),
  ('PRIORITY', 'Abordaje prioritario', 'Permite abordar antes del grupo general.'),
  ('SEAT_PLUS', 'Mejora de asiento', 'Permite seleccionar asiento preferente o con mayor espacio.'),
  ('WAIVER', 'Flexibilidad de cambio', 'Reduce o elimina penalidad de cambio.')
ON CONFLICT (benefit_code) DO UPDATE
SET benefit_name = EXCLUDED.benefit_name,
    benefit_description = EXCLUDED.benefit_description,
    updated_at = now();

INSERT INTO public.boarding_group (group_code, group_name, sequence_no)
VALUES
  ('PRIORITY', 'Prioritario', 1),
  ('A', 'Grupo A', 2),
  ('B', 'Grupo B', 3),
  ('C', 'Grupo C', 4),
  ('D', 'Grupo D', 5)
ON CONFLICT (group_code) DO UPDATE
SET group_name = EXCLUDED.group_name,
    sequence_no = EXCLUDED.sequence_no,
    updated_at = now();

INSERT INTO public.cabin_class (class_code, class_name)
VALUES
  ('F', 'First'),
  ('J', 'Business'),
  ('W', 'Premium Economy'),
  ('Y', 'Economy')
ON CONFLICT (class_code) DO UPDATE
SET class_name = EXCLUDED.class_name,
    updated_at = now();

INSERT INTO public.check_in_status (status_code, status_name)
VALUES
  ('CANCELLED', 'Cancelado'),
  ('COMPLETED', 'Completado'),
  ('OPEN', 'Abierto'),
  ('PENDING', 'Pendiente'),
  ('NO_SHOW', 'No presentado')
ON CONFLICT (status_code) DO UPDATE
SET status_name = EXCLUDED.status_name,
    updated_at = now();

INSERT INTO public.contact_type (type_code, type_name)
VALUES
  ('EMAIL', 'Correo electronico'),
  ('EMERGENCY', 'Contacto de emergencia'),
  ('HOME_PHONE', 'Telefono residencial'),
  ('MOBILE', 'Telefono movil'),
  ('WHATSAPP', 'WhatsApp'),
  ('WORK_PHONE', 'Telefono laboral')
ON CONFLICT (type_code) DO UPDATE
SET type_name = EXCLUDED.type_name,
    updated_at = now();

INSERT INTO public.continent (continent_code, continent_name)
VALUES
  ('AF', 'Africa'),
  ('AN', 'Antarctica'),
  ('AS', 'Asia'),
  ('EU', 'Europe'),
  ('NA', 'North America'),
  ('OC', 'Oceania'),
  ('SA', 'South America')
ON CONFLICT (continent_code) DO UPDATE
SET continent_name = EXCLUDED.continent_name,
    updated_at = now();

INSERT INTO public.currency (iso_currency_code, currency_name, currency_symbol, minor_units)
VALUES
  ('BRL', 'Brazilian Real', 'R$', 2),
  ('COP', 'Colombian Peso', '$', 2),
  ('EUR', 'Euro', 'EUR', 2),
  ('GBP', 'Pound Sterling', 'GBP', 2),
  ('JPY', 'Japanese Yen', 'JPY', 0),
  ('MXN', 'Mexican Peso', '$', 2),
  ('USD', 'US Dollar', '$', 2)
ON CONFLICT (iso_currency_code) DO UPDATE
SET currency_name = EXCLUDED.currency_name,
    currency_symbol = EXCLUDED.currency_symbol,
    minor_units = EXCLUDED.minor_units,
    updated_at = now();

INSERT INTO public.customer_category (category_code, category_name)
VALUES
  ('CORP', 'Corporativo'),
  ('GOLD', 'Gold'),
  ('PLAT', 'Platinum'),
  ('REG', 'Regular'),
  ('SILV', 'Silver')
ON CONFLICT (category_code) DO UPDATE
SET category_name = EXCLUDED.category_name,
    updated_at = now();

INSERT INTO public.delay_reason_type (reason_code, reason_name)
VALUES
  ('ATC', 'Control de trafico aereo'),
  ('CREW', 'Disponibilidad de tripulacion'),
  ('MX', 'Mantenimiento'),
  ('OPS', 'Operacion aeroportuaria'),
  ('SEC', 'Seguridad'),
  ('WX', 'Condiciones meteorologicas')
ON CONFLICT (reason_code) DO UPDATE
SET reason_name = EXCLUDED.reason_name,
    updated_at = now();

INSERT INTO public.document_type (type_code, type_name)
VALUES
  ('DL', 'Licencia de conduccion'),
  ('NIT', 'Documento tributario'),
  ('NID', 'Documento nacional'),
  ('PASS', 'Pasaporte'),
  ('RES', 'Tarjeta de residencia')
ON CONFLICT (type_code) DO UPDATE
SET type_name = EXCLUDED.type_name,
    updated_at = now();

INSERT INTO public.flight_status (status_code, status_name)
VALUES
  ('ARRIVED', 'Arribado'),
  ('BOARDING', 'En abordaje'),
  ('CANCELLED', 'Cancelado'),
  ('DELAYED', 'Demorado'),
  ('DEPARTED', 'Despegado'),
  ('DIVERTED', 'Desviado'),
  ('SCHEDULED', 'Programado')
ON CONFLICT (status_code) DO UPDATE
SET status_name = EXCLUDED.status_name,
    updated_at = now();

INSERT INTO public.invoice_status (status_code, status_name)
VALUES
  ('ISSUED', 'Emitida'),
  ('OVERDUE', 'Vencida'),
  ('PAID', 'Pagada'),
  ('PARTIAL', 'Pago parcial'),
  ('VOID', 'Anulada')
ON CONFLICT (status_code) DO UPDATE
SET status_name = EXCLUDED.status_name,
    updated_at = now();

INSERT INTO public.maintenance_type (type_code, type_name)
VALUES
  ('A_CHECK', 'A-Check'),
  ('C_CHECK', 'C-Check'),
  ('CABIN', 'Cabina'),
  ('ENGINE', 'Motor'),
  ('LINE', 'Linea'),
  ('UNSCHED', 'No programado')
ON CONFLICT (type_code) DO UPDATE
SET type_name = EXCLUDED.type_name,
    updated_at = now();

INSERT INTO public.payment_method (method_code, method_name)
VALUES
  ('BANK_TRANSFER', 'Transferencia bancaria'),
  ('CASH', 'Efectivo'),
  ('CREDIT_CARD', 'Tarjeta de credito'),
  ('DEBIT_CARD', 'Tarjeta debito'),
  ('MILES', 'Millas'),
  ('WALLET', 'Billetera digital')
ON CONFLICT (method_code) DO UPDATE
SET method_name = EXCLUDED.method_name,
    updated_at = now();

INSERT INTO public.payment_status (status_code, status_name)
VALUES
  ('AUTHORIZED', 'Autorizado'),
  ('CANCELLED', 'Cancelado'),
  ('CAPTURED', 'Capturado'),
  ('FAILED', 'Fallido'),
  ('PENDING', 'Pendiente'),
  ('REFUNDED', 'Reembolsado')
ON CONFLICT (status_code) DO UPDATE
SET status_name = EXCLUDED.status_name,
    updated_at = now();

INSERT INTO public.person_type (type_code, type_name)
VALUES
  ('ADULT', 'Adulto'),
  ('CHILD', 'Menor'),
  ('CONTRACTOR', 'Contratista'),
  ('EMPLOYEE', 'Empleado'),
  ('INFANT', 'Infante')
ON CONFLICT (type_code) DO UPDATE
SET type_name = EXCLUDED.type_name,
    updated_at = now();

INSERT INTO public.reservation_status (status_code, status_name)
VALUES
  ('CANCELLED', 'Cancelada'),
  ('CONFIRMED', 'Confirmada'),
  ('EXPIRED', 'Expirada'),
  ('HOLD', 'En espera'),
  ('TICKETED', 'Tiquete emitido')
ON CONFLICT (status_code) DO UPDATE
SET status_name = EXCLUDED.status_name,
    updated_at = now();

INSERT INTO public.sale_channel (channel_code, channel_name)
VALUES
  ('AGENCY', 'Agencia'),
  ('AIRPORT_COUNTER', 'Mostrador de aeropuerto'),
  ('CALL_CENTER', 'Call center'),
  ('CORPORATE', 'Portal corporativo'),
  ('MOBILE_APP', 'Aplicacion movil'),
  ('WEB', 'Web')
ON CONFLICT (channel_code) DO UPDATE
SET channel_name = EXCLUDED.channel_name,
    updated_at = now();

INSERT INTO public.security_permission (permission_code, permission_name, permission_description)
VALUES
  ('ISSUE_INVOICES', 'Emitir facturas', 'Permite emitir y consultar facturas de venta.'),
  ('ISSUE_TICKETS', 'Emitir tiquetes', 'Permite crear y actualizar tickets asociados a una venta.'),
  ('MANAGE_AIRCRAFT', 'Administrar flota', 'Permite registrar aeronaves, cabinas y asientos.'),
  ('MANAGE_FLIGHTS', 'Administrar vuelos', 'Permite crear vuelos, segmentos y estados operativos.'),
  ('MANAGE_RESERVATIONS', 'Administrar reservas', 'Permite crear, modificar o cancelar reservas.'),
  ('MANAGE_USERS', 'Administrar usuarios', 'Permite crear usuarios y asignarles roles.'),
  ('PROCESS_REFUNDS', 'Procesar reembolsos', 'Permite registrar devoluciones ligadas a pagos.'),
  ('REGISTER_PAYMENTS', 'Registrar pagos', 'Permite autorizar y registrar pagos y transacciones.'),
  ('VALIDATE_BOARDING', 'Validar abordaje', 'Permite ejecutar validaciones de boarding.'),
  ('VIEW_CUSTOMERS', 'Consultar clientes', 'Permite ver informacion comercial y de lealtad.'),
  ('VIEW_REPORTS', 'Consultar reportes', 'Permite acceder a tableros e indicadores.'),
  ('WRITE_CUSTOMERS', 'Actualizar clientes', 'Permite editar datos maestros del cliente.')
ON CONFLICT (permission_code) DO UPDATE
SET permission_name = EXCLUDED.permission_name,
    permission_description = EXCLUDED.permission_description,
    updated_at = now();

INSERT INTO public.security_role (role_code, role_name, role_description)
VALUES
  ('CS_AGENT', 'Agente de servicio', 'Gestiona atencion al cliente, reservas y cambios simples.'),
  ('FINANCE', 'Finanzas', 'Administra pagos, facturas y conciliacion.'),
  ('OPS_CTRL', 'Control operacional', 'Administra vuelos, demoras y eventos de viaje.'),
  ('SALES_AGENT', 'Agente comercial', 'Gestiona ventas, reservas y emision de tickets.'),
  ('SYS_ADMIN', 'Administrador del sistema', 'Administra seguridad, parametria y operacion completa.')
ON CONFLICT (role_code) DO UPDATE
SET role_name = EXCLUDED.role_name,
    role_description = EXCLUDED.role_description,
    updated_at = now();

INSERT INTO public.tax (tax_code, tax_name, rate_percentage, effective_from, effective_to)
VALUES
  ('AIRPORT_FEE', 'Tasa aeroportuaria', 12.00, DATE '2024-01-01', NULL),
  ('SECURITY_FEE', 'Tasa de seguridad', 4.00, DATE '2024-01-01', NULL),
  ('VAT_19', 'IVA 19', 19.00, DATE '2024-01-01', NULL)
ON CONFLICT (tax_code) DO UPDATE
SET tax_name = EXCLUDED.tax_name,
    rate_percentage = EXCLUDED.rate_percentage,
    effective_from = EXCLUDED.effective_from,
    effective_to = EXCLUDED.effective_to,
    updated_at = now();

INSERT INTO public.ticket_status (status_code, status_name)
VALUES
  ('CHECKED_IN', 'Chequeado'),
  ('EXCHANGED', 'Cambiado'),
  ('FLOWN', 'Volado'),
  ('ISSUED', 'Emitido'),
  ('REFUNDED', 'Reembolsado'),
  ('VOID', 'Anulado')
ON CONFLICT (status_code) DO UPDATE
SET status_name = EXCLUDED.status_name,
    updated_at = now();

INSERT INTO public.time_zone (time_zone_name, utc_offset_minutes)
VALUES
  ('America/Bogota', -300),
  ('America/Mexico_City', -360),
  ('America/New_York', -300),
  ('America/Sao_Paulo', -180),
  ('Europe/London', 0),
  ('Europe/Madrid', 60),
  ('UTC', 0)
ON CONFLICT (time_zone_name) DO UPDATE
SET utc_offset_minutes = EXCLUDED.utc_offset_minutes,
    updated_at = now();

INSERT INTO public.user_status (status_code, status_name)
VALUES
  ('ACTIVE', 'Activo'),
  ('INACTIVE', 'Inactivo'),
  ('LOCKED', 'Bloqueado'),
  ('PENDING', 'Pendiente'),
  ('SUSPENDED', 'Suspendido')
ON CONFLICT (status_code) DO UPDATE
SET status_name = EXCLUDED.status_name,
    updated_at = now();

INSERT INTO public.role_permission (security_role_id, security_permission_id, granted_at)
SELECT sr.security_role_id, sp.security_permission_id, now()
FROM public.security_role sr
JOIN public.security_permission sp
  ON (
    sr.role_code = 'SYS_ADMIN'
    OR (sr.role_code = 'SALES_AGENT' AND sp.permission_code IN ('VIEW_CUSTOMERS', 'WRITE_CUSTOMERS', 'MANAGE_RESERVATIONS', 'ISSUE_TICKETS', 'VIEW_REPORTS'))
    OR (sr.role_code = 'FINANCE' AND sp.permission_code IN ('REGISTER_PAYMENTS', 'ISSUE_INVOICES', 'PROCESS_REFUNDS', 'VIEW_REPORTS'))
    OR (sr.role_code = 'OPS_CTRL' AND sp.permission_code IN ('MANAGE_FLIGHTS', 'MANAGE_AIRCRAFT', 'VALIDATE_BOARDING', 'VIEW_REPORTS'))
    OR (sr.role_code = 'CS_AGENT' AND sp.permission_code IN ('VIEW_CUSTOMERS', 'MANAGE_RESERVATIONS', 'VALIDATE_BOARDING'))
  )
ON CONFLICT (security_role_id, security_permission_id) DO NOTHING;

-- Geografia y referencia operacional

INSERT INTO public.country (continent_id, iso_alpha2, iso_alpha3, country_name)
SELECT ct.continent_id, seed.iso_alpha2, seed.iso_alpha3, seed.country_name
FROM (
  VALUES
    ('SA', 'BR', 'BRA', 'Brazil'),
    ('SA', 'CO', 'COL', 'Colombia'),
    ('EU', 'ES', 'ESP', 'Spain'),
    ('NA', 'MX', 'MEX', 'Mexico'),
    ('NA', 'US', 'USA', 'United States')
) AS seed(continent_code, iso_alpha2, iso_alpha3, country_name)
JOIN public.continent ct
  ON ct.continent_code = seed.continent_code
ON CONFLICT (iso_alpha2) DO UPDATE
SET continent_id = EXCLUDED.continent_id,
    iso_alpha3 = EXCLUDED.iso_alpha3,
    country_name = EXCLUDED.country_name,
    updated_at = now();

INSERT INTO public.state_province (country_id, state_code, state_name)
SELECT c.country_id, seed.state_code, seed.state_name
FROM (
  VALUES
    ('BR', 'SP', 'Sao Paulo'),
    ('CO', 'ANT', 'Antioquia'),
    ('CO', 'BOG', 'Bogota D.C.'),
    ('ES', 'MD', 'Comunidad de Madrid'),
    ('MX', 'CMX', 'Ciudad de Mexico'),
    ('US', 'FL', 'Florida')
) AS seed(country_code, state_code, state_name)
JOIN public.country c
  ON c.iso_alpha2 = seed.country_code
ON CONFLICT (country_id, state_name) DO UPDATE
SET state_code = EXCLUDED.state_code,
    updated_at = now();

INSERT INTO public.city (state_province_id, time_zone_id, city_name)
SELECT sp.state_province_id, tz.time_zone_id, seed.city_name
FROM (
  VALUES
    ('Bogota D.C.', 'America/Bogota', 'Bogota'),
    ('Antioquia', 'America/Bogota', 'Rionegro'),
    ('Florida', 'America/New_York', 'Miami'),
    ('Comunidad de Madrid', 'Europe/Madrid', 'Madrid'),
    ('Ciudad de Mexico', 'America/Mexico_City', 'Mexico City'),
    ('Sao Paulo', 'America/Sao_Paulo', 'Sao Paulo')
) AS seed(state_name, time_zone_name, city_name)
JOIN public.state_province sp
  ON sp.state_name = seed.state_name
JOIN public.time_zone tz
  ON tz.time_zone_name = seed.time_zone_name
ON CONFLICT (state_province_id, city_name) DO UPDATE
SET time_zone_id = EXCLUDED.time_zone_id,
    updated_at = now();

INSERT INTO public.district (city_id, district_name)
SELECT c.city_id, seed.district_name
FROM (
  VALUES
    ('Bogota', 'Fontibon'),
    ('Bogota', 'Zona Industrial'),
    ('Madrid', 'Barajas'),
    ('Mexico City', 'Venustiano Carranza'),
    ('Miami', 'Miami-Dade'),
    ('Rionegro', 'Llanogrande'),
    ('Sao Paulo', 'Guarulhos')
) AS seed(city_name, district_name)
JOIN public.city c
  ON c.city_name = seed.city_name
ON CONFLICT (city_id, district_name) DO UPDATE
SET updated_at = now();

INSERT INTO public.address (address_id, district_id, address_line_1, address_line_2, postal_code, latitude, longitude)
SELECT seed.address_id, d.district_id, seed.address_line_1, seed.address_line_2, seed.postal_code, seed.latitude, seed.longitude
FROM (
  VALUES
    ('40000000-0000-0000-0000-000000000001'::uuid, 'Fontibon', 'Avenida El Dorado 103-09', 'Terminal 1', '110911', 4.7015940::numeric, -74.1469470::numeric),
    ('40000000-0000-0000-0000-000000000002'::uuid, 'Llanogrande', 'Via Aeropuerto Jose Maria Cordova Km 3.5', NULL, '054047', 6.1645360::numeric, -75.4231190::numeric),
    ('40000000-0000-0000-0000-000000000003'::uuid, 'Miami-Dade', '2100 NW 42nd Avenue', NULL, '33142', 25.7958650::numeric, -80.2870460::numeric),
    ('40000000-0000-0000-0000-000000000004'::uuid, 'Barajas', 'Av de la Hispanidad s/n', 'Terminal 4', '28042', 40.4913530::numeric, -3.5931900::numeric),
    ('40000000-0000-0000-0000-000000000005'::uuid, 'Venustiano Carranza', 'Capitan Carlos Leon s/n', 'Terminal 2', '15620', 19.4363030::numeric, -99.0720970::numeric),
    ('40000000-0000-0000-0000-000000000006'::uuid, 'Zona Industrial', 'Carrera 96G 16C-39', 'Hangar 5', '110931', 4.6902000::numeric, -74.1399000::numeric)
) AS seed(address_id, district_name, address_line_1, address_line_2, postal_code, latitude, longitude)
JOIN public.district d
  ON d.district_name = seed.district_name
ON CONFLICT (address_id) DO UPDATE
SET district_id = EXCLUDED.district_id,
    address_line_1 = EXCLUDED.address_line_1,
    address_line_2 = EXCLUDED.address_line_2,
    postal_code = EXCLUDED.postal_code,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    updated_at = now();

INSERT INTO public.airline (home_country_id, airline_code, airline_name, iata_code, icao_code, is_active)
SELECT c.country_id, seed.airline_code, seed.airline_name, seed.iata_code, seed.icao_code, seed.is_active
FROM (
  VALUES
    ('CO', 'FLY', 'FLY Airlines', 'FY', 'FLY', true),
    ('ES', 'IBA', 'Ibero Atlantic', 'IA', 'IBA', true),
    ('US', 'NVA', 'Nova America', 'NV', 'NVA', true)
) AS seed(country_code, airline_code, airline_name, iata_code, icao_code, is_active)
JOIN public.country c
  ON c.iso_alpha2 = seed.country_code
ON CONFLICT (airline_code) DO UPDATE
SET home_country_id = EXCLUDED.home_country_id,
    airline_name = EXCLUDED.airline_name,
    iata_code = EXCLUDED.iata_code,
    icao_code = EXCLUDED.icao_code,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO public.exchange_rate (from_currency_id, to_currency_id, effective_date, rate_value)
SELECT cf.currency_id, ct.currency_id, seed.effective_date, seed.rate_value
FROM (
  VALUES
    ('COP', 'USD', DATE '2026-03-01', 0.00025500::numeric),
    ('USD', 'COP', DATE '2026-03-01', 3921.56000000::numeric),
    ('EUR', 'USD', DATE '2026-03-01', 1.08750000::numeric),
    ('USD', 'EUR', DATE '2026-03-01', 0.91954000::numeric),
    ('MXN', 'USD', DATE '2026-03-01', 0.05840000::numeric),
    ('USD', 'MXN', DATE '2026-03-01', 17.12330000::numeric)
) AS seed(from_code, to_code, effective_date, rate_value)
JOIN public.currency cf
  ON cf.iso_currency_code = seed.from_code
JOIN public.currency ct
  ON ct.iso_currency_code = seed.to_code
ON CONFLICT (from_currency_id, to_currency_id, effective_date) DO UPDATE
SET rate_value = EXCLUDED.rate_value,
    updated_at = now();

INSERT INTO public.airport (address_id, airport_name, iata_code, icao_code, is_active)
SELECT seed.address_id, seed.airport_name, seed.iata_code, seed.icao_code, seed.is_active
FROM (
  VALUES
    ('40000000-0000-0000-0000-000000000001'::uuid, 'El Dorado International Airport', 'BOG', 'SKBO', true),
    ('40000000-0000-0000-0000-000000000002'::uuid, 'Jose Maria Cordova International Airport', 'MDE', 'SKRG', true),
    ('40000000-0000-0000-0000-000000000003'::uuid, 'Miami International Airport', 'MIA', 'KMIA', true),
    ('40000000-0000-0000-0000-000000000004'::uuid, 'Adolfo Suarez Madrid-Barajas Airport', 'MAD', 'LEMD', true),
    ('40000000-0000-0000-0000-000000000005'::uuid, 'Benito Juarez International Airport', 'MEX', 'MMMX', true)
  ) AS seed(address_id, airport_name, iata_code, icao_code, is_active)
ON CONFLICT (iata_code) DO UPDATE
SET address_id = EXCLUDED.address_id,
    airport_name = EXCLUDED.airport_name,
    icao_code = EXCLUDED.icao_code,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO public.terminal (airport_id, terminal_code, terminal_name)
SELECT ap.airport_id, seed.terminal_code, seed.terminal_name
FROM (
  VALUES
    ('BOG', 'T1', 'Terminal 1'),
    ('MDE', 'T1', 'Terminal Principal'),
    ('MIA', 'D', 'North Terminal D'),
    ('MAD', 'T4', 'Terminal 4'),
    ('MEX', 'T2', 'Terminal 2')
) AS seed(iata_code, terminal_code, terminal_name)
JOIN public.airport ap
  ON ap.iata_code = seed.iata_code
ON CONFLICT (airport_id, terminal_code) DO UPDATE
SET terminal_name = EXCLUDED.terminal_name,
    updated_at = now();

INSERT INTO public.boarding_gate (terminal_id, gate_code, is_active)
SELECT t.terminal_id, seed.gate_code, seed.is_active
FROM (
  VALUES
    ('BOG', 'T1', 'A12', true),
    ('BOG', 'T1', 'A18', true),
    ('MDE', 'T1', '07', true),
    ('MIA', 'D', 'D14', true),
    ('MAD', 'T4', 'S08', true),
    ('MEX', 'T2', 'B05', true)
) AS seed(iata_code, terminal_code, gate_code, is_active)
JOIN public.airport ap
  ON ap.iata_code = seed.iata_code
JOIN public.terminal t
  ON t.airport_id = ap.airport_id
 AND t.terminal_code = seed.terminal_code
ON CONFLICT (terminal_id, gate_code) DO UPDATE
SET is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO public.runway (airport_id, runway_code, length_meters, surface_type)
SELECT ap.airport_id, seed.runway_code, seed.length_meters, seed.surface_type
FROM (
  VALUES
    ('BOG', '13L/31R', 3800, 'ASPHALT'),
    ('MDE', '01/19', 3557, 'ASPHALT'),
    ('MIA', '08R/26L', 3960, 'CONCRETE'),
    ('MAD', '18L/36R', 4400, 'ASPHALT'),
    ('MEX', '05L/23R', 3900, 'CONCRETE')
  ) AS seed(iata_code, runway_code, length_meters, surface_type)
JOIN public.airport ap
  ON ap.iata_code = seed.iata_code
ON CONFLICT (airport_id, runway_code) DO UPDATE
SET length_meters = EXCLUDED.length_meters,
    surface_type = EXCLUDED.surface_type,
    updated_at = now();

INSERT INTO public.airport_regulation (airport_id, regulation_code, regulation_title, issuing_authority, effective_from, effective_to)
SELECT ap.airport_id, seed.regulation_code, seed.regulation_title, seed.issuing_authority, seed.effective_from, seed.effective_to
FROM (
  VALUES
    ('BOG', 'SLOT-OPS', 'Ventanas operacionales y asignacion de slots', 'Aerocivil', DATE '2025-01-01', NULL::date),
    ('MDE', 'WX-MIN', 'Minimos operacionales por meteorologia', 'Aerocivil', DATE '2025-01-01', NULL::date),
    ('MIA', 'SEC-STER', 'Control de acceso a zona esteril', 'FAA', DATE '2025-01-01', NULL::date),
    ('MAD', 'SCHENGEN-SEP', 'Segregacion Schengen y no Schengen', 'AENA', DATE '2025-01-01', NULL::date),
    ('MEX', 'BAG-CTRL', 'Control de equipaje y trazabilidad', 'AFAC', DATE '2025-01-01', NULL::date)
  ) AS seed(iata_code, regulation_code, regulation_title, issuing_authority, effective_from, effective_to)
JOIN public.airport ap
  ON ap.iata_code = seed.iata_code
ON CONFLICT (airport_id, regulation_code) DO UPDATE
SET regulation_title = EXCLUDED.regulation_title,
    issuing_authority = EXCLUDED.issuing_authority,
    effective_from = EXCLUDED.effective_from,
    effective_to = EXCLUDED.effective_to,
    updated_at = now();

INSERT INTO public.aircraft_model (aircraft_manufacturer_id, model_code, model_name, max_range_km)
SELECT am.aircraft_manufacturer_id, seed.model_code, seed.model_name, seed.max_range_km
FROM (
  VALUES
    ('Airbus', 'A320N', 'A320neo', 6300),
    ('Boeing', 'B788', '787-8 Dreamliner', 13620),
    ('Embraer', 'E190-E2', 'E190-E2', 5278)
) AS seed(manufacturer_name, model_code, model_name, max_range_km)
JOIN public.aircraft_manufacturer am
  ON am.manufacturer_name = seed.manufacturer_name
ON CONFLICT (aircraft_manufacturer_id, model_code) DO UPDATE
SET model_name = EXCLUDED.model_name,
    max_range_km = EXCLUDED.max_range_km,
    updated_at = now();

INSERT INTO public.aircraft (airline_id, aircraft_model_id, registration_number, serial_number, in_service_on, retired_on)
SELECT al.airline_id, am.aircraft_model_id, seed.registration_number, seed.serial_number, seed.in_service_on, seed.retired_on
FROM (
  VALUES
    ('FLY', 'A320N', 'HK-5500', 'FLY320001', DATE '2020-06-15', NULL::date),
    ('FLY', 'B788', 'HK-7870', 'FLY787001', DATE '2021-09-01', NULL::date),
    ('NVA', 'E190-E2', 'N803NV', 'NVA190001', DATE '2022-03-20', NULL::date)
) AS seed(airline_code, model_code, registration_number, serial_number, in_service_on, retired_on)
JOIN public.airline al
  ON al.airline_code = seed.airline_code
JOIN public.aircraft_model am
  ON am.model_code = seed.model_code
ON CONFLICT (registration_number) DO UPDATE
SET airline_id = EXCLUDED.airline_id,
    aircraft_model_id = EXCLUDED.aircraft_model_id,
    serial_number = EXCLUDED.serial_number,
    in_service_on = EXCLUDED.in_service_on,
    retired_on = EXCLUDED.retired_on,
    updated_at = now();

INSERT INTO public.aircraft_cabin (aircraft_id, cabin_class_id, cabin_code, deck_number)
SELECT a.aircraft_id, cc.cabin_class_id, seed.cabin_code, seed.deck_number
FROM (
  VALUES
    ('HK-5500', 'J', 'J', 1),
    ('HK-5500', 'Y', 'Y', 1),
    ('HK-7870', 'J', 'J', 1),
    ('HK-7870', 'Y', 'Y', 1),
    ('N803NV', 'Y', 'Y', 1)
  ) AS seed(registration_number, class_code, cabin_code, deck_number)
JOIN public.aircraft a
  ON a.registration_number = seed.registration_number
JOIN public.cabin_class cc
  ON cc.class_code = seed.class_code
ON CONFLICT (aircraft_id, cabin_code) DO UPDATE
SET cabin_class_id = EXCLUDED.cabin_class_id,
    deck_number = EXCLUDED.deck_number,
    updated_at = now();

INSERT INTO public.aircraft_seat (aircraft_cabin_id, seat_row_number, seat_column_code, is_window, is_aisle, is_exit_row)
SELECT ac.aircraft_cabin_id, gs.row_no, col.seat_column_code, col.is_window, col.is_aisle, false
FROM public.aircraft_cabin ac
JOIN public.aircraft a
  ON a.aircraft_id = ac.aircraft_id
CROSS JOIN generate_series(1, 3) AS gs(row_no)
CROSS JOIN (
  VALUES
    ('A', true, false),
    ('C', false, true),
    ('D', false, true),
    ('F', true, false)
) AS col(seat_column_code, is_window, is_aisle)
WHERE a.registration_number = 'HK-5500'
  AND ac.cabin_code = 'J'
ON CONFLICT (aircraft_cabin_id, seat_row_number, seat_column_code) DO UPDATE
SET is_window = EXCLUDED.is_window,
    is_aisle = EXCLUDED.is_aisle,
    is_exit_row = EXCLUDED.is_exit_row,
    updated_at = now();

INSERT INTO public.aircraft_seat (aircraft_cabin_id, seat_row_number, seat_column_code, is_window, is_aisle, is_exit_row)
SELECT ac.aircraft_cabin_id, gs.row_no, col.seat_column_code, col.is_window, col.is_aisle, gs.row_no IN (12, 13)
FROM public.aircraft_cabin ac
JOIN public.aircraft a
  ON a.aircraft_id = ac.aircraft_id
CROSS JOIN generate_series(5, 24) AS gs(row_no)
CROSS JOIN (
  VALUES
    ('A', true, false),
    ('B', false, false),
    ('C', false, true),
    ('D', false, true),
    ('E', false, false),
    ('F', true, false)
) AS col(seat_column_code, is_window, is_aisle)
WHERE a.registration_number = 'HK-5500'
  AND ac.cabin_code = 'Y'
ON CONFLICT (aircraft_cabin_id, seat_row_number, seat_column_code) DO UPDATE
SET is_window = EXCLUDED.is_window,
    is_aisle = EXCLUDED.is_aisle,
    is_exit_row = EXCLUDED.is_exit_row,
    updated_at = now();

INSERT INTO public.aircraft_seat (aircraft_cabin_id, seat_row_number, seat_column_code, is_window, is_aisle, is_exit_row)
SELECT ac.aircraft_cabin_id, gs.row_no, col.seat_column_code, col.is_window, col.is_aisle, false
FROM public.aircraft_cabin ac
JOIN public.aircraft a
  ON a.aircraft_id = ac.aircraft_id
CROSS JOIN generate_series(1, 5) AS gs(row_no)
CROSS JOIN (
  VALUES
    ('A', true, false),
    ('D', false, true),
    ('G', false, true),
    ('K', true, false)
) AS col(seat_column_code, is_window, is_aisle)
WHERE a.registration_number = 'HK-7870'
  AND ac.cabin_code = 'J'
ON CONFLICT (aircraft_cabin_id, seat_row_number, seat_column_code) DO UPDATE
SET is_window = EXCLUDED.is_window,
    is_aisle = EXCLUDED.is_aisle,
    is_exit_row = EXCLUDED.is_exit_row,
    updated_at = now();

INSERT INTO public.aircraft_seat (aircraft_cabin_id, seat_row_number, seat_column_code, is_window, is_aisle, is_exit_row)
SELECT ac.aircraft_cabin_id, gs.row_no, col.seat_column_code, col.is_window, col.is_aisle, gs.row_no IN (15, 16)
FROM public.aircraft_cabin ac
JOIN public.aircraft a
  ON a.aircraft_id = ac.aircraft_id
CROSS JOIN generate_series(10, 29) AS gs(row_no)
CROSS JOIN (
  VALUES
    ('A', true, false),
    ('C', false, true),
    ('D', false, true),
    ('F', false, true),
    ('H', false, true),
    ('K', true, false)
) AS col(seat_column_code, is_window, is_aisle)
WHERE a.registration_number = 'HK-7870'
  AND ac.cabin_code = 'Y'
ON CONFLICT (aircraft_cabin_id, seat_row_number, seat_column_code) DO UPDATE
SET is_window = EXCLUDED.is_window,
    is_aisle = EXCLUDED.is_aisle,
    is_exit_row = EXCLUDED.is_exit_row,
    updated_at = now();

INSERT INTO public.aircraft_seat (aircraft_cabin_id, seat_row_number, seat_column_code, is_window, is_aisle, is_exit_row)
SELECT ac.aircraft_cabin_id, gs.row_no, col.seat_column_code, col.is_window, col.is_aisle, gs.row_no = 12
FROM public.aircraft_cabin ac
JOIN public.aircraft a
  ON a.aircraft_id = ac.aircraft_id
CROSS JOIN generate_series(5, 20) AS gs(row_no)
CROSS JOIN (
  VALUES
    ('A', true, false),
    ('B', false, false),
    ('C', false, true),
    ('D', false, true),
    ('E', true, false)
) AS col(seat_column_code, is_window, is_aisle)
WHERE a.registration_number = 'N803NV'
  AND ac.cabin_code = 'Y'
ON CONFLICT (aircraft_cabin_id, seat_row_number, seat_column_code) DO UPDATE
SET is_window = EXCLUDED.is_window,
    is_aisle = EXCLUDED.is_aisle,
    is_exit_row = EXCLUDED.is_exit_row,
    updated_at = now();

INSERT INTO public.maintenance_provider (address_id, provider_name, contact_name)
VALUES
  ('40000000-0000-0000-0000-000000000006'::uuid, 'AeroAndes MRO Bogota', 'Mauricio Cardenas'),
  ('40000000-0000-0000-0000-000000000003'::uuid, 'Atlantic TechOps Miami', 'Helen Parker')
ON CONFLICT (provider_name) DO UPDATE
SET address_id = EXCLUDED.address_id,
    contact_name = EXCLUDED.contact_name,
    updated_at = now();

INSERT INTO public.maintenance_event (
  maintenance_event_id,
  aircraft_id,
  maintenance_type_id,
  maintenance_provider_id,
  status_code,
  started_at,
  completed_at,
  notes
)
SELECT
  seed.maintenance_event_id,
  a.aircraft_id,
  mt.maintenance_type_id,
  mp.maintenance_provider_id,
  seed.status_code,
  seed.started_at,
  seed.completed_at,
  seed.notes
FROM (
  VALUES
    ('60000000-0000-0000-0000-000000000001'::uuid, 'HK-5500', 'LINE', 'AeroAndes MRO Bogota', 'COMPLETED', TIMESTAMPTZ '2026-03-09 22:10:00-05', TIMESTAMPTZ '2026-03-10 01:15:00-05', 'Inspeccion previa a operacion domestica.'),
    ('60000000-0000-0000-0000-000000000002'::uuid, 'HK-7870', 'A_CHECK', 'Atlantic TechOps Miami', 'COMPLETED', TIMESTAMPTZ '2026-03-08 23:30:00-05', TIMESTAMPTZ '2026-03-09 05:45:00-05', 'Revision de rutina para operacion internacional.')
  ) AS seed(maintenance_event_id, registration_number, type_code, provider_name, status_code, started_at, completed_at, notes)
JOIN public.aircraft a
  ON a.registration_number = seed.registration_number
JOIN public.maintenance_type mt
  ON mt.type_code = seed.type_code
LEFT JOIN public.maintenance_provider mp
  ON mp.provider_name = seed.provider_name
ON CONFLICT (maintenance_event_id) DO UPDATE
SET aircraft_id = EXCLUDED.aircraft_id,
    maintenance_type_id = EXCLUDED.maintenance_type_id,
    maintenance_provider_id = EXCLUDED.maintenance_provider_id,
    status_code = EXCLUDED.status_code,
    started_at = EXCLUDED.started_at,
    completed_at = EXCLUDED.completed_at,
    notes = EXCLUDED.notes,
    updated_at = now();

INSERT INTO public.fare_class (cabin_class_id, fare_class_code, fare_class_name, is_refundable_by_default)
SELECT cc.cabin_class_id, seed.fare_class_code, seed.fare_class_name, seed.is_refundable_by_default
FROM (
  VALUES
    ('J', 'JF', 'Business Flex', true),
    ('W', 'WF', 'Premium Flex', true),
    ('Y', 'YB', 'Economy Basic', false),
    ('Y', 'YF', 'Economy Flex', true)
) AS seed(class_code, fare_class_code, fare_class_name, is_refundable_by_default)
JOIN public.cabin_class cc
  ON cc.class_code = seed.class_code
ON CONFLICT (fare_class_code) DO UPDATE
SET cabin_class_id = EXCLUDED.cabin_class_id,
    fare_class_name = EXCLUDED.fare_class_name,
    is_refundable_by_default = EXCLUDED.is_refundable_by_default,
    updated_at = now();

INSERT INTO public.fare (
  airline_id,
  origin_airport_id,
  destination_airport_id,
  fare_class_id,
  currency_id,
  fare_code,
  base_amount,
  valid_from,
  valid_to,
  baggage_allowance_qty,
  change_penalty_amount,
  refund_penalty_amount
)
SELECT
  al.airline_id,
  ao.airport_id,
  ad.airport_id,
  fc.fare_class_id,
  cu.currency_id,
  seed.fare_code,
  seed.base_amount,
  seed.valid_from,
  seed.valid_to,
  seed.baggage_allowance_qty,
  seed.change_penalty_amount,
  seed.refund_penalty_amount
FROM (
  VALUES
    ('FLY', 'BOG', 'MAD', 'YF', 'USD', 'FLY-BOGMAD-YF-2026', 980.00::numeric, DATE '2026-01-01', DATE '2026-12-31', 1, 120.00::numeric, 180.00::numeric),
    ('FLY', 'BOG', 'MAD', 'JF', 'USD', 'FLY-BOGMAD-JF-2026', 2450.00::numeric, DATE '2026-01-01', DATE '2026-12-31', 2, 0.00::numeric, 150.00::numeric),
    ('FLY', 'BOG', 'MDE', 'YB', 'COP', 'FLY-BOGMDE-YB-2026', 310000.00::numeric, DATE '2026-01-01', DATE '2026-12-31', 1, 90000.00::numeric, 150000.00::numeric),
    ('FLY', 'BOG', 'MIA', 'JF', 'USD', 'FLY-BOGMIA-JF-2026', 1280.00::numeric, DATE '2026-01-01', DATE '2026-12-31', 2, 0.00::numeric, 200.00::numeric),
    ('FLY', 'BOG', 'MIA', 'YF', 'USD', 'FLY-BOGMIA-YF-2026', 620.00::numeric, DATE '2026-01-01', DATE '2026-12-31', 1, 90.00::numeric, 120.00::numeric)
  ) AS seed(airline_code, origin_iata, destination_iata, fare_class_code, currency_code, fare_code, base_amount, valid_from, valid_to, baggage_allowance_qty, change_penalty_amount, refund_penalty_amount)
JOIN public.airline al
  ON al.airline_code = seed.airline_code
JOIN public.airport ao
  ON ao.iata_code = seed.origin_iata
JOIN public.airport ad
  ON ad.iata_code = seed.destination_iata
JOIN public.fare_class fc
  ON fc.fare_class_code = seed.fare_class_code
JOIN public.currency cu
  ON cu.iso_currency_code = seed.currency_code
ON CONFLICT (fare_code) DO UPDATE
SET airline_id = EXCLUDED.airline_id,
    origin_airport_id = EXCLUDED.origin_airport_id,
    destination_airport_id = EXCLUDED.destination_airport_id,
    fare_class_id = EXCLUDED.fare_class_id,
    currency_id = EXCLUDED.currency_id,
    base_amount = EXCLUDED.base_amount,
    valid_from = EXCLUDED.valid_from,
    valid_to = EXCLUDED.valid_to,
    baggage_allowance_qty = EXCLUDED.baggage_allowance_qty,
    change_penalty_amount = EXCLUDED.change_penalty_amount,
    refund_penalty_amount = EXCLUDED.refund_penalty_amount,
    updated_at = now();

INSERT INTO public.flight (airline_id, aircraft_id, flight_status_id, flight_number, service_date)
SELECT al.airline_id, a.aircraft_id, fs.flight_status_id, seed.flight_number, seed.service_date
FROM (
  VALUES
    ('FLY', 'HK-7870', 'ARRIVED', 'FY210', DATE '2026-03-10'),
    ('FLY', 'HK-7870', 'ARRIVED', 'FY711', DATE '2026-03-10'),
    ('FLY', 'HK-5500', 'ARRIVED', 'FY101', DATE '2026-03-12'),
    ('FLY', 'HK-7870', 'ARRIVED', 'FY305', DATE '2026-03-15')
  ) AS seed(airline_code, registration_number, status_code, flight_number, service_date)
JOIN public.airline al
  ON al.airline_code = seed.airline_code
JOIN public.aircraft a
  ON a.registration_number = seed.registration_number
JOIN public.flight_status fs
  ON fs.status_code = seed.status_code
ON CONFLICT (airline_id, flight_number, service_date) DO UPDATE
SET aircraft_id = EXCLUDED.aircraft_id,
    flight_status_id = EXCLUDED.flight_status_id,
    updated_at = now();

INSERT INTO public.flight_segment (
  flight_segment_id,
  flight_id,
  origin_airport_id,
  destination_airport_id,
  segment_number,
  scheduled_departure_at,
  scheduled_arrival_at,
  actual_departure_at,
  actual_arrival_at
)
SELECT
  seed.flight_segment_id,
  f.flight_id,
  ao.airport_id,
  ad.airport_id,
  seed.segment_number,
  seed.scheduled_departure_at,
  seed.scheduled_arrival_at,
  seed.actual_departure_at,
  seed.actual_arrival_at
FROM (
  VALUES
    ('61000000-0000-0000-0000-000000000001'::uuid, 'FY210', DATE '2026-03-10', 'BOG', 'MIA', 1, TIMESTAMPTZ '2026-03-10 08:15:00-05', TIMESTAMPTZ '2026-03-10 12:30:00-04', TIMESTAMPTZ '2026-03-10 08:28:00-05', TIMESTAMPTZ '2026-03-10 12:41:00-04'),
    ('61000000-0000-0000-0000-000000000002'::uuid, 'FY711', DATE '2026-03-10', 'MIA', 'MAD', 1, TIMESTAMPTZ '2026-03-10 16:00:00-04', TIMESTAMPTZ '2026-03-11 05:45:00+01', TIMESTAMPTZ '2026-03-10 16:22:00-04', TIMESTAMPTZ '2026-03-11 05:58:00+01'),
    ('61000000-0000-0000-0000-000000000003'::uuid, 'FY101', DATE '2026-03-12', 'BOG', 'MDE', 1, TIMESTAMPTZ '2026-03-12 09:00:00-05', TIMESTAMPTZ '2026-03-12 10:00:00-05', TIMESTAMPTZ '2026-03-12 09:32:00-05', TIMESTAMPTZ '2026-03-12 10:34:00-05'),
    ('61000000-0000-0000-0000-000000000004'::uuid, 'FY305', DATE '2026-03-15', 'BOG', 'MIA', 1, TIMESTAMPTZ '2026-03-15 07:00:00-05', TIMESTAMPTZ '2026-03-15 11:15:00-04', TIMESTAMPTZ '2026-03-15 07:05:00-05', TIMESTAMPTZ '2026-03-15 11:12:00-04')
  ) AS seed(flight_segment_id, flight_number, service_date, origin_iata, destination_iata, segment_number, scheduled_departure_at, scheduled_arrival_at, actual_departure_at, actual_arrival_at)
JOIN public.flight f
  ON f.flight_number = seed.flight_number
 AND f.service_date = seed.service_date
JOIN public.airport ao
  ON ao.iata_code = seed.origin_iata
JOIN public.airport ad
  ON ad.iata_code = seed.destination_iata
ON CONFLICT (flight_segment_id) DO UPDATE
SET flight_id = EXCLUDED.flight_id,
    origin_airport_id = EXCLUDED.origin_airport_id,
    destination_airport_id = EXCLUDED.destination_airport_id,
    segment_number = EXCLUDED.segment_number,
    scheduled_departure_at = EXCLUDED.scheduled_departure_at,
    scheduled_arrival_at = EXCLUDED.scheduled_arrival_at,
    actual_departure_at = EXCLUDED.actual_departure_at,
    actual_arrival_at = EXCLUDED.actual_arrival_at,
    updated_at = now();

INSERT INTO public.flight_delay (
  flight_delay_id,
  flight_segment_id,
  delay_reason_type_id,
  reported_at,
  delay_minutes,
  notes
)
SELECT
  '62000000-0000-0000-0000-000000000001'::uuid,
  fs.flight_segment_id,
  dr.delay_reason_type_id,
  TIMESTAMPTZ '2026-03-12 08:20:00-05',
  32,
  'Demora operacional por ajuste final de tripulacion.'
FROM public.flight_segment fs
JOIN public.delay_reason_type dr
  ON dr.reason_code = 'CREW'
WHERE fs.flight_segment_id = '61000000-0000-0000-0000-000000000003'::uuid
ON CONFLICT (flight_delay_id) DO UPDATE
SET flight_segment_id = EXCLUDED.flight_segment_id,
    delay_reason_type_id = EXCLUDED.delay_reason_type_id,
    reported_at = EXCLUDED.reported_at,
    delay_minutes = EXCLUDED.delay_minutes,
    notes = EXCLUDED.notes,
    updated_at = now();

-- ============================================================
-- POLITICA DE CRONOLOGIA SINTETICA (IE-005 → Resuelto)
-- Ver docs/validacion/POLITICA_CRONOLOGIA_DATOS_SINTETICOS.md
--
-- Ventanas canonicas:
--   Epoch tarifario       : 2026-01-01
--   Vuelos historicos     : 2026-03-10 .. 2026-03-15  (todos ARRIVED)
--   Reservas emitidas     : 2026-03-05 .. 2026-03-12
--   Pagos y facturas      : mismo dia de reserva
--   Check-in              : 2 h antes de salida programada
--   Boarding              : 30 min antes de salida programada
--   Lealtad apertura      : 2022-01 .. 2024-01
--   Fecha base (hoy)      : 2026-03-19
--   Zona horaria default  : America/Bogota UTC-5
--   Miami en marzo        : EDT UTC-4  (cambio DST 08-mar-2026)
--   Madrid en marzo       : CET UTC+1
-- ============================================================

-- ============================================================
-- PERSONAS
-- Pasajeros: Ana Garcia (Gold), Carlos Mendoza (Regular),
--            Laura Torres (Silver)
-- Empleados: Diego Ramirez (SYS_ADMIN), Patricia Vargas (SALES_AGENT)
-- ============================================================

INSERT INTO public.person (
  person_id, person_type_id, nationality_country_id,
  first_name, last_name, birth_date, gender_code
)
SELECT
  seed.person_id,
  pt.person_type_id,
  c.country_id,
  seed.first_name,
  seed.last_name,
  seed.birth_date,
  seed.gender_code
FROM (
  VALUES
    ('10000000-0000-0000-0000-000000000001'::uuid, 'ADULT',    'CO', 'Ana',      'Garcia',   DATE '1988-07-14', 'F'),
    ('10000000-0000-0000-0000-000000000002'::uuid, 'ADULT',    'CO', 'Carlos',   'Mendoza',  DATE '1975-11-02', 'M'),
    ('10000000-0000-0000-0000-000000000003'::uuid, 'ADULT',    'CO', 'Laura',    'Torres',   DATE '1992-04-28', 'F'),
    ('10000000-0000-0000-0000-000000000004'::uuid, 'EMPLOYEE', 'CO', 'Diego',    'Ramirez',  DATE '1985-03-15', 'M'),
    ('10000000-0000-0000-0000-000000000005'::uuid, 'EMPLOYEE', 'CO', 'Patricia', 'Vargas',   DATE '1990-09-22', 'F')
) AS seed(person_id, type_code, country_code, first_name, last_name, birth_date, gender_code)
JOIN public.person_type pt ON pt.type_code = seed.type_code
JOIN public.country c      ON c.iso_alpha2  = seed.country_code
ON CONFLICT (person_id) DO UPDATE
SET first_name         = EXCLUDED.first_name,
    last_name          = EXCLUDED.last_name,
    updated_at         = now();

-- ============================================================
-- DOCUMENTOS DE IDENTIDAD
-- ============================================================

INSERT INTO public.person_document (
  person_document_id, person_id, document_type_id,
  issuing_country_id, document_number, issued_on, expires_on
)
SELECT
  seed.doc_id,
  p.person_id,
  dt.document_type_id,
  ic.country_id,
  seed.doc_number,
  seed.issued_on,
  seed.expires_on
FROM (
  VALUES
    ('11000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'PASS', 'CO', 'PA1234567',  DATE '2020-01-15', DATE '2030-01-14'),
    ('11000000-0000-0000-0000-000000000002'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'NID',  'CO', 'CC71234567', NULL,              NULL),
    ('11000000-0000-0000-0000-000000000003'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 'PASS', 'CO', 'PA9876543',  DATE '2019-06-20', DATE '2029-06-19'),
    ('11000000-0000-0000-0000-000000000004'::uuid, '10000000-0000-0000-0000-000000000004'::uuid, 'NID',  'CO', 'CC85432100', NULL,              NULL),
    ('11000000-0000-0000-0000-000000000005'::uuid, '10000000-0000-0000-0000-000000000005'::uuid, 'NID',  'CO', 'CC90112233', NULL,              NULL)
) AS seed(doc_id, person_id, type_code, country_code, doc_number, issued_on, expires_on)
JOIN public.person p          ON p.person_id   = seed.person_id
JOIN public.document_type dt  ON dt.type_code  = seed.type_code
JOIN public.country ic        ON ic.iso_alpha2 = seed.country_code
ON CONFLICT (person_document_id) DO UPDATE
SET document_number = EXCLUDED.document_number,
    updated_at      = now();

-- ============================================================
-- CONTACTOS
-- ============================================================

INSERT INTO public.person_contact (
  person_contact_id, person_id, contact_type_id, contact_value, is_primary
)
SELECT
  seed.contact_id,
  p.person_id,
  ct.contact_type_id,
  seed.contact_value,
  seed.is_primary
FROM (
  VALUES
    ('12000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'EMAIL',  'ana.garcia@email.co',      true),
    ('12000000-0000-0000-0000-000000000002'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'MOBILE', '+573001234567',             false),
    ('12000000-0000-0000-0000-000000000003'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'EMAIL',  'carlos.mendoza@email.co',  true),
    ('12000000-0000-0000-0000-000000000004'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'MOBILE', '+573107654321',             false),
    ('12000000-0000-0000-0000-000000000005'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 'EMAIL',  'laura.torres@email.co',    true),
    ('12000000-0000-0000-0000-000000000006'::uuid, '10000000-0000-0000-0000-000000000004'::uuid, 'EMAIL',  'diego.ramirez@fly.com',    true),
    ('12000000-0000-0000-0000-000000000007'::uuid, '10000000-0000-0000-0000-000000000005'::uuid, 'EMAIL',  'patricia.vargas@fly.com',  true)
) AS seed(contact_id, person_id, type_code, contact_value, is_primary)
JOIN public.person p         ON p.person_id  = seed.person_id
JOIN public.contact_type ct  ON ct.type_code = seed.type_code
ON CONFLICT (person_contact_id) DO UPDATE
SET contact_value = EXCLUDED.contact_value,
    updated_at    = now();

-- ============================================================
-- USER ACCOUNTS
-- password_hash: marcador controlado (bcrypt placeholder)
-- ============================================================

INSERT INTO public.user_account (
  user_account_id, person_id, user_status_id, username, password_hash
)
SELECT
  seed.user_id,
  p.person_id,
  us.user_status_id,
  seed.username,
  seed.password_hash
FROM (
  VALUES
    ('20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000004'::uuid, 'ACTIVE', 'diego.ramirez',   '$2b$12$canonicoplhd.sysadmin.000000000000'),
    ('20000000-0000-0000-0000-000000000002'::uuid, '10000000-0000-0000-0000-000000000005'::uuid, 'ACTIVE', 'patricia.vargas', '$2b$12$canonicoplhd.salesagent.0000000000')
) AS seed(user_id, person_id, status_code, username, password_hash)
JOIN public.person p          ON p.person_id    = seed.person_id
JOIN public.user_status us    ON us.status_code = seed.status_code
ON CONFLICT (user_account_id) DO UPDATE
SET username   = EXCLUDED.username,
    updated_at = now();

-- ============================================================
-- USER ROLES
-- SYS_ADMIN bootstrap (sin assigned_by); SALES_AGENT asignado por SYS_ADMIN
-- ============================================================

INSERT INTO public.user_role (
  user_role_id, user_account_id, security_role_id, assigned_at, assigned_by_user_id
)
SELECT
  seed.user_role_id,
  ua.user_account_id,
  sr.security_role_id,
  seed.assigned_at,
  ab.user_account_id
FROM (
  VALUES
    ('21000000-0000-0000-0000-000000000001'::uuid,
     '20000000-0000-0000-0000-000000000001'::uuid, 'SYS_ADMIN',
     TIMESTAMPTZ '2026-01-02 08:00:00-05', NULL::uuid),
    ('21000000-0000-0000-0000-000000000002'::uuid,
     '20000000-0000-0000-0000-000000000002'::uuid, 'SALES_AGENT',
     TIMESTAMPTZ '2026-01-05 09:00:00-05',
     '20000000-0000-0000-0000-000000000001'::uuid)
) AS seed(user_role_id, user_account_id, role_code, assigned_at, assigned_by_user_id)
JOIN public.user_account ua   ON ua.user_account_id = seed.user_account_id
JOIN public.security_role sr  ON sr.role_code        = seed.role_code
LEFT JOIN public.user_account ab ON ab.user_account_id = seed.assigned_by_user_id
ON CONFLICT (user_account_id, security_role_id) DO NOTHING;

-- ============================================================
-- LOYALTY PROGRAM + TIERS  (FLY Airlines)
-- ============================================================

INSERT INTO public.loyalty_program (
  loyalty_program_id, airline_id, default_currency_id,
  program_code, program_name, expiration_months
)
SELECT
  '30000000-0000-0000-0000-000000000001'::uuid,
  al.airline_id,
  cu.currency_id,
  'FLY_MILES',
  'FLY Miles Program',
  36
FROM public.airline al
JOIN public.currency cu ON cu.iso_currency_code = 'USD'
WHERE al.airline_code = 'FLY'
ON CONFLICT (airline_id, program_code) DO UPDATE
SET program_name      = EXCLUDED.program_name,
    expiration_months = EXCLUDED.expiration_months,
    updated_at        = now();

INSERT INTO public.loyalty_tier (
  loyalty_tier_id, loyalty_program_id,
  tier_code, tier_name, priority_level, required_miles
)
SELECT
  seed.tier_id,
  lp.loyalty_program_id,
  seed.tier_code,
  seed.tier_name,
  seed.priority_level,
  seed.required_miles
FROM (
  VALUES
    ('31000000-0000-0000-0000-000000000001'::uuid, 'BRONZE', 'Bronze',  1,     0),
    ('31000000-0000-0000-0000-000000000002'::uuid, 'SILVER', 'Silver',  2, 10000),
    ('31000000-0000-0000-0000-000000000003'::uuid, 'GOLD',   'Gold',    3, 50000)
) AS seed(tier_id, tier_code, tier_name, priority_level, required_miles)
JOIN public.loyalty_program lp ON lp.program_code = 'FLY_MILES'
ON CONFLICT (loyalty_program_id, tier_code) DO UPDATE
SET tier_name      = EXCLUDED.tier_name,
    priority_level = EXCLUDED.priority_level,
    required_miles = EXCLUDED.required_miles,
    updated_at     = now();

-- ============================================================
-- CUSTOMERS
-- ============================================================

INSERT INTO public.customer (
  customer_id, airline_id, person_id, customer_category_id, customer_since
)
SELECT
  seed.customer_id,
  al.airline_id,
  p.person_id,
  cc.customer_category_id,
  seed.customer_since
FROM (
  VALUES
    ('35000000-0000-0000-0000-000000000001'::uuid,
     '10000000-0000-0000-0000-000000000001'::uuid, 'FLY', 'GOLD', DATE '2022-05-10'),
    ('35000000-0000-0000-0000-000000000002'::uuid,
     '10000000-0000-0000-0000-000000000002'::uuid, 'FLY', 'REG',  DATE '2024-01-15'),
    ('35000000-0000-0000-0000-000000000003'::uuid,
     '10000000-0000-0000-0000-000000000003'::uuid, 'FLY', 'SILV', DATE '2023-08-01')
) AS seed(customer_id, person_id, airline_code, category_code, customer_since)
JOIN public.airline al           ON al.airline_code    = seed.airline_code
JOIN public.person p             ON p.person_id        = seed.person_id
JOIN public.customer_category cc ON cc.category_code  = seed.category_code
ON CONFLICT (airline_id, person_id) DO UPDATE
SET customer_category_id = EXCLUDED.customer_category_id,
    updated_at            = now();

-- ============================================================
-- LOYALTY ACCOUNTS + TIERS ACTIVOS + BENEFICIOS
-- ============================================================

INSERT INTO public.loyalty_account (
  loyalty_account_id, customer_id, loyalty_program_id,
  account_number, opened_at
)
SELECT
  seed.account_id,
  c.customer_id,
  lp.loyalty_program_id,
  seed.account_number,
  seed.opened_at
FROM (
  VALUES
    ('36000000-0000-0000-0000-000000000001'::uuid,
     '35000000-0000-0000-0000-000000000001'::uuid,
     'FLY_MILES', 'FLY-0001-ANA', TIMESTAMPTZ '2022-05-10 10:00:00-05'),
    ('36000000-0000-0000-0000-000000000002'::uuid,
     '35000000-0000-0000-0000-000000000002'::uuid,
     'FLY_MILES', 'FLY-0002-CAR', TIMESTAMPTZ '2024-01-15 10:00:00-05'),
    ('36000000-0000-0000-0000-000000000003'::uuid,
     '35000000-0000-0000-0000-000000000003'::uuid,
     'FLY_MILES', 'FLY-0003-LAU', TIMESTAMPTZ '2023-08-01 10:00:00-05')
) AS seed(account_id, customer_id, program_code, account_number, opened_at)
JOIN public.customer c            ON c.customer_id  = seed.customer_id
JOIN public.loyalty_program lp    ON lp.program_code = seed.program_code
ON CONFLICT (account_number) DO UPDATE
SET opened_at  = EXCLUDED.opened_at,
    updated_at = now();

INSERT INTO public.loyalty_account_tier (
  loyalty_account_tier_id, loyalty_account_id, loyalty_tier_id,
  assigned_at, expires_at
)
SELECT
  seed.lat_id,
  la.loyalty_account_id,
  lt.loyalty_tier_id,
  seed.assigned_at,
  seed.expires_at
FROM (
  VALUES
    ('37000000-0000-0000-0000-000000000001'::uuid,
     '36000000-0000-0000-0000-000000000001'::uuid, 'GOLD',
     TIMESTAMPTZ '2025-01-01 00:00:00-05', TIMESTAMPTZ '2026-12-31 23:59:59-05'),
    ('37000000-0000-0000-0000-000000000002'::uuid,
     '36000000-0000-0000-0000-000000000002'::uuid, 'BRONZE',
     TIMESTAMPTZ '2024-01-15 10:00:00-05', NULL),
    ('37000000-0000-0000-0000-000000000003'::uuid,
     '36000000-0000-0000-0000-000000000003'::uuid, 'SILVER',
     TIMESTAMPTZ '2024-06-01 00:00:00-05', TIMESTAMPTZ '2026-12-31 23:59:59-05')
) AS seed(lat_id, account_id, tier_code, assigned_at, expires_at)
JOIN public.loyalty_account la ON la.loyalty_account_id = seed.account_id
JOIN public.loyalty_tier lt    ON lt.tier_code           = seed.tier_code
  AND lt.loyalty_program_id = la.loyalty_program_id
ON CONFLICT (loyalty_account_id, assigned_at) DO NOTHING;

INSERT INTO public.customer_benefit (
  customer_benefit_id, customer_id, benefit_type_id,
  granted_at, expires_at, notes
)
SELECT
  seed.cb_id,
  c.customer_id,
  bt.benefit_type_id,
  seed.granted_at,
  seed.expires_at,
  seed.notes
FROM (
  VALUES
    ('38000000-0000-0000-0000-000000000001'::uuid,
     '35000000-0000-0000-0000-000000000001'::uuid, 'LOUNGE',
     TIMESTAMPTZ '2025-01-01 00:00:00-05', TIMESTAMPTZ '2026-12-31 23:59:59-05',
     'Beneficio nivel Gold - acceso lounge'),
    ('38000000-0000-0000-0000-000000000002'::uuid,
     '35000000-0000-0000-0000-000000000001'::uuid, 'PRIORITY',
     TIMESTAMPTZ '2025-01-01 00:00:00-05', TIMESTAMPTZ '2026-12-31 23:59:59-05',
     'Beneficio nivel Gold - abordaje prioritario'),
    ('38000000-0000-0000-0000-000000000003'::uuid,
     '35000000-0000-0000-0000-000000000003'::uuid, 'PRIORITY',
     TIMESTAMPTZ '2024-06-01 00:00:00-05', TIMESTAMPTZ '2026-12-31 23:59:59-05',
     'Beneficio nivel Silver - abordaje prioritario')
) AS seed(cb_id, customer_id, benefit_code, granted_at, expires_at, notes)
JOIN public.customer c        ON c.customer_id   = seed.customer_id
JOIN public.benefit_type bt   ON bt.benefit_code = seed.benefit_code
ON CONFLICT (customer_id, benefit_type_id, granted_at) DO NOTHING;

-- ============================================================
-- RESERVACIONES
-- RES-FY-001: Ana  BOG-MIA-MAD  Business  (FY210 + FY711)
-- RES-FY-002: Carlos BOG-MDE    Economy   (FY101)
-- RES-FY-003: Laura  BOG-MIA    Economy   (FY305)
-- ============================================================

INSERT INTO public.reservation (
  reservation_id, booked_by_customer_id, reservation_status_id,
  sale_channel_id, reservation_code, booked_at, expires_at, notes
)
SELECT
  seed.res_id,
  c.customer_id,
  rs.reservation_status_id,
  sc.sale_channel_id,
  seed.reservation_code,
  seed.booked_at,
  seed.expires_at,
  seed.notes
FROM (
  VALUES
    ('70000000-0000-0000-0000-000000000001'::uuid,
     '35000000-0000-0000-0000-000000000001'::uuid,
     'TICKETED', 'WEB',
     'RES-FY-001', TIMESTAMPTZ '2026-03-05 10:15:00-05', NULL::timestamptz,
     'Viaje BOG-MIA-MAD Business JF'),
    ('70000000-0000-0000-0000-000000000002'::uuid,
     '35000000-0000-0000-0000-000000000002'::uuid,
     'TICKETED', 'MOBILE_APP',
     'RES-FY-002', TIMESTAMPTZ '2026-03-10 07:00:00-05', NULL::timestamptz,
     'Vuelo domestico BOG-MDE Economy YB'),
    ('70000000-0000-0000-0000-000000000003'::uuid,
     '35000000-0000-0000-0000-000000000003'::uuid,
     'TICKETED', 'WEB',
     'RES-FY-003', TIMESTAMPTZ '2026-03-12 09:30:00-05', NULL::timestamptz,
     'Vuelo BOG-MIA Economy YF')
) AS seed(res_id, customer_id, status_code, channel_code,
          reservation_code, booked_at, expires_at, notes)
JOIN public.customer c                   ON c.customer_id    = seed.customer_id
JOIN public.reservation_status rs        ON rs.status_code   = seed.status_code
JOIN public.sale_channel sc              ON sc.channel_code  = seed.channel_code
ON CONFLICT (reservation_code) DO UPDATE
SET reservation_status_id = EXCLUDED.reservation_status_id,
    updated_at             = now();

-- ============================================================
-- PASAJEROS POR RESERVA
-- ============================================================

INSERT INTO public.reservation_passenger (
  reservation_passenger_id, reservation_id, person_id,
  passenger_sequence_no, passenger_type
)
SELECT
  seed.rp_id,
  r.reservation_id,
  p.person_id,
  seed.sequence_no,
  seed.passenger_type
FROM (
  VALUES
    ('71000000-0000-0000-0000-000000000001'::uuid,
     '70000000-0000-0000-0000-000000000001'::uuid,
     '10000000-0000-0000-0000-000000000001'::uuid, 1, 'ADULT'),
    ('71000000-0000-0000-0000-000000000002'::uuid,
     '70000000-0000-0000-0000-000000000002'::uuid,
     '10000000-0000-0000-0000-000000000002'::uuid, 1, 'ADULT'),
    ('71000000-0000-0000-0000-000000000003'::uuid,
     '70000000-0000-0000-0000-000000000003'::uuid,
     '10000000-0000-0000-0000-000000000003'::uuid, 1, 'ADULT')
) AS seed(rp_id, reservation_id, person_id, sequence_no, passenger_type)
JOIN public.reservation r  ON r.reservation_id = seed.reservation_id
JOIN public.person p       ON p.person_id       = seed.person_id
ON CONFLICT (reservation_id, person_id) DO NOTHING;

-- ============================================================
-- VENTAS
-- ============================================================

INSERT INTO public.sale (
  sale_id, reservation_id, currency_id,
  sale_code, sold_at, external_reference
)
SELECT
  seed.sale_id,
  r.reservation_id,
  cu.currency_id,
  seed.sale_code,
  seed.sold_at,
  seed.external_reference
FROM (
  VALUES
    ('72000000-0000-0000-0000-000000000001'::uuid,
     '70000000-0000-0000-0000-000000000001'::uuid,
     'USD', 'SAL-20260305-001', TIMESTAMPTZ '2026-03-05 10:20:00-05', 'EXT-REF-001'),
    ('72000000-0000-0000-0000-000000000002'::uuid,
     '70000000-0000-0000-0000-000000000002'::uuid,
     'COP', 'SAL-20260310-001', TIMESTAMPTZ '2026-03-10 07:05:00-05', 'EXT-REF-002'),
    ('72000000-0000-0000-0000-000000000003'::uuid,
     '70000000-0000-0000-0000-000000000003'::uuid,
     'USD', 'SAL-20260312-001', TIMESTAMPTZ '2026-03-12 09:35:00-05', 'EXT-REF-003')
) AS seed(sale_id, reservation_id, currency_code, sale_code, sold_at, external_reference)
JOIN public.reservation r   ON r.reservation_id       = seed.reservation_id
JOIN public.currency cu     ON cu.iso_currency_code   = seed.currency_code
ON CONFLICT (sale_code) DO UPDATE
SET sold_at    = EXCLUDED.sold_at,
    updated_at = now();

-- ============================================================
-- TIQUETES
-- ============================================================

INSERT INTO public.ticket (
  ticket_id, sale_id, reservation_passenger_id,
  fare_id, ticket_status_id, ticket_number, issued_at
)
SELECT
  seed.ticket_id,
  sl.sale_id,
  rp.reservation_passenger_id,
  f.fare_id,
  ts.ticket_status_id,
  seed.ticket_number,
  seed.issued_at
FROM (
  VALUES
    ('73000000-0000-0000-0000-000000000001'::uuid,
     '72000000-0000-0000-0000-000000000001'::uuid,
     '71000000-0000-0000-0000-000000000001'::uuid,
     'FLY-BOGMAD-JF-2026', 'FLOWN', 'TKT-FY-00001',
     TIMESTAMPTZ '2026-03-05 10:22:00-05'),
    ('73000000-0000-0000-0000-000000000002'::uuid,
     '72000000-0000-0000-0000-000000000002'::uuid,
     '71000000-0000-0000-0000-000000000002'::uuid,
     'FLY-BOGMDE-YB-2026', 'FLOWN', 'TKT-FY-00002',
     TIMESTAMPTZ '2026-03-10 07:07:00-05'),
    ('73000000-0000-0000-0000-000000000003'::uuid,
     '72000000-0000-0000-0000-000000000003'::uuid,
     '71000000-0000-0000-0000-000000000003'::uuid,
     'FLY-BOGMIA-YF-2026', 'FLOWN', 'TKT-FY-00003',
     TIMESTAMPTZ '2026-03-12 09:37:00-05')
) AS seed(ticket_id, sale_id, rp_id, fare_code, status_code, ticket_number, issued_at)
JOIN public.sale sl                  ON sl.sale_id                    = seed.sale_id
JOIN public.reservation_passenger rp ON rp.reservation_passenger_id  = seed.rp_id
JOIN public.fare f                   ON f.fare_code                   = seed.fare_code
JOIN public.ticket_status ts         ON ts.status_code                = seed.status_code
ON CONFLICT (ticket_number) DO UPDATE
SET ticket_status_id = EXCLUDED.ticket_status_id,
    updated_at       = now();

-- ============================================================
-- SEGMENTOS DE TIQUETE
-- Ana   : FY210 BOG-MIA (seg 001) + FY711 MIA-MAD (seg 002)
-- Carlos: FY101 BOG-MDE (seg 003)
-- Laura : FY305 BOG-MIA (seg 004)
-- ============================================================

INSERT INTO public.ticket_segment (
  ticket_segment_id, ticket_id, flight_segment_id,
  segment_sequence_no, fare_basis_code
)
SELECT
  seed.ts_id,
  t.ticket_id,
  seed.flight_segment_id,
  seed.seq_no,
  seed.fare_basis_code
FROM (
  VALUES
    ('74000000-0000-0000-0000-000000000001'::uuid,
     '73000000-0000-0000-0000-000000000001'::uuid,
     '61000000-0000-0000-0000-000000000001'::uuid, 1, 'JF'),
    ('74000000-0000-0000-0000-000000000002'::uuid,
     '73000000-0000-0000-0000-000000000001'::uuid,
     '61000000-0000-0000-0000-000000000002'::uuid, 2, 'JF'),
    ('74000000-0000-0000-0000-000000000003'::uuid,
     '73000000-0000-0000-0000-000000000002'::uuid,
     '61000000-0000-0000-0000-000000000003'::uuid, 1, 'YB'),
    ('74000000-0000-0000-0000-000000000004'::uuid,
     '73000000-0000-0000-0000-000000000003'::uuid,
     '61000000-0000-0000-0000-000000000004'::uuid, 1, 'YF')
) AS seed(ts_id, ticket_id, flight_segment_id, seq_no, fare_basis_code)
JOIN public.ticket t  ON t.ticket_id = seed.ticket_id
ON CONFLICT (ticket_segment_id) DO NOTHING;

-- ============================================================
-- ASIGNACION DE ASIENTOS
-- Ana   FY210: HK-7870 J fila 1  col A
-- Ana   FY711: HK-7870 J fila 2  col A
-- Carlos FY101: HK-5500 Y fila 12 col A (exit row)
-- Laura FY305: HK-7870 Y fila 15 col A (exit row)
-- ============================================================

INSERT INTO public.seat_assignment (
  seat_assignment_id, ticket_segment_id, flight_segment_id,
  aircraft_seat_id, assigned_at, assignment_source
)
SELECT
  seed.sa_id,
  seed.ticket_segment_id,
  seed.flight_segment_id,
  acs.aircraft_seat_id,
  seed.assigned_at,
  seed.assignment_source
FROM (
  VALUES
    ('75000000-0000-0000-0000-000000000001'::uuid,
     '74000000-0000-0000-0000-000000000001'::uuid,
     '61000000-0000-0000-0000-000000000001'::uuid,
     'HK-7870', 'J', 1, 'A',
     TIMESTAMPTZ '2026-03-05 10:25:00-05', 'CUSTOMER'),
    ('75000000-0000-0000-0000-000000000002'::uuid,
     '74000000-0000-0000-0000-000000000002'::uuid,
     '61000000-0000-0000-0000-000000000002'::uuid,
     'HK-7870', 'J', 2, 'A',
     TIMESTAMPTZ '2026-03-05 10:25:00-05', 'CUSTOMER'),
    ('75000000-0000-0000-0000-000000000003'::uuid,
     '74000000-0000-0000-0000-000000000003'::uuid,
     '61000000-0000-0000-0000-000000000003'::uuid,
     'HK-5500', 'Y', 12, 'A',
     TIMESTAMPTZ '2026-03-10 07:10:00-05', 'AUTO'),
    ('75000000-0000-0000-0000-000000000004'::uuid,
     '74000000-0000-0000-0000-000000000004'::uuid,
     '61000000-0000-0000-0000-000000000004'::uuid,
     'HK-7870', 'Y', 15, 'A',
     TIMESTAMPTZ '2026-03-12 09:40:00-05', 'CUSTOMER')
) AS seed(sa_id, ticket_segment_id, flight_segment_id,
          reg_no, cabin_code, row_no, col_code, assigned_at, assignment_source)
JOIN public.aircraft a        ON a.registration_number  = seed.reg_no
JOIN public.aircraft_cabin acb ON acb.aircraft_id       = a.aircraft_id
                               AND acb.cabin_code        = seed.cabin_code
JOIN public.aircraft_seat acs  ON acs.aircraft_cabin_id = acb.aircraft_cabin_id
                               AND acs.seat_row_number   = seed.row_no
                               AND acs.seat_column_code  = seed.col_code
ON CONFLICT (ticket_segment_id) DO NOTHING;

-- ============================================================
-- EQUIPAJE
-- Carlos FY101: 22.5 kg checked, CLAIMED
-- Laura  FY305: 20.0 kg checked, CLAIMED
-- ============================================================

INSERT INTO public.baggage (
  baggage_id, ticket_segment_id,
  baggage_tag, baggage_type, baggage_status, weight_kg, checked_at
)
SELECT
  seed.bag_id,
  ts.ticket_segment_id,
  seed.baggage_tag,
  seed.baggage_type,
  seed.baggage_status,
  seed.weight_kg,
  seed.checked_at
FROM (
  VALUES
    ('76000000-0000-0000-0000-000000000001'::uuid,
     '74000000-0000-0000-0000-000000000003'::uuid,
     'BAG-FY101-001', 'CHECKED', 'CLAIMED', 22.50::numeric,
     TIMESTAMPTZ '2026-03-12 07:45:00-05'),
    ('76000000-0000-0000-0000-000000000002'::uuid,
     '74000000-0000-0000-0000-000000000004'::uuid,
     'BAG-FY305-001', 'CHECKED', 'CLAIMED', 20.00::numeric,
     TIMESTAMPTZ '2026-03-15 05:20:00-05')
) AS seed(bag_id, ticket_segment_id, baggage_tag,
          baggage_type, baggage_status, weight_kg, checked_at)
JOIN public.ticket_segment ts ON ts.ticket_segment_id = seed.ticket_segment_id
ON CONFLICT (baggage_tag) DO NOTHING;

-- ============================================================
-- CHECK-IN
-- ============================================================

INSERT INTO public.check_in (
  check_in_id, ticket_segment_id, check_in_status_id,
  boarding_group_id, checked_in_by_user_id, checked_in_at
)
SELECT
  seed.ci_id,
  ts.ticket_segment_id,
  cs.check_in_status_id,
  bg.boarding_group_id,
  ua.user_account_id,
  seed.checked_in_at
FROM (
  VALUES
    ('77000000-0000-0000-0000-000000000001'::uuid,
     '74000000-0000-0000-0000-000000000001'::uuid,
     'COMPLETED', 'PRIORITY',
     '20000000-0000-0000-0000-000000000002'::uuid,
     TIMESTAMPTZ '2026-03-10 06:00:00-05'),
    ('77000000-0000-0000-0000-000000000002'::uuid,
     '74000000-0000-0000-0000-000000000002'::uuid,
     'COMPLETED', 'PRIORITY',
     '20000000-0000-0000-0000-000000000002'::uuid,
     TIMESTAMPTZ '2026-03-10 14:00:00-04'),
    ('77000000-0000-0000-0000-000000000003'::uuid,
     '74000000-0000-0000-0000-000000000003'::uuid,
     'COMPLETED', 'B',
     '20000000-0000-0000-0000-000000000002'::uuid,
     TIMESTAMPTZ '2026-03-12 07:30:00-05'),
    ('77000000-0000-0000-0000-000000000004'::uuid,
     '74000000-0000-0000-0000-000000000004'::uuid,
     'COMPLETED', 'A',
     '20000000-0000-0000-0000-000000000002'::uuid,
     TIMESTAMPTZ '2026-03-15 05:00:00-05')
) AS seed(ci_id, ticket_segment_id, status_code,
          group_code, user_id, checked_in_at)
JOIN public.ticket_segment ts    ON ts.ticket_segment_id = seed.ticket_segment_id
JOIN public.check_in_status cs   ON cs.status_code       = seed.status_code
JOIN public.boarding_group bg    ON bg.group_code         = seed.group_code
LEFT JOIN public.user_account ua ON ua.user_account_id   = seed.user_id
ON CONFLICT (ticket_segment_id) DO NOTHING;

-- ============================================================
-- BOARDING PASSES
-- ============================================================

INSERT INTO public.boarding_pass (
  boarding_pass_id, check_in_id,
  boarding_pass_code, barcode_value, issued_at
)
SELECT
  seed.bp_id,
  ci.check_in_id,
  seed.bp_code,
  seed.barcode_value,
  seed.issued_at
FROM (
  VALUES
    ('78000000-0000-0000-0000-000000000001'::uuid,
     '77000000-0000-0000-0000-000000000001'::uuid,
     'BP-FY210-ANA-01', 'BCFY210ANA20260310J1A',
     TIMESTAMPTZ '2026-03-10 06:02:00-05'),
    ('78000000-0000-0000-0000-000000000002'::uuid,
     '77000000-0000-0000-0000-000000000002'::uuid,
     'BP-FY711-ANA-01', 'BCFY711ANA20260310J2A',
     TIMESTAMPTZ '2026-03-10 14:02:00-04'),
    ('78000000-0000-0000-0000-000000000003'::uuid,
     '77000000-0000-0000-0000-000000000003'::uuid,
     'BP-FY101-CAR-01', 'BCFY101CAR20260312Y12A',
     TIMESTAMPTZ '2026-03-12 07:32:00-05'),
    ('78000000-0000-0000-0000-000000000004'::uuid,
     '77000000-0000-0000-0000-000000000004'::uuid,
     'BP-FY305-LAU-01', 'BCFY305LAU20260315Y15A',
     TIMESTAMPTZ '2026-03-15 05:02:00-05')
) AS seed(bp_id, check_in_id, bp_code, barcode_value, issued_at)
JOIN public.check_in ci ON ci.check_in_id = seed.check_in_id
ON CONFLICT (boarding_pass_code) DO NOTHING;

-- ============================================================
-- VALIDACIONES DE BOARDING
-- FY210 → puerta A12 BOG
-- FY711 → puerta D14 MIA
-- FY101 → puerta A18 BOG
-- FY305 → puerta A12 BOG
-- ============================================================

INSERT INTO public.boarding_validation (
  boarding_validation_id, boarding_pass_id, boarding_gate_id,
  validated_by_user_id, validated_at, validation_result, notes
)
SELECT
  seed.bv_id,
  bp.boarding_pass_id,
  bg.boarding_gate_id,
  ua.user_account_id,
  seed.validated_at,
  seed.validation_result,
  seed.notes
FROM (
  VALUES
    ('79000000-0000-0000-0000-000000000001'::uuid,
     '78000000-0000-0000-0000-000000000001'::uuid,
     'BOG', 'T1', 'A12',
     '20000000-0000-0000-0000-000000000002'::uuid,
     TIMESTAMPTZ '2026-03-10 07:55:00-05', 'APPROVED',
     'Pasajero validado puerta A12 BOG.'),
    ('79000000-0000-0000-0000-000000000002'::uuid,
     '78000000-0000-0000-0000-000000000002'::uuid,
     'MIA', 'D', 'D14',
     '20000000-0000-0000-0000-000000000002'::uuid,
     TIMESTAMPTZ '2026-03-10 15:45:00-04', 'APPROVED',
     'Pasajero validado puerta D14 MIA.'),
    ('79000000-0000-0000-0000-000000000003'::uuid,
     '78000000-0000-0000-0000-000000000003'::uuid,
     'BOG', 'T1', 'A18',
     '20000000-0000-0000-0000-000000000002'::uuid,
     TIMESTAMPTZ '2026-03-12 08:45:00-05', 'APPROVED',
     'Pasajero validado puerta A18 BOG.'),
    ('79000000-0000-0000-0000-000000000004'::uuid,
     '78000000-0000-0000-0000-000000000004'::uuid,
     'BOG', 'T1', 'A12',
     '20000000-0000-0000-0000-000000000002'::uuid,
     TIMESTAMPTZ '2026-03-15 06:45:00-05', 'APPROVED',
     'Pasajero validado puerta A12 BOG.')
) AS seed(bv_id, bp_id, airport_iata, terminal_code, gate_code,
          user_id, validated_at, validation_result, notes)
JOIN public.boarding_pass bp   ON bp.boarding_pass_id  = seed.bp_id
JOIN public.airport ap         ON ap.iata_code          = seed.airport_iata
JOIN public.terminal t         ON t.airport_id          = ap.airport_id
                               AND t.terminal_code       = seed.terminal_code
JOIN public.boarding_gate bg   ON bg.terminal_id        = t.terminal_id
                               AND bg.gate_code          = seed.gate_code
LEFT JOIN public.user_account ua ON ua.user_account_id = seed.user_id
ON CONFLICT (boarding_validation_id) DO NOTHING;

-- ============================================================
-- PAGOS
-- Ana   : USD 2842.00  (2450 tarifa + 294 airport + 98 security)
-- Carlos: COP 359600   (310000 + 37200 + 12400)
-- Laura : USD 719.20   (620 + 74.40 + 24.80)
-- ============================================================

INSERT INTO public.payment (
  payment_id, sale_id, payment_status_id, payment_method_id,
  currency_id, payment_reference, amount, authorized_at
)
SELECT
  seed.payment_id,
  s.sale_id,
  ps.payment_status_id,
  pm.payment_method_id,
  cu.currency_id,
  seed.payment_reference,
  seed.amount,
  seed.authorized_at
FROM (
  VALUES
    ('80000000-0000-0000-0000-000000000001'::uuid,
     '72000000-0000-0000-0000-000000000001'::uuid,
     'CAPTURED', 'CREDIT_CARD', 'USD',
     'PAY-20260305-001', 2842.00::numeric,
     TIMESTAMPTZ '2026-03-05 10:21:00-05'),
    ('80000000-0000-0000-0000-000000000002'::uuid,
     '72000000-0000-0000-0000-000000000002'::uuid,
     'CAPTURED', 'DEBIT_CARD', 'COP',
     'PAY-20260310-001', 359600.00::numeric,
     TIMESTAMPTZ '2026-03-10 07:06:00-05'),
    ('80000000-0000-0000-0000-000000000003'::uuid,
     '72000000-0000-0000-0000-000000000003'::uuid,
     'CAPTURED', 'CREDIT_CARD', 'USD',
     'PAY-20260312-001', 719.20::numeric,
     TIMESTAMPTZ '2026-03-12 09:36:00-05')
) AS seed(payment_id, sale_id, status_code, method_code,
          currency_code, payment_reference, amount, authorized_at)
JOIN public.sale s             ON s.sale_id              = seed.sale_id
JOIN public.payment_status ps  ON ps.status_code         = seed.status_code
JOIN public.payment_method pm  ON pm.method_code         = seed.method_code
JOIN public.currency cu        ON cu.iso_currency_code   = seed.currency_code
ON CONFLICT (payment_reference) DO UPDATE
SET amount     = EXCLUDED.amount,
    updated_at = now();

-- ============================================================
-- TRANSACCIONES DE PAGO (AUTH + CAPTURE)
-- ============================================================

INSERT INTO public.payment_transaction (
  payment_transaction_id, payment_id,
  transaction_reference, transaction_type,
  transaction_amount, processed_at, provider_message
)
SELECT
  seed.pt_id,
  p.payment_id,
  seed.tx_ref,
  seed.tx_type,
  seed.tx_amount,
  seed.processed_at,
  seed.provider_message
FROM (
  VALUES
    ('81000000-0000-0000-0000-000000000001'::uuid,
     '80000000-0000-0000-0000-000000000001'::uuid,
     'TXN-20260305-AUTH-001', 'AUTH', 2842.00::numeric,
     TIMESTAMPTZ '2026-03-05 10:21:05-05',
     'Autorizacion aprobada por banco emisor.'),
    ('81000000-0000-0000-0000-000000000002'::uuid,
     '80000000-0000-0000-0000-000000000001'::uuid,
     'TXN-20260305-CAP-001', 'CAPTURE', 2842.00::numeric,
     TIMESTAMPTZ '2026-03-05 10:21:30-05',
     'Captura confirmada.'),
    ('81000000-0000-0000-0000-000000000003'::uuid,
     '80000000-0000-0000-0000-000000000002'::uuid,
     'TXN-20260310-CAP-001', 'CAPTURE', 359600.00::numeric,
     TIMESTAMPTZ '2026-03-10 07:06:10-05',
     'Debito inmediato procesado.'),
    ('81000000-0000-0000-0000-000000000004'::uuid,
     '80000000-0000-0000-0000-000000000003'::uuid,
     'TXN-20260312-AUTH-001', 'AUTH', 719.20::numeric,
     TIMESTAMPTZ '2026-03-12 09:36:05-05',
     'Autorizacion aprobada.'),
    ('81000000-0000-0000-0000-000000000005'::uuid,
     '80000000-0000-0000-0000-000000000003'::uuid,
     'TXN-20260312-CAP-001', 'CAPTURE', 719.20::numeric,
     TIMESTAMPTZ '2026-03-12 09:36:25-05',
     'Captura confirmada.')
) AS seed(pt_id, payment_id, tx_ref, tx_type,
          tx_amount, processed_at, provider_message)
JOIN public.payment p ON p.payment_id = seed.payment_id
ON CONFLICT (transaction_reference) DO NOTHING;

-- ============================================================
-- FACTURAS
-- ============================================================

INSERT INTO public.invoice (
  invoice_id, sale_id, invoice_status_id, currency_id,
  invoice_number, issued_at, due_at, notes
)
SELECT
  seed.inv_id,
  s.sale_id,
  ist.invoice_status_id,
  cu.currency_id,
  seed.invoice_number,
  seed.issued_at,
  seed.due_at,
  seed.notes
FROM (
  VALUES
    ('82000000-0000-0000-0000-000000000001'::uuid,
     '72000000-0000-0000-0000-000000000001'::uuid,
     'PAID', 'USD', 'INV-FY-2026-0001',
     TIMESTAMPTZ '2026-03-05 10:22:00-05',
     TIMESTAMPTZ '2026-03-05 10:22:00-05',
     'Venta Business JF BOG-MIA-MAD'),
    ('82000000-0000-0000-0000-000000000002'::uuid,
     '72000000-0000-0000-0000-000000000002'::uuid,
     'PAID', 'COP', 'INV-FY-2026-0002',
     TIMESTAMPTZ '2026-03-10 07:07:00-05',
     TIMESTAMPTZ '2026-03-10 07:07:00-05',
     'Venta Economy YB BOG-MDE'),
    ('82000000-0000-0000-0000-000000000003'::uuid,
     '72000000-0000-0000-0000-000000000003'::uuid,
     'PAID', 'USD', 'INV-FY-2026-0003',
     TIMESTAMPTZ '2026-03-12 09:38:00-05',
     TIMESTAMPTZ '2026-03-12 09:38:00-05',
     'Venta Economy YF BOG-MIA')
) AS seed(inv_id, sale_id, status_code, currency_code,
          invoice_number, issued_at, due_at, notes)
JOIN public.sale s             ON s.sale_id              = seed.sale_id
JOIN public.invoice_status ist ON ist.status_code        = seed.status_code
JOIN public.currency cu        ON cu.iso_currency_code   = seed.currency_code
ON CONFLICT (invoice_number) DO UPDATE
SET invoice_status_id = EXCLUDED.invoice_status_id,
    updated_at        = now();

-- ============================================================
-- LINEAS DE FACTURA
-- Estructura: linea 1 = tarifa base (sin impuesto)
--             linea 2 = tasa aeroportuaria 12 %
--             linea 3 = tasa de seguridad   4 %
-- ============================================================

INSERT INTO public.invoice_line (
  invoice_line_id, invoice_id, tax_id,
  line_number, line_description, quantity, unit_price
)
SELECT
  seed.il_id,
  inv.invoice_id,
  tx.tax_id,
  seed.line_number,
  seed.line_description,
  seed.quantity,
  seed.unit_price
FROM (
  VALUES
    ('83000000-0000-0000-0000-000000000001'::uuid,
     '82000000-0000-0000-0000-000000000001'::uuid, NULL,
     1, 'Tarifa base Business JF BOG-MAD',
     1.00::numeric, 2450.00::numeric),
    ('83000000-0000-0000-0000-000000000002'::uuid,
     '82000000-0000-0000-0000-000000000001'::uuid, 'AIRPORT_FEE',
     2, 'Tasa aeroportuaria 12 %',
     1.00::numeric, 294.00::numeric),
    ('83000000-0000-0000-0000-000000000003'::uuid,
     '82000000-0000-0000-0000-000000000001'::uuid, 'SECURITY_FEE',
     3, 'Tasa de seguridad 4 %',
     1.00::numeric, 98.00::numeric),
    ('83000000-0000-0000-0000-000000000004'::uuid,
     '82000000-0000-0000-0000-000000000002'::uuid, NULL,
     1, 'Tarifa base Economy YB BOG-MDE',
     1.00::numeric, 310000.00::numeric),
    ('83000000-0000-0000-0000-000000000005'::uuid,
     '82000000-0000-0000-0000-000000000002'::uuid, 'AIRPORT_FEE',
     2, 'Tasa aeroportuaria 12 %',
     1.00::numeric, 37200.00::numeric),
    ('83000000-0000-0000-0000-000000000006'::uuid,
     '82000000-0000-0000-0000-000000000002'::uuid, 'SECURITY_FEE',
     3, 'Tasa de seguridad 4 %',
     1.00::numeric, 12400.00::numeric),
    ('83000000-0000-0000-0000-000000000007'::uuid,
     '82000000-0000-0000-0000-000000000003'::uuid, NULL,
     1, 'Tarifa base Economy YF BOG-MIA',
     1.00::numeric, 620.00::numeric),
    ('83000000-0000-0000-0000-000000000008'::uuid,
     '82000000-0000-0000-0000-000000000003'::uuid, 'AIRPORT_FEE',
     2, 'Tasa aeroportuaria 12 %',
     1.00::numeric, 74.40::numeric),
    ('83000000-0000-0000-0000-000000000009'::uuid,
     '82000000-0000-0000-0000-000000000003'::uuid, 'SECURITY_FEE',
     3, 'Tasa de seguridad 4 %',
     1.00::numeric, 24.80::numeric)
) AS seed(il_id, invoice_id, tax_code,
          line_number, line_description, quantity, unit_price)
JOIN public.invoice inv    ON inv.invoice_id = seed.invoice_id
LEFT JOIN public.tax tx    ON tx.tax_code    = seed.tax_code
ON CONFLICT (invoice_id, line_number) DO UPDATE
SET line_description = EXCLUDED.line_description,
    quantity         = EXCLUDED.quantity,
    unit_price       = EXCLUDED.unit_price,
    updated_at       = now();

-- ============================================================
-- TRANSACCIONES DE MILLAS
-- Ana   : +3000 FY210 BOG-MIA Business  (al arribo)
-- Ana   : +5200 FY711 MIA-MAD Business  (al arribo)
-- Carlos: +420  FY101 BOG-MDE Economy   (al arribo)
-- Laura : +1500 FY305 BOG-MIA Economy   (al arribo)
-- ============================================================

INSERT INTO public.miles_transaction (
  miles_transaction_id, loyalty_account_id,
  transaction_type, miles_delta,
  occurred_at, reference_code, notes
)
SELECT
  seed.mt_id,
  la.loyalty_account_id,
  seed.tx_type,
  seed.miles_delta,
  seed.occurred_at,
  seed.reference_code,
  seed.notes
FROM (
  VALUES
    ('84000000-0000-0000-0000-000000000001'::uuid,
     '36000000-0000-0000-0000-000000000001'::uuid,
     'EARN', 3000,
     TIMESTAMPTZ '2026-03-10 12:41:00-04',
     'TKT-FY-00001-SEG1',
     'Millas acumuladas FY210 BOG-MIA Business J'),
    ('84000000-0000-0000-0000-000000000002'::uuid,
     '36000000-0000-0000-0000-000000000001'::uuid,
     'EARN', 5200,
     TIMESTAMPTZ '2026-03-11 05:58:00+01',
     'TKT-FY-00001-SEG2',
     'Millas acumuladas FY711 MIA-MAD Business J'),
    ('84000000-0000-0000-0000-000000000003'::uuid,
     '36000000-0000-0000-0000-000000000002'::uuid,
     'EARN', 420,
     TIMESTAMPTZ '2026-03-12 10:34:00-05',
     'TKT-FY-00002-SEG1',
     'Millas acumuladas FY101 BOG-MDE Economy YB'),
    ('84000000-0000-0000-0000-000000000004'::uuid,
     '36000000-0000-0000-0000-000000000003'::uuid,
     'EARN', 1500,
     TIMESTAMPTZ '2026-03-15 11:12:00-04',
     'TKT-FY-00003-SEG1',
     'Millas acumuladas FY305 BOG-MIA Economy YF')
) AS seed(mt_id, account_id, tx_type, miles_delta,
          occurred_at, reference_code, notes)
JOIN public.loyalty_account la ON la.loyalty_account_id = seed.account_id
ON CONFLICT (miles_transaction_id) DO NOTHING;

COMMIT;
