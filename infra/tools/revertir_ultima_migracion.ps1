param(
    [string]$MigrationsRoot,
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$DbUser,
    [string]$DbName,
    [switch]$SkipValidation,
    [switch]$ForceIrreversible,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$ValidatorScript = Join-Path $ScriptDir "validar_migraciones.ps1"

if ([string]::IsNullOrWhiteSpace($MigrationsRoot)) {
    $MigrationsRoot = Join-Path $RepoRoot "db\migrations"
}

$DownDir = Join-Path $MigrationsRoot "down"
$DownPattern = '^(?<id>\d{14})__(?<name>[a-z0-9_]+)\.down\.sql$'
$JournalTable = "public.schema_migration_journal"
$LockTable = "public.schema_migration_lock"
$LockKey = "global"
$LockLeaseMinutes = 15
$LockOwner = ("{0}@{1}:{2}" -f $env:USERNAME, $env:COMPUTERNAME, $PID)

if ([string]::IsNullOrWhiteSpace($DbUser)) {
    $DbUser = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_USER)) { "fly_admin" } else { $env:POSTGRES_USER }
}

if ([string]::IsNullOrWhiteSpace($DbName)) {
    $DbName = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_DB)) { "flydb" } else { $env:POSTGRES_DB }
}

function Assert-DirectoryExists {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Directorio requerido no encontrado: $Path"
    }
}

function Invoke-PsqlCommand {
    param([string]$Sql)
    docker exec $ContainerName psql -v ON_ERROR_STOP=1 -U $DbUser -d $DbName -c $Sql | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo psql ejecutando comando SQL."
    }
}

function Invoke-PsqlScalar {
    param([string]$Sql)
    $raw = docker exec $ContainerName psql -t -A -U $DbUser -d $DbName -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo psql ejecutando consulta escalar."
    }
    return $raw.Trim()
}

function Invoke-PsqlRows {
    param([string]$Sql)
    $rows = docker exec $ContainerName psql -t -A -F "|" -U $DbUser -d $DbName -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo psql ejecutando consulta tabular."
    }
    return ,@($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Ensure-MigrationLockTable {
    $sql = @"
CREATE TABLE IF NOT EXISTS public.schema_migration_lock (
    lock_key     text PRIMARY KEY,
    lock_owner   text NOT NULL,
    acquired_at  timestamptz NOT NULL DEFAULT now(),
    expires_at   timestamptz NOT NULL
);
"@
    Invoke-PsqlCommand -Sql $sql
}

function Acquire-MigrationLock {
    param([string]$Owner)

    $safeOwner = $Owner.Replace("'", "''")
    $sql = @"
WITH acquired AS (
    INSERT INTO public.schema_migration_lock (lock_key, lock_owner, acquired_at, expires_at)
    VALUES ('$LockKey', '$safeOwner', now(), now() + INTERVAL '$LockLeaseMinutes minutes')
    ON CONFLICT (lock_key) DO UPDATE
    SET lock_owner = EXCLUDED.lock_owner,
        acquired_at = now(),
        expires_at = now() + INTERVAL '$LockLeaseMinutes minutes'
    WHERE public.schema_migration_lock.expires_at < now()
       OR public.schema_migration_lock.lock_owner = EXCLUDED.lock_owner
    RETURNING lock_owner
)
SELECT count(*) FROM acquired;
"@

    $acquiredCount = Invoke-PsqlScalar -Sql $sql
    if ($acquiredCount -ne "1") {
        $current = Invoke-PsqlRows -Sql "SELECT lock_owner, acquired_at, expires_at FROM $LockTable WHERE lock_key = '$LockKey';"
        if ($current.Count -gt 0) {
            throw "No fue posible adquirir lock de migraciones. Lock activo: $($current[0])"
        }
        throw "No fue posible adquirir lock de migraciones."
    }
}

function Release-MigrationLock {
    param([string]$Owner)

    $safeOwner = $Owner.Replace("'", "''")
    $tableExists = Invoke-PsqlScalar -Sql "SELECT to_regclass('$LockTable') IS NOT NULL;"
    if ($tableExists -ne "t") {
        return
    }

    Invoke-PsqlCommand -Sql "DELETE FROM $LockTable WHERE lock_key = '$LockKey' AND lock_owner = '$safeOwner';"
}

$lockTaken = $false

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Rollback Ultima Migracion"
    Write-Host "======================================================"
    Write-Host ("  Root: {0}" -f $MigrationsRoot)
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base: {0} (usuario: {1})" -f $DbName, $DbUser)
    if ($DryRun) {
        Write-Host "  Modo: DRY RUN (sin cambios)"
    }
    Write-Host ""

    Assert-DirectoryExists -Path $MigrationsRoot
    Assert-DirectoryExists -Path $DownDir

    if (-not $SkipValidation) {
        & $ValidatorScript
        if (-not $?) {
            throw "Fallo validacion de migraciones."
        }
    }

    if (-not $DryRun) {
        Ensure-MigrationLockTable
        Acquire-MigrationLock -Owner $LockOwner
        $lockTaken = $true
    }

    $journalExists = (Invoke-PsqlScalar -Sql "SELECT to_regclass('$JournalTable') IS NOT NULL;")
    if ($journalExists -ne "t") {
        Write-Host "[OK] No existe $JournalTable. No hay migraciones registradas para revertir."
        exit 0
    }

    $latestRows = Invoke-PsqlRows -Sql "SELECT migration_id, migration_name, rollback_mode FROM $JournalTable ORDER BY migration_id DESC LIMIT 1;"
    if ($latestRows.Count -eq 0) {
        Write-Host "[OK] Journal vacio. No hay migraciones para revertir."
        exit 0
    }

    $parts = $latestRows[0].Split("|")
    if ($parts.Count -lt 3) {
        throw "No fue posible leer la ultima migracion del journal."
    }

    $migrationId = $parts[0]
    $migrationName = $parts[1]
    $rollbackMode = $parts[2].ToLowerInvariant()

    if (($rollbackMode -eq "irreversible") -and (-not $ForceIrreversible)) {
        throw "La ultima migracion ($migrationId) esta marcada como irreversible. Use -ForceIrreversible solo con aprobacion explicita."
    }

    $downCandidates = @(Get-ChildItem -Path $DownDir -File -Filter "${migrationId}__*.down.sql")
    if ($downCandidates.Count -ne 1) {
        throw "Se esperaba 1 script down para $migrationId y se encontraron $($downCandidates.Count)."
    }

    $downFile = $downCandidates[0]
    $nameMatch = [regex]::Match($downFile.Name, $DownPattern)
    if (-not $nameMatch.Success) {
        throw "Nombre invalido para archivo down: $($downFile.Name)"
    }

    $downName = $nameMatch.Groups["name"].Value
    if ($downName -ne $migrationName) {
        throw "Nombre de migracion en down no coincide con journal: down=$downName, journal=$migrationName"
    }

    Write-Host ("Ultima migracion registrada: {0} ({1})" -f $migrationId, $migrationName)
    Write-Host ("Script rollback: {0}" -f $downFile.FullName)

    if ($DryRun) {
        Write-Host ""
        Write-Host "[OK] Dry run completado. No se ejecutaron cambios."
        exit 0
    }

    $remotePath = "/tmp/migration_$migrationId.down.sql"

    docker cp $downFile.FullName "${ContainerName}:$remotePath" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo docker cp del script down para $migrationId."
    }

    try {
        docker exec $ContainerName psql -v ON_ERROR_STOP=1 -U $DbUser -d $DbName -f $remotePath | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo ejecutando rollback SQL de $migrationId."
        }
    }
    finally {
        docker exec $ContainerName rm -f $remotePath | Out-Null
    }

    $journalExistsAfterRollback = (Invoke-PsqlScalar -Sql "SELECT to_regclass('$JournalTable') IS NOT NULL;")
    if ($journalExistsAfterRollback -eq "t") {
        $safeId = $migrationId.Replace("'", "''")
        Invoke-PsqlCommand -Sql "DELETE FROM $JournalTable WHERE migration_id = '$safeId';"
    } elseif ($migrationName -eq "bootstrap_migration_journal") {
        Write-Host "[WARN] El rollback elimino el journal bootstrap; no queda registro persistente de esa migracion."
    } else {
        throw "El rollback dejo inaccesible $JournalTable para una migracion distinta al bootstrap."
    }

    Write-Host ""
    Write-Host ("[OK] Rollback aplicado y journal actualizado para migracion: {0}" -f $migrationId)
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
finally {
    if ($lockTaken) {
        try {
            Release-MigrationLock -Owner $LockOwner
        } catch {}
    }
}
