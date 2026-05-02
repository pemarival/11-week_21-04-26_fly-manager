# Plan de Refactor Visual del Portal Arquitectonico (2026-03-20)

## 1. Objetivo

Transformar la landing principal, el canvas, el informe funcional y el
cronograma en una capa visual unificada, legible y persuasiva que exprese con
claridad el valor del proyecto FLY para audiencias ejecutivas, funcionales y
técnicas.

Estado actual:

- V1 ejecutada con matriz IA del portal.
- V2 iniciada con nueva landing como portal maestro.
- Navegacion principal ya unificada entre portal, canvas, funcionalidades y cronograma.

La meta no es "decorar" el paquete, sino hacer visible el valor que ya existe:

- baseline 3FN validado
- estabilización operativa cerrada
- CI/CD inicial remoto ya operativo
- trazabilidad entre modelo, evidencias, riesgos y continuidad

## 2. Diagnostico actual

### 2.1 Hallazgos principales

1. La landing principal contiene demasiado contenido técnico en bloques largos y
   compite consigo misma por atención.
2. Los SVG y diagramas tienen demasiada densidad visual, lo que vuelve difícil
   leer relaciones, etiquetas y narrativa de valor.
3. Existen varios estilos visuales simultáneos:
   - landing oscura y altamente decorativa
   - canvas tipo tablero técnico
   - informe funcional tipo reporte editorial
   - cronograma tipo tablero operativo
4. La navegación entre piezas existe, pero todavía no se comporta como un
   sistema de información unificado.
5. El proyecto comunica muy bien "qué existe" técnicamente, pero comunica menos
   "por qué importa" y "cómo se consume" por otros equipos.
6. Hay duplicación parcial de mensajes entre landing, canvas, informe y
   cronograma, sin una jerarquía clara de lectura.
7. La capa visual actual no separa suficientemente tres niveles de mensaje:
   - ejecutivo
   - funcional
   - técnico

### 2.2 Impacto de negocio

- Un lector nuevo puede percibir complejidad, pero no necesariamente valor.
- Un equipo backend/frontend puede no entender rápido cuál es el punto de entrada
  correcto.
- Un sponsor o arquitecto externo puede ver "mucho trabajo" sin captar la
  madurez real del baseline.

## 3. Principios de rediseño

1. Una sola narrativa transversal.
2. Cada página debe tener un propósito único y evidente.
3. El valor del proyecto debe leerse antes que el detalle técnico.
4. Los diagramas deben explicar, no impresionar.
5. La navegación debe reducir fricción y duplicación.
6. La capa visual debe mantener consistencia con el estado real del repositorio.
7. Toda afirmación visual importante debe poder trazarse a un artefacto o
   evidencia real.

## 4. Arquitectura visual objetivo

## 4.1 Landing principal

Rol esperado:

- portal maestro
- entrada ejecutiva al proyecto
- resumen del valor, estado, madurez y rutas de exploración

Debe responder en menos de 30 segundos:

- qué es FLY
- por qué el proyecto tiene valor
- qué está realmente implementado
- qué puede hacer otro equipo con esta base
- hacia dónde navegar según el perfil del lector

## 4.2 Canvas arquitectonico

Rol esperado:

- tablero de arquitectura y decisiones
- mapa de capacidades, riesgos, estado y continuidad

Debe priorizar:

- decisiones clave
- módulos/capas
- riesgos cerrados vs riesgos futuros
- relación entre baseline, estabilización y CI/CD

## 4.3 Informe funcional

Rol esperado:

- traducir la arquitectura a capacidades funcionales entendibles
- explicar flujos y consumo por producto/backend/frontend

Debe priorizar:

- qué resuelve cada módulo
- flujo operativo real
- estado de preparación para otros equipos
- artefactos que deben consultar

## 4.4 Cronograma

Rol esperado:

- mostrar evolución del proyecto
- contar el camino recorrido y el siguiente frente

Debe priorizar:

- hitos
- cierres reales
- próximos pasos
- dependencia entre fases

## 5. Problemas concretos a corregir

## 5.1 Narrativa

- Falta una propuesta de valor visible al inicio.
- El lenguaje está muy orientado a "inventario técnico" y menos a "resultado".
- No hay una historia clara para distintos tipos de lector.

## 5.2 Legibilidad

- Diagramas muy densos para lectura rápida.
- Demasiados colores y estados compitiendo.
- Bloques de texto largos sin suficiente ritmo visual.
- Métricas importantes aparecen, pero no siempre resaltadas como prueba de
  madurez.

## 5.3 Navegación

- La navegación horizontal existe, pero falta una arquitectura de rutas más
  clara:
  - visión ejecutiva
  - arquitectura
  - capacidades
  - evolución
  - evidencias
- No existe todavía una sección clara de "empieza aquí" para otros equipos.

## 5.4 Unificación visual

- Cada HTML usa un lenguaje visual distinto.
- Falta un sistema de diseño mínimo compartido:
  - tokens
  - tipografía
  - badges
  - tarjetas
  - tablas
  - navegación
  - estados

## 6. Plan de trabajo propuesto

### Fase V1 - Definicion narrativa e IA

Objetivo:

- definir la historia maestra del portal

Entregables:

- mapa de audiencias
- arquitectura de información unificada
- inventario de mensajes por página
- matriz "qué vive en cada HTML"

Salida esperada:

- ya no habrá duplicación arbitraria entre landing, canvas, informe y cronograma

### Fase V2 - Rediseño de la landing principal

Objetivo:

- convertir la landing en portal ejecutivo-técnico

Cambios esperados:

- hero con propuesta de valor real
- bloque "qué logramos"
- bloque "estado actual"
- bloque "listo para otros equipos"
- bloque "recorridos por perfil"
- bloque de accesos a artefactos clave
- reducción de diagramas densos en portada

Salida esperada:

- un lector debe entender el valor del proyecto sin entrar aún al detalle

### Fase V3 - Refactor del canvas arquitectonico

Objetivo:

- hacer que el canvas explique arquitectura en vez de saturar

Cambios esperados:

- simplificar tablas y densidad
- reorganizar por decisiones/capas/riesgos
- crear una sección de "arquitectura en una mirada"
- reemplazar diagramas ilegibles por vistas más sintéticas

Salida esperada:

- lectura técnica clara en desktop y aceptable en laptop

### Fase V4 - Refactor del informe funcional

Objetivo:

- traducir la estructura a capacidades consumibles por backend/frontend

Cambios esperados:

- mapa de módulos funcionales
- flujos clave por dominio
- "cómo consumir esta base"
- sección explícita para equipos de aplicación
- enlaces a tablas, seeds, roadmap y evidencias relevantes

Salida esperada:

- handoff funcional más claro para otros equipos

### Fase V5 - Refactor del cronograma

Objetivo:

- narrar evolución y próximos frentes con claridad

Cambios esperados:

- separar hitos cerrados, frente actual y siguientes decisiones
- mostrar dependencias sin ruido
- mejorar lectura temporal
- enlazar cada tramo a evidencia o documento rector

Salida esperada:

- cronograma más comprensible y útil para seguimiento real

### Fase V6 - Sistema visual y QA transversal

Objetivo:

- unificar todo como portal coherente

Cambios esperados:

- tokens compartidos
- componentes repetibles
- navegación unificada
- validación responsive
- revisión de contraste y legibilidad
- revisión de enlaces

Salida esperada:

- portal consistente, mantenible y explicable

## 7. Entregables finales

1. Landing principal refactorizada como portal maestro.
2. Canvas arquitectónico rediseñado para lectura real.
3. Informe funcional orientado a consumo por equipos.
4. Cronograma visualmente claro y narrativamente alineado.
5. Sistema de navegación unificado entre HTML.
6. Sistema visual base compartido.
7. Matriz de enlaces y accesos cruzados entre artefactos.

## 8. Criterios de aceptacion

El frente visual se considerará cerrado cuando:

1. La landing responda claramente:
   - qué es el proyecto
   - qué valor tiene
   - qué está implementado
   - qué debe leer cada audiencia
2. Ningún diagrama principal requiera zoom mental excesivo para entenderse.
3. Los cuatro HTML compartan navegación, lenguaje visual y jerarquía coherente.
4. Exista una ruta explícita para backend/frontend.
5. Los enlaces críticos funcionen sin rutas rotas.
6. La lectura en móvil/laptop no degrade el mensaje principal.

## 9. Riesgos del frente

1. Querer meter demasiado detalle técnico en la portada.
2. Mantener diagramas densos por apego al contenido ya existente.
3. Cambiar estética sin resolver arquitectura de información.
4. Perder consistencia con el estado real del repositorio.

## 10. Orden recomendado de ejecucion

1. Definir narrativa maestra y arquitectura de información.
2. Rediseñar landing principal.
3. Rediseñar canvas.
4. Rediseñar informe funcional.
5. Rediseñar cronograma.
6. Ejecutar QA visual/documental final.

## 11. Recomendacion arquitectonica

No recomiendo hacer retoques aislados archivo por archivo sin esta secuencia.
Lo correcto es tratar estos HTML como una sola capa de producto documental.

El proyecto ya no necesita "más contenido"; necesita mejor representación del
valor que ya construimos.
