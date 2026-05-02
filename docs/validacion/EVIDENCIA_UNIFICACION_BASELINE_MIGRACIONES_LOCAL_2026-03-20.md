# Evidencia de Unificacion Baseline + Migraciones Local (2026-03-20)

## 1. Objetivo

Confirmar que la recreacion limpia local ya no deja una brecha entre el DDL
base congelado y el journal de migraciones versionadas.

## 2. Flujo validado

- `infra/docker/recrear_instalacion_limpia.ps1`
- Contrato operativo esperado:
  - `DDL base -> migraciones versionadas -> seeds -> gates`

## 3. Controles verificados

| Control | Resultado esperado | Resultado observado |
|---------|--------------------|---------------------|
| Carga de `db/ddl/modelo_postgresql.sql` | OK | OK |
| Ejecucion de `infra/tools/aplicar_migraciones.ps1` durante la recreacion | OK | OK |
| `public.schema_migration_journal` presente tras la recreacion | >= 1 fila | `1` fila |
| `public.schema_migration_lock` presente tras la recreacion | tabla disponible | presente (`0` filas activas, esperado sin lock retenido) |
| Diagnostico local tras la recreacion | journal visible | `schema_migration_journal (flydb): 1` |
| Gate integral `infra/tools/ejecutar_gate_pre_release.ps1` | Verde | Verde |

## 4. Ejecucion realizada

- Validacion documental:
  - `.\infra\tools\ejecutar_gate_pre_release.ps1 -SkipDocker`
  - Resultado: `OK`
- Validacion integral con Docker real:
  - `.\infra\tools\ejecutar_gate_pre_release.ps1`
  - Resultado: `OK`
- Observaciones del flujo:
  - La migracion `20260319213000__bootstrap_migration_journal` se aplico durante
    la recreacion limpia.
  - El journal quedo registrado con `1` migracion aplicada.
  - El diagnostico posterior ya no reporta `schema_migration_journal` como
    ausente.

## 5. Criterio de cierre

Se considera cerrada la brecha cuando:

1. El rebuild limpio materializa el journal sin pasos manuales adicionales.
2. Diagnostico y observabilidad dejan de reportar `schema_migration_journal`
   como ausente despues de la recreacion.
3. El gate integral vuelve a quedar en verde con Docker real.

Estado del corte: `CUMPLIDO`.

## 6. Lectura arquitectonica

- `db/ddl/modelo_postgresql.sql` permanece como baseline historico congelado.
- Las migraciones versionadas quedan como delta operativo obligatorio
  post-release.
- El rebuild limpio pasa a expresar una sola historia operativa y reduce el
  riesgo de doble fuente de verdad entre baseline y journal.
