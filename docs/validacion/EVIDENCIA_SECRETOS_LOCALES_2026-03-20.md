# Evidencia de Secretos Locales (2026-03-20)

## Objetivo

Validar que la infraestructura local use infra/docker/.env no versionado con
secretos runtime reales, suficientes y consistentes con Docker Compose y los
logins operativos locales.

## Contexto de ejecucion

- Fecha de ejecucion: 2026-03-20 16:21:58 -05:00
- Env local: C:\www\code-dev-projects\fly-manager\infra\docker\.env
- Template: C:\www\code-dev-projects\fly-manager\infra\docker\.env.example
- Longitud minima requerida: 24

## Resumen observado

| metric | value |
| --- | --- |
| local_env_exists | True |
| postgres_password_length | 32 |
| operational_passwords_min_length | 32 |
| effective_bind_ip | 127.0.0.1 |
| effective_port | 5435 |
| failed_controls | 0 |
| min_password_length | 24 |

## Controles

| control | observed | expected | status | note |
| --- | --- | --- | --- | --- |
| env_example_exists | True | true | OK | Debe existir template versionado de referencia |
| gitignore_protects_local_env | True | true | OK | El secreto local no debe quedar expuesto al versionado |
| local_env_present | True | true | OK | Debe existir infra/docker/.env no versionado para uso local |
| local_env_required_keys_complete | True | true | OK | Debe incluir secretos admin y credenciales operativas locales |
| operational_usernames_valid | True | true | OK | Los logins operativos deben usar identificadores simples y no vacios |
| operational_usernames_distinct_from_admin | True | true | OK | Los logins operativos no deben reutilizar POSTGRES_USER |
| operational_usernames_distinct_each_other | True | true | OK | RW, RO y AUDIT deben ser cuentas distintas |
| local_env_passwords_placeholder_removed | True | true | OK | Ningun secreto local debe quedar con el placeholder del repo |
| local_env_passwords_length_ok | admin=32, op_min=32 | >=24 | OK | Todos los secretos locales deben cumplir la longitud minima |
| local_env_passwords_complexity_ok | True | true | OK | Todos los secretos locales deben incluir mayuscula, minuscula y digito |
| compose_uses_env_password | True | true | OK | docker-compose debe resolver POSTGRES_PASSWORD desde entorno local |
| compose_supports_local_bind_scope | True | true | OK | docker-compose debe publicar PostgreSQL con bind configurable y loopback por defecto |
| effective_bind_ip_is_local_only | 127.0.0.1 | 127.0.0.1 | OK | El puerto publicado no debe abrirse en todas las interfaces del host |
| effective_port_is_valid | 5435 | 1024-65535 | OK | El puerto configurado debe ser local y valido |
| env_example_keeps_placeholders | True | true | OK | El archivo versionado debe seguir usando placeholders y no secretos reales |

## Resultado

- Estado general: SECRETOS LOCALES OK
- Fallas bloqueantes: 0
