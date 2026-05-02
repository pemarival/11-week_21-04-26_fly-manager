# Plan de Cierre Agentico FLY Manager (2026-04-13)

## 1. Scope de ejecucion

- `workspace_activo_autorizado`: `C:\www\code-dev-projects\fly-manager`
- `repo_referencia_solo_lectura`: `C:\www\code-dev-projects\automatization-develop`
- Objetivo: cerrar FLY Manager usando el framework como equipo de trabajo, pero materializando cambios solo en este repositorio.

## 2. Estado verificado del proyecto

Validacion ejecutada en este corte:

- `infra/tools/ejecutar_gate_pre_release.ps1 -SkipDocker`: `OK`
- `infra/tools/validar_control_promocion_ci.ps1`: `OK`
- Evidencia remota existente: `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md`

Conclusiones operativas:

- El baseline DB local sigue estable.
- El workflow oficial `db-gate` ya esta versionado y validado contra evidencia remota.
- El control de promocion CI ya no esta pendiente a nivel repo.
- El principal frente restante es de cierre operativo y handoff, no de rescate tecnico.

## 3. Diagnostico de cierre

### Ya cerrado en repo

- modelo canonico, DDL, seeds y validaciones bloqueantes
- gate arquitectonico local y control de promocion CI
- evidencia de pipeline remoto
- release guard documental y validable
- backlog post-release documentado

### Pendiente o residual

- actualizar documentos raiz para que reflejen el estado real vigente
- dejar una hoja de ruta final por roles del equipo agentico
- completar actividades externas al repo cuando existan permisos administrativos:
  - branch protection en GitHub
  - confirmacion nominal del responsable de validacion remota

## 4. Equipo de trabajo aplicado a FLY Manager

| Rol | Responsabilidad en este cierre | Estado |
|---|---|---|
| A00 Orquestador | consolidar plan de cierre, prioridades y criterio de listo | Activo |
| A03 UX / Calidad | validar que README, planes y evidencias cuenten una sola historia | Activo |
| A05 Product Owner | fijar alcance de cierre y separar terminado vs siguiente frente | Activo |
| A06 Tech Lead | gobernar cierre tecnico repo-local y evitar cambios innecesarios | Activo |
| A09 QA Lead | revalidar gates de salida del corte | Activo |
| A11 DevOps / SRE | custodiar CI/CD, workflow y handoff operativo | Activo |
| A12 AppSec | verificar que el release guard siga siendo criterio de promocion | Activo |

## 5. Plan de ejecucion recomendado

### Tramo 1. Cierre repo-local

Objetivo:
dejar este repositorio con narrativa actualizada y plan final explicitado.

Acciones:

- actualizar `README.md` al estado vigente del pipeline y del gate
- dejar este plan como referencia operativa de cierre
- evitar reabrir frentes ya cerrados en DB, migraciones o seeds

Salida esperada:

- repositorio alineado entre estado real, README y plan vigente

### Tramo 2. Validacion de corte

Objetivo:
confirmar que el cierre documental no rompio el baseline operativo.

Acciones:

- ejecutar `infra/tools/ejecutar_gate_pre_release.ps1 -SkipDocker`
- verificar `infra/tools/validar_control_promocion_ci.ps1`
- revisar que no se introduzcan referencias rotas

Salida esperada:

- corte documental validado sin regresion

### Tramo 3. Handoff de proyecto

Objetivo:
dejar claro que el proyecto queda tecnicamente estable y que lo pendiente es externo o de siguiente frente.

Acciones:

- declarar bloqueos externos separados de pendientes repo-locales
- dejar criterio de “proyecto listo” y “siguiente frente”
- evitar que README vuelva a marcar como pendiente algo que ya fue validado

Salida esperada:

- cierre entendible para cualquier persona que retome el repo

## 6. Bloqueos externos

Estos puntos no se resuelven solo con cambios dentro del repo:

1. Aplicar branch protection en GitHub, si se cuenta con permisos administrativos.
2. Completar el nombre del responsable de validacion en la evidencia remota, si corresponde por proceso.

## 7. Definicion de listo

FLY Manager se considera listo en este corte cuando:

- el `README.md` refleja el estado real vigente;
- el plan de cierre por roles queda documentado;
- el gate rapido sigue en verde;
- el control de promocion CI sigue en verde;
- los pendientes externos quedan explicitamente marcados como externos al repo.

## 8. Siguiente frente recomendado

Una vez completado este cierre, el siguiente frente no debe ser rehacer la base DB. Lo recomendable es elegir solo uno:

1. endurecimiento administrativo externo en GitHub;
2. siguiente fase de industrializacion;
3. evolucion visual/comunicacional del portal, si vuelve a ser prioridad.
