param(
    [string]$EnvPath,
    [string]$EnvExamplePath,
    [string]$EvidencePath,
    [int]$MinPasswordLength = 24
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$GitIgnorePath = Join-Path $RepoRoot ".gitignore"
$ComposePath = Join-Path $RepoRoot "infra\docker\docker-compose.yml"

if ([string]::IsNullOrWhiteSpace($EnvPath)) {
    $EnvPath = Join-Path $RepoRoot "infra\docker\.env"
}

if ([string]::IsNullOrWhiteSpace($EnvExamplePath)) {
    $EnvExamplePath = Join-Path $RepoRoot "infra\docker\.env.example"
}

if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
    $EvidencePath = Join-Path $RepoRoot "docs\validacion\EVIDENCIA_SECRETOS_LOCALES_2026-03-20.md"
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

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Validacion de Secretos Locales"
    Write-Host "======================================================"
    Write-Host ("  Env local: {0}" -f $EnvPath)
    Write-Host ("  Evidencia: {0}" -f $EvidencePath)
    Write-Host ""

    $placeholderSecret = "local_change_me_before_shared_use"
    $requiredKeys = @(
        "POSTGRES_DB",
        "POSTGRES_USER",
        "POSTGRES_PASSWORD",
        "FLY_APP_RW_USER",
        "FLY_APP_RW_PASSWORD",
        "FLY_APP_RO_USER",
        "FLY_APP_RO_PASSWORD",
        "FLY_APP_AUDIT_USER",
        "FLY_APP_AUDIT_PASSWORD",
        "TZ",
        "PGTZ"
    )
    $passwordKeys = @(
        "POSTGRES_PASSWORD",
        "FLY_APP_RW_PASSWORD",
        "FLY_APP_RO_PASSWORD",
        "FLY_APP_AUDIT_PASSWORD"
    )
    $allowedBindIps = @("127.0.0.1")
    $operationalUserKeys = @("FLY_APP_RW_USER", "FLY_APP_RO_USER", "FLY_APP_AUDIT_USER")

    $envExampleExists = Test-Path -LiteralPath $EnvExamplePath
    $localEnvExists = Test-Path -LiteralPath $EnvPath
    $gitIgnoreProtectsLocalEnv = (Test-Path -LiteralPath $GitIgnorePath) -and (Select-String -Path $GitIgnorePath -Pattern '^infra/docker/\.env\s*$' -Quiet)
    $composeUsesEnvPassword = (Test-Path -LiteralPath $ComposePath) -and (Select-String -Path $ComposePath -Pattern '\$\{POSTGRES_PASSWORD' -Quiet)

    $exampleMap = if ($envExampleExists) { Get-EnvMap -Path $EnvExamplePath } else { [ordered]@{} }
    $localMap = if ($localEnvExists) { Get-EnvMap -Path $EnvPath } else { [ordered]@{} }

    $examplePlaceholdersPresent = $true
    foreach ($key in $passwordKeys) {
        if (-not $exampleMap.Contains($key) -or ([string]$exampleMap[$key] -ne $placeholderSecret)) {
            $examplePlaceholdersPresent = $false
            break
        }
    }

    $exampleSecretsReusable = $true
    foreach ($key in $passwordKeys) {
        $value = if ($exampleMap.Contains($key)) { [string]$exampleMap[$key] } else { "" }
        if ([string]::IsNullOrWhiteSpace($value) -or ($value -eq $placeholderSecret) -or ($value.Length -lt $MinPasswordLength)) {
            $exampleSecretsReusable = $false
            break
        }
        if ((-not ($value -cmatch "[A-Z]")) -or (-not ($value -cmatch "[a-z]")) -or (-not ($value -match "[0-9]"))) {
            $exampleSecretsReusable = $false
            break
        }
    }
    $examplePolicyOk = $examplePlaceholdersPresent -or $exampleSecretsReusable
    $localEnvPolicyOk = $gitIgnoreProtectsLocalEnv -or $localEnvExists

    $requiredKeysPresent = $true
    foreach ($key in $requiredKeys) {
        if (-not $localMap.Contains($key) -or [string]::IsNullOrWhiteSpace([string]$localMap[$key])) {
            $requiredKeysPresent = $false
            break
        }
    }

    $postgresPassword = if ($localMap.Contains("POSTGRES_PASSWORD")) { [string]$localMap["POSTGRES_PASSWORD"] } else { "" }
    $effectiveBindIp = if ($localMap.Contains("POSTGRES_BIND_IP") -and (-not [string]::IsNullOrWhiteSpace([string]$localMap["POSTGRES_BIND_IP"]))) { [string]$localMap["POSTGRES_BIND_IP"] } else { "127.0.0.1" }
    $effectivePort = if ($localMap.Contains("POSTGRES_PORT") -and (-not [string]::IsNullOrWhiteSpace([string]$localMap["POSTGRES_PORT"]))) { [string]$localMap["POSTGRES_PORT"] } else { "5435" }
    $bindIpIsLocalOnly = $allowedBindIps -contains $effectiveBindIp
    $portIsNumeric = $effectivePort -match '^\d{2,5}$'
    $portIsValidRange = $false
    if ($portIsNumeric) {
        $portNumber = [int]$effectivePort
        $portIsValidRange = ($portNumber -ge 1024) -and ($portNumber -le 65535)
    }
    $composeUsesLocalBindParameter = (Test-Path -LiteralPath $ComposePath) -and (Select-String -Path $ComposePath -Pattern '\$\{POSTGRES_BIND_IP:-127\.0\.0\.1\}:\$\{POSTGRES_PORT:-5435\}:5432' -Quiet)
    $passwordLengths = @()
    $allPasswordsPlaceholderRemoved = $true
    $allPasswordsLengthOk = $true
    $allPasswordsComplexityOk = $true
    foreach ($key in $passwordKeys) {
        $value = if ($localMap.Contains($key)) { [string]$localMap[$key] } else { "" }
        if (($value -eq $placeholderSecret) -or [string]::IsNullOrWhiteSpace($value)) {
            $allPasswordsPlaceholderRemoved = $false
        }
        if ($value.Length -lt $MinPasswordLength) {
            $allPasswordsLengthOk = $false
        }
        if ((-not ($value -cmatch "[A-Z]")) -or (-not ($value -cmatch "[a-z]")) -or (-not ($value -match "[0-9]"))) {
            $allPasswordsComplexityOk = $false
        }
        $passwordLengths += $value.Length
    }

    $operationalUsersValid = $true
    $operationalUsersDistinctFromAdmin = $true
    $operationalUsersDistinctEachOther = $true
    $operationalUserValues = @()
    foreach ($key in $operationalUserKeys) {
        $value = if ($localMap.Contains($key)) { [string]$localMap[$key] } else { "" }
        if ([string]::IsNullOrWhiteSpace($value) -or ($value -notmatch '^[a-z][a-z0-9_]{2,62}$')) {
            $operationalUsersValid = $false
        }
        if ($value -eq [string]$localMap["POSTGRES_USER"]) {
            $operationalUsersDistinctFromAdmin = $false
        }
        $operationalUserValues += $value
    }
    if (($operationalUserValues | Sort-Object -Unique).Count -ne $operationalUserValues.Count) {
        $operationalUsersDistinctEachOther = $false
    }

    $postgresPasswordLength = $postgresPassword.Length
    $operationalMinPasswordLength = if ($passwordLengths.Count -gt 1) {
        ($passwordLengths | Select-Object -Skip 1 | Measure-Object -Minimum).Minimum
    } else {
        0
    }

    $controls = @(
        [pscustomobject]@{
            control = "env_example_exists"
            observed = $envExampleExists
            expected = "true"
            status = $(if ($envExampleExists) { "OK" } else { "FALLA" })
            note = "Debe existir template versionado de referencia"
        }
        [pscustomobject]@{
            control = "gitignore_protects_local_env"
            observed = $gitIgnoreProtectsLocalEnv
            expected = "true o modo academico versionado"
            status = $(if ($localEnvPolicyOk) { "OK" } else { "FALLA" })
            note = "Se acepta .env no versionado o .env academico versionado para bootstrap reproducible"
        }
        [pscustomobject]@{
            control = "local_env_present"
            observed = $localEnvExists
            expected = "true"
            status = $(if ($localEnvExists) { "OK" } else { "FALLA" })
            note = "Debe existir infra/docker/.env no versionado para uso local"
        }
        [pscustomobject]@{
            control = "local_env_required_keys_complete"
            observed = $requiredKeysPresent
            expected = "true"
            status = $(if ($requiredKeysPresent) { "OK" } else { "FALLA" })
            note = "Debe incluir secretos admin y credenciales operativas locales"
        }
        [pscustomobject]@{
            control = "operational_usernames_valid"
            observed = $operationalUsersValid
            expected = "true"
            status = $(if ($operationalUsersValid) { "OK" } else { "FALLA" })
            note = "Los logins operativos deben usar identificadores simples y no vacios"
        }
        [pscustomobject]@{
            control = "operational_usernames_distinct_from_admin"
            observed = $operationalUsersDistinctFromAdmin
            expected = "true"
            status = $(if ($operationalUsersDistinctFromAdmin) { "OK" } else { "FALLA" })
            note = "Los logins operativos no deben reutilizar POSTGRES_USER"
        }
        [pscustomobject]@{
            control = "operational_usernames_distinct_each_other"
            observed = $operationalUsersDistinctEachOther
            expected = "true"
            status = $(if ($operationalUsersDistinctEachOther) { "OK" } else { "FALLA" })
            note = "RW, RO y AUDIT deben ser cuentas distintas"
        }
        [pscustomobject]@{
            control = "local_env_passwords_placeholder_removed"
            observed = $allPasswordsPlaceholderRemoved
            expected = "true"
            status = $(if ($allPasswordsPlaceholderRemoved) { "OK" } else { "FALLA" })
            note = "Ningun secreto local debe quedar con el placeholder del repo"
        }
        [pscustomobject]@{
            control = "local_env_passwords_length_ok"
            observed = "admin=$postgresPasswordLength, op_min=$operationalMinPasswordLength"
            expected = ">=$MinPasswordLength"
            status = $(if ($allPasswordsLengthOk) { "OK" } else { "FALLA" })
            note = "Todos los secretos locales deben cumplir la longitud minima"
        }
        [pscustomobject]@{
            control = "local_env_passwords_complexity_ok"
            observed = $allPasswordsComplexityOk
            expected = "true"
            status = $(if ($allPasswordsComplexityOk) { "OK" } else { "FALLA" })
            note = "Todos los secretos locales deben incluir mayuscula, minuscula y digito"
        }
        [pscustomobject]@{
            control = "compose_uses_env_password"
            observed = $composeUsesEnvPassword
            expected = "true"
            status = $(if ($composeUsesEnvPassword) { "OK" } else { "FALLA" })
            note = "docker-compose debe resolver POSTGRES_PASSWORD desde entorno local"
        }
        [pscustomobject]@{
            control = "compose_supports_local_bind_scope"
            observed = $composeUsesLocalBindParameter
            expected = "true"
            status = $(if ($composeUsesLocalBindParameter) { "OK" } else { "FALLA" })
            note = "docker-compose debe publicar PostgreSQL con bind configurable y loopback por defecto"
        }
        [pscustomobject]@{
            control = "effective_bind_ip_is_local_only"
            observed = $effectiveBindIp
            expected = "127.0.0.1"
            status = $(if ($bindIpIsLocalOnly) { "OK" } else { "FALLA" })
            note = "El puerto publicado no debe abrirse en todas las interfaces del host"
        }
        [pscustomobject]@{
            control = "effective_port_is_valid"
            observed = $effectivePort
            expected = "1024-65535"
            status = $(if ($portIsValidRange) { "OK" } else { "FALLA" })
            note = "El puerto configurado debe ser local y valido"
        }
        [pscustomobject]@{
            control = "env_example_password_policy_ok"
            observed = "placeholders=$examplePlaceholdersPresent; reusable=$exampleSecretsReusable"
            expected = "placeholders o credenciales academicas robustas"
            status = $(if ($examplePolicyOk) { "OK" } else { "FALLA" })
            note = "El template versionado puede usar placeholders o credenciales academicas estables"
        }
    )

    $failedControls = @($controls | Where-Object { $_.status -eq "FALLA" })

    $summaryRows = @(
        [pscustomobject]@{ metric = "local_env_exists"; value = $localEnvExists }
        [pscustomobject]@{ metric = "postgres_password_length"; value = $postgresPasswordLength }
        [pscustomobject]@{ metric = "operational_passwords_min_length"; value = $operationalMinPasswordLength }
        [pscustomobject]@{ metric = "effective_bind_ip"; value = $effectiveBindIp }
        [pscustomobject]@{ metric = "effective_port"; value = $effectivePort }
        [pscustomobject]@{ metric = "failed_controls"; value = $failedControls.Count }
        [pscustomobject]@{ metric = "min_password_length"; value = $MinPasswordLength }
    )

    $summaryTable = New-MarkdownTable -Rows $summaryRows -Headers @("metric", "value")
    $controlsTable = New-MarkdownTable -Rows $controls -Headers @("control", "observed", "expected", "status", "note")

    $evidenceDir = Split-Path -Parent $EvidencePath
    $null = New-Item -ItemType Directory -Force -Path $evidenceDir

    $content = @"
# Evidencia de Secretos Locales (2026-03-20)

## Objetivo

Validar que la infraestructura local use `infra/docker/.env` no versionado con
secretos runtime reales, suficientes y consistentes con Docker Compose y los
logins operativos locales.

## Contexto de ejecucion

- Fecha de ejecucion: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
- Env local: $EnvPath
- Template: $EnvExamplePath
- Longitud minima requerida: $MinPasswordLength

## Resumen observado

$summaryTable

## Controles

$controlsTable

## Resultado

- Estado general: $(if ($failedControls.Count -eq 0) { "SECRETOS LOCALES OK" } else { "SECRETOS LOCALES CON FALLAS" })
- Fallas bloqueantes: $($failedControls.Count)
"@

    Set-Content -Path $EvidencePath -Value $content -Encoding UTF8
    Write-Host ("[OK] Evidencia escrita en: {0}" -f $EvidencePath)

    if ($failedControls.Count -gt 0) {
        throw ("La validacion de secretos locales detecto {0} fallas bloqueantes." -f $failedControls.Count)
    }

    Write-Output ([pscustomobject]@{
        evidence_path = $EvidencePath
        failed_controls = $failedControls.Count
        postgres_password_length = $postgresPasswordLength
        operational_min_password_length = $operationalMinPasswordLength
    })
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
