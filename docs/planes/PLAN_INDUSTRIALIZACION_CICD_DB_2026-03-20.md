# Plan de Industrializacion CI/CD DB (2026-03-20)

## 1. Objetivo

Convertir el baseline estabilizado de FLY Manager en un delivery DB repetible,
auditable y ejecutable por pipeline sin reabrir el modelo ni cambiar todavía de
motor de migraciones.

## 2. Punto de partida

El baseline actual ya dispone de:

- `DDL base -> migraciones -> seeds -> gates`
- hardening, recovery, observabilidad y menor privilegio validados
- gate integral en verde con Docker real
- evidencias operativas consistentes

Lo que falta ya no es estabilidad local, sino **ejecución automatizada fuera del
equipo local**.

## 3. Principios

1. No duplicar source of truth.
2. No introducir Liquibase en esta fase.
3. No abrir un repositorio separado todavía.
4. Reutilizar primero los scripts ya validados.
5. Diseñar vendor-neutral y ejecutar la primera versión sobre el proveedor real del repo.
6. Separar claramente validación rápida de validación integral.

## 4. No objetivos de esta fase

- rehacer el esquema
- migrar a Liquibase
- portar todo a Linux runner
- introducir nuevos entornos productivos
- rediseñar seeds o gates ya cerrados

## 5. Entregables del frente

### F1.1 Gobierno de decisión

- ADR formal del delivery DB post-estabilización
- subplan de industrialización por fases

### F1.2 Contrato CI mínimo

- definición de stages del pipeline
- definición de jobs rápidos vs integrales
- definición de secretos requeridos en CI
- definición de runner base

### F1.3 Pipeline inicial

- validación automática de migraciones
- gate documental mínimo
- recreación técnica integral en PostgreSQL efímero
- publicación de resultados del gate

### F1.4 Control de promoción

- criterio de merge/release
- checklist de evidencia mínima
- retención de artefactos del pipeline

## 6. Arquitectura objetivo del pipeline

### Stage 1 - Lint y contrato rápido

Propósito:

- fallar rápido sin arrancar contenedores pesados

Comandos base:

- `pwsh -File .\infra\tools\validar_migraciones.ps1`
- `pwsh -File .\infra\tools\ejecutar_gate_pre_release.ps1 -SkipDocker`

Salida esperada:

- migraciones consistentes
- rutas documentales válidas
- controles mínimos en verde

### Stage 2 - Rebuild técnico integral

Propósito:

- demostrar que el baseline reconstruye la base completa desde cero

Comando base:

- `pwsh -File .\infra\tools\ejecutar_gate_pre_release.ps1`

Salida esperada:

- recreación limpia exitosa
- seeds y regresión post-seed en verde
- seguridad, logins y admin bootstrap validados

### Stage 3 - Artefactos de evidencia

Propósito:

- conservar trazabilidad del run CI

Artefactos mínimos:

- salida del gate
- `docs/validacion/` regenerados en el run
- resumen de éxito/falla del pipeline

### Stage 4 - Release guard

Propósito:

- bloquear promotion si el baseline no es repetible

Condiciones:

- stage 1 verde
- stage 2 verde
- artefactos publicados
- aprobación manual si aplica a corte release

## 7. Requerimientos técnicos previos

### Runner

- estrategia inicial recomendada: `GitHub Actions + ubuntu-latest`

Razón:

- el remoto actual del repositorio vive en GitHub
- PostgreSQL corre en contenedor Linux y obtiene mejor paridad remota sobre runner Linux
- PowerShell 7 sigue disponible para ejecutar el contrato actual sin reescribir scripts

### Proveedor seleccionado para F1.2

- `GitHub Actions`
- workflow inicial versionado en:
  - `.github/workflows/db-gate.yml`
- estado:
  - implementado en el repositorio
  - primera corrida remota ya validada en `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md`
  - control de promocion repo-local validado con `infra/tools/validar_control_promocion_ci.ps1`

### Secretos CI

Se requerirá mapear en el proveedor CI/CD al menos:

- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`
- `POSTGRES_PORT` si se parametriza
- credenciales operativas si el pipeline las exige explícitamente

Nota:

- `infra/docker/.env` sigue siendo local; en CI los secretos deben venir del
  store nativo del proveedor

### Servicio de base

Opciones aceptables:

1. runner con Docker daemon disponible
2. service container PostgreSQL si el proveedor lo permite con paridad suficiente

Recomendación inicial:

- usar Docker en CI mientras se preserve el mismo contrato del baseline local

## 8. Fases de ejecución recomendadas

### Fase F1.1 - Aterrizaje de decisión

Estado actual:

- completado en este corte mediante ADR y subplan

### Fase F1.2 - Bootstrap del pipeline

Objetivo:

- elegir proveedor y dejar pipeline mínimo versionado

Salida:

- archivo CI inicial (`.github/workflows/db-gate.yml`)
- stages `quick` y `full`
- generación efímera de `infra/docker/.env` para CI
- resumen por job y artefactos con retención base

### Fase F1.3 - Validación integral automatizada

Objetivo:

- ejecutar rebuild + gate completo en runner

Salida:

- run reproducible en CI
- evidencia de primer pipeline verde
- plantilla de evidencia remota preparada en:
  - `docs/validacion/PLANTILLA_EVIDENCIA_PIPELINE_CI.md`
- script operativo para preparar evidencia de corrida remota:
  - `infra/tools/preparar_evidencia_pipeline_ci.ps1`

### Fase F1.4 - Control de promoción

Objetivo:

- convertir el pipeline en criterio real de merge/corte

Salida:

- reglas de branch/release
- artifacts retenidos
- checklist enlazado al pipeline
- politica de promocion y validador automatizado del release guard

Estado actual:

- implementado en repositorio con:
  - `docs/validacion/POLITICA_PROMOCION_DB_RELEASE_GUARD.md`
  - `docs/validacion/CHECKLIST_PROMOCION_CI_DB.md`
  - `infra/tools/validar_control_promocion_ci.ps1`
  - `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md`
- pendiente externo al repo:
  - aplicar branch protection en GitHub si se decide endurecer el control administrativo

## 9. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Elegir provider antes de fijar contrato | Medio | Definir primero stages y comandos canónicos |
| Reabrir discusión de Liquibase demasiado pronto | Alto | Mantener ADR-001 como decisión vigente |
| Querer Linux runner sin pruebas previas | Medio | Empezar Windows-first y medir después |
| Secretos CI mal resueltos | Alto | Usar secret store nativo; no replicar `.env` local |
| Divergencia entre local y CI | Alto | Reutilizar exactamente los scripts del baseline |

## 10. Definición de listo de este frente

Se considerará industrialización inicial cerrada cuando exista:

- pipeline versionado en el repo
- validación rápida automática
- gate completo corriendo sobre base efímera
- artefactos del run conservados
- evidencia del primer run remoto documentada
- criterio de merge/release documentado

## 11. Siguiente paso inmediato recomendado

`F1` queda cerrado a nivel repo. El siguiente frente recomendado es:

- aplicar branch protection en GitHub si hay permisos administrativos
- o continuar con observabilidad/reporting de pipeline y disciplina de promocion siguiente

## 12. Referencias

- `docs/arquitectura/ADR-001_ESTRATEGIA_DELIVERY_DB_POST_ESTABILIZACION.md`
- `docs/planes/ROADMAP_ESTABILIZACION_DB_SENIOR.md`
- `docs/planes/PLAN_CONTINUIDAD_FASES_2026-03-19.md`
- `docs/validacion/POLITICA_CICD_DB_GITHUB_ACTIONS.md`
- `docs/validacion/POLITICA_MIGRACIONES_Y_ROLLBACK.md`
- `infra/tools/ejecutar_gate_pre_release.ps1`
