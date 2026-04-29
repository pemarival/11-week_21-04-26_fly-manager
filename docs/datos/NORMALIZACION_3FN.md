# Guia de Normalizacion a 3FN

## 1. Objetivo

Este documento define como debe evaluarse la nueva version del modelo para asegurar que el diseno llegue correctamente a Tercera Forma Normal (3FN).

## 2. Criterios formales

### 2.1 Primera Forma Normal

Una tabla cumple 1FN si:

- cada columna almacena un valor atomico
- no existen grupos repetitivos
- no existen listas embebidas en una sola columna
- cada fila es identificable por una clave

Aplicacion en esta version:

- pasajeros multiples se resuelven con `reservation_passenger`
- segmentos multiples se resuelven con `ticket_segment`
- contactos multiples se resuelven con `person_contact`
- documentos multiples se resuelven con `person_document`
- roles y permisos multiples se resuelven con tablas puente

### 2.2 Segunda Forma Normal

Una tabla cumple 2FN si:

- ya cumple 1FN
- todos los atributos no clave dependen de la clave completa
- no existen dependencias parciales sobre una parte de una clave compuesta

Aplicacion en esta version:

- las relaciones N:M se convierten en tablas puente con restricciones unicas
- los atributos del detalle de ticket dependen de `ticket_segment` y no solo de `ticket`
- los atributos de una persona no se duplican en tablas de cliente, seguridad o venta

### 2.3 Tercera Forma Normal

Una tabla cumple 3FN si:

- ya cumple 2FN
- no existen dependencias transitivas entre atributos no clave
- ningun atributo no clave determina a otro atributo no clave

Aplicacion en esta version:

- la geografia se descompone en `continent -> country -> state_province -> city -> district -> address`
- la zona horaria se ubica en `city` y no se repite en `airport`
- moneda, estado, tipo y categoria se modelan en catalogos separados
- no se almacenan totales derivados en `sale`, `invoice` o `invoice_line`
- el modelo evita tablas genericas redundantes como `geolocation` si duplican la jerarquia ya normalizada

## 3. Reglas de diseno obligatorias

- una entidad representa un solo concepto del negocio
- una columna no debe mezclar significado operativo y descriptivo
- toda relacion N:M debe tener tabla intermedia
- todo dominio estable de codigos debe vivir en catalogo o `CHECK`
- no se almacenan atributos calculables si pueden derivarse del modelo
- no se duplica un dato maestro en varias tablas transaccionales

## 4. Correcciones clave frente al material previo

### 4.1 Flujo comercial

Correccion:

- `reservation` pasa a ser la raiz del flujo comercial

Justificacion 3FN:

- evita que la venta y la emision de ticket se mezclen como un solo hecho
- separa reserva, emision, pago y facturacion en entidades distintas

### 4.2 Ticket y segmentos

Correccion:

- `ticket` y `flight_segment` se relacionan mediante `ticket_segment`

Justificacion 3FN:

- elimina la falsa relacion 1:1
- evita duplicacion de segmentos dentro del ticket
- permite multiples escalas sin campos repetidos

### 4.3 Geolocalizacion

Correccion:

- se elimina la necesidad de una tabla generica `geolocation` cuando la jerarquia normalizada ya resuelve el problema

Justificacion 3FN:

- evita dependencia transitiva de pais, ciudad y zona horaria en una sola tabla agregada

### 4.4 Estados y tipos

Correccion:

- estados, tipos y categorias pasan a catalogos dedicados

Justificacion 3FN:

- se evita texto libre repetido
- se reduce inconsistencia semantica
- se desacopla el dato operacional de la clasificacion

### 4.5 Facturacion y pagos

Correccion:

- pagos, transacciones, reembolsos, facturas y lineas de factura se separan

Justificacion 3FN:

- cada entidad representa un hecho distinto
- se evita mezclar cobro, evidencia transaccional e impuesto en una sola tabla

## 5. Regla de oro para este proyecto

Si un atributo puede obtenerse de otra tabla sin perder el hecho original, no debe duplicarse en la tabla actual.

Ejemplos:

- no guardar `country_name` en `airport`
- no guardar `currency_code` libre en `sale`
- no guardar `full_name` si ya existe `first_name` y `last_name`
- no guardar `line_total` si se deriva de `quantity * unit_price`
- no guardar `time_zone` en `airport` si ya depende de `city`

## 6. Excepciones controladas

Hay casos en los que un sistema productivo podria romper 3FN por razones historicas o de performance, por ejemplo snapshots de boarding pass o totales congelados en factura.

Para esta version base:

- esas excepciones no se implementan
- el diseno prioriza consistencia conceptual sobre optimizacion prematura

## 7. Checklist de revision a 3FN

- cada tabla tiene PK clara
- no hay columnas multivalor
- no hay listas embebidas
- toda relacion N:M esta resuelta
- los catalogos estan separados
- las jerarquias maestras no se duplican
- no hay atributos descriptivos redundantes en transaccionales
- no hay agregados derivados persistidos sin justificacion formal

## 8. Nivel de garantia alcanzable en esta carpeta

Con los artefactos generados aqui se puede asegurar:

- diseno intencionalmente orientado a 3FN
- documentacion explicita de reglas y exclusiones
- DDL coherente con esa estrategia

Lo que aun falta para cierre tecnico total:

- ejecutar el DDL en PostgreSQL real
- revisar warnings o ajustes de sintaxis
- validar el modelo con casos de negocio extremos

