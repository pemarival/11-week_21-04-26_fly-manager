# Modelo Canonico de Trabajo

## 1. Estado del documento

Estado: borrador arquitectonico de trabajo

Fuente:

- `app/landing/index.html`
- `architecture/canvas/canvas_arquitectura.html`
- hallazgos de `docs/arquitectura/BASELINE_ARQUITECTONICO.md`
- conflictos registrados en `docs/arquitectura/MATRIZ_CONSISTENCIA_INICIAL.md`

Uso:

Este documento gobierna la siguiente fase de construccion del DDL. No reemplaza la validacion tecnica final; la prepara.

## 2. Alcance canonico propuesto

Se propone tomar como objetivo del release:

- un modelo estable de `v2`
- con separacion explicita entre "implementado" y "roadmap"
- orientado a sistema integral de aerolinea comercial

Queda fuera del alcance del release base:

- soft delete completo
- auditoria total transversal
- particionamiento fisico avanzado
- refactor DDD por bounded contexts
- cualquier elemento marcado como propuesta v3

## 3. Nombre y version de trabajo

Regla provisional:

- nombre funcional del sistema: `Sistema FLY`
- no debe usarse marca previa en el release final salvo definicion formal en contrario
- version objetivo del paquete: `v2 estable`

## 4. Flujo canonico del negocio

### 4.1 Principio rector

La raiz del flujo comercial debe ser `reservation (PNR)` y no `sale`.

Razon:

- permite manejar multiples pasajeros
- permite manejar multiples segmentos por ticket
- desacopla la confirmacion comercial de la emision fisica/logica del ticket

### 4.2 Flujo propuesto

1. `person`
2. `customer`
3. `reservation`
4. `reservation_passenger`
5. `ticket`
6. `ticket_flight_segment`
7. `seat_assignment`
8. `check_in`
9. `boarding_pass`
10. `payment`
11. `payment_transaction`
12. `invoice`

### 4.3 Reglas canonicas del flujo

- una reserva puede contener uno o varios pasajeros
- un ticket pertenece al flujo de una reserva
- un ticket puede cubrir uno o varios segmentos
- la relacion ticket-segmento debe modelarse mediante tabla puente
- la asignacion de asiento debe quedar ligada al contexto de ticket y segmento
- check-in y boarding deben depender del contexto de viaje, no solo del pasajero
- pago e invoice deben quedar trazables al evento comercial correspondiente

## 5. Modulos canonicos propuestos

### 5.1 Identity

Responsabilidad:

- identidad base de personas y contacto

Entidades nucleares:

- `person`
- `document_identity`
- `contact_information`
- `type_document`
- `type_person`

### 5.2 Security

Responsabilidad:

- autenticacion, autorizacion y estados de acceso

Entidades nucleares:

- `user_account`
- `role`
- `permission`
- `user_role`
- `role_permission`
- `status_user`

### 5.3 Customer

Responsabilidad:

- cliente comercial y programa de lealtad

Entidades nucleares:

- `customer`
- `loyalty_program`
- `loyalty_account`
- `miles_transaction`
- `customer_benefit`
- `type_customer_category`
- `type_benefit`

### 5.4 Aircraft

Responsabilidad:

- flota, configuracion de cabina, asientos y mantenimiento

Entidades nucleares:

- `aircraft`
- `aircraft_model`
- `cabin_configuration`
- `seat`
- `maintenance_history`
- `maintenance_provider`
- tablas tipo y catalogos de mantenimiento

### 5.5 Airport

Responsabilidad:

- infraestructura aeroportuaria

Entidades nucleares:

- `airport`
- `terminal`
- `boarding_gate`
- `runway`
- `airport_regulation`

### 5.6 Flight

Responsabilidad:

- operacion del vuelo y sus segmentos

Entidades nucleares:

- `flight`
- `flight_segment`
- `flight_delay_reason`
- `status_flight`
- `type_delay_reason`

### 5.7 Sales and Reservation

Responsabilidad:

- reserva, tarifa, emision y elementos comerciales del viaje

Entidades nucleares propuestas:

- `reservation`
- `reservation_passenger`
- `sale`
- `ticket`
- `ticket_flight_segment`
- `fare`
- `fare_class`
- `seat_assignment`
- `baggage`
- tablas de estado y tipo necesarias

Regla:

`sale` se considera evento comercial, no raiz del dominio.

### 5.8 Boarding

Responsabilidad:

- check-in, pase de abordar y validacion de embarque

Entidades nucleares:

- `check_in`
- `boarding_pass`
- `boarding_group`
- `boarding_validation`

### 5.9 Payment

Responsabilidad:

- cobro, transaccion y devolucion

Entidades nucleares:

- `payment`
- `payment_transaction`
- `refund`
- `status_payment`
- `type_payment_method`

### 5.10 Billing

Responsabilidad:

- factura, detalle, impuestos y moneda

Entidades nucleares:

- `invoice`
- `invoice_detail`
- `tax`
- `exchange_rate`
- `currency`

### 5.11 Geolocation

Responsabilidad:

- jerarquia geografica normalizada

Entidades nucleares propuestas:

- `continent`
- `country`
- `state`
- `city`
- `district`
- `address`
- `coordinate`
- `time_zone`

Regla:

la tabla generica `geolocation` no debe incluirse si duplica una jerarquia ya normalizada. Solo debe existir si resuelve un caso concreto no redundante.

### 5.12 Airline

Responsabilidad:

- maestro institucional de la aerolinea

Entidad nuclear:

- `airline`

## 6. Reglas de modelado obligatorias

- PKs consistentes en todas las tablas
- convencion uniforme de nombres para PK y FK
- tablas puente explicitas para relaciones N:M
- catalogos normalizados para estados, tipos y clasificaciones
- no usar texto libre para dominios controlados si existe catalogo
- no mezclar roadmap con implementado en el DDL base
- todo conteo publico debe salir del esquema final ejecutable

## 7. Decisiones de datos recomendadas para el DDL

- separar maestros, catalogos y transaccionales
- usar restricciones `UNIQUE` en identificadores naturales cuando aplique
- usar `CHECK` para reglas basicas de integridad
- indexar todas las FK criticas y claves de busqueda operativa
- comentar las tablas y relaciones de negocio mas sensibles
- dejar espacio para auditoria futura sin contaminar el release base

## 8. Decisiones pendientes antes de congelar el DDL

- confirmar si `sale` permanece como tabla separada o se absorbe por `reservation` e `invoice`
- confirmar la estructura exacta de `reservation_passenger`
- confirmar si `baggage` vive en Sales o Boarding
- confirmar si `boarding_validation` debe quedar en el modelo base
- confirmar si `country_code` y `currency_code` seran FK estrictas a catalogos
- confirmar el patron de PK a utilizar de forma transversal

## 9. Definicion de cierre para pasar a DDL

La fase de modelo canonico se considera cerrada cuando:

- el flujo raiz ya no presenta contradicciones
- la relacion ticket-segmento esta cerrada
- cada modulo tiene responsabilidad y limites claros
- toda entidad visible en la landing pertenece al modelo oficial o se elimina
- los elementos v3 quedan fuera del DDL base o marcados solo como roadmap
