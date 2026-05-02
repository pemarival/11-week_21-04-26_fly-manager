# Evidencia de Observabilidad Local (2026-03-19)

## Objetivo

Capturar una fotografia minima de salud operativa de PostgreSQL local para
seguimiento de capacidad, locks, actividad y crecimiento.

## Contexto de ejecucion

- Fecha de ejecucion: 2026-03-19 21:25:08 -05:00
- Contenedor: fly-bd-pg-5435
- Base primaria: flydb
- Base secundaria: flydb_restore_validation
- Umbral long query: 60 segundos

## Resumen observado

| metric | value |
| --- | --- |
| primary_db_size_pretty | 20 MB |
| secondary_db_size_pretty | 21 MB |
| public_tables | 78 |
| active_connections | 0 |
| idle_in_transaction | 0 |
| waiting_locks | 0 |
| long_running_queries_gt_60s | 0 |
| cache_hit_ratio_pct | 99.88 |
| schema_migration_journal_rows | 1 |

## Controles minimos

| control | observed | threshold | status |
| --- | --- | --- | --- |
| waiting_locks | 0 | <= 0 | OK |
| idle_in_transaction | 0 | <= 0 | OK |
| long_running_queries_gt_60s | 0 | <= 0 | OK |
| cache_hit_ratio_pct | 99.88 | >= 95 | OK |

## Top 10 tablas por tamano

| table_name | total_size_bytes | total_size_pretty |
| --- | --- | --- |
| invoice_line | 1024000 | 1000 kB |
| payment_transaction | 581632 | 568 kB |
| ticket_segment | 548864 | 536 kB |
| payment | 548864 | 536 kB |
| invoice | 491520 | 480 kB |
| boarding_pass | 458752 | 448 kB |
| ticket | 450560 | 440 kB |
| reservation | 450560 | 440 kB |
| miles_transaction | 442368 | 432 kB |
| reservation_passenger | 417792 | 408 kB |

## Resultado

- Estado general: OBSERVABILIDAD OK
