# Runbook de Branch Protection en GitHub

## Objetivo

Aplicar el endurecimiento administrativo recomendado para que la promocion de
cambios DB en FLY Manager no dependa solo de evidencia documental, sino tambien
de controles nativos de GitHub.

## Alcance

- rama `codex/develop`
- ramas de release DB cuando existan
- workflow oficial `.github/workflows/db-gate.yml`
- checks requeridos:
  - `Quick Gate`
  - `Full DB Gate`

## Precondiciones

- contar con permisos administrativos sobre el repositorio en GitHub
- verificar que el workflow `db-gate` ya haya corrido en la rama objetivo
- confirmar que los nombres visibles de los checks coincidan con:
  - `Quick Gate`
  - `Full DB Gate`

## Referencias

- `docs/validacion/POLITICA_PROMOCION_DB_RELEASE_GUARD.md`
- `docs/validacion/CHECKLIST_PROMOCION_CI_DB.md`
- `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md`
- `docs/validacion/PROCEDIMIENTO_CORTE_RELEASE.md`

## Procedimiento recomendado

### 1. Abrir la configuracion del repositorio

En GitHub:

1. entrar al repositorio `fly-manager`
2. abrir `Settings`
3. entrar a `Branches`

### 2. Crear o editar la regla para `codex/develop`

Crear una branch protection rule para:

- `codex/develop`

Configurar como minimo:

- `Require a pull request before merging`
- `Require status checks to pass before merging`
- `Require branches to be up to date before merging`

Checks requeridos:

- `Quick Gate`
- `Full DB Gate`

### 3. Aplicar regla equivalente para ramas de release

Crear una regla para el patron que use el equipo en release DB. Ejemplos:

- `codex/release/*`
- o la convención vigente usada por el repositorio

Aplicar los mismos checks:

- `Quick Gate`
- `Full DB Gate`

### 4. Validar que GitHub reconozca los checks correctos

Antes de guardar la regla:

- confirmar que los checks listados provengan del workflow oficial `db-gate`
- evitar seleccionar checks obsoletos o nombres historicos

### 5. Registrar aplicacion administrativa

Una vez aplicada la regla, actualizar como minimo:

- `docs/validacion/CHECKLIST_PROMOCION_CI_DB.md`
- `docs/planes/NOTA_EJECUTIVA_CIERRE_AGENTICO_2026-04-13.md` si se quiere dejar constancia del cierre total del pendiente externo

## Criterio de exito

Se considera completado este runbook cuando:

- `codex/develop` exige `Quick Gate` y `Full DB Gate`
- las ramas de release equivalentes exigen los mismos checks
- ya no es posible promover cambios DB sin pipeline remoto en verde

## Criterio de falla

Detener y corregir si ocurre alguno de estos casos:

- GitHub no muestra `Quick Gate` o `Full DB Gate` como checks seleccionables
- los checks visibles no corresponden al workflow oficial `db-gate`
- la regla se aplica a un patron de rama incorrecto
- la rama release queda menos protegida que `codex/develop`

## Nota

Este runbook documenta un control administrativo externo al repositorio. No
reemplaza el release guard local; lo complementa.
