# Matriz de Consistencia Inicial

> Estado documental: **Historico (Fase 0)**.
> Fecha de referencia: **2026-03-19**.
> Uso correcto: registro de contradicciones iniciales antes de la consolidacion tecnica.
> No usar esta matriz como estado vigente de release; para estado actual revisar
> `docs/planes/PLAN_CONTINUIDAD_FASES_2026-03-19.md` y `docs/validacion/SEGUIMIENTO_INCONSISTENCIAS_ESTRUCTURALES.md`.

## Objetivo

Registrar contradicciones, vacios y decisiones necesarias para lograr una entrega coherente entre landing, DDL y documentacion.

## Estado de referencias

- Fuente A: `index.html`
- Fuente B: `canvas_arquitectura.html`
- Fuente C: archivos de descarga prometidos
- Fuente D: fuentes externas citadas por el canvas y no presentes en esta carpeta

## Matriz

| ID | Tema | Fuente A | Fuente B | Estado | Riesgo | Accion requerida |
| --- | --- | --- | --- | --- | --- | --- |
| MC-01 | Nombre del sistema | `SkyDB` | `Sistema FLY` | Abierto | Alto | Definir nombre canonico unico para release |
| MC-02 | Version objetivo | No explicita version cerrada | Declara `v2.0` y mezcla `v3 propuesta` | Abierto | Alto | Separar implementado vs roadmap |
| MC-03 | Conteo de entidades/tablas | `68 entidades` | `73 tablas v2` | Abierto | Alto | Recalcular desde DDL canonico |
| MC-04 | Conteo de FKs | `85+` | `95+` | Abierto | Alto | Recalcular desde DDL canonico |
| MC-05 | Flujo comercial raiz | `sale` domina la narrativa | `reservation (PNR)` domina la narrativa v2 | Abierto | Critico | Cerrar flujo canonico de negocio |
| MC-06 | Relacion ticket-segmento | Ticket parece depender directo de `flight_segment` | Se declara N:M con `ticket_flight_segment` | Abierto | Critico | Confirmar estructura canonica y reflejarla en todos los artefactos |
| MC-07 | Geolocalizacion | Se muestra como modulo activo en la landing | Se afirma que `geolocation` redundante fue eliminada en v2 | Abierto | Medio | Aclarar si existe modulo geoespacial sin tabla redundante o si debe cambiar la narrativa |
| MC-08 | Descarga de documentacion | `modelo_documentado.md` enlazado | No existe en carpeta | Abierto | Alto | Generar archivo real y validarlo |
| MC-09 | Descarga del DDL | `modelo_postgresql.sql` enlazado | No existe en carpeta | Abierto | Critico | Generar DDL oficial y validarlo en PostgreSQL |
| MC-10 | Fuentes de evidencia | No visibles | Se citan `V1`, `V2`, `SRS`, `MOSCOW` no presentes aqui | Abierto | Alto | Incorporar fuentes o bajar esas afirmaciones a "pendiente de verificacion" |
| MC-11 | Stack tecnico | No se explica en la landing | Go, PostgreSQL, Redis, Kafka, Kubernetes | Abierto | Medio | Decidir si la landing final lo mostrara o si quedara solo en dossier tecnico |
| MC-12 | Estado de implementacion | La landing parece final | El canvas mezcla aceptado, propuesto y pendiente | Abierto | Alto | Marcar el estado de cada elemento con precision |
| MC-13 | Metricas publicas | Hay metricas hero y stats | Hay metricas ampliadas y distintas | Abierto | Alto | Crear catalogo oficial de metricas derivadas del DDL |
| MC-14 | Calidad de release | No hay checklist visible | No hay checklist visible | Abierto | Alto | Crear checklist de validacion DDL y checklist de release |

## Prioridades inmediatas

1. Resolver MC-05 y MC-06 porque afectan la arquitectura del dominio.
2. Resolver MC-09 porque sin DDL no existe fuente tecnica canonica.
3. Resolver MC-01, MC-02, MC-03 y MC-04 para eliminar contradicciones publicas.
4. Resolver MC-08 y MC-10 para cerrar trazabilidad documental.

## Regla operativa desde esta fase

Hasta que exista `modelo_postgresql.sql` validado:

- ninguna cifra visible se considera definitiva
- ningun diagrama se considera canonico
- ninguna descarga publicada se considera release-ready
