# Baseline Arquitectonico Inicial

## 1. Proposito

Este documento fija la linea base de arranque del proyecto para evitar que la landing, el DDL y la documentacion evolucionen por caminos distintos.

## 2. Activos actuales en el repositorio

Archivos detectados:

- `index.html`
- `styles.css`
- `script.js`
- `canvas_arquitectura.html`

## 3. Lectura ejecutiva del estado actual

El repositorio contiene material de presentacion, pero no contiene aun el paquete tecnico completo necesario para una entrega de nivel arquitecto lider.

Estado actual:

- existe una landing visual con buena base de comunicacion
- existe un canvas arquitectonico separado
- no existe en la carpeta el DDL prometido por la landing
- no existe la documentacion descargable prometida por la landing
- existen contradicciones funcionales y de version entre artefactos

Conclusion:

el proyecto no esta listo para release arquitectonico. Primero debe consolidarse una verdad canonica.

## 4. Hallazgos criticos

### H-01. Inconsistencia de nombre del sistema

Observacion:

- `index.html` usa `SkyDB`
- `canvas_arquitectura.html` usa `Sistema FLY`

Impacto:

- rompe identidad del producto
- genera confusion en la presentacion ejecutiva
- invalida el paquete como entrega formal

Accion:

- definir un solo nombre canonico para release

### H-02. Inconsistencia de version y alcance

Observacion:

- la landing no declara claramente una version consolidada
- el canvas habla explicitamente de modelo `v2.0`
- el canvas tambien incluye elementos `v3 propuesta`

Impacto:

- mezcla implementado con propuesto
- riesgo de vender futuro como estado actual

Accion:

- separar "estado implementado" de "roadmap"

### H-03. Inconsistencia de metricas del modelo

Observacion:

- landing: `12 modulos`, `68 entidades`, `85+ relaciones FK`
- canvas: `73 tablas v2`, `95+ FKs`, `49 indices`, `3 vistas`

Impacto:

- cualquier presentacion publica pierde credibilidad

Accion:

- calcular metricas solo desde el DDL canonico validado

### H-04. Inconsistencia del flujo comercial

Observacion:

- la landing coloca `sale` como eje central del flujo
- el canvas v2 indica que `reservation (PNR)` es la entidad raiz del flujo comercial

Impacto:

- error de arquitectura del dominio
- riesgo de construir narrativa y modelo con logica incompatible

Accion:

- cerrar flujo canonico y hacerlo gobernar los demas artefactos

### H-05. Posible inconsistencia en ticket vs segmentos

Observacion:

- la landing sugiere que `ticket` referencia `flight_segment` directamente
- el canvas v2 indica una relacion N:M por `ticket_flight_segment`

Impacto:

- afecta el corazon del modelo de reservas, escalas y trazabilidad operativa

Accion:

- confirmar estructura canonica y reflejarla en DDL, diagrama y landing

### H-06. Descargas rotas

Observacion:

La landing publica estos archivos:

- `modelo_documentado.md`
- `modelo_postgresql.sql`

Ninguno existe en la carpeta actual.

Impacto:

- la landing no cumple su promesa funcional
- bloquea la entrega tecnica

Accion:

- generar archivos reales y validar apertura

### H-07. Fuentes citadas ausentes

Observacion:

El canvas hace referencia a artefactos no presentes en esta carpeta, por ejemplo:

- `V1/modelo_postgresql.sql`
- `V2/modelo_postgresql_v2.sql`
- `V2/CORRECCIONES_DBA.md`
- `SRS_Sistema_Aerolinea.md`
- `MOSCOW_Priorizacion.md`

Impacto:

- no es posible verificar localmente la trazabilidad de todo lo afirmado

Accion:

- importar fuentes faltantes o degradar esas afirmaciones a estado "pendiente de verificacion"

### H-08. Material visual fuerte, pero no aun material de release

Observacion:

El HTML/CSS/JS actual aporta buena base visual, pero hoy actua mas como showcase que como pieza sincronizada con una arquitectura canonica cerrada.

Impacto:

- riesgo de estetica correcta con contenido tecnicamente incorrecto

Accion:

- convertir la landing en interfaz de explicacion gobernada por el modelo final

## 5. Supuestos de trabajo propuestos

Para poder avanzar sin quedar bloqueados, se proponen estos supuestos provisionales:

- el repositorio actual es una base de trabajo, no el release final
- el objetivo inmediato es consolidar una version estable del modelo antes de abrir trabajo de v3
- `Sistema FLY` queda como nombre funcional provisional del sistema hasta confirmacion formal
- toda cifra publica futura saldra del DDL canonico
- toda seccion de roadmap quedara marcada explicitamente como futura

## 6. Bloqueadores de release

- falta el DDL oficial en la carpeta
- falta la documentacion descargable
- falta una fuente unica de verdad
- falta validacion tecnica ejecutable
- faltan criterios de aceptacion documentados

## 7. Recomendacion arquitectonica inmediata

No modificar la landing final "a ciegas".

Orden correcto:

1. cerrar baseline y matriz de consistencia
2. construir modelo canonico
3. generar DDL y validarlo
4. recien despues sincronizar landing y descargas

## 8. Estado del proyecto al cierre de esta fase

Estado actual recomendado:

- fase: baseline y control de consistencia
- semaforo: amarillo
- apto para continuar: si
- apto para release: no

