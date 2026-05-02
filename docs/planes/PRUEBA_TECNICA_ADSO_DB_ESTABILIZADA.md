# Prueba Tecnica ADSO - Diseno y Estabilizacion de Base de Datos

## 1. Proposito

Esta prueba esta dirigida a aprendices SENA del programa ADSO y tiene como finalidad evaluar su capacidad para analizar un modelo de datos existente, proponer su evolucion arquitectonica y organizar un plan serio de estabilizacion de base de datos.

El ejercicio no parte de cero. El repositorio ya contiene una base de datos funcional y una linea de maduracion tecnica documentada. Por tanto, se espera que cada aprendiz o equipo trabaje con criterio de continuidad, trazabilidad y coherencia tecnica.

## 2. Contexto del caso

El proyecto base corresponde a `FLY Manager` y cuenta con un script SQL funcional en [modelo_postgresql.sql](../../db/ddl/modelo_postgresql.sql). Este artefacto representa un baseline real del modelo relacional y debe asumirse como punto de partida del ejercicio.

Adicionalmente, el repositorio documenta como el proyecto fue madurado hasta alcanzar una linea operativa estable, con decisiones sobre normalizacion, migraciones versionadas, seeds, gates de validacion y CI/CD. Esa maduracion debe ser estudiada antes de proponer cambios.

Importante:

- El baseline actual del repositorio opera con el flujo `DDL base -> migraciones -> seeds -> gates`.
- El repositorio todavia no adopta `Liquibase` como herramienta oficial del baseline actual.
- En esta prueba, `Liquibase` debe entenderse como una propuesta de evolucion futura, sustentada mediante ADR, backlog y plan de implementacion, sin desconocer el estado real del proyecto.

## 3. Fuentes de consulta obligatoria

Antes de iniciar la propuesta, revise como minimo los siguientes artefactos:

- [modelo_postgresql.sql](../../db/ddl/modelo_postgresql.sql)
- [modelo_documentado.md](../datos/modelo_documentado.md)
- [NORMALIZACION_3FN.md](../datos/NORMALIZACION_3FN.md)
- [ROADMAP_ESTABILIZACION_DB_SENIOR.md](ROADMAP_ESTABILIZACION_DB_SENIOR.md)
- [ADR-001_ESTRATEGIA_DELIVERY_DB_POST_ESTABILIZACION.md](../arquitectura/ADR-001_ESTRATEGIA_DELIVERY_DB_POST_ESTABILIZACION.md)
- [README de migraciones](../../db/migrations/README.md)
- [POLITICA_MIGRACIONES_Y_ROLLBACK.md](../validacion/POLITICA_MIGRACIONES_Y_ROLLBACK.md)
- [PLAN_GENERACION_DATOS_SEMILLA.md](PLAN_GENERACION_DATOS_SEMILLA.md)
- [MATRIZ_ORDEN_CARGA_SEEDS.md](../validacion/MATRIZ_ORDEN_CARGA_SEEDS.md)
- [POLITICA_CICD_DB_GITHUB_ACTIONS.md](../validacion/POLITICA_CICD_DB_GITHUB_ACTIONS.md)

## 4. Duracion y modalidad

- Tiempo total de la prueba sincronica: `4 horas`
- Horario de ejecucion: `8:00 a.m. a 12:00 m.`
- Punto de control obligatorio para entrega del plan de trabajo desescolarizado: `11:20 a.m.`
- Modalidad posterior: trabajo desescolarizado orientado a estabilizar la base de datos y consolidar la propuesta

## 5. Resultado esperado al cierre de las 4 horas

Al finalizar la jornada sincronica, cada aprendiz o equipo debe dejar una propuesta tecnica clara, argumentada y organizada para evolucionar la base de datos hacia un modelo estabilizado y versionable.

No se espera que todo quede implementado en las 4 horas. Si se espera que queden definidos:

- el analisis del modelo y sus dominios
- las decisiones arquitectonicas principales
- la estructura inicial de trabajo
- la estrategia de ramas `develop`, `qa` y `main`
- la primera historia de usuario iniciada
- el backlog de estabilizacion
- el plan de datos de prueba y de validacion
- el plan de trabajo para la fase desescolarizada

## 6. Actividades obligatorias durante la prueba

### 6.1 Analizar el modelo e identificar los dominios

A partir del script base y la documentacion del repositorio, identifique los dominios funcionales del sistema y justifique su clasificacion.

La respuesta debe evidenciar:

- lectura del modelo relacional existente
- agrupacion coherente de entidades por dominio
- relaciones de dependencia entre dominios
- reconocimiento del flujo critico del negocio

### 6.2 Disenar cinco ADR

Se deben redactar `5` ADR con estructura formal y lenguaje tecnico claro. Cada ADR debe incluir, como minimo: contexto, decision, alternativas consideradas, consecuencias y riesgos.

Los ADR obligatorios son:

1. ampliacion de un nuevo dominio del negocio
2. manejo de roles con permisos diferenciados
3. adopcion de `Liquibase` como estrategia de evolucion
4. versionamiento y promocion entre `develop`, `qa` y `main`
5. una decision adicional propuesta por el aprendiz o equipo

### 6.3 Proponer la estructura inicial de trabajo

Durante la prueba debe quedar definida la estructura propuesta del proyecto para soportar la estabilizacion de base de datos. Esta estructura debe diferenciar, como minimo:

- artefactos base del modelo
- changelogs o migraciones por dominio
- scripts de datos semilla
- pruebas o validaciones de datos
- documentacion arquitectonica
- backlog y planeacion

### 6.4 Implementar la estrategia de ramas y arrancar con la primera HU

Durante el tiempo de la prueba se debe dejar planteado el flujo de trabajo con las ramas:

- `develop`
- `qa`
- `main`

Ademas, se debe registrar e iniciar la primera historia de usuario (`HU-001`) relacionada con la estabilizacion de la base de datos.

La historia de usuario debe contener:

- descripcion funcional
- criterio de aceptacion
- definicion tecnica inicial
- evidencia del primer avance

### 6.5 Establecer un backlog de estabilizacion de base de datos

Se debe construir un tablero o backlog de trabajo para llevar la base de datos desde el baseline actual hasta una solucion estabilizada y trazable mediante `Liquibase`.

Condicion obligatoria del backlog:

- cada changelog debe agrupar como maximo las entidades de un solo dominio

El backlog debe incluir, como minimo:

- actividades de conversion del `DDL` base a changelogs versionados
- orden de implementacion por dominio
- historias o tareas tecnicas
- dependencias
- riesgos
- criterio de terminado por cada frente

### 6.6 Generar el plan de datos de prueba

Se debe construir un plan que permita poblar datos de prueba de manera controlada y verificable.

Este plan debe contemplar:

- estrategia de poblamiento por capas de dependencia
- orden de carga de datos
- scripts de `insert` o seeds
- pruebas unitarias o validaciones automatizadas por dependencia de datos
- documentacion del seguimiento realizado

La propuesta debe demostrar que los datos de prueba no son un agregado posterior, sino un componente esencial de la estabilizacion.

## 7. Entregables minimos al cierre de la prueba

Al finalizar las 4 horas deben entregarse, como minimo, los siguientes productos:

- documento con identificacion y justificacion de dominios
- `5` ADR redactados
- estructura inicial propuesta del proyecto
- definicion del flujo `develop -> qa -> main`
- `HU-001` creada e iniciada
- backlog de estabilizacion
- plan de datos de prueba
- plan de trabajo desescolarizado entregado a las `11:20 a.m.`

## 8. Trabajo desescolarizado

La fase desescolarizada tiene como objetivo construir el proyecto a nivel de base de datos estabilizada, tomando como insumo lo definido durante la prueba.

En esta fase se espera avanzar en:

- implementacion progresiva de changelogs por dominio
- consolidacion de la estrategia de ramas y promocion
- evolucion de roles y permisos diferenciados
- desarrollo del plan de seeds y pruebas de datos
- seguimiento del backlog hasta lograr una base de datos estable, versionable y verificable

## 9. Estructura minima sugerida para la entrega

La siguiente estructura es una referencia valida para organizar la solucion:

```text
/
|-- README.md
|-- docs/
|   |-- arquitectura/
|   |   `-- adr/
|   |-- backlog/
|   |-- historias_usuario/
|   `-- planes/
|-- db/
|   |-- ddl/
|   |-- changelog/
|   |-- seeds/
|   `-- tests/
`-- infra/
```

Notas:

- `db/ddl/modelo_postgresql.sql` debe conservarse como baseline de referencia.
- El master changelog puede orquestar multiples archivos, pero cada archivo detallado debe corresponder a un dominio.
- Los nombres, convenciones y formatos elegidos deben mantenerse de forma consistente.

## 10. Criterios de calidad

La evaluacion priorizara los siguientes aspectos:

- claridad y coherencia en la redaccion
- comprension del modelo de datos existente
- capacidad para justificar decisiones tecnicas
- trazabilidad entre problema, propuesta y entregables
- calidad del backlog y del plan de ejecucion
- consistencia de la propuesta de `Liquibase` frente al estado real del proyecto
- calidad del plan de datos de prueba y sus validaciones

## 11. Recomendaciones para el desarrollo de la prueba

- no reescriba el proyecto desde cero sin justificarlo
- no desconozca el baseline ya estabilizado del repositorio
- use la documentacion del repo como insumo de analisis, no solo como referencia superficial
- proponga una evolucion controlada, incremental y verificable
- documente decisiones, riesgos y supuestos

## 12. Cierre esperado

La propuesta final debe demostrar que el aprendiz o equipo comprende tres niveles de trabajo:

1. el modelo de datos que ya existe
2. la forma en que ese modelo fue madurado dentro del repositorio
3. la ruta tecnica para evolucionarlo hacia una base de datos estabilizada, gobernada y versionable

El valor principal de la prueba no esta en producir la mayor cantidad de archivos, sino en evidenciar criterio arquitectonico, orden de trabajo, capacidad de analisis y calidad en la toma de decisiones.
