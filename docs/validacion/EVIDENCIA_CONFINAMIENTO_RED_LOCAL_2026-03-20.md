# Evidencia de Confinamiento de Red Local (2026-03-20)

## Objetivo

Confirmar que PostgreSQL local publicado por Docker queda confinado a loopback
por defecto y ya no abre el puerto en todas las interfaces del host.

## Controles esperados

| Control | Resultado esperado | Resultado observado |
|---------|--------------------|---------------------|
| `docker-compose.yml` usa `POSTGRES_BIND_IP` configurable | OK | OK |
| Bind por defecto queda en `127.0.0.1` | OK | `127.0.0.1` |
| Puerto local efectivo | `5435` o valor local valido | `5435` |
| Publicacion observada del contenedor | `127.0.0.1:<puerto>->5432/tcp` | `127.0.0.1:5435->5432/tcp` |
| Gate integral con Docker real | Verde | Verde |

## Resumen operativo

- `.\infra\tools\ejecutar_gate_pre_release.ps1 -SkipDocker`: `OK`
- `.\infra\tools\ejecutar_gate_pre_release.ps1`: `OK`
- Auditoria de seguridad regenerada:
  - `effective_bind_scope = 127.0.0.1:5435`
  - `risk_controls = 0`
  - `bootstrap_admin_isolated_by_tcp = SI`
  - `unexpected_superuser_logins = none`

Estado del corte: `CUMPLIDO`.

## Lectura arquitectonica

- Se reduce la superficie de exposicion local sin romper el flujo de trabajo
  diario sobre `localhost`.
- El residual de red deja de ser "puerto expuesto a todas las interfaces" y
  pasa a estar confinado a loopback.
- El admin bootstrap permanece solo por restriccion del motor, pero ya no queda
  expuesto por TCP y se acota a uso break-glass por socket interno.
- El baseline local queda sin residuales expuestos al host.
