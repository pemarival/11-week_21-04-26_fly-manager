# Politica CI/CD DB en GitHub Actions (F1.2)

## 1. Objetivo

Definir el contrato operativo del pipeline de base de datos en GitHub Actions
para FLY Manager, reutilizando el baseline ya estabilizado y evitando una segunda
fuente de verdad.

## 2. Alcance

- workflow `.github/workflows/db-gate.yml`
- ejecución sobre pushes, pull requests y disparo manual
- validación rápida y validación integral del delivery DB

## 3. Principios

1. El pipeline no redefine el proceso: ejecuta los mismos scripts validados en local.
2. El source of truth sigue siendo este repositorio.
3. La validación rápida y la validación integral deben permanecer separadas.
4. Los secretos de CI no deben vivir en el repo ni sustituir el contrato local.
5. GitHub Actions es el proveedor oficial de CI para este proyecto mientras
   `origin` permanezca en GitHub.

## 4. Workflow oficial

- Archivo:
  - `.github/workflows/db-gate.yml`
- Nombre del workflow:
  - `db-gate`

## 5. Stages operativos

### Quick Gate

Objetivo:

- fallar rápido sin ejecutar la reconstrucción técnica completa

Comandos:

- `.\infra\tools\validar_migraciones.ps1`
- `.\infra\tools\inicializar_secretos_locales.ps1`
- `.\infra\tools\ejecutar_gate_pre_release.ps1 -SkipDocker`

Salida esperada:

- migraciones válidas
- secretos CI generados en forma efímera
- consistencia documental mínima en verde

### Full DB Gate

Objetivo:

- reconstruir y validar la base completa en runner efímero

Comandos:

- `.\infra\tools\inicializar_secretos_locales.ps1`
- `.\infra\tools\ejecutar_gate_pre_release.ps1`

Salida esperada:

- rebuild limpio exitoso
- regresión post-seed en verde
- logins, menor privilegio y admin bootstrap validados
- auditoría de seguridad sin fallas bloqueantes

## 6. Secretos y entorno

### Regla actual

El workflow genera un `infra/docker/.env` efímero para CI usando:

- `.\infra\tools\inicializar_secretos_locales.ps1`

Esto es aceptable en esta fase porque:

- el entorno CI es efímero
- los secretos no se persisten en el repositorio
- el objetivo actual es validar reproducibilidad del baseline

### Evolución esperada

En una fase posterior puede migrarse a secretos nativos de GitHub Actions si:

- el pipeline necesita valores controlados externamente
- aparecen entornos no efímeros
- se requiere promoción entre ambientes

## 7. Artefactos mínimos

El workflow debe conservar:

- `docs/validacion/`
- `infra/runtime/` cuando aplique al gate integral
- resumen por job en `GITHUB_STEP_SUMMARY`

Retencion inicial recomendada:

- `14` dias para artefactos del pipeline

## 8. Criterio de éxito de F1.2

Se considera `F1.2` efectivamente cerrado cuando:

1. el workflow queda versionado en la rama objetivo
2. se ejecuta al menos una corrida remota real
3. `Quick Gate` queda en verde
4. `Full DB Gate` queda en verde
5. la salida remota no contradice el baseline local
6. existe evidencia documentada del primer run remoto

## 9. Criterio de falla

Se considera que el pipeline requiere ajuste si ocurre cualquiera de estos casos:

- el runner no puede recrear el baseline limpio
- aparecen diferencias entre local y remoto
- el workflow necesita lógica distinta a los scripts oficiales
- se requiere parchear CI sin reflejarlo en los scripts del repo

## 10. Relación con otros artefactos

- ADR:
  - `docs/arquitectura/ADR-001_ESTRATEGIA_DELIVERY_DB_POST_ESTABILIZACION.md`
- Subplan:
  - `docs/planes/PLAN_INDUSTRIALIZACION_CICD_DB_2026-03-20.md`
- Gate oficial:
  - `infra/tools/ejecutar_gate_pre_release.ps1`
- Evidencia operativa:
  - `infra/tools/preparar_evidencia_pipeline_ci.ps1`
- Procedimiento de corte:
  - `docs/validacion/PROCEDIMIENTO_CORTE_RELEASE.md`
- Release guard:
  - `docs/validacion/POLITICA_PROMOCION_DB_RELEASE_GUARD.md`
  - `docs/validacion/CHECKLIST_PROMOCION_CI_DB.md`
  - `infra/tools/validar_control_promocion_ci.ps1`
