# Checklist de Promocion CI DB

## Objetivo

Verificar que el delivery DB no se promueva a `develop` o release sin pipeline
remoto consistente, evidencia documentada y criterio de corte claro.

## Estado actual del control

- Fecha de control: 2026-03-20
- Workflow oficial: `.github/workflows/db-gate.yml`
- Politica de promocion: `docs/validacion/POLITICA_PROMOCION_DB_RELEASE_GUARD.md`
- Evidencia remota base: `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md`

## Gate de promocion

| Codigo | Criterio | Evidencia primaria | Estado |
|--------|----------|--------------------|--------|
| PG-01 | Workflow `db-gate` versionado en repo | `.github/workflows/db-gate.yml` | OK |
| PG-02 | `Quick Gate` del run remoto confirmado en verde | `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md` | OK |
| PG-03 | `Full DB Gate` del run remoto confirmado en verde | `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md` | OK |
| PG-04 | Rama `codex/develop` validada por pipeline remoto | `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md` | OK |
| PG-05 | Rama release validada por pipeline remoto | `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md` | OK |
| PG-06 | Artefactos y resumen de CI retenidos | `.github/workflows/db-gate.yml` | OK |
| PG-07 | Procedimiento de corte enlaza el pipeline oficial | `docs/validacion/PROCEDIMIENTO_CORTE_RELEASE.md` | OK |
| PG-08 | Politica de promocion documentada | `docs/validacion/POLITICA_PROMOCION_DB_RELEASE_GUARD.md` | OK |
| PG-09 | Validacion automatizada del control disponible | `infra/tools/validar_control_promocion_ci.ps1` | OK |

## Resultado

- Estado del gate: `OK`
- Bloqueantes abiertos: `0`
- Riesgos residuales: `1`
- Nota residual:
  - branch protection de GitHub recomendada pero aun dependiente de configuracion administrativa fuera del repo
