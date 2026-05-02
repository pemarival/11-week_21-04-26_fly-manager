param(
    [string]$EvidencePath,
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$EnvPath,
    [string]$DbUser,
    [string]$DbPassword,
    [string]$PrimaryDbName,
    [string]$SecondaryDbName = "flydb_restore_validation",
    [int]$LongQuerySeconds = 60,
    [int]$MaxWaitingLocks = 0,
    [int]$MaxIdleInTransaction = 0,
    [int]$MaxLongQueries = 0,
    [decimal]$MinCacheHitRatioPct = 95
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$AuthHelperPath = Join-Path $ScriptDir "_shared\postgres_local_auth.ps1"
if (-not (Test-Path -LiteralPath $AuthHelperPath)) {
    throw "Helper de autenticacion no encontrado: $AuthHelperPath"
}
. $AuthHelperPath

if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
    $EvidencePath = Join-Path $RepoRoot "docs\validacion\EVIDENCIA_OBSERVABILIDAD_LOCAL_2026-03-19.md"
}

$loginContext = Resolve-DbLoginContext `
    -Mode "audit" `
    -ScriptPath $MyInvocation.MyCommand.Path `
    -EnvPath $EnvPath `
    -DbUser $DbUser `
    -DbPassword $DbPassword `
    -DbName $PrimaryDbName

$EnvPath = $loginContext.EnvPath
$DbUser = $loginContext.DbUser
$DbPassword = $loginContext.DbPassword
$PrimaryDbName = $loginContext.DbName

function Invoke-PsqlScalar {
    param(
        [string]$Database,
        [string]$Sql
    )

    return Invoke-ContainerPsqlScalar `
        -ContainerName $ContainerName `
        -DbUser $DbUser `
        -DbPassword $DbPassword `
        -Database $Database `
        -Sql $Sql
}

function Invoke-PsqlRows {
    param(
        [string]$Database,
        [string]$Sql
    )

    return Invoke-ContainerPsqlRows `
        -ContainerName $ContainerName `
        -DbUser $DbUser `
        -DbPassword $DbPassword `
        -Database $Database `
        -Sql $Sql
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
    Write-Host "  FLY Manager - Observabilidad Local"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base primaria: {0}" -f $PrimaryDbName)
    Write-Host ("  Login operativo: {0} (AUDIT)" -f $DbUser)
    Write-Host ("  Evidencia: {0}" -f $EvidencePath)
    Write-Host ""

    $primaryDbSizeBytes = [int64](Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT pg_database_size('$PrimaryDbName');")
    $primaryDbSizePretty = Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT pg_size_pretty(pg_database_size('$PrimaryDbName'));"
    $secondaryExists = Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT exists(SELECT 1 FROM pg_database WHERE datname = '$SecondaryDbName');"
    $secondaryDbSizePretty = if ($secondaryExists -eq "t") { Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT pg_size_pretty(pg_database_size('$SecondaryDbName'));" } else { "N/A" }
    $publicTables = [int](Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT count(*) FROM pg_tables WHERE schemaname = 'public';")
    $activeConnections = [int](Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT count(*) FROM pg_stat_activity WHERE datname = '$PrimaryDbName' AND state = 'active';")
    $idleInTransaction = [int](Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT count(*) FROM pg_stat_activity WHERE datname = '$PrimaryDbName' AND state = 'idle in transaction';")
    $longRunningQueries = [int](Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT count(*) FROM pg_stat_activity WHERE datname = '$PrimaryDbName' AND state <> 'idle' AND now() - query_start > interval '$LongQuerySeconds seconds';")
    $waitingLocks = [int](Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT count(*) FROM pg_locks l JOIN pg_stat_activity a ON a.pid = l.pid WHERE a.datname = '$PrimaryDbName' AND NOT l.granted;")
    $cacheHitRatioPct = [decimal](Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT COALESCE(round(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2), 100.0) FROM pg_stat_database WHERE datname = '$PrimaryDbName';")
    $journalExists = Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT to_regclass('public.schema_migration_journal') IS NOT NULL;"
    $journalRows = if ($journalExists -eq "t") { [int](Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT count(*) FROM public.schema_migration_journal;") } else { 0 }

    $summaryRows = @(
        [pscustomobject]@{ metric = "primary_db_size_pretty"; value = $primaryDbSizePretty }
        [pscustomobject]@{ metric = "secondary_db_size_pretty"; value = $secondaryDbSizePretty }
        [pscustomobject]@{ metric = "public_tables"; value = $publicTables }
        [pscustomobject]@{ metric = "active_connections"; value = $activeConnections }
        [pscustomobject]@{ metric = "idle_in_transaction"; value = $idleInTransaction }
        [pscustomobject]@{ metric = "waiting_locks"; value = $waitingLocks }
        [pscustomobject]@{ metric = "long_running_queries_gt_60s"; value = $longRunningQueries }
        [pscustomobject]@{ metric = "cache_hit_ratio_pct"; value = $cacheHitRatioPct }
        [pscustomobject]@{ metric = "schema_migration_journal_rows"; value = $journalRows }
    )

    $statusRows = @(
        [pscustomobject]@{ control = "waiting_locks"; observed = $waitingLocks; threshold = "<= $MaxWaitingLocks"; status = $(if ($waitingLocks -le $MaxWaitingLocks) { "OK" } else { "FALLA" }) }
        [pscustomobject]@{ control = "idle_in_transaction"; observed = $idleInTransaction; threshold = "<= $MaxIdleInTransaction"; status = $(if ($idleInTransaction -le $MaxIdleInTransaction) { "OK" } else { "FALLA" }) }
        [pscustomobject]@{ control = "long_running_queries_gt_60s"; observed = $longRunningQueries; threshold = "<= $MaxLongQueries"; status = $(if ($longRunningQueries -le $MaxLongQueries) { "OK" } else { "FALLA" }) }
        [pscustomobject]@{ control = "cache_hit_ratio_pct"; observed = $cacheHitRatioPct; threshold = ">= $MinCacheHitRatioPct"; status = $(if ($cacheHitRatioPct -ge $MinCacheHitRatioPct) { "OK" } else { "FALLA" }) }
    )

    $largestTablesRaw = Invoke-PsqlRows -Database $PrimaryDbName -Sql @"
SELECT
  relname AS table_name,
  pg_total_relation_size(relid) AS total_size_bytes,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size_pretty
FROM pg_catalog.pg_statio_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;
"@

    $largestTableRows = foreach ($row in $largestTablesRaw) {
        $parts = $row.Split("|")
        [pscustomobject]@{
            table_name = $parts[0]
            total_size_bytes = $parts[1]
            total_size_pretty = $parts[2]
        }
    }

    $summaryTable = New-MarkdownTable -Rows $summaryRows -Headers @("metric", "value")
    $statusTable = New-MarkdownTable -Rows $statusRows -Headers @("control", "observed", "threshold", "status")
    $largestTable = New-MarkdownTable -Rows $largestTableRows -Headers @("table_name", "total_size_bytes", "total_size_pretty")

    $evidenceDir = Split-Path -Parent $EvidencePath
    $null = New-Item -ItemType Directory -Force -Path $evidenceDir

    $content = @"
# Evidencia de Observabilidad Local (2026-03-19)

## Objetivo

Capturar una fotografia minima de salud operativa de PostgreSQL local para
seguimiento de capacidad, locks, actividad y crecimiento.

## Contexto de ejecucion

- Fecha de ejecucion: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
- Contenedor: $ContainerName
- Base primaria: $PrimaryDbName
- Base secundaria: $SecondaryDbName
- Login operativo AUDIT: $DbUser
- Umbral long query: $LongQuerySeconds segundos

## Resumen observado

$summaryTable

## Controles minimos

$statusTable

## Top 10 tablas por tamano

$largestTable

## Resultado

- Estado general: $(if (@($statusRows | Where-Object { $_.status -ne "OK" }).Count -eq 0) { "OBSERVABILIDAD OK" } else { "OBSERVABILIDAD CON ALERTAS" })
"@

    Set-Content -Path $EvidencePath -Value $content -Encoding UTF8

    $failed = @($statusRows | Where-Object { $_.status -ne "OK" })
    if ($failed.Count -gt 0) {
        throw ("Se detectaron {0} controles de observabilidad fuera de umbral." -f $failed.Count)
    }

    Write-Host ("[OK] Evidencia escrita en: {0}" -f $EvidencePath)
    Write-Output ([pscustomobject]@{
        evidence_path = $EvidencePath
        failed_controls = $failed.Count
        primary_db_size_bytes = $primaryDbSizeBytes
        db_user = $DbUser
        login_mode = "audit"
    })
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
