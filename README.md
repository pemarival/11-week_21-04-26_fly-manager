# fly-manager

Baseline de datos y arquitectura operativa de FLY Manager, estabilizado hasta
`S4.6`, con `F1` de industrializacion CI/CD ya materializado a nivel repo y
validado en corte rapido el `2026-04-13`.

## Estado actual

- Delivery DB estabilizado con flujo `DDL base -> migraciones -> seeds -> gates`.
- Seguridad local endurecida con secretos no versionados, logins operativos y
  admin bootstrap aislado por TCP.
- CI oficial del repo definida en GitHub Actions mediante:
  - `.github/workflows/db-gate.yml`
- Gate rapido validado el `2026-04-13` con:
  - `infra/tools/ejecutar_gate_pre_release.ps1 -SkipDocker`
  - `infra/tools/validar_control_promocion_ci.ps1`
- Evidencia remota del pipeline ya publicada en:
  - `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md`

## Validacion local

Gate integral:

```powershell
.\infra\tools\ejecutar_gate_pre_release.ps1
```

Gate rapido documental:

```powershell
.\infra\tools\ejecutar_gate_pre_release.ps1 -SkipDocker
```

## CI/CD actual

El frente post-estabilizacion ya esta documentado en:

- `docs/arquitectura/ADR-001_ESTRATEGIA_DELIVERY_DB_POST_ESTABILIZACION.md`
- `docs/planes/PLAN_INDUSTRIALIZACION_CICD_DB_2026-03-20.md`
- `docs/validacion/POLITICA_CICD_DB_GITHUB_ACTIONS.md`

El workflow `db-gate` ejecuta:

- `Quick Gate`: validacion rapida del contrato, migraciones y consistencia documental.
- `Full DB Gate`: reconstruccion completa del baseline con Docker y publicacion de artefactos.

## Siguiente frente operativo

El siguiente trabajo ya no es demostrar la primera corrida remota del workflow,
porque esa evidencia ya existe. El foco actual es cerrar el handoff del
proyecto y dejar explicitados los pendientes externos al repo.

Referencias:

- `docs/planes/PLAN_CIERRE_AGENTICO_FLY_MANAGER_2026-04-13.md`
- `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md`
- `docs/validacion/PLANTILLA_EVIDENCIA_PIPELINE_CI.md`

Pendientes externos al repo:

- branch protection en GitHub, si hay permisos administrativos
- responsable nominal de validacion remota, si aplica al proceso
