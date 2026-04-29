# Politica de Cronologia de Datos Sinteticos

## Objetivo

Establecer la ventana temporal canonica y las reglas de precedencia de eventos
para todos los datos sinteticos del proyecto FLY. Esta politica cierra IE-005
y es prerequisito obligatorio del seed volumetrico.

## Fecha base del sistema

| Variable | Valor |
|---|---|
| Fecha base (hoy simulado) | 2026-03-19 |
| Epoch tarifario | 2026-01-01 |
| Zona horaria de referencia | America/Bogota (UTC-5) |
| Zona de persistencia | TIMESTAMPTZ con offset explicito en cada valor |

## Ventanas temporales canonicas

### Vuelos historicos (seed canonico)

Todos los vuelos del seed canonico tienen `status = ARRIVED` y fechas pasadas:

| Vuelo | Fecha de operacion | Ruta |
|---|---|---|
| FY210 | 2026-03-10 | BOG → MIA |
| FY711 | 2026-03-10 | MIA → MAD |
| FY101 | 2026-03-12 | BOG → MDE |
| FY305 | 2026-03-15 | BOG → MIA |

### Ciclo de vida de una reserva canonica

```
Reserva creada       → entre 3 y 14 dias antes del vuelo
Sale creada          → mismo timestamp +5 min que la reserva
Ticket emitido       → mismo timestamp +2 min que la sale
Pago autorizado      → mismo timestamp +1 min que la sale
Pago capturado       → mismo timestamp +25 seg que la autorizacion
Factura emitida      → mismo timestamp +2 min que el ticket
Check-in             → entre 2 h y 24 h antes de la salida programada
Boarding pass        → 2 min despues del check-in
Validacion boarding  → entre 30 min y 5 min antes de la salida programada
Miles acreditadas    → al momento del arribo real (actual_arrival_at)
```

### Apertura de cuentas de lealtad

- Rango permitido: entre 6 y 48 meses antes de la fecha base.
- Minimo: 2024-01-01
- Maximo: 2025-09-19

### Asignacion de tier de lealtad

- El tier activo debe tener `assigned_at` anterior a la primera reserva del cliente.
- `expires_at` de tiers activos: fin del ano en curso (2026-12-31 23:59:59-05).

### Tasas de cambio

- `effective_date = 2026-03-01` para el seed canonico.
- El seed volumetrico puede agregar fechas adicionales sin sobrescribir las canonicas.

## Restricciones de consistencia cronologica

1. `scheduled_departure_at` < `actual_departure_at` solo si hay demora.
2. `actual_departure_at` < `actual_arrival_at` siempre.
3. `booked_at` < `issued_at` (ticket).
4. `authorized_at` (payment) <= `issued_at` (ticket).
5. `authorized_at` < `checked_in_at`.
6. `checked_in_at` < `issued_at` (boarding_pass).
7. `issued_at` (boarding_pass) < `validated_at` (boarding_validation).
8. `validated_at` < `scheduled_departure_at` del segmento.
9. `occurred_at` (miles) = `actual_arrival_at` del segmento correspondiente.

## Huso horario por aeropuerto

| IATA | Ciudad | Offset UTC |
|---|---|---|
| BOG | Bogota | -05:00 |
| MDE | Rionegro | -05:00 |
| MIA | Miami | -04:00 (EDT vigente en marzo) |
| MAD | Madrid | +01:00 (CET vigente en marzo) |
| MEX | Mexico City | -06:00 |

> Nota: en marzo de 2026 Miami opera en EDT (UTC-4) y Madrid en CET (UTC+1).
> El cambio de horario en Estados Unidos ocurre el segundo domingo de marzo.
> En 2026 eso corresponde al 08 de marzo, por lo que los vuelos del 10/03 en
> adelante ya usan UTC-4 en Miami.

## Aplicacion en el seed volumetrico

- Vuelos futuros (seed volumetrico): `service_date` entre 2026-04-01 y 2026-06-30.
- Reservas futuras: `booked_at` entre 2026-01-01 y 2026-03-18.
- Vuelos en estado SCHEDULED o DEPARTED para fechas > 2026-03-19.
- Vuelos en estado ARRIVED para fechas <= 2026-03-19.

## Estado del hallazgo

| ID | Estado anterior | Estado nuevo | Fecha de cierre |
|---|---|---|---|
| IE-005 | Abierto | Resuelto | 2026-03-19 |
