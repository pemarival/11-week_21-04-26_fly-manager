# Diccionario de Datos (Base Inicial)

## Estado

Documento en construccion para consolidar el diccionario tecnico-funcional del
modelo `FLY v2-estable-3fn`.

Fecha de corte: 2026-03-19.

## Fuente de verdad actual

- DDL oficial: `db/ddl/modelo_postgresql.sql`
- Modelo documentado: `docs/datos/modelo_documentado.md`
- Reglas 3FN: `docs/datos/NORMALIZACION_3FN.md`

## Alcance minimo para cierre

1. Definicion funcional por tabla.
2. Definicion de PK/FK y reglas de negocio relevantes.
3. Campos sensibles y reglas de calidad de dato.
4. Mapeo de tablas por modulo (12 modulos canonicos).

## Nota operativa

Hasta cerrar este documento, cualquier validacion de detalle por entidad debe
tomar como referencia principal el DDL oficial.
