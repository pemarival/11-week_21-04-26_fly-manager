# Backlog de Refactor Post-Release

## Objetivo

Registrar mejoras y deuda tecnica no bloqueante para la siguiente iteracion,
preservando el principio de "release estable primero, refactor despues".

## Criterio de prioridad

- `P1`: impacto alto en mantenibilidad o riesgo de regresion narrativa.
- `P2`: mejora importante de higiene tecnica sin impacto inmediato en release.
- `P3`: optimizacion deseable de bajo riesgo.

## Backlog priorizado

| ID | Prioridad | Tema | Alcance | Criterio de cierre |
|----|-----------|------|---------|--------------------|
| BR-001 | P1 | Normalizacion de documentos historicos | Marcar artefactos de baseline/matriz inicial como "historico" con nota de no-regresion narrativa. | Todo documento de fase inicial incluye encabezado de contexto y no compite con el estado vigente. |
| BR-002 | P1 | Linter de rutas documentales | Automatizar chequeo de rutas internas de documentos/descargas para detectar referencias huerfanas. | Pipeline detecta rutas rotas o no existentes antes de merge. |
| BR-003 | P2 | Higiene de nomenclatura residual | Eliminar referencias residuales de marca previa en comentarios tecnicos y assets secundarios. | Cero coincidencias de marca legacy en `app/`, `docs/`, `reports/`, `architecture/`. |
| BR-004 | P2 | Consolidacion de evidencia de release | Crear plantilla unica de nota ejecutiva de entrega con hash, estado de gates y anexos. | Nota publicada con enlaces al checklist y seguimiento de inconsistencias. |
| BR-005 | P3 | Hardening de validaciones post-seed | Agregar pruebas de regresion SQL para umbrales volumetricos y checks cronologicos. | Ejecucion automatica en entorno local sin intervencion manual. |

## Dependencias y notas

- No bloquear el release por items de este backlog salvo reclasificacion explicita.
- Cada item debe referenciar evidencia de ejecucion o diff verificable al cerrarse.
- Avances ya aplicados en el corte 2026-03-19:
- BR-001 implementado en `docs/arquitectura/BASELINE_ARQUITECTONICO.md` y `docs/arquitectura/MATRIZ_CONSISTENCIA_INICIAL.md` con etiquetado historico.
- BR-002 implementado mediante `infra/tools/validar_rutas_docs.ps1`.
- BR-003 implementado en documentos vigentes (`docs/datos/MODELO_CANONICO.md` y `docs/planes/PLAN_MAESTRO_ENTREGA.md`) sin alterar artefactos historicos de fase 0.
- BR-004 implementado mediante `docs/validacion/PLANTILLA_EVIDENCIA_RELEASE.md` y uso en `docs/validacion/ACTA_CONGELAMIENTO_RELEASE_2026-03-19.md`.
- BR-005 implementado mediante `infra/sql/regresion_post_seed.sql`, `infra/tools/ejecutar_regresion_post_seed.ps1` e integracion en `infra/tools/ejecutar_gate_pre_release.ps1`.
- Roadmap de estabilizacion senior formalizado en `docs/planes/ROADMAP_ESTABILIZACION_DB_SENIOR.md`.
