# Politica de Migraciones y Rollback (S2.1)

## 1. Objetivo

Estandarizar como se versionan, validan, aplican y revierten cambios de esquema
despues del release congelado, con trazabilidad auditable y riesgo controlado.

## 2. Alcance

- Aplica a cambios en estructura de base de datos (tablas, indices, constraints,
  vistas o datos tecnicos de soporte de esquema).
- No reemplaza el DDL maestro historico; lo complementa desde el corte
  post-release.
- El DDL maestro opera como baseline congelado; toda recreacion limpia debe
  materializar despues el bootstrap del journal de migraciones antes de cargar
  seeds.

## 3. Contrato tecnico obligatorio

1. Toda migracion debe existir en par `up/down` bajo `db/migrations/`.
2. Nombre obligatorio:
   - `YYYYMMDDHHMMSS__descripcion_snake_case.up.sql`
   - `YYYYMMDDHHMMSS__descripcion_snake_case.down.sql`
3. Encabezado obligatorio en ambos archivos:
   - `-- MIGRATION: <id>`
   - `-- NAME: <nombre>`
   - `-- ROLLBACK: reversible|irreversible`
   - `-- AUTHOR: <autor>`
4. Se prohibe editar una migracion ya aplicada; cambios posteriores se hacen con
   una nueva migracion.

## 4. Flujo operativo minimo

1. En reconstruccion limpia:
   - `.\infra\docker\recrear_instalacion_limpia.ps1`
   - Contrato: `DDL base -> migraciones versionadas -> seeds -> gates`
2. Validar estructura y metadatos:
   - `.\infra\tools\validar_migraciones.ps1`
3. Aplicar pendientes en orden:
   - `.\infra\tools\aplicar_migraciones.ps1`
4. Ejecutar gate de corte:
   - `.\infra\tools\ejecutar_gate_pre_release.ps1`
5. En contingencia, revertir ultima migracion (si procede):
   - `.\infra\tools\revertir_ultima_migracion.ps1`

## 5. Registro auditable

- Tabla de control: `public.schema_migration_journal`.
- Tabla de lock operacional: `public.schema_migration_lock`.
- Campos minimos registrados: `migration_id`, `migration_name`,
  `checksum_sha256`, `script_path`, `rollback_mode`, `execution_ms`,
  `executed_by`, `executed_at`.
- El checksum permite detectar alteraciones posteriores de scripts aplicados.
- El lock operacional usa lease temporal para evitar ejecuciones concurrentes
  desde sesiones distintas de `psql`/`docker exec`.

## 6. Reglas de rollback

1. Si `ROLLBACK = reversible`, debe existir script down operativo.
2. Si `ROLLBACK = irreversible`, el rollback automatizado exige uso explicito de
   `-ForceIrreversible` y aprobacion arquitectonica.
3. Ningun rollback debe ejecutarse sin evidencia del motivo, alcance e impacto.

## 7. Evidencia requerida por corte

- Evidencia de reconstruccion limpia con journal materializado.
- Salida de `validar_migraciones.ps1`.
- Salida de `aplicar_migraciones.ps1` (o `-DryRun` cuando corresponda).
- Estado del gate integral pre-release.
- Nota de cambios y riesgo residual en `docs/validacion/`.
