param(
    [string]$OutputDir,
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$DbUser,
    [string]$DbName,
    [string]$Tag = "manual"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $RepoRoot "infra\runtime\backups"
}

if ([string]::IsNullOrWhiteSpace($DbUser)) {
    $DbUser = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_USER)) { "fly_admin" } else { $env:POSTGRES_USER }
}

if ([string]::IsNullOrWhiteSpace($DbName)) {
    $DbName = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_DB)) { "flydb" } else { $env:POSTGRES_DB }
}

function Invoke-PsqlScalar {
    param([string]$Sql)
    $raw = docker exec $ContainerName psql -t -A -U $DbUser -d $DbName -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo consulta de metadatos para backup."
    }
    return $raw.Trim()
}

try {
    $null = New-Item -ItemType Directory -Force -Path $OutputDir

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeTag = ($Tag.ToLowerInvariant() -replace '[^a-z0-9_-]', '_')
    $baseName = "{0}_{1}_{2}" -f $DbName, $safeTag, $timestamp
    $backupPath = Join-Path $OutputDir ($baseName + ".dump")
    $metadataPath = Join-Path $OutputDir ($baseName + ".metadata.json")
    $remoteBackupPath = "/tmp/{0}.dump" -f $baseName

    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Backup Local PostgreSQL"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base origen: {0}" -f $DbName)
    Write-Host ("  Destino host: {0}" -f $backupPath)
    Write-Host ""

    $startedAt = Get-Date

    docker exec $ContainerName pg_dump -U $DbUser -d $DbName -Fc -f $remoteBackupPath
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo pg_dump al generar backup."
    }

    try {
        docker cp "${ContainerName}:$remoteBackupPath" $backupPath | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo docker cp al copiar backup al host."
        }
    }
    finally {
        docker exec $ContainerName rm -f $remoteBackupPath | Out-Null
    }

    $elapsedMs = [int][Math]::Round(((Get-Date) - $startedAt).TotalMilliseconds, 0)
    $fileInfo = Get-Item -LiteralPath $backupPath
    $sha256 = (Get-FileHash -Path $backupPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $dbSizeBytes = [int64](Invoke-PsqlScalar -Sql "SELECT pg_database_size('$DbName');")
    $dbSizePretty = Invoke-PsqlScalar -Sql "SELECT pg_size_pretty(pg_database_size('$DbName'));"
    $publicTables = [int](Invoke-PsqlScalar -Sql "SELECT count(*) FROM pg_tables WHERE schemaname = 'public';")
    $journalRows = 0
    $journalExists = Invoke-PsqlScalar -Sql "SELECT to_regclass('public.schema_migration_journal') IS NOT NULL;"
    if ($journalExists -eq "t") {
        $journalRows = [int](Invoke-PsqlScalar -Sql "SELECT count(*) FROM public.schema_migration_journal;")
    }

    $metadata = [pscustomobject]@{
        created_at = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz")
        container_name = $ContainerName
        source_database = $DbName
        source_user = $DbUser
        backup_path = $backupPath
        metadata_path = $metadataPath
        file_name = $fileInfo.Name
        file_size_bytes = $fileInfo.Length
        checksum_sha256 = $sha256
        duration_ms = $elapsedMs
        source_db_size_bytes = $dbSizeBytes
        source_db_size_pretty = $dbSizePretty
        public_table_count = $publicTables
        schema_migration_journal_rows = $journalRows
        tag = $safeTag
    }

    $metadata | ConvertTo-Json -Depth 4 | Set-Content -Path $metadataPath -Encoding UTF8

    Write-Host ("[OK] Backup generado en {0} ms" -f $elapsedMs)
    Write-Host ("[OK] SHA256: {0}" -f $sha256)
    Write-Host ("[OK] Metadata: {0}" -f $metadataPath)

    Write-Output $metadata
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    throw
}
