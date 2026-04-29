# Arquitectura de Seeds - Sistema FLY

## Objetivo

Preparar una estrategia reproducible para cargar datos semilla sobre `FLY v2-estable-3fn` sin romper integridad referencial, manteniendo dos capas de seed:

- `00_seed_canonico.sql`: datos base semanticamente correctos
- `01_seed_volumetrico.sql`: crecimiento controlado para volumen operativo
- `99_validaciones_post_seed.sql`: chequeos obligatorios de conteo y consistencia

## Principios

- primero se asegura la verdad del dominio, luego el volumen
- ningun script debe invalidar PK, FK, UNIQUE ni CHECK
- los datos deben parecer plausibles para una aerolinea comercial
- los seeds deben poder ejecutarse en un contenedor limpio
- cualquier excepcion al umbral de `1000` filas debe quedar documentada

## Clasificacion de Tablas

### Referencia fija o controlada

Estas tablas no deben inflarse ciegamente porque representan catalogos cerrados o semiestables:

- `person_type`
- `document_type`
- `contact_type`
- `user_status`
- `customer_category`
- `benefit_type`
- `boarding_group`
- `check_in_status`
- `payment_status`
- `payment_method`
- `reservation_status`
- `sale_channel`
- `ticket_status`
- `flight_status`
- `delay_reason_type`
- `maintenance_type`
- `fare_class`
- `cabin_class`
- `invoice_status`
- `currency`
- `tax`
- `time_zone`
- `continent`

### Maestras operativas

Estas tablas si admiten crecimiento fuerte con realismo:

- `person`
- `customer`
- `user_account`
- `aircraft`
- `airport`
- `address`
- `city`
- `country`
- `state_province`
- `district`
- `aircraft_model`
- `flight`
- `flight_segment`
- `fare`

### Transaccionales y de detalle

Estas tablas deben absorber el volumen principal:

- `reservation`
- `reservation_passenger`
- `sale`
- `ticket`
- `ticket_segment`
- `seat_assignment`
- `check_in`
- `boarding_pass`
- `boarding_validation`
- `payment`
- `payment_transaction`
- `invoice`
- `invoice_line`
- `refund`
- `baggage`
- `miles_transaction`
- `maintenance_event`
- `flight_delay`

## Orden de Carga Recomendado

1. Catalogos base
2. Geografia y ubicacion
3. Personas y contactos
4. Seguridad
5. Cliente y lealtad
6. Aerolinea, aeropuertos y flota
7. Tarifas, rutas y vuelos
8. Reservas, ventas, tickets y equipaje
9. Check-in y boarding
10. Pagos, facturacion, impuestos y reembolsos
11. Validaciones post-seed

## Politica de Volumen

- `seed canonico`: prioriza consistencia del negocio
- `seed volumetrico`: apunta a `>=1000` filas en maestras, transaccionales y tablas puente
- `catalogos cerrados`: se tratan como excepcion controlada si el inflado compromete el significado funcional

## Ejecucion Sugerida en Contenedor

```powershell
docker exec -i fly-bd-pg-5435 psql -U fly_admin -d flydb -v ON_ERROR_STOP=1 -f /workspace/seeds/00_seed_canonico.sql
docker exec -i fly-bd-pg-5435 psql -U fly_admin -d flydb -v ON_ERROR_STOP=1 -f /workspace/seeds/01_seed_volumetrico.sql
docker exec -i fly-bd-pg-5435 psql -U fly_admin -d flydb -v ON_ERROR_STOP=1 -f /workspace/seeds/99_validaciones_post_seed.sql
```

## Bootstrap deterministico

- la carga de `DDL + seeds + validaciones` se ejecuta de forma deterministica desde:
- `infra/docker/recrear_instalacion_limpia.ps1`
- este enfoque evita depender del `initdb` automatico para poblar datos.

Para recrear una instalacion local limpia desde cero:

```powershell
Set-Location infra\docker
.\recrear_instalacion_limpia.ps1
```

## Estado Actual

- el contenedor de trabajo ya esta disponible en `localhost:5435`
- el DDL canonico ya se inicializa correctamente desde `db/ddl/modelo_postgresql.sql`
- `00_seed_canonico.sql` ya puebla catalogos raiz, permisos, roles, monedas, impuestos y husos horarios
- `01_seed_volumetrico.sql` ya implementa una expansion inicial (vuelos futuros Q2, personas/clientes, reservas, pagos y facturas volumetricas)
- la siguiente etapa es escalar cobertura de volumetria (`>=1000` donde aplique) y extender el flujo de viaje volumetrico (seat_assignment, baggage, check_in, boarding, refund y mantenimiento)
