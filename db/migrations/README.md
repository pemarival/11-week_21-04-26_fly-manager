# Migraciones Versionadas

Este directorio define el contrato operativo de cambios de esquema despues del
release congelado.

## Estructura

- `up/`: scripts de avance
- `down/`: scripts de rollback

## Convencion de nombres

Cada migracion debe existir en par:

- `YYYYMMDDHHMMSS__descripcion_snake_case.up.sql`
- `YYYYMMDDHHMMSS__descripcion_snake_case.down.sql`

Ejemplo:

- `20260320103000__add_index_ticket_issued_at.up.sql`
- `20260320103000__add_index_ticket_issued_at.down.sql`

## Metadatos minimos requeridos en SQL

Cada archivo debe incluir encabezado:

```sql
-- MIGRATION: 20260320103000
-- NAME: add_index_ticket_issued_at
-- ROLLBACK: reversible
-- AUTHOR: <autor>
```

## Flujo recomendado

1. Crear par `up/down`.
2. Ejecutar `infra/tools/validar_migraciones.ps1`.
3. Ejecutar `infra/tools/aplicar_migraciones.ps1` en entorno de prueba.
4. Validar gates SQL y documentales.
5. Solo despues promover al siguiente entorno.

## Contrato con el baseline limpio

- `db/ddl/modelo_postgresql.sql` permanece como baseline congelado del release.
- Toda recreacion limpia debe ejecutar despues `infra/tools/aplicar_migraciones.ps1`
  antes de cargar seeds.
- El resultado esperado del rebuild local es:
  `DDL base -> migraciones versionadas -> seeds -> gates`.
- Tras la recreacion limpia, `public.schema_migration_journal` debe existir y
  registrar al menos la migracion bootstrap.

## Bootstrap actual

- La primera migracion operativa es
  `20260319213000__bootstrap_migration_journal`.
- Esta crea `public.schema_migration_journal`, tabla usada para registrar
  checksum, autor, duracion y fecha de cada migracion aplicada.
- La ejecucion de migraciones usa ademas `public.schema_migration_lock` como
  lock operacional con lease para evitar carreras entre ejecuciones paralelas.
