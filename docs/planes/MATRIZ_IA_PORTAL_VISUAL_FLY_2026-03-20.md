# Matriz IA del Portal Visual FLY (2026-03-20)

## 1. Objetivo

Definir la arquitectura de informacion del portal visual FLY para que landing,
canvas, informe funcional y cronograma trabajen como un sistema narrativo unico.

## 2. Audiencias y pregunta principal

| Audiencia | Pregunta que trae | Pieza de entrada | Siguiente salto |
| --- | --- | --- | --- |
| Sponsor / liderazgo | "Que valor real tiene esto y en que nivel de madurez va?" | Landing | Cronograma + evidencias |
| Arquitectura / datos | "Como esta estructurada la solucion y que decisiones la gobiernan?" | Canvas | Roadmap + DDL + migraciones |
| Backend | "Sobre que contrato puedo empezar a construir?" | Informe funcional | DDL + rebuild limpio + gate |
| Frontend / producto | "Que flujos y conceptos del negocio ya estan estabilizados?" | Informe funcional | Landing + cronograma |
| Operacion / QA | "Como recreo, valido y audito la base?" | Landing | Scripts operativos + evidencias |

## 3. Rol de cada HTML

### 3.1 Landing

- Rol: portal maestro.
- Debe responder rapido que es FLY, que ya esta cerrado y por donde empezar.
- No debe intentar explicar todo el modelo ni mostrar diagramas densos.

### 3.2 Canvas

- Rol: mapa arquitectonico.
- Debe explicar decisiones, capas, riesgos y estado de gobierno.
- Debe ser la vista tecnica sintetica, no un mural saturado.

### 3.3 Informe funcional

- Rol: puente de consumo para backend, frontend y producto.
- Debe traducir el modelo a modulos, capacidades y flujos.
- Debe aclarar que ya se puede construir y que sigue siendo soporte de datos.

### 3.4 Cronograma

- Rol: historia del camino recorrido y siguiente frente.
- Debe demostrar continuidad, no solo fechas.

## 4. Jerarquia del mensaje

1. Valor del proyecto.
2. Estado y madurez actual.
3. Preparacion para otros equipos.
4. Arquitectura funcional y tecnica.
5. Evidencias y artefactos de soporte.

## 5. Matriz de contenido

| Contenido | Landing | Canvas | Funcional | Cronograma |
| --- | --- | --- | --- | --- |
| Propuesta de valor | Principal | Resumen corto | Resumen corto | Secundario |
| Estado del baseline | Principal | Principal | Principal | Principal |
| Rutas por audiencia | Principal | Secundario | Secundario | Secundario |
| Decisiones tecnicas | Resumen | Principal | Secundario | Secundario |
| Modulos y dominios | Resumen | Principal | Principal | Secundario |
| Flujos de negocio | Resumen | Secundario | Principal | Secundario |
| Evolucion temporal | Resumen | Secundario | Secundario | Principal |
| Evidencias y scripts | Principal | Principal | Principal | Principal |

## 6. Navegacion unificada

La capa visual debe exponer siempre estas rutas:

- Portal
- Canvas
- Capacidades
- Evolucion

Regla:

- La landing es el punto de entrada maestro.
- Las otras tres vistas deben permitir volver al portal sin friccion.

## 7. Guardrails de copy y visual

- Primero resultado, despues inventario tecnico.
- No usar diagramas complejos en portada.
- No repetir el mismo mensaje completo en las cuatro piezas.
- Toda afirmacion fuerte debe poder enlazarse a un artefacto real.
- Backend y frontend deben tener una ruta visible de "empieza aqui".

## 8. Criterio de terminado para la primera iteracion

Se considera cerrada la primera iteracion visual cuando:

- la landing se comporta como portal maestro;
- el lector entiende valor, estado y rutas en menos de 30 segundos;
- canvas, funcionalidades y cronograma comparten navegacion coherente;
- existen enlaces visibles para arquitectura, backend, frontend y operacion.
