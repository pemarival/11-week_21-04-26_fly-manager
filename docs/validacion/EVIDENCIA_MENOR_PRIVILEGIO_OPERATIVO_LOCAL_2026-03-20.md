# Evidencia de Menor Privilegio Operativo Local (2026-03-20)

## Objetivo

Verificar que los flujos cotidianos de diagnostico, observabilidad y baseline
local ya no dependan de `fly_admin` y usen por defecto logins operativos
AUDIT, RO y RW con privilegio minimo verificable.

## Contexto de ejecucion

- Fecha de ejecucion: 2026-04-28 13:48:57 -05:00
- Contenedor: fly-bd-pg-5435
- Base validada: flydb
- Login AUDIT: fly_local_audit
- Login RO: fly_local_ro
- Login RW: fly_local_rw
- Evidencia runtime observabilidad: C:\www\code-dev-projects\fly-manager\infra\runtime\least_privilege\observabilidad_s43_20260320.md
- Evidencia runtime baseline: C:\www\code-dev-projects\fly-manager\infra\runtime\least_privilege\baseline_s43_20260320.md

## Resumen observado

| metric | value |
| --- | --- |
| validated_non_admin_flows | 3 |
| failed_controls | 0 |
| diagnostic_login | fly_local_audit |
| observability_login | fly_local_audit |
| baseline_read_login | fly_local_ro |
| baseline_write_login | fly_local_rw |

## Controles

| control | observed | expected | status | note |
| --- | --- | --- | --- | --- |
| diagnostic_defaults_to_audit_login | fly_local_audit | fly_local_audit | OK | El diagnostico local debe resolver AUDIT por defecto |
| observability_defaults_to_audit_login | fly_local_audit | fly_local_audit | OK | La observabilidad local debe ejecutarse con AUDIT |
| baseline_defaults_to_ro_read_login | fly_local_ro | fly_local_ro | OK | Las consultas de lectura del baseline deben usar RO |
| baseline_defaults_to_rw_write_login | fly_local_rw | fly_local_rw | OK | La prueba de escritura del baseline debe usar RW |
| audit_stats_probe_ok | True | true | OK | AUDIT debe consultar pg_stat_activity |
| audit_journal_probe_ok | True | true | OK | AUDIT debe inspeccionar la presencia del journal cuando exista |
| audit_dml_denied | True | true | OK | AUDIT no debe poder ejecutar DML |
| audit_temp_denied | True | true | OK | AUDIT no debe crear tablas temporales |
| ro_read_probe_ok | True | true | OK | RO debe poder ejecutar joins operativos de lectura |
| ro_dml_denied | True | true | OK | RO no debe poder ejecutar DML |
| ro_temp_denied | True | true | OK | RO no debe crear tablas temporales |
| rw_temp_probe_ok | True | true | OK | RW debe poder ejecutar el probe temporal seguro |

## Probes directos

| probe | ok | detail |
| --- | --- | --- |
| audit_stats | True | 1 |
| audit_journal | True | schema_migration_journal |
| audit_dml_denied | True | ERROR:  cannot execute DELETE in a read-only transaction |
| audit_temp_denied | True | ERROR:  cannot execute CREATE TABLE in a read-only transaction |
| ro_read | True | 1223 |
| ro_dml_denied | True | ERROR:  cannot execute DELETE in a read-only transaction |
| ro_temp_denied | True | ERROR:  cannot execute CREATE TABLE in a read-only transaction |
| rw_temp_probe | True | 2 |

## Resultado

- Estado general: MENOR PRIVILEGIO OPERATIVO OK
- Fallas bloqueantes: 0
