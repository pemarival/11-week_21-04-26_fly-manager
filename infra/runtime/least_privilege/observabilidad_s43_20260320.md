# Evidencia de Observabilidad Local (2026-03-19)

## Objetivo

Capturar una fotografia minima de salud operativa de PostgreSQL local para
seguimiento de capacidad, locks, actividad y crecimiento.

## Contexto de ejecucion

- Fecha de ejecucion: 2026-04-28 13:48:49 -05:00
- Contenedor: fly-bd-pg-5435
- Base primaria: flydb
- Base secundaria: flydb_restore_validation
- Login operativo AUDIT: fly_local_audit
- Umbral long query: 60 segundos

## Resumen observado

| metric | value |
| --- | --- |
| primary_db_size_pretty | 20 MB |
| secondary_db_size_pretty | N/A |
| public_tables | 78 |
| active_connections | 1 |
| idle_in_transaction | 0 |
| waiting_locks | 0 |
| long_running_queries_gt_60s | 0 |
| cache_hit_ratio_pct | 99.9 |
| schema_migration_journal_rows | 1 |

## Controles minimos

| control | observed | threshold | status |
| --- | --- | --- | --- |
| waiting_locks | 0 | <= 0 | OK |
| idle_in_transaction | 0 | <= 0 | OK |
| long_running_queries_gt_60s | 0 | <= 0 | OK |
| cache_hit_ratio_pct | 99.9 | >= 95 | OK |

## Top 10 tablas por tamano

| table_name | total_size_bytes | total_size_pretty |
| --- | --- | --- |
| invoice_line | 1015808 | 992 kB |
| payment_transaction | 573440 | 560 kB |
| payment | 548864 | 536 kB |
| ticket_segment | 540672 | 528 kB |
| invoice | 483328 | 472 kB |
| boarding_pass | 450560 | 440 kB |
| ticket | 442368 | 432 kB |
| reservation | 442368 | 432 kB |
| miles_transaction | 434176 | 424 kB |
| reservation_passenger | 409600 | 400 kB |

## Resultado

- Estado general: OBSERVABILIDAD OK
