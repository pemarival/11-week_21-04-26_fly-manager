# ADR-001 - Estrategia de Delivery DB Post-Estabilizacion

- Fecha: 2026-03-20
- Estado: Aceptado
- Decisores: arquitectura local del baseline FLY Manager

## Contexto

El repositorio ya cerró el tramo de estabilización hasta `S4.6` con:

- rebuild limpio determinístico (`DDL base -> migraciones -> seeds -> gates`)
- migraciones versionadas con journal y rollback controlado
- backup/restore y prueba de recuperación
- baseline de performance y observabilidad mínima
- hardening local, logins operativos, menor privilegio y aislamiento del admin bootstrap

En este punto el problema principal deja de ser técnico-operativo y pasa a ser
de industrialización del delivery de la base.

También se observó lo siguiente:

- no existe aún proveedor CI/CD configurado en el repo
- no existe todavía un pipeline versionado para validar la base fuera del equipo local
- el repo ya tiene una línea operativa propia alrededor de `db/ddl/`,
  `db/migrations/`, `db/seeds/` e `infra/tools/`
- introducir ahora `Liquibase` o un segundo repositorio crearía doble fuente de
  verdad en un momento donde el baseline recién quedó estable

## Decision

Se adopta la siguiente estrategia para el frente post-estabilización:

1. El **source of truth inmediato** del delivery DB seguirá siendo este mismo
   repositorio.
2. El siguiente frente será **industrializar CI/CD alrededor del flujo actual**,
   no cambiar todavía de motor de migraciones.
3. **No se adopta Liquibase en esta fase inmediata**.
4. **No se separa a otro repositorio** la entrega de base de datos en esta fase.
5. La primera industrialización se construirá usando los artefactos ya
   validados:
   - `infra/tools/validar_migraciones.ps1`
   - `infra/tools/ejecutar_gate_pre_release.ps1 -SkipDocker`
   - `infra/tools/ejecutar_gate_pre_release.ps1`
6. La primera implementación CI/CD será **vendor-neutral en el diseño**.
7. Dado que el remoto actual del repositorio vive en GitHub, la primera
   implementación versionada usará **GitHub Actions**.
8. La primera ejecución remota usará **`ubuntu-latest`** para maximizar paridad
   con Docker y PostgreSQL Linux, manteniendo el baseline local en PowerShell
   como contrato operativo.

## Justificación

### Por qué no Liquibase ahora

- El repo ya tiene una columna vertebral funcional para cambios de esquema.
- Cambiar de motor en este momento reabre riesgo estructural sin necesidad
  inmediata.
- La prioridad correcta ahora es convertir el delivery actual en algo
  repetible, verificable y promovible por pipeline.

### Por qué no un segundo repo ahora

- Todavía no hay necesidad operativa demostrada de ownership separado.
- Duplicar repositorios antes del CI crearía coordinación adicional y riesgo de
  divergencia.
- Primero conviene consolidar un solo flujo de publicación y validación.

### Por qué GitHub Actions sobre `ubuntu-latest`

- El remoto `origin` del repositorio apunta a GitHub.
- El baseline técnico gira alrededor de contenedores Docker con PostgreSQL
  Linux, por lo que un runner Linux ofrece mejor paridad operativa remota.
- Los scripts siguen siendo PowerShell, por lo que no se pierde el contrato
  operativo actual aunque el runner remoto no sea Windows.

## Consecuencias

### Positivas

- Se acelera la llegada a CI/CD real sin cambiar la verdad operativa.
- El pipeline podrá reutilizar exactamente el flujo ya validado en local.
- Se reduce el riesgo de introducir una segunda arquitectura de migración.

### Costos o límites

- La primera versión del pipeline dependerá del stack actual de scripts.
- La evaluación de Liquibase queda diferida a un siguiente ADR.
- La estandarización Linux runner también queda diferida.

## Alcance de esta decisión

### Dentro

- estrategia inmediata de delivery DB
- criterio de source of truth
- orden recomendado del siguiente frente
- decisión de no introducir Liquibase ni repo separado todavía
- selección inicial de proveedor CI/CD para este repositorio

### Fuera

- selección definitiva de proveedor CI/CD
- implementación del pipeline vendor-specific
- adopción futura o descarte definitivo de Liquibase
- partición organizacional por repositorios

## Criterios para reabrir esta decisión

Esta decisión se revisa solo si ocurre al menos una de estas condiciones:

1. El pipeline inicial del repo actual queda verde de forma sostenida y aun así
   el costo de operar migraciones sigue siendo alto.
2. Aparece necesidad real de ownership separado entre app y base.
3. Se requiere promoción por múltiples entornos con controles que el enfoque
   actual no cubra razonablemente.
4. La organización define explícitamente una herramienta corporativa de schema
   management obligatoria.

## Salida esperada del siguiente frente

La siguiente fase ya no debe discutir de nuevo el baseline. Debe entregar:

- contrato CI/CD del delivery DB
- pipeline mínimo reproducible
- validación automática sobre PostgreSQL efímero
- artefactos y criterios de promoción
- primera implementación versionada en `.github/workflows/db-gate.yml`

## Relación con artefactos vigentes

- Roadmap operativo: `docs/planes/ROADMAP_ESTABILIZACION_DB_SENIOR.md`
- Continuidad: `docs/planes/PLAN_CONTINUIDAD_FASES_2026-03-19.md`
- Política de migraciones: `docs/validacion/POLITICA_MIGRACIONES_Y_ROLLBACK.md`
- Gate arquitectónico: `infra/tools/ejecutar_gate_pre_release.ps1`
