# Procedimiento de Corte para Release (Operativo)

## Objetivo

Estandarizar el cierre tecnico previo al commit/tag final, dejando trazabilidad
de validaciones y evidencia de corte.

## Precondiciones

- Estar en la rama de trabajo de release/pre-release.
- Tener Docker operativo (si se ejecutara validacion completa).
- Tener cambios listos para commit (el commit lo realiza el responsable Git).

## Paso 1. Ejecutar gate integral

Validacion completa (recomendada):

```powershell
.\infra\tools\ejecutar_gate_pre_release.ps1
```

Este gate incluye: DDL base + migraciones versionadas + seeds + gates
bloqueantes + regresion SQL post-seed + validacion documental de rutas.

Validacion solo documental (si no deseas ejecutar Docker en ese momento):

```powershell
.\infra\tools\ejecutar_gate_pre_release.ps1 -SkipDocker
```

## Paso 2. Verificar estado de trabajo antes de commit

```powershell
git status -sb
git diff --stat
```

## Paso 3. Commit manual (responsable Git)

Ejemplo de commit:

```powershell
git add .
git commit -m "chore(release): cierre pre-release arquitectonico y gate operativo"
```

## Paso 4. Registrar hash/fecha en nota ejecutiva

Actualizar:

- `docs/planes/NOTA_EJECUTIVA_PRE_RELEASE_2026-03-19.md`

Campos a completar:

- Rama de integracion
- Hash del commit
- Fecha/hora del commit
- Responsable

## Paso 5. Verificacion final post-commit

```powershell
git log -1 --oneline
```

El hash de `git log -1` debe coincidir con el registrado en la nota ejecutiva.

## Paso 6. Verificacion remota del pipeline oficial

Despues del push, confirmar la corrida del workflow oficial en GitHub Actions:

- Workflow:
  - `.github/workflows/db-gate.yml`
- Politica operativa:
  - `docs/validacion/POLITICA_CICD_DB_GITHUB_ACTIONS.md`

Resultado esperado:

- `Quick Gate`: verde
- `Full DB Gate`: verde

Registrar la primera corrida remota en:

- `docs/validacion/PLANTILLA_EVIDENCIA_PIPELINE_CI.md`
- o preparar un archivo base operativo con:
  - `.\infra\tools\preparar_evidencia_pipeline_ci.ps1`

Si el pipeline remoto falla, el corte no debe considerarse industrializado
hasta ajustar la diferencia runner/local.

## Paso 7. Ejecutar release guard de promocion

```powershell
.\infra\tools\validar_control_promocion_ci.ps1
```

Resultado esperado:

- evidencia remota del pipeline en verde
- checklist de promocion en `OK`
- politica de promocion alineada al workflow oficial
