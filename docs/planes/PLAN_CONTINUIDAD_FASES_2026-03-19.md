# Plan de Continuidad por Fases (Corte 2026-03-19)

## 1. Objetivo

Retomar la ejecucion del paquete arquitectonico FLY con una lectura unica de estado,
evitando contradicciones entre DDL, seeds, reportes y documentos de gobierno.

## 2. Estado del corte (2026-03-19)

- DDL maestro validado en PostgreSQL 16.
- Seed canonico cerrado con flujo E2E funcional.
- Seed volumetrico cerrado en umbral operativo `1000+` para entidades aplicables.
- Validaciones post-seed extendidas con gate canonico + gate volumetrico bloqueante.
- Narrativa documental cerrada y release arquitectonico congelado con hash de corte.

## 3. Estado por fase del Plan Maestro

### Fase 0. Gobierno y baseline

- Estado: Cerrada.
- Evidencia: baseline, matriz de consistencia y plan maestro ya presentes.

### Fase 1. Modelo canonico

- Estado: Cerrada.
- Evidencia: modelo canonico y reglas de normalizacion 3FN documentadas.

### Fase 2. DDL maestro

- Estado: Cerrada.
- Evidencia: `db/ddl/modelo_postgresql.sql` validado sin errores.

### Fase 3. Validacion dura del DDL

- Estado: Cerrada.
- Evidencia: validacion DDL completa + seed canonico validado + seed volumetrico extendido con gate en verde.
- Gap: ninguno bloqueante a nivel de datos.

### Fase 4. Landing multimedia final

- Estado: Cerrada.
- Evidencia: landing, canvas y reportes alineados al cierre tecnico volumetrico.
- Gap: ninguno bloqueante en esta fase.

### Fase 5. QA cruzado

- Estado: Cerrada.
- Evidencia: verificacion cruzada landing/reportes/docs ejecutada y consistente con seeds.
- Gap: mantener control de regresion narrativa en siguientes cortes.

### Fase 6. Release arquitectonico

- Estado: Cerrada.
- Evidencia: checklist en estado `RELEASE CONGELADO`, nota ejecutiva con hash de corte y gate integral en verde.
- Gap: ninguno bloqueante.

## 4. Brechas activas a cerrar

1. Ejecutar backlog post-release no bloqueante segun prioridad.
2. Ejecutar roadmap de estabilizacion senior por fases (`docs/planes/ROADMAP_ESTABILIZACION_DB_SENIOR.md`).
3. Consolidar siguientes evidencias operativas de S2/S3 sin romper baseline ya estabilizado.

## 5. Plan operativo recomendado (continuacion)

### Tramo A. Cierre tecnico del seed volumetrico

- Expandir `01_seed_volumetrico.sql` por lotes con metas de volumen por entidad aplicable.
- Incluir cobertura volumetrica de viaje: `ticket_segment`, `seat_assignment`, `baggage`,
  `check_in`, `boarding_pass`, `boarding_validation`, y escenarios de `refund` cuando aplique.
- Salida esperada: seed volumetrico ejecutable de punta a punta sobre base limpia.
- Estado actual: Completado en corte tecnico (ejecucion limpia validada).

### Tramo B. Gate volumetrico de validacion

- Extender `99_validaciones_post_seed.sql` con umbrales de fase volumetrica.
- Incorporar chequeos de cronologia y orfandad para nuevas tablas pobladas en volumen.
- Salida esperada: reporte de validacion sin fallas bloqueantes.
- Estado actual: Completado con `tablas_falla = 0` en gate volumetrico.

### Tramo C. QA cruzado de narrativa y evidencia

- Alinear `landing`, `canvas`, `reportes` y `seguimiento` al mismo estado real.
- Verificar que no existan afirmaciones de "pendiente" cuando ya hay implementacion parcial.
- Salida esperada: narrativa unica y auditable.
- Estado actual: Completado en corte documental.

### Tramo D. Pre-release arquitectonico

- Cerrar IE en seguimiento que impacten lectura ejecutiva.
- Congelar paquete tecnico y registrar backlog de refactor posterior.
- Salida esperada: paquete listo para entrega tecnica y explicacion ejecutiva.
- Estado actual: Completado con checklist `docs/validacion/CHECKLIST_RELEASE_ARQUITECTONICO.md` y nota ejecutiva `docs/planes/NOTA_EJECUTIVA_PRE_RELEASE_2026-03-19.md`.

## 6. Prioridad de fixes (orden de ejecucion)

1. P0: Ejecutar BR-003 (higiene de nomenclatura residual) sin afectar baseline historico.
2. P1: Operar plantilla unica de evidencia de release (BR-004) en siguientes cortes.
3. P2: Mantener regresion SQL post-seed automatizada como control permanente (BR-005).

## 7. Definicion de listo para continuar

Se considera lista la siguiente iteracion cuando:

- `01_seed_volumetrico.sql` corre completo sobre base limpia.
- `99_validaciones_post_seed.sql` no reporta fallas bloqueantes en fase volumetrica.
- Documentacion y reportes reflejan exactamente el mismo estado de avance.

Estado de verificacion tecnica (corte actual):

- Condicion 1: cumplida.
- Condicion 2: cumplida.
- Condicion 3: cumplida tras cierre de ajustes del Tramo C.
- Condicion 4 (release): cumplida con congelamiento documentado.

## 8. Continuidad post-corte senior

- S2.1 migraciones versionadas: implementado y validado.
- S2.2 backup/restore local: implementado y validado con evidencia de recuperacion.
- S2.3 runbook inicial de incidentes: implementado.
- S3.1 baseline de performance local: implementado y validado.
- S3.2 observabilidad minima local: implementado y validado.
- S3.3 hardening inicial de seguridad: implementado, auditado e integrado al flujo deterministico de recreacion limpia.
- S4.1 gestion local de secretos: implementado y validado con control bloqueante sobre `infra/docker/.env` y placeholders runtime.
- S4.2 logins operativos locales: implementado y validado con RW, RO y AUDIT conectables por password y heredando privilegios minimos.
- S4.3 menor privilegio operativo: implementado y validado con diagnostico/observabilidad usando AUDIT y baseline separado entre RO/RW.
- S4.4 unificacion del rebuild limpio: implementado y validado con contrato `DDL base -> migraciones versionadas -> seeds -> gates` y `schema_migration_journal` materializado desde la recreacion.
- S4.5 confinamiento de red local: implementado y validado con bind loopback por defecto (`127.0.0.1`) y auditoria actualizada.
- S4.6 aislamiento del admin bootstrap: implementado y validado con rechazo TCP en `pg_hba.conf`, validacion dedicada y uso break-glass por socket interno.
- Estado residual actual: sin residuales expuestos al host en el baseline local.
- Frente F1 industrializacion del delivery DB: abierto con ADR y subplan formal publicados.
- Workflow inicial F1.2: versionado en `.github/workflows/db-gate.yml` para GitHub Actions.
- Plantilla de evidencia remota F1.3: preparada en `docs/validacion/PLANTILLA_EVIDENCIA_PIPELINE_CI.md`.
- Script de preparacion de evidencia remota: `infra/tools/preparar_evidencia_pipeline_ci.ps1`.
- Evidencia remota F1.3: validada con runs verdes en `docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md`.
- F1.4 release guard: implementado con politica, checklist y validador.
- Siguiente foco recomendado: aplicar branch protection en GitHub si procede, o abrir el siguiente frente de industrializacion sin introducir aun Liquibase ni repo separado.
- Frente visual propuesto: `docs/planes/PLAN_REFACTOR_VISUAL_PORTAL_ARQUITECTURA_2026-03-20.md` para convertir landing/canvas/reportes en una capa de comunicacion mas clara y unificada.
- Ejecucion visual inicial: matriz IA publicada en `docs/planes/MATRIZ_IA_PORTAL_VISUAL_FLY_2026-03-20.md`, nueva landing portal implementada y navegacion unificada entre piezas HTML.
