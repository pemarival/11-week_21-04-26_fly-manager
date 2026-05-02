param(
    [string]$MigrationsRoot,
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$DbUser,
    [string]$DbName,
    [switch]$SkipValidation,
    [switch]$DryRun,
    [switch]$AllowOutOfOrder
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$ValidatorScript = Join-Path $ScriptDir "validar_migraciones.ps1"

if ([string]::IsNullOrWhiteSpace($MigrationsRoot)) {
    $MigrationsRoot = Join-Path $RepoRoot "db\migrations"
}

$UpDir = Join-Path $MigrationsRoot "up"
$NamePattern = '^(?<id>\d{14})__(?<name>[a-z0-9_]+)\.up\.sql$'
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

function Ensure-MigrationJournal {
    $sql = @"
CREATE TABLE IF NOT EXISTS public.schema_migration_journal (
    migration_id     char(14) PRIMARY KEY,
    migration_name   text NOT NULL,
    checksum_sha256  char(64) NOT NULL,
    script_path      text NOT NULL,
    rollback_mode    text NOT NULL,
    execution_ms     integer NOT NULL DEFAULT 0,
    executed_by      text NOT NULL DEFAULT current_user,
    executed_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_schema_migration_journal_executed_at
    ON public.schema_migration_journal (executed_at DESC);
"@
    Invoke-PsqlCommand -Sql $sql
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

function Parse-UpMigration {
    param([System.IO.FileInfo]$File)

    $match = [regex]::Match($File.Name, $NamePattern)
    if (-not $match.Success) {
        throw "Nombre invalido de migracion up: $($File.Name)"
    }

    return [pscustomobject]@{
        Id = $match.Groups["id"].Value
        Name = $match.Groups["name"].Value
        Path = $File.FullName
        FileName = $File.Name
    }
}

function Get-RollbackModeFromHeader {
    param([string]$Path)
    $header = (Get-Content -Path $Path -TotalCount 40) -join "`n"
    $rollbackMatch = [regex]::Match($header, "(?m)^--\s*ROLLBACK:\s*(?<mode>[a-zA-Z_]+)\s*$")
    if (-not $rollbackMatch.Success) {
        throw "No se pudo leer ROLLBACK en migracion: $Path"
    }
    return $rollbackMatch.Groups["mode"].Value.ToLowerInvariant()
}

function Get-RelativePathCompat {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    $baseFullPath = [System.IO.Path]::GetFullPath($BasePath)
    $targetFullPath = [System.IO.Path]::GetFullPath($TargetPath)

    if (-not $baseFullPath.EndsWith([System.IO.Path]::DirectorySeparatorChar) -and -not $baseFullPath.EndsWith([System.IO.Path]::AltDirectorySeparatorChar)) {
        $baseFullPath += [System.IO.Path]::DirectorySeparatorChar
    }

    $baseUri = New-Object System.Uri($baseFullPath)
    $targetUri = New-Object System.Uri($targetFullPath)

    if ($baseUri.Scheme -ne $targetUri.Scheme -or $baseUri.Host -ne $targetUri.Host) {
        return $targetFullPath
    }

    $relativeUri = $baseUri.MakeRelativeUri($targetUri)
    $relativePath = [System.Uri]::UnescapeDataString($relativeUri.ToString())

    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        return "."
    }

    return $relativePath.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
}

$lockTaken = $false

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Aplicacion de Migraciones"
    Write-Host "======================================================"
    Write-Host ("  Root: {0}" -f $MigrationsRoot)
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base: {0} (usuario: {1})" -f $DbName, $DbUser)
    if ($DryRun) {
        Write-Host "  Modo: DRY RUN (sin cambios)"
    }
    Write-Host ""

    Assert-DirectoryExists -Path $MigrationsRoot
    Assert-DirectoryExists -Path $UpDir

    if (-not $SkipValidation) {
        & $ValidatorScript
        if (-not $?) {
            throw "Fallo validacion de migraciones."
        }
    }

    $upFiles = @(Get-ChildItem -Path $UpDir -File -Filter "*.sql" | Sort-Object Name)
    if ($upFiles.Count -eq 0) {
        Write-Host "[WARN] No hay migraciones up para aplicar."
        exit 0
    }

    $migrations = @()
    foreach ($file in $upFiles) {
        $migration = Parse-UpMigration -File $file
        $hash = (Get-FileHash -Path $migration.Path -Algorithm SHA256).Hash.ToLowerInvariant()
        $rollbackMode = Get-RollbackModeFromHeader -Path $migration.Path

        $migration | Add-Member -NotePropertyName Checksum -NotePropertyValue $hash
        $migration | Add-Member -NotePropertyName RollbackMode -NotePropertyValue $rollbackMode
        $migrations += $migration
    }

    if (-not $DryRun) {
        Ensure-MigrationLockTable
        Acquire-MigrationLock -Owner $LockOwner
        $lockTaken = $true
    }

    if (-not $DryRun) {
        $journalExists = (Invoke-PsqlScalar -Sql "SELECT to_regclass('$JournalTable') IS NOT NULL;")
        if ($journalExists -eq "t") {
            Ensure-MigrationJournal
        }
    }

    $journalExists = (Invoke-PsqlScalar -Sql "SELECT to_regclass('$JournalTable') IS NOT NULL;")
    $appliedById = @{}
    $maxAppliedId = ""

    if ($journalExists -eq "t") {
        $rows = Invoke-PsqlRows -Sql "SELECT migration_id, checksum_sha256 FROM $JournalTable ORDER BY migration_id;"
        foreach ($row in $rows) {
            $parts = $row.Split("|")
            if ($parts.Count -lt 2) {
                continue
            }
            $appliedById[$parts[0]] = $parts[1].ToLowerInvariant()
        }
        $maxAppliedId = Invoke-PsqlScalar -Sql "SELECT COALESCE(max(migration_id), '') FROM $JournalTable;"
    }

    $pending = @()
    foreach ($migration in $migrations) {
        if ($appliedById.ContainsKey($migration.Id)) {
            if ($appliedById[$migration.Id] -ne $migration.Checksum) {
                throw "Checksum inconsistente para migracion ya aplicada: $($migration.FileName). No editar migraciones ejecutadas."
            }
            Write-Host ("[SKIP] Ya aplicada: {0}" -f $migration.FileName)
            continue
        }

        if (
            (-not $AllowOutOfOrder) -and
            (-not [string]::IsNullOrWhiteSpace($maxAppliedId)) -and
            ($migration.Id -lt $maxAppliedId)
        ) {
            throw "Migracion fuera de orden detectada ($($migration.FileName)). Ultima aplicada: $maxAppliedId"
        }

        $pending += $migration
    }

    if ($pending.Count -eq 0) {
        Write-Host ""
        Write-Host "[OK] No hay migraciones pendientes."
        exit 0
    }

    Write-Host "Pendientes por aplicar:"
    $pending | Select-Object Id, Name, FileName | Format-Table -AutoSize

    if ($DryRun) {
        Write-Host ""
        Write-Host "[OK] Dry run completado. No se aplicaron cambios."
        exit 0
    }

    foreach ($migration in $pending) {
        $remotePath = "/tmp/migration_$($migration.Id).up.sql"
        $startedAt = Get-Date

        Write-Host ""
        Write-Host ("[APPLY] {0}" -f $migration.FileName)

        docker cp $migration.Path "${ContainerName}:$remotePath" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo docker cp para migracion: $($migration.FileName)"
        }

        try {
            docker exec $ContainerName psql -v ON_ERROR_STOP=1 -U $DbUser -d $DbName -f $remotePath | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "Fallo al ejecutar migracion: $($migration.FileName)"
            }
        }
        finally {
            docker exec $ContainerName rm -f $remotePath | Out-Null
        }

        $elapsedMs = [int][Math]::Round(((Get-Date) - $startedAt).TotalMilliseconds, 0)
        $journalExistsAfterApply = (Invoke-PsqlScalar -Sql "SELECT to_regclass('$JournalTable') IS NOT NULL;")
        if ($journalExistsAfterApply -ne "t") {
            throw "La migracion $($migration.FileName) no dejo disponible $JournalTable. Aplica primero el bootstrap del journal."
        }

        $relativePath = (Get-RelativePathCompat -BasePath $RepoRoot -TargetPath $migration.Path).Replace("\", "/")
        $safeName = $migration.Name.Replace("'", "''")
        $safePath = $relativePath.Replace("'", "''")
        $safeRollback = $migration.RollbackMode.Replace("'", "''")

        $insertSql = @"
INSERT INTO public.schema_migration_journal
    (migration_id, migration_name, checksum_sha256, script_path, rollback_mode, execution_ms)
VALUES
    ('$($migration.Id)', '$safeName', '$($migration.Checksum)', '$safePath', '$safeRollback', $elapsedMs)
ON CONFLICT (migration_id) DO UPDATE
SET migration_name = EXCLUDED.migration_name,
    checksum_sha256 = EXCLUDED.checksum_sha256,
    script_path = EXCLUDED.script_path,
    rollback_mode = EXCLUDED.rollback_mode,
    execution_ms = EXCLUDED.execution_ms,
    executed_at = now(),
    executed_by = current_user;
"@

        Invoke-PsqlCommand -Sql $insertSql
        Write-Host ("[OK] Aplicada {0} ({1} ms)" -f $migration.Id, $elapsedMs)
    }

    $totalApplied = Invoke-PsqlScalar -Sql "SELECT count(*) FROM $JournalTable;"
    Write-Host ""
    Write-Host ("[OK] Migraciones aplicadas en journal: {0}" -f $totalApplied)
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
