# Evidencia de Logins Operativos Locales (2026-03-20)

## Objetivo

Validar que el entorno local ya no dependa solo de `fly_admin` para uso
cotidiano y disponga de logins operativos minimos, conectables y alineados a
los roles `fly_app_rw`, `fly_app_ro` y `fly_app_audit`.

## Contexto de ejecucion

- Fecha de ejecucion: 2026-04-28 13:48:46 -05:00
- Contenedor: fly-bd-pg-5435
- Base auditada: flydb
- Admin actual de bootstrap: fly_admin
- Login RW local: fly_local_rw
- Login RO local: fly_local_ro
- Login AUDIT local: fly_local_audit

## Resumen observado

| metric | value |
| --- | --- |
| expected_operational_logins | 3 |
| present_operational_logins | 3 |
| validated_connections | 3 |
| failed_controls | 0 |

## Atributos de logins

| login_name | superuser | create_role | create_db | can_login | member_rw | member_ro | member_audit |
| --- | --- | --- | --- | --- | --- | --- | --- |
| fly_local_audit | f | f | f | t | f | f | t |
| fly_local_ro | f | f | f | t | f | t | f |
| fly_local_rw | f | f | f | t | t | f | f |

## Validacion de conexion

| login_name | connection_ok | current_user |
| --- | --- | --- |
| fly_local_rw | True | fly_local_rw |
| fly_local_ro | True | fly_local_ro |
| fly_local_audit | True | fly_local_audit |

## Controles

| control | observed | expected | status | note |
| --- | --- | --- | --- | --- |
| operational_logins_distinct_from_admin | True | true | OK | Los logins operativos no deben reutilizar el usuario administrativo |
| operational_logins_distinct_each_other | True | true | OK | RW, RO y AUDIT deben ser cuentas distintas |
| rw_login_present | True | true | OK | Debe existir el login local heredando de fly_app_rw |
| ro_login_present | True | true | OK | Debe existir el login local heredando de fly_app_ro |
| audit_login_present | True | true | OK | Debe existir el login local heredando de fly_app_audit |
| operational_logins_non_superuser | True | true | OK | Los logins operativos no deben ser superuser ni crear roles/bases |
| rw_membership_ok | t | t | OK | El login RW debe heredar de fly_app_rw |
| ro_membership_ok | t | t | OK | El login RO debe heredar de fly_app_ro |
| audit_membership_ok | t | t | OK | El login AUDIT debe heredar de fly_app_audit |
| operational_logins_can_connect | 3/3 | 3/3 | OK | Los tres logins deben conectarse con password sobre TCP |
| rw_privileges_match_runtime_role | t | t | OK | El login RW debe conservar DML completo via fly_app_rw |
| ro_privileges_match_readonly_role | t | t | OK | El login RO debe quedar limitado a SELECT |
| audit_privileges_match_audit_role | t | t | OK | El login AUDIT debe quedar limitado a lectura |
| audit_login_has_pg_read_all_stats | t | t | OK | El login AUDIT debe heredar acceso a estadisticas globales |
| rw_login_has_temp_privilege | t | t | OK | El login RW debe poder crear tablas temporales de sesion para probes seguros |
| ro_login_no_temp_privilege | t | t | OK | El login RO no debe crear tablas temporales |
| audit_login_no_temp_privilege | t | t | OK | El login AUDIT no debe crear tablas temporales |

## Resultado

- Estado general: LOGINS OPERATIVOS OK
- Fallas bloqueantes: 0
