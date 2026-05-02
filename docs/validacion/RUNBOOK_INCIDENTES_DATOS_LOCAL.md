# Runbook de Incidentes de Datos Local (S2.3)

## 1. Objetivo

Disponer de una guia corta y ejecutable para responder incidentes operativos
sobre la base local Docker de FLY Manager sin depender de memoria tribal.

## 2. Herramientas base

- Diagnostico rapido:
  - `.\infra\tools\diagnosticar_postgres_local.ps1`
- Observabilidad minima:
  - `.\infra\tools\capturar_observabilidad_local.ps1`
- Reinstalacion limpia con validacion:
  - `.\infra\docker\recrear_instalacion_limpia.ps1`
- Validacion de migraciones:
  - `.\infra\tools\validar_migraciones.ps1`
- Aplicacion de migraciones:
  - `.\infra\tools\aplicar_migraciones.ps1`
- Rollback de ultima migracion:
  - `.\infra\tools\revertir_ultima_migracion.ps1`
- Prueba de recuperacion:
  - `.\infra\tools\ejecutar_prueba_recuperacion_local.ps1`
- Hardening de seguridad:
  - `.\infra\tools\endurecer_seguridad_postgres_local.ps1`
- Auditoria de seguridad:
  - `.\infra\tools\auditar_seguridad_postgres_local.ps1`
- Inicializacion de secretos locales:
  - `.\infra\tools\inicializar_secretos_locales.ps1`
- Validacion de secretos locales:
  - `.\infra\tools\validar_secretos_locales.ps1`
- Provision de logins operativos:
  - `.\infra\tools\provisionar_logins_operativos_locales.ps1`
- Validacion de logins operativos:
  - `.\infra\tools\validar_logins_operativos_locales.ps1`
- Validacion de menor privilegio operativo:
  - `.\infra\tools\validar_menor_privilegio_operativo_local.ps1`
- Confinamiento admin bootstrap:
  - `.\infra\tools\confinar_admin_bootstrap_local.ps1`
- Validacion admin bootstrap:
  - `.\infra\tools\validar_admin_bootstrap_local.ps1`

## 3. Escenario A: la base no responde o el contenedor luce inestable

1. Ejecutar diagnostico:
   - `.\infra\tools\diagnosticar_postgres_local.ps1`
2. Capturar snapshot de observabilidad:
   - `.\infra\tools\capturar_observabilidad_local.ps1`
3. Revisar `docker ps`, logs recientes, locks y tamanos de base.
4. Si el problema es corrupcion local o estado incierto:
   - `.\infra\docker\recrear_instalacion_limpia.ps1`
5. Confirmar conteos minimos, salud del contenedor y evidencia de seguridad regenerada.

## 4. Escenario B: una migracion falla

1. Validar estructura de migraciones:
   - `.\infra\tools\validar_migraciones.ps1`
2. Revisar journal:
   - `.\infra\tools\diagnosticar_postgres_local.ps1`
3. Si la ultima migracion quedo aplicada y es reversible:
   - `.\infra\tools\revertir_ultima_migracion.ps1`
4. Corregir con una nueva migracion. No editar una migracion ya ejecutada.

## 5. Escenario C: se necesita comprobar recuperabilidad

1. Ejecutar prueba integral:
   - `.\infra\tools\ejecutar_prueba_recuperacion_local.ps1`
2. Verificar evidencia:
   - `docs/validacion/EVIDENCIA_RECUPERACION_LOCAL_2026-03-19.md`
3. Confirmar diferencias de conteo en `0`.

## 6. Escenario D: inconsistencia funcional despues de seed o restore

1. Repetir carga limpia:
   - `.\infra\docker\recrear_instalacion_limpia.ps1`
2. Ejecutar regresion post-seed:
   - `.\infra\tools\ejecutar_regresion_post_seed.ps1`
3. Ejecutar gate documental/tecnico segun corresponda:
   - `.\infra\tools\ejecutar_gate_pre_release.ps1`

## 7. Escenario E: deriva de privilegios o duda sobre accesos

1. Ejecutar auditoria:
   - `.\infra\tools\auditar_seguridad_postgres_local.ps1`
2. Si hay fallas bloqueantes, reaplicar baseline:
   - `.\infra\tools\endurecer_seguridad_postgres_local.ps1`
3. Reprovisionar logins operativos si aplica:
   - `.\infra\tools\provisionar_logins_operativos_locales.ps1`
4. Reejecutar auditoria y revisar evidencia:
   - `docs/validacion/EVIDENCIA_AUDITORIA_SEGURIDAD_LOCAL_2026-03-20.md`
5. Si la deriva afecta al admin bootstrap, reaplicar:
   - `.\infra\tools\confinar_admin_bootstrap_local.ps1`
   - `.\infra\tools\validar_admin_bootstrap_local.ps1`
6. Documentar solo excepciones reales; el estado esperado ya no incluye
   `fly_admin` expuesto por TCP ni bind mas amplio que `127.0.0.1`.

## 8. Escenario F: secreto local ausente, placeholder o invalido

1. Validar secreto runtime:
   - `.\infra\tools\validar_secretos_locales.ps1`
2. Si falta `infra/docker/.env` o el password sigue en placeholder:
   - `.\infra\tools\inicializar_secretos_locales.ps1`
3. Si se requiere rotacion controlada:
   - `.\infra\tools\inicializar_secretos_locales.ps1 -RotatePassword`
4. Reprovisionar y validar logins operativos locales:
   - `.\infra\tools\provisionar_logins_operativos_locales.ps1`
   - `.\infra\tools\validar_logins_operativos_locales.ps1`
5. Repetir recreacion limpia o gate completo para que Docker arranque con el
   secreto ya validado.

## 9. Escenario G: login operativo local falla o se sospecha deriva de membresias

1. Validar secretos:
   - `.\infra\tools\validar_secretos_locales.ps1`
2. Reprovisionar logins:
   - `.\infra\tools\provisionar_logins_operativos_locales.ps1`
3. Validar conectividad y privilegios:
   - `.\infra\tools\validar_logins_operativos_locales.ps1`
4. Validar menor privilegio efectivo en scripts operativos:
   - `.\infra\tools\validar_menor_privilegio_operativo_local.ps1`
5. Si hay dudas de grants base, reaplicar hardening y luego repetir los pasos 2 a 4.

## 10. Escenario H: diagnostico/observabilidad/baseline vuelven a depender de admin

1. Ejecutar:
   - `.\infra\tools\validar_menor_privilegio_operativo_local.ps1`
2. Confirmar en evidencia que:
   - diagnostico y observabilidad resuelven `AUDIT`
   - baseline de lectura resuelve `RO`
   - probe temporal resuelve `RW`
3. Si hay deriva, reaplicar recreacion limpia o revisar el ultimo cambio en scripts operativos.

## 11. Escenario I: el admin bootstrap vuelve a aceptar conexiones TCP

1. Ejecutar:
   - `.\infra\tools\validar_admin_bootstrap_local.ps1`
2. Si falla el aislamiento:
   - `.\infra\tools\confinar_admin_bootstrap_local.ps1`
3. Revalidar seguridad integral:
   - `.\infra\tools\auditar_seguridad_postgres_local.ps1`
   - `.\infra\tools\ejecutar_gate_pre_release.ps1`
4. Confirmar evidencia:
   - `docs/validacion/EVIDENCIA_ADMIN_BOOTSTRAP_LOCAL_2026-03-20.md`
   - `docs/validacion/EVIDENCIA_AUDITORIA_SEGURIDAD_LOCAL_2026-03-20.md`

## 12. Criterio de cierre de incidente

- Causa y accion aplicada documentadas.
- Comando de recuperacion ejecutado sin error.
- Validacion posterior en verde.
- Si hubo restore, evidencia publicada con tiempos observados.
- Si hubo ajuste de seguridad, auditoria publicada sin fallas bloqueantes.
- Si hubo ajuste de secreto, evidencia local de secretos publicada sin fallas bloqueantes.
- Si hubo ajuste de accesos, evidencia de logins operativos publicada sin fallas bloqueantes.
- Si hubo deriva operativa, evidencia de menor privilegio publicada sin fallas bloqueantes.
- Si hubo aislamiento del admin bootstrap, evidencia dedicada publicada sin fallas bloqueantes.
