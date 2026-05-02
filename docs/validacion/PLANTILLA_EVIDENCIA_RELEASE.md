# Plantilla Unica de Evidencia de Release

## 1. Identificacion del corte

- Fecha:
- Rama:
- Commit:
- Responsable:
- Objetivo del corte:

## 2. Resultado global

- Estado del gate: (`APTO PARA PRE-RELEASE` | `RELEASE CONGELADO`)
- Bloqueantes abiertos:
- Excepciones controladas:
- Hallazgos no bloqueantes:

## 3. Evidencia tecnica obligatoria

| Item | Evidencia | Resultado |
|------|-----------|-----------|
| DDL validado | `docs/validacion/VALIDACION_DDL_3FN.md` | |
| Carga deterministica DDL base + migraciones + seeds + gates | `infra/docker/recrear_instalacion_limpia.ps1` | |
| Regresion SQL post-seed | `infra/tools/ejecutar_regresion_post_seed.ps1` + `infra/sql/regresion_post_seed.sql` | |
| Rutas documentales | `infra/tools/validar_rutas_docs.ps1` | |
| Gate operativo unificado | `infra/tools/ejecutar_gate_pre_release.ps1` | |
| Seguimiento de inconsistencias | `docs/validacion/SEGUIMIENTO_INCONSISTENCIAS_ESTRUCTURALES.md` | |

## 4. Resumen de hallazgos

- IE-001:
- IE-002:
- IE-003..IE-010:

## 5. Integridad del paquete

Agregar checksums SHA-256 de artefactos criticos:

```text
<ruta>|<sha256>
```

## 6. Decisiones

- Decision de release:
- Alcance congelado:
- Deuda no bloqueante delegada a backlog:

## 7. Proximos pasos

1.
2.
3.
