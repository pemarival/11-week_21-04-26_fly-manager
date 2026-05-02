# fly-manager

Baseline de datos y arquitectura operativa de FLY Manager, estabilizado hasta
`S4.6` y ya encaminado al frente `F1` de industrializacion CI/CD.

## Estado actual

- Delivery DB estabilizado con flujo `DDL base -> migraciones -> seeds -> gates`.
- Seguridad local endurecida con secretos no versionados, logins operativos y
  admin bootstrap aislado por TCP.
- CI oficial del repo definida en GitHub Actions mediante:
  - `.github/workflows/db-gate.yml`

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

## Siguiente paso operativo

Despues del commit y push manual, confirmar la primera corrida remota del
workflow en GitHub Actions y registrar la evidencia en:

- `docs/validacion/PLANTILLA_EVIDENCIA_PIPELINE_CI.md`
