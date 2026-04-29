# Plan Detallado de Generacion de Datos Semilla

## 1. Objetivo de esta fase

Generar datos semilla reales y consistentes para el esquema `FLY v2-estable-3fn`, con dos metas simultaneas:

- validar el flujo operacional completo con inserts reales
- preparar una base volumetrica para analisis, explicacion y refactor posterior

Esta fase ya no es solo documental. Su producto esperado es una base de datos poblada, reproducible y verificable.

## 2. Alcance funcional que debe quedar cubierto

El seed debe poblar y poder demostrar, como minimo, este flujo de negocio:

1. `person`
2. `customer`
3. `reservation`
4. `reservation_passenger`
5. `sale`
6. `ticket`
7. `ticket_segment`
8. `check_in`
9. `boarding_pass`
10. `payment`
11. `payment_transaction`
12. `invoice`
13. `invoice_line`

Coberturas complementarias obligatorias:

- `person_document`
- `person_contact`
- `fare`
- `flight`
- `flight_segment`
- `seat_assignment`
- `baggage`
- `boarding_validation`
- `refund`
- `miles_transaction`

## 3. Modelo de ejecucion

La generacion de datos se divide en tres capas ejecutables:

### 3.1 Seed canonico

Proposito:

- sembrar catalogos
- sembrar geografia y estructura base del dominio
- crear entidades maestras minimas
- habilitar un flujo real completo de punta a punta

Meta:

- no buscar volumen alto aun
- buscar consistencia total y trazabilidad

Archivo objetivo:

- `db/seeds/00_seed_canonico.sql`

### 3.2 Seed volumetrico

Proposito:

- escalar el esquema a volumen util
- alcanzar al menos `1000` registros en entidades maestras, transaccionales y puente donde eso sea semanticamente valido
- conservar integridad, cronologia y unicidad

Archivo objetivo:

- `db/seeds/01_seed_volumetrico.sql`

### 3.3 Validacion post-seed

Proposito:

- confirmar integridad
- medir cobertura
- detectar vacios o incoherencias
- exponer excepciones controladas

Archivo objetivo:

- `db/seeds/99_validaciones_post_seed.sql`

## 4. Criterios de realismo

### 4.1 Reglas de identidad

- nombres y apellidos plausibles por pais o region
- documentos con formatos distintos por tipo
- fechas de nacimiento coherentes con edad laboral o de pasajero
- contactos con emails y telefonos consistentes

### 4.2 Reglas comerciales

- cada `reservation` debe tener codigo unico y uno o mas pasajeros
- cada `sale` debe corresponder a una reserva existente
- cada `ticket` debe pertenecer a un pasajero de esa reserva
- cada `payment` y `invoice` deben referenciar la misma venta

### 4.3 Reglas operacionales

- vuelos con aeronaves y aerolinea validos
- segmentos con origen y destino distintos
- asientos existentes en la cabina de la aeronave usada
- check-in solo despues de ticket y antes de boarding
- boarding validation solo sobre boarding pass existente

### 4.4 Reglas temporales

- `reservation.booked_at` < `sale.sold_at`
- `ticket.issued_at` >= `sale.sold_at`
- `check_in` debe ocurrir antes de la salida del segmento
- `payment.authorized_at` no puede ser anterior a `sale.sold_at`
- `invoice.issued_at` no puede ser anterior al pago o a la venta segun el escenario definido
- `refund` solo si existe pago previo

## 5. Politica de volumen

### 5.1 Regla general

El objetivo `1000+` se aplica de forma estricta a:

- entidades maestras operativas
- entidades transaccionales
- entidades puente y detalle de negocio

### 5.2 Excepcion controlada

No se inflaran artificialmente catalogos cerrados cuyo significado se degrade al hacerlo.

Ejemplos:

- `reservation_status`
- `ticket_status`
- `payment_method`
- `payment_status`
- `flight_status`
- `cabin_class`
- `continent`
- `document_type`

Estas tablas se pueblan con set canonico realista y quedan explicitamente exceptuadas.

## 6. Metas de volumen propuestas

### 6.1 Catalogos y referencia

- catalogos cerrados: volumen realista, no forzado
- geografia: volumen funcional suficiente para variedad regional

### 6.2 Maestras operativas

- `person`: 6000
- `customer`: 4000
- `user_account`: 500
- `airline`: 8
- `airport`: 120
- `aircraft_manufacturer`: 12
- `aircraft_model`: 40
- `aircraft`: 180
- `flight`: 2500
- `flight_segment`: 6000
- `fare`: 5000

### 6.3 Transaccionales

- `reservation`: 5000
- `reservation_passenger`: 8500
- `sale`: 5000
- `ticket`: 8500
- `ticket_segment`: 14000
- `seat_assignment`: 9000
- `baggage`: 7000
- `check_in`: 8000
- `boarding_pass`: 8000
- `boarding_validation`: 7800
- `payment`: 5000
- `payment_transaction`: 5500
- `invoice`: 5000
- `invoice_line`: 15000
- `refund`: 400

### 6.4 Lealtad y mantenimiento

- `loyalty_program`: 8
- `loyalty_account`: 2500
- `loyalty_account_tier`: 3000
- `miles_transaction`: 12000
- `maintenance_provider`: 40
- `maintenance_event`: 2500

## 7. Camino critico de implementacion

### Tramo 1. Seed canonico minimo viable

Debe resolverse primero:

- catalogos base
- geografia base
- airline, airport, aircraft y flight
- person, customer y reservation
- sale, ticket, payment e invoice

Resultado esperado:

- una historia de negocio completa y funcional

### Tramo 2. Consolidacion del flujo critico

Debe resolverse en segundo lugar:

- `reservation_passenger`
- `ticket_segment`
- `seat_assignment`
- `check_in`
- `boarding_pass`
- `boarding_validation`
- `invoice_line`

Resultado esperado:

- un flujo de viaje y cobro navegable de punta a punta

### Tramo 3. Expansión volumetrica

Debe resolverse solo despues del seed canonico:

- crecimiento masivo por lotes
- control de unicidad
- control de distribucion temporal
- distribucion por aerolinea, aeropuerto y ruta

Resultado esperado:

- volumen util para pruebas, demostracion y futuras refactorizaciones

## 8. Controles obligatorios

### 8.1 Tecnicos

- ejecucion en PostgreSQL 16 sin errores
- integridad FK completa
- ausencia de colisiones `UNIQUE`
- respeto a `CHECK`
- scripts reejecutables sobre base limpia

### 8.2 Funcionales

- existencia de reservas multi-pasajero
- existencia de tickets multi-segmento
- existencia de vuelos con demoras
- existencia de pagos y facturas vinculados correctamente
- existencia de equipaje, check-in y boarding

### 8.3 Arquitectonicos

- no introducir redundancias nuevas
- no inflar catalogos cerrados sin justificacion
- no romper narrativa 3FN
- documentar cada excepcion o simplificacion

## 9. Riesgos a controlar durante la generacion

- inflado artificial de catalogos
- cronologia imposible entre venta, ticket, pago e invoice
- asientos asignados a aeronaves o segmentos incompatibles
- pasajeros sin documentos o contactos minimos
- payment e invoice desacoplados de la venta real
- mezcla de narrativa historica con la version vigente

## 10. Entregables concretos de esta fase

1. `db/seeds/00_seed_canonico.sql` implementado
2. `db/seeds/01_seed_volumetrico.sql` implementado
3. `db/seeds/99_validaciones_post_seed.sql` ejecutado
4. evidencia de conteos y cobertura del flujo critico
5. actualizacion del seguimiento de inconsistencias

## 11. Orden de trabajo inmediato

1. cerrar matriz de orden de carga
2. definir set canonico de catalogos y geografia
3. implementar `00_seed_canonico.sql`
4. validar un caso completo `reservation -> sale -> ticket -> payment -> invoice`
5. construir el seed volumetrico por lotes
6. ejecutar validacion final de volumen y coherencia
