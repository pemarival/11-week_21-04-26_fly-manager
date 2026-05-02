param(
    [string]$BackupDir,
    [string]$EvidencePath,
    [string]$SourceDbName,
    [string]$TargetDbName = "flydb_restore_validation",
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$DbUser
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$BackupScript = Join-Path $ScriptDir "generar_backup_local.ps1"
$RestoreScript = Join-Path $ScriptDir "restaurar_backup_local.ps1"

if ([string]::IsNullOrWhiteSpace($BackupDir)) {
    $BackupDir = Join-Path $RepoRoot "infra\runtime\backups"
}

if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
    $EvidencePath = Join-Path $RepoRoot "docs\validacion\EVIDENCIA_RECUPERACION_LOCAL_2026-03-19.md"
}

if ([string]::IsNullOrWhiteSpace($DbUser)) {
    $DbUser = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_USER)) { "fly_admin" } else { $env:POSTGRES_USER }
}

if ([string]::IsNullOrWhiteSpace($SourceDbName)) {
    $SourceDbName = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_DB)) { "flydb" } else { $env:POSTGRES_DB }
}

function Invoke-PsqlScalar {
    param(
        [string]$Database,
        [string]$Sql
    )
    $raw = docker exec $ContainerName psql -t -A -U $DbUser -d $Database -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo consulta escalar en prueba de recuperacion."
    }
    return $raw.Trim()
}

function Invoke-PsqlRows {
    param(
        [string]$Database,
        [string]$Sql
    )
    $rows = docker exec $ContainerName psql -t -A -F "|" -U $DbUser -d $Database -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo consulta tabular en prueba de recuperacion."
    }
    return ,@($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Get-TableCounts {
    param([string]$Database)

    $tables = Invoke-PsqlRows -Database $Database -Sql "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;"
    $result = @{}

    foreach ($tableName in $tables) {
        $count = [int64](Invoke-PsqlScalar -Database $Database -Sql "SELECT count(*) FROM public.$tableName;")
        $result[$tableName] = $count
    }

    return $result
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
    Write-Host "  FLY Manager - Prueba de Recuperacion Local"
    Write-Host "======================================================"
    Write-Host ("  Base origen: {0}" -f $SourceDbName)
    Write-Host ("  Base destino: {0}" -f $TargetDbName)
    Write-Host ("  Evidencia: {0}" -f $EvidencePath)
    Write-Host ""

    $sourceCounts = Get-TableCounts -Database $SourceDbName
    $sourceTableNames = @($sourceCounts.Keys | Sort-Object)
    $backupResult = & $BackupScript -OutputDir $BackupDir -ContainerName $ContainerName -DbUser $DbUser -DbName $SourceDbName -Tag "recovery_test"
    if (-not $?) {
        throw "Fallo la generacion del backup."
    }

    $restoreResult = & $RestoreScript -BackupPath $backupResult.backup_path -TargetDbName $TargetDbName -ContainerName $ContainerName -DbUser $DbUser
    if (-not $?) {
        throw "Fallo la restauracion del backup."
    }

    $targetCounts = Get-TableCounts -Database $TargetDbName
    $targetTableNames = @($targetCounts.Keys | Sort-Object)

    $comparison = @()
    $allTables = @($sourceTableNames + $targetTableNames | Sort-Object -Unique)
    foreach ($tableName in $allTables) {
        $sourceCount = if ($sourceCounts.ContainsKey($tableName)) { $sourceCounts[$tableName] } else { $null }
        $targetCount = if ($targetCounts.ContainsKey($tableName)) { $targetCounts[$tableName] } else { $null }
        $status = if ($sourceCount -eq $targetCount) { "OK" } else { "DIFF" }

        $comparison += [pscustomobject]@{
            table_name = $tableName
            source_rows = $sourceCount
            restored_rows = $targetCount
            status = $status
        }
    }

    $mismatches = @($comparison | Where-Object { $_.status -ne "OK" })
    if ($mismatches.Count -gt 0) {
        throw ("Se detectaron diferencias post-restore en {0} tablas." -f $mismatches.Count)
    }

    $summaryRows = @(
        [pscustomobject]@{ metric = "backup_ms"; value = $backupResult.duration_ms }
        [pscustomobject]@{ metric = "restore_ms"; value = $restoreResult.duration_ms }
        [pscustomobject]@{ metric = "public_tables_compared"; value = $comparison.Count }
        [pscustomobject]@{ metric = "mismatches"; value = $mismatches.Count }
        [pscustomobject]@{ metric = "backup_sha256"; value = $backupResult.checksum_sha256 }
    )

    $keyTables = @(
        "country",
        "airline",
        "airport",
        "aircraft",
        "flight",
        "person",
        "customer",
        "loyalty_account",
        "reservation",
        "ticket",
        "payment",
        "invoice",
        "miles_transaction",
        "schema_migration_journal"
    )

    $keyRows = foreach ($tableName in $keyTables) {
        if ($sourceCounts.ContainsKey($tableName)) {
            [pscustomobject]@{
                table_name = $tableName
                source_rows = $sourceCounts[$tableName]
                restored_rows = $targetCounts[$tableName]
                status = "OK"
            }
        }
    }

    $summaryTable = New-MarkdownTable -Rows $summaryRows -Headers @("metric", "value")
    $keyTable = New-MarkdownTable -Rows $keyRows -Headers @("table_name", "source_rows", "restored_rows", "status")

    $evidenceDir = Split-Path -Parent $EvidencePath
    $null = New-Item -ItemType Directory -Force -Path $evidenceDir

    $content = @"
# Evidencia de Recuperacion Local (2026-03-19)

## Objetivo

Validar que el backup local de `PostgreSQL 16` puede restaurarse de forma
controlada en una base temporal y conservar integridad de tablas y conteos.

## Contexto de ejecucion

- Fecha de ejecucion: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
- Contenedor: $ContainerName
- Base origen: $SourceDbName
- Base destino restaurada: $TargetDbName
- Backup generado: $($backupResult.backup_path)
- Metadata backup: $($backupResult.metadata_path)

## Resumen observado

$summaryTable

## Conteos clave verificados

$keyTable

## Resultado

- Estado general: RECUPERACION VALIDADA
- Tablas comparadas: $($comparison.Count)
- Diferencias detectadas: 0
- Criterio de aceptacion: conteos equivalentes entre origen y restaurado.
"@

    Set-Content -Path $EvidencePath -Value $content -Encoding UTF8

    Write-Host ""
    Write-Host ("[OK] Recuperacion validada con {0} tablas comparadas." -f $comparison.Count)
    Write-Host ("[OK] Evidencia escrita en: {0}" -f $EvidencePath)

    Write-Output ([pscustomobject]@{
        source_database = $SourceDbName
        restored_database = $TargetDbName
        compared_tables = $comparison.Count
        mismatches = $mismatches.Count
        backup_ms = $backupResult.duration_ms
        restore_ms = $restoreResult.duration_ms
        evidence_path = $EvidencePath
        backup_path = $backupResult.backup_path
    })
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
