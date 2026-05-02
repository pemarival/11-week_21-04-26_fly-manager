$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path

$RegressionSqlPath = Join-Path $RepoRoot "infra\sql\regresion_post_seed.sql"
$ContainerName = "fly-bd-pg-5435"
$DbUser = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_USER)) { "fly_admin" } else { $env:POSTGRES_USER }
$DbName = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_DB))   { "flydb" }     else { $env:POSTGRES_DB }
$RemoteSqlPath = "/tmp/05_regresion_post_seed.sql"

function Assert-RequiredFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Archivo requerido no encontrado: $Path"
    }
}

try {
    Assert-RequiredFile -Path $RegressionSqlPath

    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Regresion Post-Seed"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base: {0} (usuario: {1})" -f $DbName, $DbUser)
    Write-Host ""

    docker cp $RegressionSqlPath "${ContainerName}:$RemoteSqlPath" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo docker cp para script de regresion."
    }

    try {
        docker exec $ContainerName psql `
            -v ON_ERROR_STOP=1 `
            -U $DbUser -d $DbName `
            -f $RemoteSqlPath
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo psql al ejecutar regresion post-seed."
        }
    } finally {
        docker exec $ContainerName rm -f $RemoteSqlPath | Out-Null
    }

    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  Regresion Post-Seed completada sin fallas"
    Write-Host "======================================================"
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}

