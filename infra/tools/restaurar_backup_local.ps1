param(
    [string]$BackupPath,
    [string]$TargetDbName = "flydb_restore_validation",
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$DbUser,
    [string]$MaintenanceDb = "postgres"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($DbUser)) {
    $DbUser = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_USER)) { "fly_admin" } else { $env:POSTGRES_USER }
}

function Assert-RequiredFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Archivo requerido no encontrado: $Path"
    }
}

function Invoke-PsqlMaintenance {
    param([string]$Sql)
    docker exec $ContainerName psql -v ON_ERROR_STOP=1 -U $DbUser -d $MaintenanceDb -c $Sql | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo operacion SQL de restore sobre base de mantenimiento."
    }
}

function Invoke-PsqlScalar {
    param(
        [string]$Database,
        [string]$Sql
    )
    $raw = docker exec $ContainerName psql -t -A -U $DbUser -d $Database -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo consulta de verificacion post-restore."
    }
    return $raw.Trim()
}

try {
    Assert-RequiredFile -Path $BackupPath

    $backupFileName = Split-Path -Leaf $BackupPath
    $remoteBackupPath = "/tmp/{0}" -f $backupFileName

    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Restore Local PostgreSQL"
    Write-Host "======================================================"
    Write-Host ("  Backup origen: {0}" -f $BackupPath)
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base destino: {0}" -f $TargetDbName)
    Write-Host ""

    $startedAt = Get-Date

    docker cp $BackupPath "${ContainerName}:$remoteBackupPath" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo docker cp al subir backup al contenedor."
    }

    try {
        $safeTargetDbName = $TargetDbName.Replace("'", "''")
        $safeDbUser = $DbUser.Replace("'", "''")

        Invoke-PsqlMaintenance -Sql "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$safeTargetDbName' AND pid <> pg_backend_pid();"
        Invoke-PsqlMaintenance -Sql "DROP DATABASE IF EXISTS $TargetDbName;"
        Invoke-PsqlMaintenance -Sql "CREATE DATABASE $TargetDbName OWNER $DbUser;"

        docker exec $ContainerName pg_restore -U $DbUser -d $TargetDbName --no-owner --no-privileges $remoteBackupPath
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo pg_restore al restaurar backup."
        }

        $elapsedMs = [int][Math]::Round(((Get-Date) - $startedAt).TotalMilliseconds, 0)
        $publicTables = [int](Invoke-PsqlScalar -Database $TargetDbName -Sql "SELECT count(*) FROM pg_tables WHERE schemaname = 'public';")
        $dbSizePretty = Invoke-PsqlScalar -Database $MaintenanceDb -Sql "SELECT pg_size_pretty(pg_database_size('$safeTargetDbName'));"

        Write-Host ("[OK] Restore completado en {0} ms" -f $elapsedMs)
        Write-Host ("[OK] Tablas public restauradas: {0}" -f $publicTables)

        Write-Output ([pscustomobject]@{
            restored_at = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz")
            backup_path = $BackupPath
            target_database = $TargetDbName
            container_name = $ContainerName
            target_owner = $DbUser
            public_table_count = $publicTables
            restored_db_size_pretty = $dbSizePretty
            duration_ms = $elapsedMs
        })
    }
    finally {
        docker exec $ContainerName rm -f $remoteBackupPath | Out-Null
    }
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    throw
}
