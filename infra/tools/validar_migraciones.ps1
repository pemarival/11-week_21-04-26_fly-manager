param(
    [string]$MigrationsRoot,
    [switch]$AllowEmpty
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path

if ([string]::IsNullOrWhiteSpace($MigrationsRoot)) {
    $MigrationsRoot = Join-Path $RepoRoot "db\migrations"
}

$UpDir = Join-Path $MigrationsRoot "up"
$DownDir = Join-Path $MigrationsRoot "down"
$NamePattern = '^(?<id>\d{14})__(?<name>[a-z0-9_]+)\.(?<direction>up|down)\.sql$'
$ValidRollbackModes = @("reversible", "irreversible")

function Assert-DirectoryExists {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Directorio requerido no encontrado: $Path"
    }
}

function Parse-MigrationFile {
    param([System.IO.FileInfo]$File)

    $match = [regex]::Match($File.Name, $NamePattern)
    if (-not $match.Success) {
        throw "Nombre invalido para migracion: $($File.Name). Use YYYYMMDDHHMMSS__descripcion_snake_case.(up|down).sql"
    }

    return [pscustomobject]@{
        Id = $match.Groups["id"].Value
        Name = $match.Groups["name"].Value
        Direction = $match.Groups["direction"].Value
        Path = $File.FullName
        FileName = $File.Name
    }
}

function Assert-MigrationHeader {
    param(
        [string]$Path,
        [string]$ExpectedId,
        [string]$ExpectedName
    )

    $header = (Get-Content -Path $Path -TotalCount 40) -join "`n"

    if (-not [regex]::IsMatch($header, "(?m)^--\s*MIGRATION:\s*$([regex]::Escape($ExpectedId))\s*$")) {
        throw "Header MIGRATION no coincide en: $Path"
    }

    if (-not [regex]::IsMatch($header, "(?m)^--\s*NAME:\s*$([regex]::Escape($ExpectedName))\s*$")) {
        throw "Header NAME no coincide en: $Path"
    }

    $rollbackMatch = [regex]::Match($header, "(?m)^--\s*ROLLBACK:\s*(?<mode>[a-zA-Z_]+)\s*$")
    if (-not $rollbackMatch.Success) {
        throw "Header ROLLBACK faltante en: $Path"
    }

    $rollbackMode = $rollbackMatch.Groups["mode"].Value.ToLowerInvariant()
    if ($ValidRollbackModes -notcontains $rollbackMode) {
        throw "Header ROLLBACK invalido en: $Path (valor: $rollbackMode)"
    }

    if (-not [regex]::IsMatch($header, "(?m)^--\s*AUTHOR:\s*.+$")) {
        throw "Header AUTHOR faltante en: $Path"
    }

    return $rollbackMode
}

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Validacion de Migraciones"
    Write-Host "======================================================"
    Write-Host ("  Root: {0}" -f $MigrationsRoot)
    Write-Host ""

    Assert-DirectoryExists -Path $MigrationsRoot
    Assert-DirectoryExists -Path $UpDir
    Assert-DirectoryExists -Path $DownDir

    $upFiles = @(Get-ChildItem -Path $UpDir -File -Filter "*.sql" | Sort-Object Name)
    $downFiles = @(Get-ChildItem -Path $DownDir -File -Filter "*.sql" | Sort-Object Name)

    if (($upFiles.Count -eq 0) -and ($downFiles.Count -eq 0)) {
        if ($AllowEmpty) {
            Write-Host "[WARN] No se encontraron migraciones (permitido por -AllowEmpty)."
            exit 0
        }
        throw "No se encontraron migraciones en up/down."
    }

    $upById = @{}
    foreach ($file in $upFiles) {
        $parsed = Parse-MigrationFile -File $file
        if ($parsed.Direction -ne "up") {
            throw "Archivo en up con sufijo no permitido: $($parsed.FileName)"
        }
        if ($upById.ContainsKey($parsed.Id)) {
            throw "ID duplicado en up: $($parsed.Id)"
        }
        $upById[$parsed.Id] = $parsed
    }

    $downById = @{}
    foreach ($file in $downFiles) {
        $parsed = Parse-MigrationFile -File $file
        if ($parsed.Direction -ne "down") {
            throw "Archivo en down con sufijo no permitido: $($parsed.FileName)"
        }
        if ($downById.ContainsKey($parsed.Id)) {
            throw "ID duplicado en down: $($parsed.Id)"
        }
        $downById[$parsed.Id] = $parsed
    }

    foreach ($id in $upById.Keys) {
        if (-not $downById.ContainsKey($id)) {
            throw "Migracion sin rollback: $id"
        }
        if ($upById[$id].Name -ne $downById[$id].Name) {
            throw "Nombre inconsistente entre up/down para $id"
        }
    }

    foreach ($id in $downById.Keys) {
        if (-not $upById.ContainsKey($id)) {
            throw "Rollback huérfano sin up asociado: $id"
        }
    }

    $summary = @()
    $orderedIds = @($upById.Keys | Sort-Object)
    foreach ($id in $orderedIds) {
        $up = $upById[$id]
        $down = $downById[$id]

        $upRollback = Assert-MigrationHeader -Path $up.Path -ExpectedId $up.Id -ExpectedName $up.Name
        $downRollback = Assert-MigrationHeader -Path $down.Path -ExpectedId $down.Id -ExpectedName $down.Name

        if ($upRollback -ne $downRollback) {
            throw "Modo de rollback inconsistente entre up/down para $id"
        }

        $summary += [pscustomobject]@{
            migration_id = $id
            name = $up.Name
            rollback = $upRollback
            up_file = $up.FileName
            down_file = $down.FileName
        }
    }

    $summary | Format-Table -AutoSize

    Write-Host ""
    Write-Host ("[OK] Migraciones validadas: {0}" -f $summary.Count)
    Write-Host ("[OK] Archivos up: {0}" -f $upFiles.Count)
    Write-Host ("[OK] Archivos down: {0}" -f $downFiles.Count)
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
