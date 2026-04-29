# Matriz Operativa de Orden de Carga para Seeds

## Fuente

Matriz derivada de las llaves foraneas reales del esquema cargado en PostgreSQL 16 sobre `localhost:5435`.

## Principio

Las tablas deben poblarse por capas de dependencia para evitar violaciones de FK y para preservar un flujo funcional de negocio.

## Capas de carga

### Nivel 0. Raices sin dependencias de entrada

- `aircraft_manufacturer`
- `benefit_type`
- `boarding_group`
- `cabin_class`
- `check_in_status`
- `contact_type`
- `continent`
- `currency`
- `customer_category`
- `delay_reason_type`
- `document_type`
- `flight_status`
- `invoice_status`
- `maintenance_type`
- `payment_method`
- `payment_status`
- `person_type`
- `reservation_status`
- `sale_channel`
- `security_permission`
- `security_role`
- `tax`
- `ticket_status`
- `time_zone`
- `user_status`

### Nivel 1. Referencia de segundo orden

- `aircraft_model`
- `country`
- `exchange_rate`
- `fare_class`
- `role_permission`

### Nivel 2. Identidad y estructura base

- `airline`
- `person`
- `state_province`

### Nivel 3. Maestras principales

- `aircraft`
- `city`
- `customer`
- `loyalty_program`
- `person_contact`
- `person_document`
- `user_account`

### Nivel 4. Nucleo comercial inicial

- `aircraft_cabin`
- `customer_benefit`
- `district`
- `flight`
- `loyalty_account`
- `loyalty_tier`
- `reservation`
- `user_role`

### Nivel 5. Habilitadores del flujo

- `address`
- `aircraft_seat`
- `loyalty_account_tier`
- `miles_transaction`
- `reservation_passenger`
- `sale`

### Nivel 6. Operacion comercial y soporte

- `airport`
- `invoice`
- `maintenance_provider`
- `payment`

### Nivel 7. Nucleo operacional extendido

- `airport_regulation`
- `fare`
- `flight_segment`
- `invoice_line`
- `maintenance_event`
- `payment_transaction`
- `refund`
- `runway`
- `terminal`

### Nivel 8. Dependencia de viaje

- `boarding_gate`
- `flight_delay`
- `ticket`

### Nivel 9. Viaje emitido

- `ticket_segment`

### Nivel 10. Ejecucion de viaje

- `baggage`
- `check_in`
- `seat_assignment`

### Nivel 11. Evidencia de abordaje

- `boarding_pass`

### Nivel 12. Validacion final

- `boarding_validation`

## Flujo critico minimo que debe poblarse primero

1. `person`
2. `customer`
3. `reservation`
4. `reservation_passenger`
5. `sale`
6. `ticket`
7. `ticket_segment`
8. `payment`
9. `payment_transaction`
10. `invoice`
11. `invoice_line`

Extensiones funcionales del flujo:

- `check_in`
- `boarding_pass`
- `boarding_validation`
- `seat_assignment`
- `baggage`

## Estrategia de implementacion recomendada

### Lote A. Catalogos y geografia

Poblar:

- niveles `0` a `3`

Objetivo:

- habilitar identidades, paises, monedas, estados y usuarios

### Lote B. Maestras del dominio

Poblar:

- niveles `4` a `7` sin transacciones masivas

Objetivo:

- habilitar aerolinea, flota, aeropuertos, tarifas y rutas

### Lote C. Flujo comercial canonico

Poblar:

- `reservation`
- `reservation_passenger`
- `sale`
- `ticket`
- `payment`
- `payment_transaction`
- `invoice`
- `invoice_line`

Objetivo:

- validar un caso funcional completo

### Lote D. Flujo operacional canonico

Poblar:

- `ticket_segment`
- `seat_assignment`
- `baggage`
- `check_in`
- `boarding_pass`
- `boarding_validation`

Objetivo:

- validar la ejecucion del viaje

### Lote E. Expansion volumetrica

Poblar:

- crecimiento progresivo por lotes en maestras y transaccionales

Objetivo:

- alcanzar umbrales de volumen sin perder trazabilidad

## Reglas adicionales

- `sale` nunca se crea sin `reservation`
- `ticket` nunca se crea sin `sale`, `fare` y `reservation_passenger`
- `ticket_segment` nunca se crea sin `ticket` y `flight_segment`
- `payment` e `invoice` deben derivar de la misma `sale`
- `boarding_validation` es la ultima evidencia del flujo y nunca debe sembrarse de forma aislada
