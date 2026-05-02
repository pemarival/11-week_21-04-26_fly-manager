# Checklist de Release Arquitectonico

## Objetivo

Definir y ejecutar el gate de salida de la Fase 6 para congelar el paquete tecnico
sin contradicciones entre DDL, seeds, validaciones y narrativa documental.

## Corte de control

- Fecha: 2026-03-19
- Rama operativa: `codex/develop`
- Entorno de referencia: Docker + PostgreSQL 16 (`localhost:5435`)
- Script operativo: `infra/docker/recrear_instalacion_limpia.ps1`

## Gate de salida (pre-release)

| Codigo | Criterio | Evidencia primaria | Estado |
|--------|----------|--------------------|--------|
| RL-01 | DDL ejecuta completo en base limpia | `docs/validacion/VALIDACION_DDL_3FN.md` | OK |
| RL-02 | Seed canonico + seed volumetrico corren de punta a punta | `infra/docker/recrear_instalacion_limpia.ps1` | OK |
| RL-03 | Gate canonico y gate volumetrico sin fallas bloqueantes | `db/seeds/99_validaciones_post_seed.sql` | OK |
| RL-04 | Consistencia E2E sin orfandad ni anomalias cronologicas | `db/seeds/99_validaciones_post_seed.sql` | OK |
| RL-05 | Narrativa alineada en landing/canvas/reportes/docs | `app/landing/index.html`, `architecture/canvas/canvas_arquitectura.html`, `reports/html/funcionalidades_sistema.html`, `reports/cronograma/cronograma_realizacion.html` | OK |
| RL-06 | Hallazgos estructurales sin bloqueantes abiertos | `docs/validacion/SEGUIMIENTO_INCONSISTENCIAS_ESTRUCTURALES.md` | OK |
| RL-07 | Backlog post-release documentado para deuda no bloqueante | `docs/planes/BACKLOG_REFACTOR_POST_RELEASE.md` | OK |
| RL-08 | Rutas documentales sin referencias faltantes | `infra/tools/validar_rutas_docs.ps1` | OK |
| RL-09 | Gate operativo de pre-release ejecutable en un solo comando | `infra/tools/ejecutar_gate_pre_release.ps1` | OK |
| RL-10 | Acta de congelamiento emitida con checksums de artefactos | `docs/validacion/ACTA_CONGELAMIENTO_RELEASE_2026-03-19.md` | OK |
| RL-11 | Regresion SQL post-seed automatizada y sin fallas | `infra/tools/ejecutar_regresion_post_seed.ps1` + `infra/sql/regresion_post_seed.sql` | OK |

## Resumen de resultado del corte

- Estado del gate: `RELEASE CONGELADO`
- Bloqueantes abiertos: `0`
- Excepciones controladas: `1` (catalogos cerrados vs volumen uniforme)
- Hallazgos en seguimiento no bloqueantes: `0`
- Commit de congelamiento: `8b31fdc` (`2026-03-19T20:20:09-05:00`)

## Criterio de congelamiento final

Para pasar de pre-release a release congelado, completar en esta secuencia:

1. Confirmar commit final del paquete en rama de integracion.
2. Registrar hash de congelamiento y fecha de corte.
3. Emitir nota ejecutiva de entrega enlazando este checklist y el backlog post-release.
