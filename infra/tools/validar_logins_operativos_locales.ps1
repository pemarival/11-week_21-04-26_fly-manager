param(
    [string]$EnvPath,
    [string]$EvidencePath,
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

if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
    $EvidencePath = Join-Path $RepoRoot "docs\validacion\EVIDENCIA_LOGINS_OPERATIVOS_LOCALES_2026-03-20.md"
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

function Invoke-AdminScalar {
    param(
        [string]$Database,
        [string]$Sql
    )

    $raw = docker exec $ContainerName psql -t -A -U $DbAdminUser -d $Database -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo consulta escalar de validacion de logins operativos."
    }
    return $raw.Trim()
}

function Invoke-AdminRows {
    param(
        [string]$Database,
        [string]$Sql
    )

    $rows = docker exec $ContainerName psql -t -A -F "|" -U $DbAdminUser -d $Database -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo consulta tabular de validacion de logins operativos."
    }
    return ,@($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function New-MarkdownTable {
    param(
        [object[]]$Rows,
        [string[]]$Headers
    )

    $lines = @()
    $lines += "| " + ($Headers -join " | ") + " |"
    $lines += "| " + (($Headers | ForEach-Object { "---" }) -join " | ") + " |"

    foreach ($row in $Rows) {
        $values = foreach ($header in $Headers) {
            [string]$row.PSObject.Properties[$header].Value
        }
        $lines += "| " + ($values -join " | ") + " |"
    }

    return ($lines -join "`r`n")
}

function Test-LoginConnection {
    param(
        [string]$LoginName,
        [string]$Password
    )

    $raw = docker exec `
        -e "PGPASSWORD=$Password" `
        -e "PGCONNECT_TIMEOUT=5" `
        $ContainerName `
        psql -h 127.0.0.1 -t -A -U $LoginName -d $DbName -c "SELECT current_user;"

    $ok = ($LASTEXITCODE -eq 0) -and ($raw.Trim() -eq $LoginName)
    return [pscustomobject]@{
        login_name = $LoginName
        connection_ok = $ok
        current_user = $raw.Trim()
    }
}

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Validacion Logins Operativos Locales"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base: {0}" -f $DbName)
    Write-Host ("  Evidencia: {0}" -f $EvidencePath)
    Write-Host ""

    if (-not (Test-Path -LiteralPath $SecretsValidationScript)) {
        throw "Validador de secretos no encontrado: $SecretsValidationScript"
    }

    & $SecretsValidationScript -EnvPath $EnvPath | Out-Null
    if (-not $?) {
        throw "La validacion de secretos locales fallo antes de validar logins operativos."
    }

    $envMap = Get-EnvMap -Path $EnvPath
    $runtimeLogin = [string]$envMap["FLY_APP_RW_USER"]
    $runtimePassword = [string]$envMap["FLY_APP_RW_PASSWORD"]
    $readOnlyLogin = [string]$envMap["FLY_APP_RO_USER"]
    $readOnlyPassword = [string]$envMap["FLY_APP_RO_PASSWORD"]
    $auditLogin = [string]$envMap["FLY_APP_AUDIT_USER"]
    $auditPassword = [string]$envMap["FLY_APP_AUDIT_PASSWORD"]

    $loginsDistinctFromAdmin = ($runtimeLogin -ne $DbAdminUser) -and ($readOnlyLogin -ne $DbAdminUser) -and ($auditLogin -ne $DbAdminUser)
    $loginsDistinctEachOther = (@($runtimeLogin, $readOnlyLogin, $auditLogin) | Sort-Object -Unique).Count -eq 3

    $roleRowsRaw = Invoke-AdminRows -Database "postgres" -Sql @"
SELECT
  rolname,
  rolsuper,
  rolcreaterole,
  rolcreatedb,
  rolcanlogin,
  pg_has_role(rolname, '$RuntimeRole', 'member'),
  pg_has_role(rolname, '$ReadOnlyRole', 'member'),
  pg_has_role(rolname, '$AuditRole', 'member')
FROM pg_roles
WHERE rolname IN ('$runtimeLogin', '$readOnlyLogin', '$auditLogin')
ORDER BY rolname;
"@

    $roleRows = foreach ($row in $roleRowsRaw) {
        $parts = $row.Split("|")
        [pscustomobject]@{
            login_name = $parts[0]
            superuser = $parts[1]
            create_role = $parts[2]
            create_db = $parts[3]
            can_login = $parts[4]
            member_rw = $parts[5]
            member_ro = $parts[6]
            member_audit = $parts[7]
        }
    }

    $roleMap = @{}
    foreach ($row in $roleRows) {
        $roleMap[$row.login_name] = $row
    }

    $runtimeConnection = Test-LoginConnection -LoginName $runtimeLogin -Password $runtimePassword
    $readOnlyConnection = Test-LoginConnection -LoginName $readOnlyLogin -Password $readOnlyPassword
    $auditConnection = Test-LoginConnection -LoginName $auditLogin -Password $auditPassword
    $connectionRows = @($runtimeConnection, $readOnlyConnection, $auditConnection)
    $successfulConnections = @($connectionRows | Where-Object { $_.connection_ok }).Count

    $runtimePrivilegesOk = Invoke-AdminScalar -Database $DbName -Sql "SELECT has_table_privilege('$runtimeLogin', 'public.country', 'SELECT,INSERT,UPDATE,DELETE');"
    $readOnlyPrivilegesOk = Invoke-AdminScalar -Database $DbName -Sql "SELECT has_table_privilege('$readOnlyLogin', 'public.country', 'SELECT') AND NOT has_table_privilege('$readOnlyLogin', 'public.country', 'INSERT,UPDATE,DELETE');"
    $auditPrivilegesOk = Invoke-AdminScalar -Database $DbName -Sql "SELECT has_table_privilege('$auditLogin', 'public.country', 'SELECT') AND NOT has_table_privilege('$auditLogin', 'public.country', 'INSERT,UPDATE,DELETE');"
    $auditStatsOk = Invoke-AdminScalar -Database "postgres" -Sql "SELECT pg_has_role('$auditLogin', 'pg_read_all_stats', 'member');"
    $runtimeTempOk = Invoke-AdminScalar -Database $DbName -Sql "SELECT has_database_privilege('$runtimeLogin', '$DbName', 'TEMP');"
    $readOnlyTempDenied = Invoke-AdminScalar -Database $DbName -Sql "SELECT NOT has_database_privilege('$readOnlyLogin', '$DbName', 'TEMP');"
    $auditTempDenied = Invoke-AdminScalar -Database $DbName -Sql "SELECT NOT has_database_privilege('$auditLogin', '$DbName', 'TEMP');"

    $runtimeRoleRow = if ($roleMap.ContainsKey($runtimeLogin)) { $roleMap[$runtimeLogin] } else { $null }
    $readOnlyRoleRow = if ($roleMap.ContainsKey($readOnlyLogin)) { $roleMap[$readOnlyLogin] } else { $null }
    $auditRoleRow = if ($roleMap.ContainsKey($auditLogin)) { $roleMap[$auditLogin] } else { $null }

    $nonSuperuserLogins = @($roleRows | Where-Object {
        ($_.superuser -eq "f") -and ($_.create_role -eq "f") -and ($_.create_db -eq "f") -and ($_.can_login -eq "t")
    }).Count -eq 3

    $controls = @(
        [pscustomobject]@{
            control = "operational_logins_distinct_from_admin"
            observed = $loginsDistinctFromAdmin
            expected = "true"
            status = $(if ($loginsDistinctFromAdmin) { "OK" } else { "FALLA" })
            note = "Los logins operativos no deben reutilizar el usuario administrativo"
        }
        [pscustomobject]@{
            control = "operational_logins_distinct_each_other"
            observed = $loginsDistinctEachOther
            expected = "true"
            status = $(if ($loginsDistinctEachOther) { "OK" } else { "FALLA" })
            note = "RW, RO y AUDIT deben ser cuentas distintas"
        }
        [pscustomobject]@{
            control = "rw_login_present"
            observed = ($null -ne $runtimeRoleRow)
            expected = "true"
            status = $(if ($null -ne $runtimeRoleRow) { "OK" } else { "FALLA" })
            note = "Debe existir el login local heredando de fly_app_rw"
        }
        [pscustomobject]@{
            control = "ro_login_present"
            observed = ($null -ne $readOnlyRoleRow)
            expected = "true"
            status = $(if ($null -ne $readOnlyRoleRow) { "OK" } else { "FALLA" })
            note = "Debe existir el login local heredando de fly_app_ro"
        }
        [pscustomobject]@{
            control = "audit_login_present"
            observed = ($null -ne $auditRoleRow)
            expected = "true"
            status = $(if ($null -ne $auditRoleRow) { "OK" } else { "FALLA" })
            note = "Debe existir el login local heredando de fly_app_audit"
        }
        [pscustomobject]@{
            control = "operational_logins_non_superuser"
            observed = $nonSuperuserLogins
            expected = "true"
            status = $(if ($nonSuperuserLogins) { "OK" } else { "FALLA" })
            note = "Los logins operativos no deben ser superuser ni crear roles/bases"
        }
        [pscustomobject]@{
            control = "rw_membership_ok"
            observed = $(if ($null -eq $runtimeRoleRow) { "missing" } else { $runtimeRoleRow.member_rw })
            expected = "t"
            status = $(if (($null -ne $runtimeRoleRow) -and ($runtimeRoleRow.member_rw -eq "t")) { "OK" } else { "FALLA" })
            note = "El login RW debe heredar de fly_app_rw"
        }
        [pscustomobject]@{
            control = "ro_membership_ok"
            observed = $(if ($null -eq $readOnlyRoleRow) { "missing" } else { $readOnlyRoleRow.member_ro })
            expected = "t"
            status = $(if (($null -ne $readOnlyRoleRow) -and ($readOnlyRoleRow.member_ro -eq "t")) { "OK" } else { "FALLA" })
            note = "El login RO debe heredar de fly_app_ro"
        }
        [pscustomobject]@{
            control = "audit_membership_ok"
            observed = $(if ($null -eq $auditRoleRow) { "missing" } else { $auditRoleRow.member_audit })
            expected = "t"
            status = $(if (($null -ne $auditRoleRow) -and ($auditRoleRow.member_audit -eq "t")) { "OK" } else { "FALLA" })
            note = "El login AUDIT debe heredar de fly_app_audit"
        }
        [pscustomobject]@{
            control = "operational_logins_can_connect"
            observed = "$successfulConnections/3"
            expected = "3/3"
            status = $(if ($successfulConnections -eq 3) { "OK" } else { "FALLA" })
            note = "Los tres logins deben conectarse con password sobre TCP"
        }
        [pscustomobject]@{
            control = "rw_privileges_match_runtime_role"
            observed = $runtimePrivilegesOk
            expected = "t"
            status = $(if ($runtimePrivilegesOk -eq "t") { "OK" } else { "FALLA" })
            note = "El login RW debe conservar DML completo via fly_app_rw"
        }
        [pscustomobject]@{
            control = "ro_privileges_match_readonly_role"
            observed = $readOnlyPrivilegesOk
            expected = "t"
            status = $(if ($readOnlyPrivilegesOk -eq "t") { "OK" } else { "FALLA" })
            note = "El login RO debe quedar limitado a SELECT"
        }
        [pscustomobject]@{
            control = "audit_privileges_match_audit_role"
            observed = $auditPrivilegesOk
            expected = "t"
            status = $(if ($auditPrivilegesOk -eq "t") { "OK" } else { "FALLA" })
            note = "El login AUDIT debe quedar limitado a lectura"
        }
        [pscustomobject]@{
            control = "audit_login_has_pg_read_all_stats"
            observed = $auditStatsOk
            expected = "t"
            status = $(if ($auditStatsOk -eq "t") { "OK" } else { "FALLA" })
            note = "El login AUDIT debe heredar acceso a estadisticas globales"
        }
        [pscustomobject]@{
            control = "rw_login_has_temp_privilege"
            observed = $runtimeTempOk
            expected = "t"
            status = $(if ($runtimeTempOk -eq "t") { "OK" } else { "FALLA" })
            note = "El login RW debe poder crear tablas temporales de sesion para probes seguros"
        }
        [pscustomobject]@{
            control = "ro_login_no_temp_privilege"
            observed = $readOnlyTempDenied
            expected = "t"
            status = $(if ($readOnlyTempDenied -eq "t") { "OK" } else { "FALLA" })
            note = "El login RO no debe crear tablas temporales"
        }
        [pscustomobject]@{
            control = "audit_login_no_temp_privilege"
            observed = $auditTempDenied
            expected = "t"
            status = $(if ($auditTempDenied -eq "t") { "OK" } else { "FALLA" })
            note = "El login AUDIT no debe crear tablas temporales"
        }
    )

    $failedControls = @($controls | Where-Object { $_.status -eq "FALLA" })

    $summaryRows = @(
        [pscustomobject]@{ metric = "expected_operational_logins"; value = 3 }
        [pscustomobject]@{ metric = "present_operational_logins"; value = $roleRows.Count }
        [pscustomobject]@{ metric = "validated_connections"; value = $successfulConnections }
        [pscustomobject]@{ metric = "failed_controls"; value = $failedControls.Count }
    )

    $summaryTable = New-MarkdownTable -Rows $summaryRows -Headers @("metric", "value")
    $loginsTable = New-MarkdownTable -Rows $roleRows -Headers @("login_name", "superuser", "create_role", "create_db", "can_login", "member_rw", "member_ro", "member_audit")
    $connectionsTable = New-MarkdownTable -Rows $connectionRows -Headers @("login_name", "connection_ok", "current_user")
    $controlsTable = New-MarkdownTable -Rows $controls -Headers @("control", "observed", "expected", "status", "note")

    $evidenceDir = Split-Path -Parent $EvidencePath
    $null = New-Item -ItemType Directory -Force -Path $evidenceDir

    $content = @"
# Evidencia de Logins Operativos Locales (2026-03-20)

## Objetivo

Validar que el entorno local ya no dependa solo de ``fly_admin`` para uso
cotidiano y disponga de logins operativos minimos, conectables y alineados a
los roles ``fly_app_rw``, ``fly_app_ro`` y ``fly_app_audit``.

## Contexto de ejecucion

- Fecha de ejecucion: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
- Contenedor: $ContainerName
- Base auditada: $DbName
- Admin actual de bootstrap: $DbAdminUser
- Login RW local: $runtimeLogin
- Login RO local: $readOnlyLogin
- Login AUDIT local: $auditLogin

## Resumen observado

$summaryTable

## Atributos de logins

$loginsTable

## Validacion de conexion

$connectionsTable

## Controles

$controlsTable

## Resultado

- Estado general: $(if ($failedControls.Count -eq 0) { "LOGINS OPERATIVOS OK" } else { "LOGINS OPERATIVOS CON FALLAS" })
- Fallas bloqueantes: $($failedControls.Count)
"@

    Set-Content -Path $EvidencePath -Value $content -Encoding UTF8
    Write-Host ("[OK] Evidencia escrita en: {0}" -f $EvidencePath)

    if ($failedControls.Count -gt 0) {
        throw ("La validacion de logins operativos detecto {0} fallas bloqueantes." -f $failedControls.Count)
    }

    Write-Output ([pscustomobject]@{
        evidence_path = $EvidencePath
        failed_controls = $failedControls.Count
        validated_connections = $successfulConnections
    })
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
