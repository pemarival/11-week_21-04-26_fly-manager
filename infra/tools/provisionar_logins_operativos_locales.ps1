param(
    [string]$EnvPath,
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$DbAdminUser,
    [string]$DbName,
    [string]$RuntimeRole = "fly_app_rw",
    [string]$ReadOnlyRole = "fly_app_ro",
    [string]$AuditRole = "fly_app_audit"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$SecretsValidationScript = Join-Path $ScriptDir "validar_secretos_locales.ps1"

if ([string]::IsNullOrWhiteSpace($EnvPath)) {
    $EnvPath = Join-Path $RepoRoot "infra\docker\.env"
}

if ([string]::IsNullOrWhiteSpace($DbAdminUser)) {
    $DbAdminUser = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_USER)) { "fly_admin" } else { $env:POSTGRES_USER }
}

if ([string]::IsNullOrWhiteSpace($DbName)) {
    $DbName = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_DB)) { "flydb" } else { $env:POSTGRES_DB }
}

function Get-EnvMap {
    param([string]$Path)

    $map = [ordered]@{}
    foreach ($line in Get-Content -Path $Path) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) {
            continue
        }

        $separator = $trimmed.IndexOf("=")
        if ($separator -lt 1) {
            throw "Formato invalido en archivo .env: $Path"
        }

        $key = $trimmed.Substring(0, $separator).Trim()
        $value = $trimmed.Substring($separator + 1)
        $map[$key] = $value
    }

    return $map
}

function Assert-SafeRoleName {
    param(
        [string]$Value,
        [string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or ($Value -notmatch '^[a-z][a-z0-9_]{2,62}$')) {
        throw "$Label invalido. Usa solo minusculas, numeros y underscore."
    }
}

function Escape-SqlLiteral {
    param([string]$Value)
    return $Value.Replace("'", "''")
}

function Invoke-PsqlFile {
    param(
        [string]$LocalPath,
        [string]$RemotePath
    )

    docker cp $LocalPath "${ContainerName}:$RemotePath" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo docker cp al transferir SQL de provision de logins."
    }

    try {
        docker exec $ContainerName psql -v ON_ERROR_STOP=1 -U $DbAdminUser -d $DbName -f $RemotePath | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo psql al provisionar logins operativos."
        }
    }
    finally {
        docker exec $ContainerName rm -f $RemotePath | Out-Null
    }
}

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Provision Logins Operativos Locales"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base: {0}" -f $DbName)
    Write-Host ""

    if (-not (Test-Path -LiteralPath $SecretsValidationScript)) {
        throw "Validador de secretos no encontrado: $SecretsValidationScript"
    }

    & $SecretsValidationScript -EnvPath $EnvPath | Out-Null
    if (-not $?) {
        throw "La validacion de secretos locales fallo antes de provisionar logins."
    }

    $envMap = Get-EnvMap -Path $EnvPath
    $runtimeLogin = [string]$envMap["FLY_APP_RW_USER"]
    $runtimePassword = [string]$envMap["FLY_APP_RW_PASSWORD"]
    $readOnlyLogin = [string]$envMap["FLY_APP_RO_USER"]
    $readOnlyPassword = [string]$envMap["FLY_APP_RO_PASSWORD"]
    $auditLogin = [string]$envMap["FLY_APP_AUDIT_USER"]
    $auditPassword = [string]$envMap["FLY_APP_AUDIT_PASSWORD"]

    Assert-SafeRoleName -Value $RuntimeRole -Label "RuntimeRole"
    Assert-SafeRoleName -Value $ReadOnlyRole -Label "ReadOnlyRole"
    Assert-SafeRoleName -Value $AuditRole -Label "AuditRole"
    Assert-SafeRoleName -Value $runtimeLogin -Label "FLY_APP_RW_USER"
    Assert-SafeRoleName -Value $readOnlyLogin -Label "FLY_APP_RO_USER"
    Assert-SafeRoleName -Value $auditLogin -Label "FLY_APP_AUDIT_USER"

    if (($runtimeLogin -eq $DbAdminUser) -or ($readOnlyLogin -eq $DbAdminUser) -or ($auditLogin -eq $DbAdminUser)) {
        throw "Los logins operativos no deben reutilizar el usuario administrativo."
    }

    if ((@($runtimeLogin, $readOnlyLogin, $auditLogin) | Sort-Object -Unique).Count -ne 3) {
        throw "Los logins operativos deben ser distintos entre si."
    }

    $localSqlPath = Join-Path ([System.IO.Path]::GetTempPath()) ("codex_pg_operational_logins_{0}.sql" -f [guid]::NewGuid().ToString("N"))
    $remoteSqlPath = "/tmp/{0}" -f ([System.IO.Path]::GetFileName($localSqlPath))

    $sqlTemplate = @'
DO $provision$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{0}') THEN
    CREATE ROLE {0} LOGIN PASSWORD '{1}';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{2}') THEN
    CREATE ROLE {2} LOGIN PASSWORD '{3}';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{4}') THEN
    CREATE ROLE {4} LOGIN PASSWORD '{5}';
  END IF;
END
$provision$;

ALTER ROLE {0} WITH LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION PASSWORD '{1}';
ALTER ROLE {2} WITH LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION PASSWORD '{3}';
ALTER ROLE {4} WITH LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION PASSWORD '{5}';

DO $cleanup$
BEGIN
  IF pg_has_role('{0}', '{6}', 'member') THEN
    REVOKE {6} FROM {0};
  END IF;
  IF pg_has_role('{0}', '{7}', 'member') THEN
    REVOKE {7} FROM {0};
  END IF;
  IF pg_has_role('{0}', '{8}', 'member') THEN
    REVOKE {8} FROM {0};
  END IF;

  IF pg_has_role('{2}', '{6}', 'member') THEN
    REVOKE {6} FROM {2};
  END IF;
  IF pg_has_role('{2}', '{7}', 'member') THEN
    REVOKE {7} FROM {2};
  END IF;
  IF pg_has_role('{2}', '{8}', 'member') THEN
    REVOKE {8} FROM {2};
  END IF;

  IF pg_has_role('{4}', '{6}', 'member') THEN
    REVOKE {6} FROM {4};
  END IF;
  IF pg_has_role('{4}', '{7}', 'member') THEN
    REVOKE {7} FROM {4};
  END IF;
  IF pg_has_role('{4}', '{8}', 'member') THEN
    REVOKE {8} FROM {4};
  END IF;
END
$cleanup$;

GRANT {6} TO {0};
GRANT {7} TO {2};
GRANT {8} TO {4};

ALTER ROLE {0} IN DATABASE {9} SET search_path TO public;
ALTER ROLE {2} IN DATABASE {9} SET search_path TO public;
ALTER ROLE {4} IN DATABASE {9} SET search_path TO public;

ALTER ROLE {2} SET default_transaction_read_only = on;
ALTER ROLE {4} SET default_transaction_read_only = on;

COMMENT ON ROLE {0} IS 'Login operativo local RW heredando de {6}';
COMMENT ON ROLE {2} IS 'Login operativo local RO heredando de {7}';
COMMENT ON ROLE {4} IS 'Login operativo local AUDIT heredando de {8}';
'@

    $sql = [string]::Format(
        $sqlTemplate,
        $runtimeLogin,
        (Escape-SqlLiteral -Value $runtimePassword),
        $readOnlyLogin,
        (Escape-SqlLiteral -Value $readOnlyPassword),
        $auditLogin,
        (Escape-SqlLiteral -Value $auditPassword),
        $RuntimeRole,
        $ReadOnlyRole,
        $AuditRole,
        $DbName
    )

    Set-Content -Path $localSqlPath -Value $sql -Encoding UTF8

    try {
        Invoke-PsqlFile -LocalPath $localSqlPath -RemotePath $remoteSqlPath
    }
    finally {
        if (Test-Path -LiteralPath $localSqlPath) {
            Remove-Item -LiteralPath $localSqlPath -Force
        }
    }

    Write-Host ("[OK] Logins operativos provisionados: {0}, {1}, {2}" -f $runtimeLogin, $readOnlyLogin, $auditLogin)
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
