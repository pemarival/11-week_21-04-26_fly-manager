# Evidencia de Recuperacion Local (2026-03-19)

## Objetivo

Validar que el backup local de PostgreSQL 16 puede restaurarse de forma
controlada en una base temporal y conservar integridad de tablas y conteos.

## Contexto de ejecucion

- Fecha de ejecucion: 2026-03-19 21:05:18 -05:00
- Contenedor: fly-bd-pg-5435
- Base origen: flydb
- Base destino restaurada: flydb_restore_validation
- Backup generado: C:\www\code-dev-projects\fly-manager\infra\runtime\backups\flydb_recovery_test_20260319_210502.dump
- Metadata backup: C:\www\code-dev-projects\fly-manager\infra\runtime\backups\flydb_recovery_test_20260319_210502.metadata.json

## Resumen observado

| metric | value |
| --- | --- |
| backup_ms | 420 |
| restore_ms | 2478 |
| public_tables_compared | 78 |
| mismatches | 0 |
| backup_sha256 | fd315bc7ed555d824c5b7aec8bfdef9146e9323a405cbf8b34601d526071031d |

## Conteos clave verificados

| table_name | source_rows | restored_rows | status |
| --- | --- | --- | --- |
| country | 5 | 5 | OK |
| airline | 3 | 3 | OK |
| airport | 5 | 5 | OK |
| aircraft | 3 | 3 | OK |
| flight | 121 | 121 | OK |
| person | 305 | 305 | OK |
| customer | 253 | 253 | OK |
| loyalty_account | 253 | 253 | OK |
| reservation | 1223 | 1223 | OK |
| ticket | 1223 | 1223 | OK |
| payment | 1223 | 1223 | OK |
| invoice | 1223 | 1223 | OK |
| miles_transaction | 1454 | 1454 | OK |
| schema_migration_journal | 1 | 1 | OK |

## Resultado

- Estado general: RECUPERACION VALIDADA
- Tablas comparadas: 78
- Diferencias detectadas: 0
- Criterio de aceptacion: conteos equivalentes entre origen y restaurado.
