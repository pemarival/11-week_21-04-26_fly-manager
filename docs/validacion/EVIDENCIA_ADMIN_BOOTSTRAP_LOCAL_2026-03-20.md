# Evidencia de Admin Bootstrap Local (2026-03-20)

## Objetivo

Validar que el usuario bootstrap administrativo permanezca como superuser solo
por restriccion del motor, pero quede confinado a uso break-glass por socket
local interno y no por TCP.

## Contexto de ejecucion

- Fecha de ejecucion: 2026-04-28 13:48:58 -05:00
- Contenedor: fly-bd-pg-5435
- Base: flydb
- Admin bootstrap: fly_admin
- Bind TCP publicado: 127.0.0.1:5435
- Archivo HBA auditado: /var/lib/postgresql/data/pg_hba.conf

## Resumen observado

| metric | value |
| --- | --- |
| failed_controls | 0 |
| admin_bootstrap | fly_admin |
| tcp_bind_scope | 127.0.0.1:5435 |
| socket_probe_user | fly_admin |

## Controles de aislamiento

| control | observed | expected | status | note |
| --- | --- | --- | --- | --- |
| bootstrap_admin_retained_as_superuser | t | t | OK | El bootstrap user debe permanecer superuser por restriccion del motor |
| bootstrap_admin_hba_reject_ipv4_present | True | true | OK | Debe existir regla reject para TCP IPv4 |
| bootstrap_admin_hba_reject_ipv6_present | True | true | OK | Debe existir regla reject para TCP IPv6 |
| bootstrap_admin_tcp_access_denied | True | true | OK | El admin bootstrap no debe autenticarse por TCP |
| bootstrap_admin_socket_access_ok | True | true | OK | El admin bootstrap debe seguir disponible por socket local interno |

## Resultado

- Estado general: ADMIN BOOTSTRAP CONFINADO Y VALIDADO
- Fallas bloqueantes: 0
- Evidencia TCP: psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  pg_hba.conf rejects connection for host "127.0.0.1", user "fly_admin", database "flydb", no encryption
- Evidencia socket local: fly_admin
