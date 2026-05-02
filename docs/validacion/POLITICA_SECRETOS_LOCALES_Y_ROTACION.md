# Politica de Secretos Locales y Rotacion (S4.1)

## 1. Objetivo

Controlar el secreto local de PostgreSQL fuera del repositorio, con validacion
bloqueante y rotacion segura para que el entorno Docker no dependa de
placeholders versionados.

## 2. Alcance

- Archivo local `infra/docker/.env`.
- Valor runtime de `POSTGRES_PASSWORD`.
- Credenciales locales de `FLY_APP_RW_USER`, `FLY_APP_RO_USER` y `FLY_APP_AUDIT_USER`.
- Integracion del control al gate arquitectonico y a la recreacion limpia.

## 3. Artefactos operativos

- `infra/tools/inicializar_secretos_locales.ps1`
- `infra/tools/validar_secretos_locales.ps1`
- `infra/docker/.env.example`

## 4. Principios

1. Ningun secreto runtime real debe quedar en archivos versionados.
2. El repositorio debe exponer solo placeholders seguros y explicitos.
3. `infra/docker/.env` debe existir localmente antes de levantar Docker.
4. El secreto runtime debe tener longitud y complejidad minima verificables.
5. Los passwords de logins operativos deben seguir el mismo estandar y no
   reutilizar el placeholder versionado.

## 5. Flujo recomendado

1. Inicializar o rotar secreto local:
   - `.\infra\tools\inicializar_secretos_locales.ps1`
2. Validar secreto local:
   - `.\infra\tools\validar_secretos_locales.ps1`
3. Provisionar y validar logins operativos:
   - `.\infra\tools\provisionar_logins_operativos_locales.ps1`
   - `.\infra\tools\validar_logins_operativos_locales.ps1`
4. Ejecutar recreacion limpia o gate:
   - `.\infra\docker\recrear_instalacion_limpia.ps1`
   - `.\infra\tools\ejecutar_gate_pre_release.ps1`

## 6. Criterio de salida S4.1

- `infra/docker/.env` existe y no esta versionado.
- `POSTGRES_PASSWORD` runtime no usa placeholder.
- Los passwords de logins operativos tampoco usan placeholder.
- Longitud minima y complejidad de secretos validadas.
- Gate arquitectonico detecta secreto ausente o invalido antes de Docker.
