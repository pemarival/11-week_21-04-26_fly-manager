# Modelo Documentado

## Sistema FLY

Version propuesta de trabajo: `v2-estable-3fn`

Objetivo:

Definir una version del modelo relacional enfocada en consistencia arquitectonica, normalizacion hasta 3FN y trazabilidad entre negocio, documentacion y DDL.

## Principios del modelo

- `reservation` es la raiz del flujo comercial
- `ticket` se relaciona con `flight_segment` por tabla puente
- estados, tipos y categorias se separan en catalogos
- geografia se modela por jerarquia normalizada
- no se almacenan totales derivados en tablas transaccionales base

## Modulos

### 1. Airline

- `airline`

### 2. Identity

- `person_type`
- `document_type`
- `contact_type`
- `person`
- `person_document`
- `person_contact`

### 3. Security

- `user_status`
- `security_role`
- `security_permission`
- `user_account`
- `user_role`
- `role_permission`

### 4. Customer

- `customer_category`
- `benefit_type`
- `loyalty_program`
- `loyalty_tier`
- `customer`
- `loyalty_account`
- `miles_transaction`
- `customer_benefit`

### 5. Geolocation

- `time_zone`
- `continent`
- `country`
- `state_province`
- `city`
- `district`
- `address`

### 6. Airport

- `airport`
- `terminal`
- `boarding_gate`
- `runway`
- `airport_regulation`

### 7. Aircraft

- `aircraft_manufacturer`
- `aircraft_model`
- `cabin_class`
- `aircraft`
- `aircraft_cabin`
- `aircraft_seat`
- `maintenance_provider`
- `maintenance_type`
- `maintenance_event`

### 8. Flight

- `flight_status`
- `delay_reason_type`
- `flight`
- `flight_segment`
- `flight_delay`

### 9. Sales and Reservation

- `reservation_status`
- `sale_channel`
- `fare_class`
- `fare`
- `ticket_status`
- `reservation`
- `reservation_passenger`
- `sale`
- `ticket`
- `ticket_segment`
- `seat_assignment`
- `baggage`

### 10. Boarding

- `boarding_group`
- `check_in_status`
- `check_in`
- `boarding_pass`
- `boarding_validation`

### 11. Payment

- `payment_status`
- `payment_method`
- `payment`
- `payment_transaction`
- `refund`

### 12. Billing

- `currency`
- `exchange_rate`
- `tax`
- `invoice_status`
- `invoice`
- `invoice_line`

## Flujo principal

1. `person`
2. `customer`
3. `reservation`
4. `reservation_passenger`
5. `sale`
6. `ticket`
7. `ticket_segment`
8. `flight_segment`
9. `seat_assignment`
10. `check_in`
11. `boarding_pass`
12. `payment`
13. `invoice`

## Decisiones clave de arquitectura de datos

- se elimina la dependencia conceptual de `sale` como raiz
- se evita la tabla generica `geolocation` para no duplicar jerarquia
- se centraliza la moneda en `currency`
- se modela la facturacion sin totales derivados persistidos
- se mantiene una separacion clara entre evento comercial, evento de pago y documento fiscal

## Archivos relacionados

- DDL: `db/ddl/modelo_postgresql.sql`
- normalizacion: `docs/datos/NORMALIZACION_3FN.md`
- baseline: `docs/arquitectura/BASELINE_ARQUITECTONICO.md`
- modelo canonico: `docs/datos/MODELO_CANONICO.md`
