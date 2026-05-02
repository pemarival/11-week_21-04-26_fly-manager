param(
    [string]$EnvPath,
    [string]$EvidencePath,
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$DbName,
    [int]$TailLogs = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$AuthHelperPath = Join-Path $ScriptDir "_shared\postgres_local_auth.ps1"
$SecretsValidationScript = Join-Path $ScriptDir "validar_secretos_locales.ps1"
$OperationalLoginsValidationScript = Join-Path $ScriptDir "validar_logins_operativos_locales.ps1"
$DiagnosticScript = Join-Path $ScriptDir "diagnosticar_postgres_local.ps1"
$ObservabilityScript = Join-Path $ScriptDir "capturar_observabilidad_local.ps1"
$BaselineScript = Join-Path $ScriptDir "ejecutar_baseline_performance_local.ps1"

if (-not (Test-Path -LiteralPath $AuthHelperPath)) {
    throw "Helper de autenticacion no encontrado: $AuthHelperPath"
}
. $AuthHelperPath

if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
    $EvidencePath = Join-Path $RepoRoot "docs\validacion\EVIDENCIA_MENOR_PRIVILEGIO_OPERATIVO_LOCAL_2026-03-20.md"
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

function Test-LoginSql {
    param(
        [pscustomobject]$LoginContext,
        [string]$Sql
    )

    $dockerArgs = @(
        "exec"
        "-e"
        "PGPASSWORD=$($LoginContext.DbPassword)"
        "-e"
        "PGCONNECT_TIMEOUT=5"
        $ContainerName
        "psql"
        "-h"
        "127.0.0.1"
        "-U"
        $LoginContext.DbUser
        "-d"
        $LoginContext.DbName
        "-v"
        "ON_ERROR_STOP=1"
        "-q"
        "-t"
        "-A"
        "-c"
        $Sql
    )

    $raw = & docker @dockerArgs 2>&1
    $ok = ($LASTEXITCODE -eq 0)
    $output = (($raw | ForEach-Object { $_.ToString() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n").Trim()

    return [pscustomobject]@{
        ok = $ok
        output = $output
    }
}

try {
    foreach ($path in @(
        $SecretsValidationScript,
        $OperationalLoginsValidationScript,
        $DiagnosticScript,
        $ObservabilityScript,
        $BaselineScript
    )) {
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Archivo requerido no encontrado: $path"
        }
    }

    & $SecretsValidationScript -EnvPath $EnvPath | Out-Null
    if (-not $?) {
        throw "La validacion de secretos locales fallo antes del control de menor privilegio."
    }

    & $OperationalLoginsValidationScript -EnvPath $EnvPath | Out-Null
    if (-not $?) {
        throw "La validacion de logins operativos fallo antes del control de menor privilegio."
    }

    $auditLoginContext = Resolve-DbLoginContext `
        -Mode "audit" `
        -ScriptPath $MyInvocation.MyCommand.Path `
        -EnvPath $EnvPath `
        -DbName $DbName

    $roLoginContext = Resolve-DbLoginContext `
        -Mode "ro" `
        -ScriptPath $MyInvocation.MyCommand.Path `
        -EnvPath $auditLoginContext.EnvPath `
        -DbName $auditLoginContext.DbName

    $rwLoginContext = Resolve-DbLoginContext `
        -Mode "rw" `
        -ScriptPath $MyInvocation.MyCommand.Path `
        -EnvPath $auditLoginContext.EnvPath `
        -DbName $auditLoginContext.DbName

    $runtimeEvidenceDir = Join-Path $RepoRoot "infra\runtime\least_privilege"
    $null = New-Item -ItemType Directory -Force -Path $runtimeEvidenceDir
    $observabilityRuntimeEvidence = Join-Path $runtimeEvidenceDir "observabilidad_s43_20260320.md"
    $baselineRuntimeEvidence = Join-Path $runtimeEvidenceDir "baseline_s43_20260320.md"

    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Validacion Menor Privilegio Operativo"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base: {0}" -f $auditLoginContext.DbName)
    Write-Host ("  Login AUDIT: {0}" -f $auditLoginContext.DbUser)
    Write-Host ("  Login RO: {0}" -f $roLoginContext.DbUser)
    Write-Host ("  Login RW: {0}" -f $rwLoginContext.DbUser)
    Write-Host ("  Evidencia: {0}" -f $EvidencePath)
    Write-Host ""

    $diagnosticResult = @(& $DiagnosticScript `
        -ContainerName $ContainerName `
        -EnvPath $auditLoginContext.EnvPath `
        -PrimaryDbName $auditLoginContext.DbName `
        -TailLogs $TailLogs) | Select-Object -Last 1
    if (-not $?) {
        throw "El diagnostico local no pudo ejecutarse con defaults operativos."
    }

    $observabilityResult = @(& $ObservabilityScript `
        -ContainerName $ContainerName `
        -EnvPath $auditLoginContext.EnvPath `
        -PrimaryDbName $auditLoginContext.DbName `
        -EvidencePath $observabilityRuntimeEvidence) | Select-Object -Last 1
    if (-not $?) {
        throw "La observabilidad local no pudo ejecutarse con login AUDIT."
    }

    $baselineResult = @(& $BaselineScript `
        -ContainerName $ContainerName `
        -EnvPath $auditLoginContext.EnvPath `
        -DbName $auditLoginContext.DbName `
        -EvidencePath $baselineRuntimeEvidence) | Select-Object -Last 1
    if (-not $?) {
        throw "El baseline local no pudo ejecutarse con logins RO/RW."
    }

    $auditStatsProbe = Test-LoginSql -LoginContext $auditLoginContext -Sql "SELECT count(*) FROM pg_stat_activity WHERE datname = current_database();"
    $auditJournalProbe = Test-LoginSql -LoginContext $auditLoginContext -Sql "SELECT COALESCE(to_regclass('public.schema_migration_journal')::text, 'missing');"
    $auditDmlDenied = Test-LoginSql -LoginContext $auditLoginContext -Sql "DELETE FROM public.country WHERE 1 = 0;"
    $auditTempDenied = Test-LoginSql -LoginContext $auditLoginContext -Sql "CREATE TEMP TABLE tmp_s43_audit_probe (id int);"

    $roReadProbe = Test-LoginSql -LoginContext $roLoginContext -Sql @"
SELECT count(*)
FROM public.reservation r
JOIN public.customer c ON c.customer_id = r.booked_by_customer_id;
"@
    $roDmlDenied = Test-LoginSql -LoginContext $roLoginContext -Sql "DELETE FROM public.country WHERE 1 = 0;"
    $roTempDenied = Test-LoginSql -LoginContext $roLoginContext -Sql "CREATE TEMP TABLE tmp_s43_ro_probe (id int);"

    $rwTempProbe = Test-LoginSql -LoginContext $rwLoginContext -Sql @"
CREATE TEMP TABLE tmp_s43_rw_probe (id int);
INSERT INTO tmp_s43_rw_probe VALUES (1), (2);
SELECT count(*) FROM tmp_s43_rw_probe;
"@

    $controls = @(
        [pscustomobject]@{
            control = "diagnostic_defaults_to_audit_login"
            observed = $diagnosticResult.db_user
            expected = $auditLoginContext.DbUser
            status = $(if ($diagnosticResult.db_user -eq $auditLoginContext.DbUser) { "OK" } else { "FALLA" })
            note = "El diagnostico local debe resolver AUDIT por defecto"
        }
        [pscustomobject]@{
            control = "observability_defaults_to_audit_login"
            observed = $observabilityResult.db_user
            expected = $auditLoginContext.DbUser
            status = $(if ($observabilityResult.db_user -eq $auditLoginContext.DbUser) { "OK" } else { "FALLA" })
            note = "La observabilidad local debe ejecutarse con AUDIT"
        }
        [pscustomobject]@{
            control = "baseline_defaults_to_ro_read_login"
            observed = $baselineResult.read_db_user
            expected = $roLoginContext.DbUser
            status = $(if ($baselineResult.read_db_user -eq $roLoginContext.DbUser) { "OK" } else { "FALLA" })
            note = "Las consultas de lectura del baseline deben usar RO"
        }
        [pscustomobject]@{
            control = "baseline_defaults_to_rw_write_login"
            observed = $baselineResult.write_db_user
            expected = $rwLoginContext.DbUser
            status = $(if ($baselineResult.write_db_user -eq $rwLoginContext.DbUser) { "OK" } else { "FALLA" })
            note = "La prueba de escritura del baseline debe usar RW"
        }
        [pscustomobject]@{
            control = "audit_stats_probe_ok"
            observed = $auditStatsProbe.ok
            expected = "true"
            status = $(if ($auditStatsProbe.ok) { "OK" } else { "FALLA" })
            note = "AUDIT debe consultar pg_stat_activity"
        }
        [pscustomobject]@{
            control = "audit_journal_probe_ok"
            observed = $auditJournalProbe.ok
            expected = "true"
            status = $(if ($auditJournalProbe.ok) { "OK" } else { "FALLA" })
            note = "AUDIT debe inspeccionar la presencia del journal cuando exista"
        }
        [pscustomobject]@{
            control = "audit_dml_denied"
            observed = (-not $auditDmlDenied.ok)
            expected = "true"
            status = $(if (-not $auditDmlDenied.ok) { "OK" } else { "FALLA" })
            note = "AUDIT no debe poder ejecutar DML"
        }
        [pscustomobject]@{
            control = "audit_temp_denied"
            observed = (-not $auditTempDenied.ok)
            expected = "true"
            status = $(if (-not $auditTempDenied.ok) { "OK" } else { "FALLA" })
            note = "AUDIT no debe crear tablas temporales"
        }
        [pscustomobject]@{
            control = "ro_read_probe_ok"
            observed = $roReadProbe.ok
            expected = "true"
            status = $(if ($roReadProbe.ok) { "OK" } else { "FALLA" })
            note = "RO debe poder ejecutar joins operativos de lectura"
        }
        [pscustomobject]@{
            control = "ro_dml_denied"
            observed = (-not $roDmlDenied.ok)
            expected = "true"
            status = $(if (-not $roDmlDenied.ok) { "OK" } else { "FALLA" })
            note = "RO no debe poder ejecutar DML"
        }
        [pscustomobject]@{
            control = "ro_temp_denied"
            observed = (-not $roTempDenied.ok)
            expected = "true"
            status = $(if (-not $roTempDenied.ok) { "OK" } else { "FALLA" })
            note = "RO no debe crear tablas temporales"
        }
        [pscustomobject]@{
            control = "rw_temp_probe_ok"
            observed = $rwTempProbe.ok
            expected = "true"
            status = $(if ($rwTempProbe.ok) { "OK" } else { "FALLA" })
            note = "RW debe poder ejecutar el probe temporal seguro"
        }
    )

    $probeRows = @(
        [pscustomobject]@{ probe = "audit_stats"; ok = $auditStatsProbe.ok; detail = $auditStatsProbe.output }
        [pscustomobject]@{ probe = "audit_journal"; ok = $auditJournalProbe.ok; detail = $auditJournalProbe.output }
        [pscustomobject]@{ probe = "audit_dml_denied"; ok = (-not $auditDmlDenied.ok); detail = $auditDmlDenied.output }
        [pscustomobject]@{ probe = "audit_temp_denied"; ok = (-not $auditTempDenied.ok); detail = $auditTempDenied.output }
        [pscustomobject]@{ probe = "ro_read"; ok = $roReadProbe.ok; detail = $roReadProbe.output }
        [pscustomobject]@{ probe = "ro_dml_denied"; ok = (-not $roDmlDenied.ok); detail = $roDmlDenied.output }
        [pscustomobject]@{ probe = "ro_temp_denied"; ok = (-not $roTempDenied.ok); detail = $roTempDenied.output }
        [pscustomobject]@{ probe = "rw_temp_probe"; ok = $rwTempProbe.ok; detail = $rwTempProbe.output }
    )

    $failedControls = @($controls | Where-Object { $_.status -ne "OK" })
    $summaryRows = @(
        [pscustomobject]@{ metric = "validated_non_admin_flows"; value = 3 }
        [pscustomobject]@{ metric = "failed_controls"; value = $failedControls.Count }
        [pscustomobject]@{ metric = "diagnostic_login"; value = $diagnosticResult.db_user }
        [pscustomobject]@{ metric = "observability_login"; value = $observabilityResult.db_user }
        [pscustomobject]@{ metric = "baseline_read_login"; value = $baselineResult.read_db_user }
        [pscustomobject]@{ metric = "baseline_write_login"; value = $baselineResult.write_db_user }
    )

    $summaryTable = New-MarkdownTable -Rows $summaryRows -Headers @("metric", "value")
    $controlsTable = New-MarkdownTable -Rows $controls -Headers @("control", "observed", "expected", "status", "note")
    $probesTable = New-MarkdownTable -Rows $probeRows -Headers @("probe", "ok", "detail")

    $evidenceDir = Split-Path -Parent $EvidencePath
    $null = New-Item -ItemType Directory -Force -Path $evidenceDir

    $content = @"
# Evidencia de Menor Privilegio Operativo Local (2026-03-20)

## Objetivo

Verificar que los flujos cotidianos de diagnostico, observabilidad y baseline
local ya no dependan de ``fly_admin`` y usen por defecto logins operativos
AUDIT, RO y RW con privilegio minimo verificable.

## Contexto de ejecucion

- Fecha de ejecucion: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
- Contenedor: $ContainerName
- Base validada: $($auditLoginContext.DbName)
- Login AUDIT: $($auditLoginContext.DbUser)
- Login RO: $($roLoginContext.DbUser)
- Login RW: $($rwLoginContext.DbUser)
- Evidencia runtime observabilidad: $observabilityRuntimeEvidence
- Evidencia runtime baseline: $baselineRuntimeEvidence

## Resumen observado

$summaryTable

## Controles

$controlsTable

## Probes directos

$probesTable

## Resultado

- Estado general: $(if ($failedControls.Count -eq 0) { "MENOR PRIVILEGIO OPERATIVO OK" } else { "MENOR PRIVILEGIO OPERATIVO CON FALLAS" })
- Fallas bloqueantes: $($failedControls.Count)
"@

    Set-Content -Path $EvidencePath -Value $content -Encoding UTF8
    Write-Host ("[OK] Evidencia escrita en: {0}" -f $EvidencePath)

    if ($failedControls.Count -gt 0) {
        throw ("La validacion de menor privilegio operativo detecto {0} fallas bloqueantes." -f $failedControls.Count)
    }

    Write-Output ([pscustomobject]@{
        evidence_path = $EvidencePath
        failed_controls = $failedControls.Count
        diagnostic_login = $diagnosticResult.db_user
        observability_login = $observabilityResult.db_user
        baseline_read_login = $baselineResult.read_db_user
        baseline_write_login = $baselineResult.write_db_user
    })
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
