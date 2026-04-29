# Seguimiento Estricto de Inconsistencias Estructurales

## Objetivo

Registrar de forma continua los posibles desalineamientos arquitectonicos y estructurales del sistema FLY para preparar una futura fase de refactorizacion con evidencia.

## Convenciones

- `Bloqueante`: impide o invalida la siguiente fase
- `Alta`: no bloquea hoy, pero compromete consistencia o realismo
- `Media`: genera deuda tecnica o ambiguedad documental
- `Observacion`: mejora recomendada sin impacto inmediato

Estados:

- `Abierto`
- `En seguimiento`
- `Resuelto`
- `Excepcion controlada`

## Hallazgos Iniciales

| ID | Fecha | Objeto | Severidad | Estado | Hallazgo | Impacto | Recomendacion |
|----|-------|--------|-----------|--------|----------|---------|---------------|
| IE-001 | 2026-03-19 | Politica de seeds | Alta | En seguimiento | El requerimiento de `1000` filas por tabla entra en conflicto con catalogos cerrados del dominio. | Puede degradar realismo y contaminar la base canonica que servira para refactor. | Mantener `seed canonico` realista y tratar catalogos cerrados como excepcion controlada. |
| IE-002 | 2026-03-19 | Documentacion historica | Media | Abierto | Existen documentos heredados que aun referencian rutas previas a la reorganizacion del repositorio. | Riesgo de confusion al auditar evidencias y fuentes. | Alinear progresivamente referencias internas o marcar los artefactos como historicos. |
| IE-003 | 2026-03-19 | Seeds masivos | Alta | Resuelto | El seed volumetrico fue extendido por lotes y ahora cubre flujo comercial + flujo de viaje en volumen (`ticket_segment`, `seat_assignment`, `baggage`, `check_in`, `boarding_pass`, `boarding_validation`) con escenarios de `refund`. | Se cierra el gap operativo de volumen en entidades aplicables y se mantiene integridad referencial/cronologica en ejecucion limpia. | Mantener crecimiento por lotes controlados y evitar inflar catalogos cerrados fuera de excepcion documentada. |
| IE-004 | 2026-03-19 | Orden de carga | Alta | Resuelto | La matriz topologica definitiva de carga por FK ya fue extraida y documentada. | Reduce el riesgo de fallas por secuencia incorrecta al poblar datos. | Usar `docs/validacion/MATRIZ_ORDEN_CARGA_SEEDS.md` como contrato operativo del pipeline. |
| IE-005 | 2026-03-19 | Reglas temporales | Alta | Resuelto | Politica de cronologia definida y documentada en `docs/validacion/POLITICA_CRONOLOGIA_DATOS_SINTETICOS.md`. Cubre: epoch tarifario, ventanas de vuelos historicos, ciclo de vida de reserva, apertura de cuentas de lealtad, husos horarios por aeropuerto (incluyendo EDT de Miami en marzo 2026) y restricciones de consistencia cronologica. | Seed canonico aplica la politica en todos sus timestamps. | Usar como contrato obligatorio en el seed volumetrico. |
| IE-006 | 2026-03-19 | Infraestructura local | Observacion | Resuelto | El contenedor de PostgreSQL esta estandarizado en `localhost:5435` con carga deterministica de `DDL + seeds + validaciones` desde script operativo. | Reduce dispersion operativa y facilita pruebas repetibles con diagnostico y fail-fast. | Mantener esta convencion como punto unico de entrada local. |
| IE-007 | 2026-03-19 | Validacion funcional punta a punta | Bloqueante | Resuelto | El seed canonico implementa 3 flujos comerciales completos: (1) Ana Garcia BOG-MIA-MAD Business con conexion, (2) Carlos Mendoza BOG-MDE Economy, (3) Laura Torres BOG-MIA Economy. Cada flujo cubre: person → customer → loyalty → reservation → sale → ticket → ticket_segment → seat_assignment → baggage → check_in → boarding_pass → boarding_validation → payment → payment_transaction → invoice → invoice_line → miles_transaction. Todos los timestamps son consistentes con la politica IE-005. | La base ahora demuestra comportamiento funcional integral end-to-end. | Ejecutar `99_validaciones_post_seed.sql` para confirmar conteos y consistencia. |
| IE-008 | 2026-03-19 | Cronograma vs estado real | Media | Resuelto | Se alinearon cronograma, canvas, landing y reportes al estado tecnico actual: seed canónico y volumétrico cerrados; QA cruzado documental como fase activa previa a release. | Se elimina la lectura inconsistente entre evidencia tecnica y narrativa visual/documental. | Mantener verificacion cruzada en cada corte para evitar regresion narrativa. |
| IE-009 | 2026-03-19 | Politica de validacion post-seed | Media | Resuelto | `99_validaciones_post_seed.sql` quedo en 7 fases: conteo general, gate canonico bloqueante, tablas sin datos, flujo critico E2E, spot checks referenciales, consistencia cronologica, y gate volumetrico bloqueante con umbrales por entidad aplicable. | Se elimina la ambiguedad de validacion y se vuelve auditable el cierre de volumen sin falsos positivos por catalogos cerrados. | Mantener separados los umbrales canonicos y volumetricos para evitar regresiones de criterio. |

## Regla de Actualizacion

Cada nuevo hallazgo debe registrar:

- evidencia concreta
- archivo o modulo afectado
- impacto funcional y estructural
- propuesta de correccion o criterio de excepcion
- fecha y estado actualizado
