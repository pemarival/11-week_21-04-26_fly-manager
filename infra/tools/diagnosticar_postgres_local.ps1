param(
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$EnvPath,
    [string]$DbUser,
    [string]$DbPassword,
    [string]$PrimaryDbName,
    [string]$SecondaryDbName = "flydb_restore_validation",
    [int]$TailLogs = 80
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AuthHelperPath = Join-Path $ScriptDir "_shared\postgres_local_auth.ps1"
if (-not (Test-Path -LiteralPath $AuthHelperPath)) {
    throw "Helper de autenticacion no encontrado: $AuthHelperPath"
}
. $AuthHelperPath

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

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Diagnostico PostgreSQL Local"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base primaria: {0}" -f $PrimaryDbName)
    Write-Host ("  Base secundaria: {0}" -f $SecondaryDbName)
    Write-Host ("  Login operativo: {0} (AUDIT)" -f $DbUser)
    Write-Host ""

    Write-Host "[1/5] Estado del contenedor"
    docker ps --filter "name=$ContainerName" --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
    if ($LASTEXITCODE -ne 0) {
        throw "No fue posible consultar docker ps para el contenedor."
    }

    Write-Host ""
    Write-Host "[2/5] Bases disponibles"
    $databaseRows = Invoke-ContainerPsql `
        -ContainerName $ContainerName `
        -DbUser $DbUser `
        -DbPassword $DbPassword `
        -Database $PrimaryDbName `
        -Arguments @(
            "-P", "pager=off",
            "-c", "SELECT datname AS database_name, pg_size_pretty(pg_database_size(datname)) AS size FROM pg_database WHERE datistemplate = false ORDER BY datname;"
        )
    foreach ($row in $databaseRows) {
        Write-Host $row
    }

    Write-Host ""
    Write-Host "[3/5] Conteos principales"
    $primaryTables = Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT count(*) FROM pg_tables WHERE schemaname = 'public';"
    Write-Host ("      public tables ({0}): {1}" -f $PrimaryDbName, $primaryTables)

    $journalExists = Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT to_regclass('public.schema_migration_journal') IS NOT NULL;"
    if ($journalExists -eq "t") {
        $primaryJournal = Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT count(*) FROM public.schema_migration_journal;"
        Write-Host ("      schema_migration_journal ({0}): {1}" -f $PrimaryDbName, $primaryJournal)
    } else {
        Write-Host ("      schema_migration_journal ({0}): no disponible" -f $PrimaryDbName)
    }

    $secondaryExists = Invoke-PsqlScalar -Database $PrimaryDbName -Sql "SELECT exists(SELECT 1 FROM pg_database WHERE datname = '$SecondaryDbName');"
    if ($secondaryExists -eq "t") {
        try {
            $secondaryTables = Invoke-PsqlScalar -Database $SecondaryDbName -Sql "SELECT count(*) FROM pg_tables WHERE schemaname = 'public';"
            Write-Host ("      public tables ({0}): {1}" -f $SecondaryDbName, $secondaryTables)
        }
        catch {
            Write-Host ("      base secundaria detectada pero no accesible con login operativo: {0}" -f $SecondaryDbName)
        }
    } else {
        Write-Host ("      base secundaria no encontrada: {0}" -f $SecondaryDbName)
    }

    Write-Host ""
    Write-Host "[4/5] Ultimas migraciones registradas"
    if ($journalExists -ne "t") {
        Write-Host "      Journal no disponible en la base primaria."
    } else {
        $journalRows = Invoke-PsqlRows -Database $PrimaryDbName -Sql "SELECT migration_id, migration_name, rollback_mode, executed_at FROM public.schema_migration_journal ORDER BY migration_id DESC LIMIT 5;"
        if ($journalRows.Count -eq 0) {
            Write-Host "      Sin migraciones registradas."
        } else {
            foreach ($row in $journalRows) {
                $parts = $row.Split("|")
                Write-Host ("      {0} | {1} | {2} | {3}" -f $parts[0], $parts[1], $parts[2], $parts[3])
            }
        }
    }

    Write-Host ""
    Write-Host ("[5/5] Ultimos logs del contenedor (tail {0})" -f $TailLogs)
    docker logs --tail $TailLogs $ContainerName
    if ($LASTEXITCODE -ne 0) {
        throw "No fue posible leer logs del contenedor."
    }

    Write-Output ([pscustomobject]@{
        container_name = $ContainerName
        db_user = $DbUser
        login_mode = "audit"
        primary_db = $PrimaryDbName
        secondary_db = $SecondaryDbName
    })
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
