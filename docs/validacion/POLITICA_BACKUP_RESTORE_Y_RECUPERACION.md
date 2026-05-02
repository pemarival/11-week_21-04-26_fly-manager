# Politica de Backup, Restore y Recuperacion Local (S2.2)

## 1. Objetivo

Definir un procedimiento repetible para respaldar la base operativa local,
restaurarla en una base temporal de validacion y registrar evidencia objetiva
de recuperacion.

## 2. Alcance

- Aplica al entorno local Docker de PostgreSQL 16 usado como baseline tecnico.
- Cubre respaldo logico, restauracion controlada y verificacion por conteos.

## 3. Artefactos operativos

- `infra/tools/generar_backup_local.ps1`
- `infra/tools/restaurar_backup_local.ps1`
- `infra/tools/ejecutar_prueba_recuperacion_local.ps1`

## 4. Flujo minimo obligatorio

1. Generar backup logico en formato custom:
   - `.\infra\tools\generar_backup_local.ps1`
2. Restaurar en base temporal:
   - `.\infra\tools\restaurar_backup_local.ps1 -BackupPath <ruta>`
3. Ejecutar prueba integral con evidencia:
   - `.\infra\tools\ejecutar_prueba_recuperacion_local.ps1`

## 5. Reglas operativas

1. Los backups runtime se almacenan en `infra/runtime/` y no se versionan en Git.
2. La restauracion de validacion debe ejecutarse sobre una base temporal
   independiente del baseline operativo.
3. La aceptacion minima exige equivalencia de conteos entre origen y restaurado
   para las tablas `public`.
4. Toda prueba de recuperacion debe dejar evidencia en `docs/validacion/`.

## 6. Evidencia requerida

- Ruta del backup generado.
- Checksum SHA-256 del backup.
- Tiempos observados de backup y restore.
- Base origen y base restaurada.
- Conteos comparados y resultado final.

## 7. Criterio de salida S2.2

- Backup generado sin error.
- Restore completado sin error en base temporal.
- Diferencias de conteo: `0`.
- Evidencia publicada con tiempos observados.
