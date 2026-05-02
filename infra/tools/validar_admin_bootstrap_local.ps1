param(
    [string]$EnvPath,
    [string]$EvidencePath,
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$DbAdminUser,
    [string]$DbName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$AuthHelperPath = Join-Path $ScriptDir "_shared\postgres_local_auth.ps1"
$SecretsValidationScript = Join-Path $ScriptDir "validar_secretos_locales.ps1"

if (-not (Test-Path -LiteralPath $AuthHelperPath)) {
    throw "Helper de autenticacion no encontrado: $AuthHelperPath"
}
. $AuthHelperPath

if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
    $EvidencePath = Join-Path $RepoRoot "docs\validacion\EVIDENCIA_ADMIN_BOOTSTRAP_LOCAL_2026-03-20.md"
}

function Invoke-AdminSocketScalar {
    param(
        [string]$Database,
        [string]$Sql
    )

    $raw = docker exec $ContainerName psql -t -A -U $DbAdminUser -d $Database -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo consulta escalar por socket local del admin bootstrap."
    }

    return $raw.Trim()
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

function Test-AdminTcpDenied {
    param(
        [string]$AdminUser,
        [string]$AdminPassword,
        [string]$Database
    )

    $raw = docker exec `
        -e "PGPASSWORD=$AdminPassword" `
        -e "PGCONNECT_TIMEOUT=5" `
        $ContainerName `
        psql -h 127.0.0.1 -t -A -U $AdminUser -d $Database -c "SELECT current_user;" 2>&1

    return [pscustomobject]@{
        connection_denied = ($LASTEXITCODE -ne 0)
        output = (($raw | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join " ").Trim()
    }
}

function Test-AdminSocketAllowed {
    param(
        [string]$AdminUser,
        [string]$Database
    )

    $raw = docker exec $ContainerName psql -t -A -U $AdminUser -d $Database -c "SELECT current_user;"
    return [pscustomobject]@{
        connection_ok = ($LASTEXITCODE -eq 0) -and ($raw.Trim() -eq $AdminUser)
        current_user = $raw.Trim()
    }
}

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Validacion Admin Bootstrap Local"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Evidencia: {0}" -f $EvidencePath)
    Write-Host ""

    if (-not (Test-Path -LiteralPath $SecretsValidationScript)) {
        throw "Validador de secretos no encontrado: $SecretsValidationScript"
    }

    & $SecretsValidationScript -EnvPath $EnvPath | Out-Null
    if (-not $?) {
        throw "La validacion de secretos locales fallo antes de validar admin bootstrap."
    }

    $loginContext = Resolve-DbLoginContext `
        -Mode "admin" `
        -ScriptPath $MyInvocation.MyCommand.Path `
        -EnvPath $EnvPath `
        -DbUser $DbAdminUser `
        -DbPassword $null `
        -DbName $DbName

    $EnvPath = $loginContext.EnvPath
    $DbAdminUser = $loginContext.DbUser
    $DbAdminPassword = $loginContext.DbPassword
    $DbName = $loginContext.DbName
    $envMap = $loginContext.EnvMap
    $effectiveBindIp = if ($envMap.Contains("POSTGRES_BIND_IP") -and (-not [string]::IsNullOrWhiteSpace([string]$envMap["POSTGRES_BIND_IP"]))) { [string]$envMap["POSTGRES_BIND_IP"] } else { "127.0.0.1" }
    $effectivePort = if ($envMap.Contains("POSTGRES_PORT") -and (-not [string]::IsNullOrWhiteSpace([string]$envMap["POSTGRES_PORT"]))) { [string]$envMap["POSTGRES_PORT"] } else { "5435" }

    $isSuperuser = Invoke-AdminSocketScalar -Database "postgres" -Sql "SELECT rolsuper FROM pg_roles WHERE rolname = '$DbAdminUser';"
    $hbaFile = Invoke-AdminSocketScalar -Database $DbName -Sql "SHOW hba_file;"
    $hbaContent = docker exec $ContainerName cat $hbaFile
    if ($LASTEXITCODE -ne 0) {
        throw "No fue posible leer pg_hba.conf desde el contenedor."
    }

    $hbaJoined = ($hbaContent -join "`n")
    $ipv4RejectPresent = $hbaJoined -match "(?m)^\s*host\s+all\s+$([regex]::Escape($DbAdminUser))\s+0\.0\.0\.0/0\s+reject\s*$"
    $ipv6RejectPresent = $hbaJoined -match "(?m)^\s*host\s+all\s+$([regex]::Escape($DbAdminUser))\s+::/0\s+reject\s*$"

    $tcpProbe = Test-AdminTcpDenied -AdminUser $DbAdminUser -AdminPassword $DbAdminPassword -Database $DbName
    $socketProbe = Test-AdminSocketAllowed -AdminUser $DbAdminUser -Database $DbName

    $controls = @(
        [pscustomobject]@{
            control = "bootstrap_admin_retained_as_superuser"
            observed = $isSuperuser
            expected = "t"
            status = $(if ($isSuperuser -eq "t") { "OK" } else { "FALLA" })
            note = "El bootstrap user debe permanecer superuser por restriccion del motor"
        }
        [pscustomobject]@{
            control = "bootstrap_admin_hba_reject_ipv4_present"
            observed = $ipv4RejectPresent
            expected = "true"
            status = $(if ($ipv4RejectPresent) { "OK" } else { "FALLA" })
            note = "Debe existir regla reject para TCP IPv4"
        }
        [pscustomobject]@{
            control = "bootstrap_admin_hba_reject_ipv6_present"
            observed = $ipv6RejectPresent
            expected = "true"
            status = $(if ($ipv6RejectPresent) { "OK" } else { "FALLA" })
            note = "Debe existir regla reject para TCP IPv6"
        }
        [pscustomobject]@{
            control = "bootstrap_admin_tcp_access_denied"
            observed = $tcpProbe.connection_denied
            expected = "true"
            status = $(if ($tcpProbe.connection_denied) { "OK" } else { "FALLA" })
            note = "El admin bootstrap no debe autenticarse por TCP"
        }
        [pscustomobject]@{
            control = "bootstrap_admin_socket_access_ok"
            observed = $socketProbe.connection_ok
            expected = "true"
            status = $(if ($socketProbe.connection_ok) { "OK" } else { "FALLA" })
            note = "El admin bootstrap debe seguir disponible por socket local interno"
        }
    )

    $failedControls = @($controls | Where-Object { $_.status -eq "FALLA" })
    $summaryRows = @(
        [pscustomobject]@{ metric = "failed_controls"; value = $failedControls.Count }
        [pscustomobject]@{ metric = "admin_bootstrap"; value = $DbAdminUser }
        [pscustomobject]@{ metric = "tcp_bind_scope"; value = "$effectiveBindIp`:$effectivePort" }
        [pscustomobject]@{ metric = "socket_probe_user"; value = $socketProbe.current_user }
    )

    $summaryTable = New-MarkdownTable -Rows $summaryRows -Headers @("metric", "value")
    $controlsTable = New-MarkdownTable -Rows $controls -Headers @("control", "observed", "expected", "status", "note")

    $evidenceDir = Split-Path -Parent $EvidencePath
    $null = New-Item -ItemType Directory -Force -Path $evidenceDir

    $content = @"
# Evidencia de Admin Bootstrap Local (2026-03-20)

## Objetivo

Validar que el usuario bootstrap administrativo permanezca como superuser solo
por restriccion del motor, pero quede confinado a uso break-glass por socket
local interno y no por TCP.

## Contexto de ejecucion

- Fecha de ejecucion: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
- Contenedor: $ContainerName
- Base: $DbName
- Admin bootstrap: $DbAdminUser
- Bind TCP publicado: $effectiveBindIp`:$effectivePort
- Archivo HBA auditado: $hbaFile

## Resumen observado

$summaryTable

## Controles de aislamiento

$controlsTable

## Resultado

- Estado general: $(if ($failedControls.Count -eq 0) { "ADMIN BOOTSTRAP CONFINADO Y VALIDADO" } else { "ADMIN BOOTSTRAP CON FALLAS" })
- Fallas bloqueantes: $($failedControls.Count)
- Evidencia TCP: $($tcpProbe.output)
- Evidencia socket local: $($socketProbe.current_user)
"@

    Set-Content -Path $EvidencePath -Value $content -Encoding UTF8

    if ($failedControls.Count -gt 0) {
        throw "La validacion del admin bootstrap reporto fallas."
    }

    Write-Host ("[OK] Evidencia escrita en: {0}" -f $EvidencePath)
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
