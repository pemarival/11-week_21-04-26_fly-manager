# Evidencia de Baseline Performance Local (2026-03-19)

## Objetivo

Medir una linea base de performance local sobre consultas operativas reales de
FLY Manager, usando EXPLAIN ANALYZE con buffers para lectura, joins criticos y
una prueba de escritura segura sobre tabla temporal.

## Contexto de ejecucion

- Fecha de ejecucion: 2026-03-19 21:25:08 -05:00
- Contenedor: fly-bd-pg-5435
- Base medida: flydb
- Warmup previo: True

## Resumen observado

| metric | value |
| --- | --- |
| queries_measured | 6 |
| queries_failed | 0 |
| warmup_enabled | True |
| dataset_reference_reservation_rows | 1223 |
| dataset_reference_ticket_rows | 1223 |

## Resultados por consulta

| metric_name | execution_ms | planning_ms | threshold_ms | actual_rows | shared_hit_blocks | shared_read_blocks | shared_written_blocks | status | note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| flight_board_search | 0.246 | 0.881 | 20 | 100 | 24 | 0 | 0 | OK | Lectura operativa de vuelos por fecha con join de aeropuertos |
| customer_itinerary_join | 0.69 | 3.874 | 45 | 6 | 126 | 0 | 0 | OK | Join critico de reserva, venta, ticket, segmento y vuelo |
| financial_reconciliation_join | 1.76 | 1.126 | 45 | 300 | 128 | 0 | 0 | OK | Conciliacion de venta, pago, transaccion e invoice |
| loyalty_ledger_customer | 0.604 | 0.96 | 25 | 6 | 38 | 0 | 0 | OK | Ledger de millas por cliente con join de persona |
| boarding_flow_join | 2.15 | 5.161 | 35 | 200 | 93 | 0 | 0 | OK | Join de check-in, boarding pass, validation y vuelo |
| temp_write_select_into | 1.018 | 0.042 | 25 | 1000 | 0 | 0 | 0 | OK | Write baseline seguro en tabla temporal de sesion |

## Resultado

- Estado general: BASELINE OK
- Consultas evaluadas: 6
- Consultas fuera de umbral: 0
