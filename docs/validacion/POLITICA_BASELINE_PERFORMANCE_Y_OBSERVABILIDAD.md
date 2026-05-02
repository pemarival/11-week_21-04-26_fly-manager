# Politica de Baseline Performance y Observabilidad Local (S3)

## 1. Objetivo

Establecer una linea base medible de rendimiento y una fotografia minima de
salud operativa para PostgreSQL local, usando consultas reales del dominio FLY
sin alterar el baseline funcional ya estabilizado ni depender del login
administrativo para tareas cotidianas.

## 2. Alcance

- Consultas criticas de lectura y joins del flujo comercial y operativo.
- Una prueba de escritura segura sobre tabla temporal.
- Snapshot local de locks, actividad, cache y crecimiento.
- Uso por defecto de `FLY_APP_AUDIT_USER`, `FLY_APP_RO_USER` y `FLY_APP_RW_USER`
  segun el tipo de operacion.

## 3. Artefactos operativos

- `infra/tools/ejecutar_baseline_performance_local.ps1`
- `infra/tools/capturar_observabilidad_local.ps1`
- `infra/tools/diagnosticar_postgres_local.ps1`
- `infra/tools/validar_menor_privilegio_operativo_local.ps1`

## 4. Consultas baseline incluidas

- Busqueda operativa de vuelos por fecha.
- Itinerario completo cliente -> reserva -> ticket -> segmento -> vuelo.
- Conciliacion financiera de venta, pago, transaccion e invoice.
- Ledger de millas por cliente.
- Flujo de boarding.
- Escritura segura en tabla temporal con login RW.

## 5. Controles minimos de observabilidad

- Waiting locks: `0`
- Idle in transaction: `0`
- Long running queries (`> 60s`): `0`
- Cache hit ratio: `>= 95%`

## 6. Flujo recomendado

1. Ejecutar baseline de performance:
   - `.\infra\tools\ejecutar_baseline_performance_local.ps1`
   - Lecturas por defecto con `FLY_APP_RO_USER`; probe temporal con `FLY_APP_RW_USER`.
2. Capturar snapshot de observabilidad:
   - `.\infra\tools\capturar_observabilidad_local.ps1`
   - Ejecuta por defecto con `FLY_APP_AUDIT_USER`.
3. Ejecutar diagnostico puntual si aparece desviacion:
   - `.\infra\tools\diagnosticar_postgres_local.ps1`
   - Ejecuta por defecto con `FLY_APP_AUDIT_USER`.
4. Validar menor privilegio operativo:
   - `.\infra\tools\validar_menor_privilegio_operativo_local.ps1`
5. Publicar evidencia en `docs/validacion/`.

## 7. Criterio de salida inicial S3

- Baseline ejecutado con consultas dentro de umbral.
- Snapshot de observabilidad sin alertas en controles minimos.
- Evidencia publicada con tiempos y metricas observadas.
- Diagnostico, observabilidad y baseline ejecutables con logins operativos no administrativos.
