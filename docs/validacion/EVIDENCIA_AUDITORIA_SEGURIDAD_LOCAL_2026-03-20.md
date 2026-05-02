# Evidencia de Auditoria de Seguridad Local (2026-03-20)

## Objetivo

Auditar el estado de privilegios, roles, secretos locales y superficie de
exposicion del PostgreSQL de desarrollo despues del endurecimiento progresivo
completado hasta S4.6.

## Contexto de ejecucion

- Fecha de ejecucion: 2026-04-28 13:49:01 -05:00
- Contenedor: fly-bd-pg-5435
- Base auditada: flydb
- Role admin actual: fly_admin
- Roles de minimo privilegio esperados: fly_app_rw, fly_app_ro, fly_app_audit
- Archivo HBA auditado: /var/lib/postgresql/data/pg_hba.conf

## Resumen observado

| metric | value |
| --- | --- |
| public_tables | 78 |
| hard_fail_controls | 0 |
| risk_controls | 0 |
| superuser_login_roles | 1 |
| unexpected_superuser_logins | none |
| local_env_exists | True |
| effective_bind_scope | 127.0.0.1:5435 |
| bootstrap_admin_hba_file | /var/lib/postgresql/data/pg_hba.conf |

## Roles relevantes

| role_name | superuser | create_role | create_db | can_login |
| --- | --- | --- | --- | --- |
| fly_admin | t | t | t | t |
| fly_app_audit | f | f | f | f |
| fly_app_ro | f | f | f | f |
| fly_app_rw | f | f | f | f |

## Controles de seguridad

| control | observed | expected | status | note |
| --- | --- | --- | --- | --- |
| public_connect_revoked | f | false | OK | PUBLIC no debe conservar CONNECT sobre la base |
| public_schema_create_revoked | f | false | OK | PUBLIC no debe poder crear en schema public |
| public_schema_usage_revoked | f | false | OK | PUBLIC no debe conservar USAGE abierto en schema public |
| least_privilege_roles_present | 3 | 3 | OK | Roles base de runtime, readonly y audit deben existir |
| runtime_rw_grants_complete | 78/78/78/78 | 78/78/78/78 | OK | Runtime debe tener DML completo sobre tablas public |
| readonly_select_grants_complete | 78 | 78 | OK | Readonly debe tener SELECT sobre todas las tablas public |
| audit_select_grants_complete | 78 | 78 | OK | Audit debe tener SELECT sobre todas las tablas public |
| audit_role_has_pg_read_all_stats | t | true | OK | Audit debe poder leer estadisticas globales |
| bootstrap_admin_superuser_retained | True | true | OK | El bootstrap admin debe permanecer superuser por restriccion del motor |
| bootstrap_admin_tcp_reject_ipv4_present | True | true | OK | Debe existir regla reject IPv4 para el bootstrap admin |
| bootstrap_admin_tcp_reject_ipv6_present | True | true | OK | Debe existir regla reject IPv6 para el bootstrap admin |
| unexpected_superuser_login_count | 0 | 0 | OK | No deben existir logins superuser adicionales al bootstrap admin |
| repo_weak_password_literal_removed | False | false | OK | No debe permanecer la clave literal legacy en archivos versionados |
| local_env_secret_present | True | true recomendado | OK | Se recomienda definir POSTGRES_PASSWORD en infra/docker/.env |
| compose_password_placeholder_present | True | true | OK | El repo debe sugerir placeholder y no una clave operativa real |
| compose_supports_loopback_bind | True | true | OK | docker-compose debe soportar bind local a loopback por defecto |
| host_port_bound_to_loopback | 127.0.0.1:5435 | 127.0.0.1:<puerto> | OK | El puerto publicado debe quedar confinado a loopback local |

## Resultado

- Estado general: AUDITORIA SIN FALLAS BLOQUEANTES
- Fallas bloqueantes: 0
- Riesgos controlados: 0
- Bootstrap admin aislado por TCP: SI
