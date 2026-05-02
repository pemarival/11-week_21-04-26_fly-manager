# Politica de Promocion DB y Release Guard

## 1. Objetivo

Convertir el workflow `db-gate` en criterio formal de promocion para cambios de
base de datos en FLY Manager, evitando merges o cortes de release sin una
validacion remota consistente con el baseline local.

## 2. Alcance

- ramas `codex/develop` y ramas de release DB
- workflow `.github/workflows/db-gate.yml`
- evidencia remota del pipeline
- checklist de promocion previo a merge/corte

## 3. Regla principal

Ningun cambio DB debe considerarse promocionable si el workflow `db-gate` de la
rama objetivo no esta en verde en su corrida mas reciente aplicable.

## 4. Status checks requeridos

Los checks minimos esperados para promocion son:

- `Quick Gate`
- `Full DB Gate`

Interpretacion:

- si el workflow aparece exitoso en GitHub Actions, se asume que ambos jobs
  quedaron en verde
- si alguno falla, el cambio no es promocionable

## 5. Criterio de merge

Para promover hacia `codex/develop`:

1. la rama origen debe tener `db-gate` en verde
2. la evidencia remota debe quedar registrada
3. no debe existir divergencia runner/local no resuelta

Para promover hacia rama de release:

1. `codex/develop` debe estar en verde
2. la rama release debe tener `db-gate` en verde
3. el checklist de promocion debe quedar conforme

## 6. Criterio de release guard

Un corte release DB se considera protegido cuando:

- existe workflow versionado
- existe evidencia remota del pipeline
- el checklist de promocion queda en `OK`
- el procedimiento de corte enlaza el pipeline verde

## 7. Implementacion en repositorio

Los artefactos oficiales de este control son:

- `.github/workflows/db-gate.yml`
- `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md`
- `docs/validacion/CHECKLIST_PROMOCION_CI_DB.md`
- `infra/tools/validar_control_promocion_ci.ps1`

## 8. Aplicacion manual en GitHub

Como control adicional, se recomienda configurar branch protection en GitHub
para exigir:

- `Quick Gate`
- `Full DB Gate`

Nota:

- esta configuracion vive fuera del repositorio y requiere permisos
  administrativos; por eso no se versiona como cambio local directo

## 9. Criterio de falla

El cambio debe detenerse si ocurre cualquiera de estos casos:

- no existe evidencia remota del run
- el run mas reciente no esta en verde
- los checks requeridos no aparecen alineados al workflow oficial
- la rama release avanza sin validacion remota equivalente

## 10. Relacion con otros artefactos

- `docs/validacion/POLITICA_CICD_DB_GITHUB_ACTIONS.md`
- `docs/validacion/PROCEDIMIENTO_CORTE_RELEASE.md`
- `docs/planes/PLAN_INDUSTRIALIZACION_CICD_DB_2026-03-20.md`
- `docs/planes/ROADMAP_ESTABILIZACION_DB_SENIOR.md`
