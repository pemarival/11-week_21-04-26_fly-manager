# Plan Maestro de Trabajo

## 1. Objetivo

Entregar un paquete arquitectonico de nivel lider compuesto por:

- landing multimedia para explicacion ejecutiva y tecnica
- script DDL canonico y ejecutable en PostgreSQL
- documentacion trazable y consistente con el DDL
- evidencia formal de validacion

La meta operativa no es "hacer una demo", sino construir una fuente unica de verdad para que la landing, los diagramas, la documentacion y el DDL digan exactamente lo mismo.

## 2. Principios Rectores

- Una sola verdad funcional y de datos.
- Ninguna cifra publica sin respaldo en el DDL canonico.
- Ninguna regla de negocio sin trazabilidad documental.
- Ningun archivo de descarga sin existencia real y prueba de apertura.
- Ninguna fase pasa a la siguiente sin gate de salida.

## 3. Alcance del Paquete Final

### 3.1 Entregables obligatorios

- landing final en HTML/CSS/JS
- `db/ddl/modelo_postgresql.sql`
- `docs/datos/modelo_documentado.md`
- `docs/datos/diccionario_datos.md`
- `docs/arquitectura/BASELINE_ARQUITECTONICO.md`
- `docs/arquitectura/MATRIZ_CONSISTENCIA_INICIAL.md`
- `docs/validacion/VALIDACION_DDL_3FN.md`
- `docs/validacion/CHECKLIST_RELEASE_ARQUITECTONICO.md`
- `docs/planes/BACKLOG_REFACTOR_POST_RELEASE.md`

### 3.2 Alcance funcional minimo

- narrativa ejecutiva del sistema
- narrativa tecnica del modelo de datos
- explicacion de modulos y flujo operacional/comercial
- diagrama ER coherente con el modelo final
- seccion de descargas funcional
- DDL completo con PK, FK, UNIQUE, CHECK, indices y comentarios clave

## 4. Fases de Trabajo

### Fase 0. Gobierno y baseline

Objetivo:
cerrar el marco de control antes de editar landing o generar el DDL final.

Actividades:

- auditar archivos actuales
- detectar contradicciones y vacios
- definir version objetivo del modelo
- establecer criterio de nombre y alcance oficial
- acordar reglas de trazabilidad

Entregables:

- `docs/arquitectura/BASELINE_ARQUITECTONICO.md`
- `docs/arquitectura/MATRIZ_CONSISTENCIA_INICIAL.md`
- `docs/planes/PLAN_MAESTRO_ENTREGA.md`

Gate de salida:

- contradicciones criticas identificadas
- version objetivo propuesta
- ruta de trabajo aprobada

### Fase 1. Modelo canonico

Objetivo:
definir el modelo funcional y de datos que gobernara toda la entrega.

Actividades:

- cerrar modulos definitivos
- cerrar flujo canonico del negocio
- definir entidades, relaciones, catalogos y restricciones
- diferenciar obligatorio vs futuro
- establecer convenciones de naming

Entregables:

- `docs/datos/MODELO_CANONICO.md`
- diagrama ER definitivo
- tabla de decisiones arquitectonicas de datos

Gate de salida:

- flujo comercial y operacional sin contradicciones
- conteos oficiales de tablas y relaciones
- decisiones pendientes reducidas a cero o marcadas como fuera de alcance

### Fase 2. DDL maestro

Objetivo:
construir el script DDL oficial y ejecutable.

Actividades:

- generar extensiones requeridas
- definir tablas en orden correcto
- declarar PK, FK, UNIQUE, CHECK, DEFAULT e indices
- agregar comentarios tecnicos
- separar catalogos, maestros y transaccionales

Entregables:

- `db/ddl/modelo_postgresql.sql`
- notas de implementacion del DDL

Gate de salida:

- el script compila de inicio a fin en una base limpia
- no hay referencias rotas ni orden incorrecto de dependencias

### Fase 3. Validacion dura del DDL

Objetivo:
demostrar que el DDL es consistente y apto para entrega formal.

Actividades:

- ejecutar el DDL en PostgreSQL limpio
- validar PK, FK, UNIQUE, CHECK e indices
- revisar redundancias, nombres y tipos
- revisar reglas de negocio traducidas a constraints
- inspeccionar consistencia referencial y tablas puente

Entregables:

- `docs/validacion/VALIDACION_DDL_3FN.md`
- evidencia de ejecucion y hallazgos corregidos

Gate de salida:

- cero errores de ejecucion
- cero referencias faltantes
- hallazgos P1 y P2 cerrados

### Fase 4. Landing multimedia final

Objetivo:
convertir la landing en material de explicacion listo para audiencias ejecutivas y tecnicas.

Actividades:

- unificar marca y version
- reescribir narrativa de valor
- explicar modulos, flujo y capas
- sincronizar cifras con el DDL final
- integrar diagramas y descargas reales

Entregables:

- `app/landing/index.html`
- `app/landing/styles.css`
- `app/landing/script.js`
- activos visuales y diagramas necesarios

Gate de salida:

- la landing explica el modelo correcto
- todos los CTA y descargas funcionan
- no hay cifras ni textos que contradigan el DDL

### Fase 5. QA cruzado

Objetivo:
validar que todo el paquete cuente la misma historia.

Actividades:

- comparar landing vs DDL
- comparar landing vs documentacion
- comparar DDL vs diccionario de datos
- validar nombres, conteos, flujos y descargas
- revisar legibilidad ejecutiva y precision tecnica

Entregables:

- `docs/validacion/SEGUIMIENTO_INCONSISTENCIAS_ESTRUCTURALES.md`

Gate de salida:

- cero inconsistencias abiertas
- paquete listo para presentacion y entrega tecnica

### Fase 6. Release arquitectonico

Objetivo:
cerrar el paquete final con soporte de presentacion.

Actividades:

- empaquetar archivos finales
- preparar guion de explicacion
- congelar version
- registrar pendientes para roadmap posterior

Entregables:

- paquete final versionado
- resumen ejecutivo de presentacion
- notas de roadmap posterior

Gate de salida:

- paquete entregable sin dependencias faltantes
- narrativa ejecutiva y tecnica cerradas

## 5. Cronograma recomendado

Escenario sugerido de 10 dias habiles:

1. Dia 1: baseline, auditoria, matriz de consistencia.
2. Dias 2 a 3: modelo canonico y decisiones de datos.
3. Dias 4 a 6: construccion del DDL maestro.
4. Dia 7: validacion dura del DDL.
5. Dias 8 a 9: landing multimedia y sincronizacion documental.
6. Dia 10: QA cruzado, correcciones finales y release.

## 6. Criterios de aceptacion

- el DDL corre completo en PostgreSQL limpio
- no existen links rotos en la landing
- no existen cifras contradictorias entre artefactos
- el flujo de negocio esta cerrado y explicado
- todos los modulos mostrados existen en el modelo oficial
- toda afirmacion tecnica visible tiene respaldo documental

## 7. Riesgos principales

- contradiccion entre version conceptual y version fisica del modelo
- mezcla de marcas o nombres del sistema
- ausencia de archivos reales para las descargas
- inclusion de funcionalidades propuestas como si ya estuvieran implementadas
- falta de pruebas de ejecucion del DDL
- cambios tardios en el flujo comercial

## 8. Orden de ejecucion recomendado

1. Baseline y matriz de consistencia.
2. Modelo canonico.
3. DDL maestro.
4. Validacion DDL.
5. Landing multimedia.
6. QA cruzado.
7. Release.

## 9. Decision de trabajo propuesta

Hasta tener confirmacion formal en contra, se recomienda trabajar con estas reglas:

- tratar el paquete actual como pre-release no consolidado
- tomar `Sistema FLY` como nombre funcional provisional del sistema
- retirar referencias a marca previa del mensaje final salvo definicion formal en contrario
- tomar como objetivo la construccion de un modelo canonico estable antes de hablar de v3
