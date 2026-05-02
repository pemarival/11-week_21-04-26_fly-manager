param(
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$DbUser,
    [string]$DbName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($DbUser)) {
    $DbUser = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_USER)) { "fly_admin" } else { $env:POSTGRES_USER }
}

if ([string]::IsNullOrWhiteSpace($DbName)) {
    $DbName = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_DB)) { "flydb" } else { $env:POSTGRES_DB }
}

$BlockBegin = "# BEGIN FLY_MANAGER_BOOTSTRAP_ADMIN_TCP_BLOCK"
$BlockEnd = "# END FLY_MANAGER_BOOTSTRAP_ADMIN_TCP_BLOCK"

function Invoke-PsqlScalar {
    param([string]$Sql)

    $raw = docker exec $ContainerName psql -t -A -U $DbUser -d $DbName -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo consulta escalar al confinar admin bootstrap."
    }

    return $raw.Trim()
}

function Get-ManagedBlock {
    param([string]$AdminUser)

    return @(
        $BlockBegin
        "host all $AdminUser 0.0.0.0/0 reject"
        "host all $AdminUser ::/0 reject"
        $BlockEnd
    ) -join "`n"
}

function Remove-ExistingManagedBlock {
    param([string]$Content)

    $escapedBegin = [regex]::Escape($BlockBegin)
    $escapedEnd = [regex]::Escape($BlockEnd)
    $pattern = "(?ms)^$escapedBegin\r?\n.*?^$escapedEnd\r?\n?"
    return [regex]::Replace($Content, $pattern, "")
}

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Confinamiento Admin Bootstrap Local"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base: {0}" -f $DbName)
    Write-Host ("  Admin bootstrap: {0}" -f $DbUser)
    Write-Host ""

    $hbaFile = Invoke-PsqlScalar -Sql "SHOW hba_file;"
    if ([string]::IsNullOrWhiteSpace($hbaFile)) {
        throw "No se pudo resolver la ruta de pg_hba.conf."
    }

    $localTempPath = Join-Path ([System.IO.Path]::GetTempPath()) ("codex_pg_hba_{0}.conf" -f [guid]::NewGuid().ToString("N"))

    try {
        docker cp "${ContainerName}:$hbaFile" $localTempPath | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo docker cp al leer pg_hba.conf desde el contenedor."
        }

        $currentContent = Get-Content -Path $localTempPath -Raw
        $sanitizedContent = Remove-ExistingManagedBlock -Content $currentContent
        $managedBlock = Get-ManagedBlock -AdminUser $DbUser

        $trimmedContent = $sanitizedContent.TrimStart("`r", "`n")
        $newContent = if ([string]::IsNullOrWhiteSpace($trimmedContent)) {
            "$managedBlock`n"
        } else {
            "$managedBlock`n`n$trimmedContent"
        }

        [System.IO.File]::WriteAllText(
            $localTempPath,
            $newContent,
            [System.Text.UTF8Encoding]::new($false)
        )

        docker cp $localTempPath "${ContainerName}:$hbaFile" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo docker cp al escribir pg_hba.conf en el contenedor."
        }

        docker exec $ContainerName chown postgres:postgres $hbaFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo al restaurar owner de pg_hba.conf."
        }
    }
    finally {
        if (Test-Path -LiteralPath $localTempPath) {
            Remove-Item -LiteralPath $localTempPath -Force
        }
    }

    $reloadOk = Invoke-PsqlScalar -Sql "SELECT pg_reload_conf();"
    if ($reloadOk -ne "t") {
        throw "PostgreSQL no confirmo recarga de configuracion."
    }

    Write-Host ("[OK] pg_hba.conf actualizado: {0}" -f $hbaFile)
    Write-Host "[OK] fly_admin queda rechazado sobre TCP y preservado para socket local interno."
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
