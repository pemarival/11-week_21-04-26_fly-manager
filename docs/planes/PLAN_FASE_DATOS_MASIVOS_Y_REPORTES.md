# Plan Maestro de Implementacion - Contenedor, Reorganizacion, Seeds Masivos y Reportes

## 1. Proposito

Este plan define la siguiente fase de trabajo del paquete arquitectonico `FLY v2-estable-3fn` para llevarlo desde un esquema validado en DDL hacia una base operable para demostracion, auditoria estructural, refactor futuro y presentacion ejecutiva.

El alcance de esta fase incluye:

- contenedor PostgreSQL estable sobre el puerto `5435`
- reorganizacion del repositorio por capas tecnicas
- estrategia de generacion de inserts masivos y funcionales
- seguimiento estricto de inconsistencias arquitectonicas y estructurales
- construccion de reportes HTML de capacidades del sistema y cronograma de realizacion

## 2. Objetivos Arquitectonicos

1. Garantizar un entorno reproducible para ejecutar `DDL + inserts + validaciones`.
2. Separar claramente infraestructura, base de datos, documentacion y piezas de presentacion.
3. Diseñar un pipeline de datos semilla que preserve integridad referencial y orden de carga.
4. Detectar, registrar y priorizar inconsistencias estructurales antes de una futura refactorizacion.
5. Dejar una base documental y visual apta para exposicion tecnica y ejecutiva.

## 3. Decision Arquitectonica Critica

La exigencia de "`1000` registros por tabla" no tiene el mismo impacto en todos los tipos de tablas.

Clasificacion arquitectonica:

- `Referencia fija`: catalogos cerrados o normativos. Ejemplo: estados, tipos, clases, motivos, canales.
- `Maestras operativas`: actores, activos o ubicaciones con variabilidad alta. Ejemplo: clientes, empleados, aeronaves, aeropuertos.
- `Transaccionales`: reservas, tickets, pagos, facturas, segmentos, eventos.
- `Puente / detalle`: relaciones N:M y lineas de detalle.

Riesgo:

- Inflar catalogos cerrados hasta `1000` filas puede degradar el realismo del dominio y contaminar la futura refactorizacion.

Decicion de trabajo propuesta para esta fase:

- mantener un `seed canonico` semanticamente correcto para catalogos cerrados
- construir un `seed volumetrico` para tablas maestras, transaccionales y puente con minimo de `1000` filas
- registrar como excepcion controlada cualquier tabla cuyo crecimiento artificial rompa el significado del negocio

Esta decision protege la consistencia del modelo y deja trazabilidad formal para el refactor posterior.

## 4. Estructura Objetivo del Repositorio

```text
fly-bd/
|-- app/
|   `-- landing/
|       |-- index.html
|       |-- styles.css
|       `-- script.js
|-- db/
|   |-- ddl/
|   |   `-- modelo_postgresql.sql
|   `-- seeds/
|       |-- README.md
|       |-- 00_seed_canonico.sql
|       |-- 01_seed_volumetrico.sql
|       `-- 99_validaciones_post_seed.sql
|-- docs/
|   |-- arquitectura/
|   |-- datos/
|   |-- planes/
|   `-- validacion/
|-- infra/
|   `-- docker/
|       |-- docker-compose.yml
|       `-- .env.example
|-- reports/
|   |-- html/
|   |   `-- funcionalidades_sistema.html
|   `-- cronograma/
|       `-- cronograma_realizacion.html
`-- architecture/
    `-- canvas/
        `-- canvas_arquitectura.html
```

## 5. Fases de Ejecucion

### Fase 1. Ordenamiento de base tecnica

- mover artefactos actuales a su carpeta definitiva
- corregir rutas locales en landing y documentos HTML
- preservar compatibilidad de descargas y referencias

Entregables:

- estructura reorganizada
- referencias locales corregidas

### Fase 2. Infraestructura reproducible

- definir contenedor PostgreSQL `16` en puerto `5435`
- exponer volumen persistente y punto de montaje de scripts
- validar arranque y conectividad local

Entregables:

- `infra/docker/docker-compose.yml`
- `infra/docker/.env.example`
- evidencia de arranque

### Fase 3. Arquitectura de seeds

- inventariar tablas y dependencias
- clasificar tablas por tipo arquitectonico
- definir orden de carga por capas: referencia, maestra, transaccional, detalle, puente
- preparar estrategia para datos realistas y consistentes

Entregables:

- `db/seeds/README.md`
- matriz de orden de carga
- criterios de excepcion para catalogos cerrados

### Fase 4. Seguimiento estricto de inconsistencias

- crear registro formal de hallazgos arquitectonicos y estructurales
- separar hallazgos por severidad: bloqueante, alta, media, observacion
- documentar impacto, evidencia, area afectada y recomendacion de refactor

Entregables:

- documento de seguimiento vivo
- checklist de validaciones estructurales

### Fase 5. Reporteria HTML

- construir reporte navegable de funcionalidades del sistema
- construir HTML de cronograma de realizacion
- alinear ambos reportes con el baseline arquitectonico y el DDL canonico

Entregables:

- `reports/html/funcionalidades_sistema.html`
- `reports/cronograma/cronograma_realizacion.html`

## 6. Estrategia para Inserts Masivos

### 6.1 Principios

- ningun insert debe violar PK, FK, UNIQUE ni CHECK
- los datos deben parecer plausibles para una aerolinea comercial
- el script debe poder reejecutarse contra una base limpia
- el volumen debe crecer respetando dependencias y temporalidad del negocio

### 6.2 Paquetes de carga

1. `00_seed_canonico.sql`
   - catalogos, parametros, tablas base y datos irreductibles del dominio
2. `01_seed_volumetrico.sql`
   - crecimiento masivo controlado sobre maestras, transaccionales y detalle
3. `99_validaciones_post_seed.sql`
   - conteos, integridad, cobertura y chequeos de consistencia

### 6.3 Reglas de realismo

- clientes con nombres, documentos, paises, contactos y fechas plausibles
- empleados con cargos, bases y periodos de contratacion realistas
- aeronaves, aeropuertos, rutas y vuelos consistentes en capacidad y ubicacion
- reservas, tickets, pagos e invoices con cronologia coherente
- programas de lealtad con acumulacion, movimientos y niveles verificables

### 6.4 Regla de conservacion del script funcional

- el script final de inserts no reemplaza el seed canonico
- el seed canonico sigue siendo la base confiable de ejecucion
- el seed volumetrico se apoya sobre el seed canonico y no debe romperlo

## 7. Seguimiento de Inconsistencias para Refactor

Cada hallazgo debera registrar:

- identificador unico
- fecha de deteccion
- objeto afectado
- tipo de inconsistencia
- severidad
- evidencia
- impacto funcional y arquitectonico
- recomendacion de correccion
- estado

Tipos de inconsistencia a vigilar:

- redundancia estructural
- dependencia transitoria residual
- cardinalidad dudosa
- catalogo inflado artificialmente
- nomenclatura inconsistente
- dominio ambiguo
- constraint ausente o demasiado permisivo
- indice faltante
- coupling entre modulos

## 8. Criterios de Aceptacion

- el contenedor PostgreSQL inicia y escucha por `localhost:5435`
- la reorganizacion de carpetas no rompe la landing ni los enlaces de descarga
- la arquitectura de seeds queda documentada y lista para implementacion
- existe un registro formal de inconsistencias estructurales
- los reportes HTML abren correctamente y son coherentes con el sistema FLY

## 9. Orden de Ejecucion Inmediato

1. reorganizar carpetas y ajustar referencias
2. agregar contenedor PostgreSQL en `5435`
3. dejar base documental y tecnica para seeds masivos
4. construir reporte HTML de funcionalidades
5. construir HTML de cronograma
6. iniciar la matriz estricta de inconsistencias estructurales

## 10. Nota de Gobierno Tecnico

Esta fase no cierra aun la generacion de todos los `inserts` masivos. Cierra primero el marco tecnico y documental correcto para poder construirlos con trazabilidad, evitando errores de arquitectura que luego contaminen el refactor.
