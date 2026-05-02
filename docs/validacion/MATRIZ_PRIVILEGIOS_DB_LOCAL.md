# Matriz de Privilegios DB Local (S3.3)

## Objetivo

Definir el modelo minimo de privilegios para PostgreSQL local, separando
administracion, runtime operativo, lectura y auditoria.

## Roles

| Rol | Tipo | Login | Alcance | Uso esperado |
|-----|------|-------|---------|--------------|
| `fly_admin` | administrativo | Si | bootstrap owner, migraciones, mantenimiento break-glass | Solo por socket local interno del contenedor |
| `fly_app_rw` | grupo | No | DML completo sobre `public` + `TEMP` sobre la base local objetivo | Base para futuros logins de aplicacion y probes temporales seguros |
| `fly_app_ro` | grupo | No | `SELECT` sobre `public` | Consultas operativas y lectura controlada |
| `fly_app_audit` | grupo | No | `SELECT` + `pg_read_all_stats` | Auditoria, observabilidad y soporte |
| `fly_app_ddl` | grupo | No | `CONNECT` a la base + `USAGE/CREATE` en schema `public` + lectura de `public` | Crear tablas, vistas, funciones, secuencias y otros objetos nuevos sin usar `fly_admin` |
| `fly_app_dml` | grupo | No | DML amplio sobre `public` + `TEMP` sobre la base local objetivo | Usuarios delegados que requieren manipulacion de datos mas amplia que el runtime minimo |
| `FLY_APP_RW_USER` (`fly_local_rw`) | login local | Si | hereda de `fly_app_rw` | Uso cotidiano local con escritura controlada |
| `FLY_APP_RO_USER` (`fly_local_ro`) | login local | Si | hereda de `fly_app_ro` | Consulta operativa sin DML |
| `FLY_APP_AUDIT_USER` (`fly_local_audit`) | login local | Si | hereda de `fly_app_audit` | Soporte, diagnostico y observabilidad |

## Reglas

1. `fly_admin` no debe ser el login de uso cotidiano de la aplicacion.
2. Los logins futuros deben heredar de `fly_app_rw`, `fly_app_ro` o
   `fly_app_audit` segun necesidad.
3. `PUBLIC` no debe retener `CONNECT` sobre la base ni `USAGE/CREATE` sobre el
   schema `public`.
4. Los privilegios por defecto de nuevas tablas y secuencias deben propagarse
   desde `fly_admin` hacia los roles de grupo.
5. Los logins operativos locales deben estar definidos en `infra/docker/.env`,
   ser distintos de `fly_admin` y validarse por conexion real.
6. Diagnostico y observabilidad deben resolver por defecto `FLY_APP_AUDIT_USER`.
7. El baseline de lectura debe resolver `FLY_APP_RO_USER`; la prueba temporal
   segura debe ejecutarse con `FLY_APP_RW_USER`.
8. La publicacion del puerto PostgreSQL local debe quedar confinada a loopback
   (`127.0.0.1`) salvo excepcion documentada.
9. `fly_admin` debe quedar bloqueado por TCP en `pg_hba.conf` y usarse solo
   como cuenta break-glass por socket local interno.
10. `fly_app_ddl` permite crear objetos nuevos en `public`, pero no sustituye al
    owner de objetos existentes para `ALTER/DROP`.
11. Si en el futuro se requiere DDL compartido sobre objetos existentes, debe
    definirse un owner-role dedicado; eso implica aceptar capacidad de
    `GRANT/REVOKE` sobre los objetos que dicho owner posea.
12. `fly_app_dml` existe para usuarios delegados con DML amplio y no reemplaza
    el perfil minimo cotidiano de `fly_app_rw`.
