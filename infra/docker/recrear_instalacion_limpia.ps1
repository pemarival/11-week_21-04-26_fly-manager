$ErrorActionPreference = "Stop"

# ============================================================
# recrear_instalacion_limpia.ps1
# Flujo deterministico:
# 1) down -v
# 2) up -d
# 3) cargar DDL base manualmente (sin depender de initdb)
# 4) aplicar migraciones versionadas obligatorias
# 5) cargar seeds y validaciones de datos
# 6) validar conteos y minimos operativos
# 7) aplicar hardening y auditoria local de seguridad
# ============================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$ProjectRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path

$DdlPath           = Join-Path $ProjectRoot "db\ddl\modelo_postgresql.sql"
$MigrationApplyPath = Join-Path $ProjectRoot "infra\tools\aplicar_migraciones.ps1"
$SeedCanonicoPath  = Join-Path $ProjectRoot "db\seeds\00_seed_canonico.sql"
$SeedVolPath       = Join-Path $ProjectRoot "db\seeds\01_seed_volumetrico.sql"
$SeedValidPath     = Join-Path $ProjectRoot "db\seeds\99_validaciones_post_seed.sql"
$SecretsValidationPath = Join-Path $ProjectRoot "infra\tools\validar_secretos_locales.ps1"
$SecurityHardeningPath = Join-Path $ProjectRoot "infra\tools\endurecer_seguridad_postgres_local.ps1"
$BootstrapAdminConfinementPath = Join-Path $ProjectRoot "infra\tools\confinar_admin_bootstrap_local.ps1"
$OperationalLoginsProvisionPath = Join-Path $ProjectRoot "infra\tools\provisionar_logins_operativos_locales.ps1"
$DelegatedUsersProvisionPath = Join-Path $ProjectRoot "infra\tools\provisionar_usuarios_delegados_locales.ps1"
$DelegatedUsersCsvPath = Join-Path $ProjectRoot "infra\runtime\security\delegated_users_local.csv"
$OperationalLoginsValidationPath = Join-Path $ProjectRoot "infra\tools\validar_logins_operativos_locales.ps1"
$OperationalLoginsEvidencePath   = Join-Path $ProjectRoot "docs\validacion\EVIDENCIA_LOGINS_OPERATIVOS_LOCALES_2026-03-20.md"
$LeastPrivilegeValidationPath    = Join-Path $ProjectRoot "infra\tools\validar_menor_privilegio_operativo_local.ps1"
$LeastPrivilegeEvidencePath      = Join-Path $ProjectRoot "docs\validacion\EVIDENCIA_MENOR_PRIVILEGIO_OPERATIVO_LOCAL_2026-03-20.md"
$BootstrapAdminValidationPath    = Join-Path $ProjectRoot "infra\tools\validar_admin_bootstrap_local.ps1"
$BootstrapAdminEvidencePath      = Join-Path $ProjectRoot "docs\validacion\EVIDENCIA_ADMIN_BOOTSTRAP_LOCAL_2026-03-20.md"
$SecurityAuditPath     = Join-Path $ProjectRoot "infra\tools\auditar_seguridad_postgres_local.ps1"
$SecurityAuditEvidencePath = Join-Path $ProjectRoot "docs\validacion\EVIDENCIA_AUDITORIA_SEGURIDAD_LOCAL_2026-03-20.md"
$EnvPath = Join-Path $ProjectRoot "infra\docker\.env"

$ContainerName = "fly-bd-pg-5435"
$DbUser = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_USER)) { "fly_admin" } else { $env:POSTGRES_USER }
$DbName = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_DB))   { "flydb" }     else { $env:POSTGRES_DB }
$HostBindIp = "127.0.0.1"
$HostPort = "5435"
$RuntimeLogin = "fly_local_rw"
$ReadOnlyLogin = "fly_local_ro"
$AuditLogin = "fly_local_audit"

function Assert-RequiredFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Archivo requerido no encontrado: $Path"
    }
}

function Get-EnvMap {
    param([string]$Path)

    $map = [ordered]@{}
    foreach ($line in Get-Content -Path $Path) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) {
            continue
        }

        $separator = $trimmed.IndexOf("=")
        if ($separator -lt 1) {
            throw "Formato invalido en archivo .env: $Path"
        }

        $key = $trimmed.Substring(0, $separator).Trim()
        $value = $trimmed.Substring($separator + 1)
        $map[$key] = $value
    }

    return $map
}

function Invoke-PsqlFile {
    param(
        [string]$LocalPath,
        [string]$RemotePath,
        [string]$Label
    )

    Write-Host "      -> $Label"
    docker cp $LocalPath "${ContainerName}:$RemotePath" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo docker cp para $Label"
    }
    try {
        docker exec $ContainerName psql `
            -v ON_ERROR_STOP=1 `
            -U $DbUser -d $DbName `
            -f $RemotePath
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo psql al ejecutar $Label"
        }
    } finally {
        docker exec $ContainerName rm -f $RemotePath | Out-Null
    }
}

function Invoke-PsqlScalar {
    param([string]$Sql)
    $raw = docker exec $ContainerName psql -t -A -U $DbUser -d $DbName -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo consulta escalar de verificacion."
    }
    return $raw.Trim()
}

function Assert-PositiveCount {
    param(
        [string]$Label,
        [string]$Sql
    )

    $value = [int64](Invoke-PsqlScalar -Sql $Sql)
    if ($value -le 0) {
        throw "Validacion fallida: $Label = $value"
    }
    Write-Host ("      OK {0}: {1}" -f $Label, $value)
}

function Assert-RelationExists {
    param(
        [string]$Label,
        [string]$Relation
    )

    $safeRelation = $Relation.Replace("'", "''")
    $exists = Invoke-PsqlScalar -Sql "SELECT to_regclass('$safeRelation') IS NOT NULL;"
    if ($exists -ne "t") {
        throw "Validacion fallida: $Label no disponible ($Relation)"
    }
    Write-Host ("      OK {0}: presente" -f $Label)
}

function Assert-MinCount {
    param(
        [string]$Label,
        [string]$Sql,
        [int64]$MinExpected
    )

    $value = [int64](Invoke-PsqlScalar -Sql $Sql)
    if ($value -lt $MinExpected) {
        throw "Validacion fallida: $Label = $value (minimo esperado: $MinExpected)"
    }
    Write-Host ("      OK {0}: {1} (min {2})" -f $Label, $value, $MinExpected)
}

function Show-Diagnostics {
    Write-Host ""
    Write-Host "[DIAG] Estado del contenedor:"
    try {
        docker ps --filter "name=$ContainerName" --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
    } catch {}

    Write-Host ""
    Write-Host "[DIAG] Ultimos logs del contenedor:"
    try {
        docker logs --tail 200 $ContainerName
    } catch {}

    Write-Host ""
    Write-Host "[DIAG] Tablas en schema public:"
    try {
        docker exec $ContainerName psql -U $DbUser -d $DbName -P pager=off -c "\dt public.*"
    } catch {}
}

try {
    Assert-RequiredFile -Path $DdlPath
    Assert-RequiredFile -Path $MigrationApplyPath
    Assert-RequiredFile -Path $SeedCanonicoPath
    Assert-RequiredFile -Path $SeedVolPath
    Assert-RequiredFile -Path $SeedValidPath
    Assert-RequiredFile -Path $SecretsValidationPath
    Assert-RequiredFile -Path $SecurityHardeningPath
    Assert-RequiredFile -Path $BootstrapAdminConfinementPath
    Assert-RequiredFile -Path $OperationalLoginsProvisionPath
    Assert-RequiredFile -Path $DelegatedUsersProvisionPath
    Assert-RequiredFile -Path $OperationalLoginsValidationPath
    Assert-RequiredFile -Path $LeastPrivilegeValidationPath
    Assert-RequiredFile -Path $BootstrapAdminValidationPath
    Assert-RequiredFile -Path $SecurityAuditPath

    Write-Host ""
    Write-Host "[1/9] Validando secretos locales..."
    & $SecretsValidationPath | Out-Null
    if (-not $?) {
        throw "La validacion de secretos locales fallo. Ejecuta .\infra\tools\inicializar_secretos_locales.ps1"
    }

    $envMap = Get-EnvMap -Path $EnvPath
    if ($envMap.Contains("POSTGRES_BIND_IP") -and (-not [string]::IsNullOrWhiteSpace([string]$envMap["POSTGRES_BIND_IP"]))) {
        $HostBindIp = [string]$envMap["POSTGRES_BIND_IP"]
    }
    if ($envMap.Contains("POSTGRES_PORT") -and (-not [string]::IsNullOrWhiteSpace([string]$envMap["POSTGRES_PORT"]))) {
        $HostPort = [string]$envMap["POSTGRES_PORT"]
    }
    if ($envMap.Contains("FLY_APP_RW_USER") -and (-not [string]::IsNullOrWhiteSpace([string]$envMap["FLY_APP_RW_USER"]))) {
        $RuntimeLogin = [string]$envMap["FLY_APP_RW_USER"]
    }
    if ($envMap.Contains("FLY_APP_RO_USER") -and (-not [string]::IsNullOrWhiteSpace([string]$envMap["FLY_APP_RO_USER"]))) {
        $ReadOnlyLogin = [string]$envMap["FLY_APP_RO_USER"]
    }
    if ($envMap.Contains("FLY_APP_AUDIT_USER") -and (-not [string]::IsNullOrWhiteSpace([string]$envMap["FLY_APP_AUDIT_USER"]))) {
        $AuditLogin = [string]$envMap["FLY_APP_AUDIT_USER"]
    }

    docker compose config -q
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose config reporto errores."
    }

    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Recreacion de instalacion limpia"
    Write-Host "======================================================"
    Write-Host ""

    Write-Host "[2/9] Deteniendo y eliminando contenedor y volumen..."
    docker compose down -v --remove-orphans
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose down -v fallo."
    }
    Write-Host "      Contenedor y volumen eliminados."

    Write-Host ""
    Write-Host "[3/9] Levantando contenedor PostgreSQL 16..."
    docker compose up -d
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose up -d fallo."
    }
    Write-Host "      Contenedor iniciado. Esperando estado healthy..."

    $maxWait = 180
    $waited = 0
    $healthy = $false
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 5
        $waited += 5
        $status = docker inspect --format "{{.State.Health.Status}}" $ContainerName 2>$null
        Write-Host "      $waited seg - estado: $status"
        if ($status -eq "healthy") {
            $healthy = $true
            break
        }
    }

    if (-not $healthy) {
        throw "El contenedor no alcanzo estado 'healthy' en $maxWait segundos."
    }

    Write-Host ""
    Write-Host "[4/9] Cargando DDL base congelado..."
    Invoke-PsqlFile -LocalPath $DdlPath          -RemotePath "/tmp/01_modelo_postgresql.sql"        -Label "DDL maestro"
    Write-Host "      DDL base cargado."

    Write-Host ""
    Write-Host "[5/9] Aplicando migraciones versionadas sobre baseline..."
    & $MigrationApplyPath `
        -ContainerName $ContainerName `
        -DbUser $DbUser `
        -DbName $DbName | Out-Null
    if (-not $?) {
        throw "Fallo la aplicacion de migraciones versionadas."
    }
    Assert-RelationExists -Label "schema_migration_journal" -Relation "public.schema_migration_journal"
    Assert-RelationExists -Label "schema_migration_lock"    -Relation "public.schema_migration_lock"
    Assert-MinCount -Label "schema_migration_journal_rows" -Sql "SELECT count(*) FROM public.schema_migration_journal;" -MinExpected 1
    Write-Host "      Baseline limpio alineado con journal de migraciones."

    Write-Host ""
    Write-Host "[6/9] Cargando seeds y validaciones post-seed..."
    Invoke-PsqlFile -LocalPath $SeedCanonicoPath -RemotePath "/tmp/02_seed_canonico.sql"            -Label "Seed canonico"
    Invoke-PsqlFile -LocalPath $SeedVolPath      -RemotePath "/tmp/03_seed_volumetrico.sql"         -Label "Seed volumetrico"
    Invoke-PsqlFile -LocalPath $SeedValidPath    -RemotePath "/tmp/04_validaciones_post_seed.sql"   -Label "Validaciones post-seed"
    Write-Host "      Carga completada."

    Write-Host ""
    Write-Host "[7/9] Verificando integridad de datos post-seed..."
    Write-Host "      -> Seed canonico"
    $queryCanon = @"
SELECT
  (SELECT count(*) FROM public.country)              AS paises,
  (SELECT count(*) FROM public.airline)              AS aerolineas,
  (SELECT count(*) FROM public.airport)              AS aeropuertos,
  (SELECT count(*) FROM public.aircraft)             AS aeronaves,
  (SELECT count(*) FROM public.flight)               AS vuelos,
  (SELECT count(*) FROM public.person)               AS personas,
  (SELECT count(*) FROM public.customer)             AS clientes,
  (SELECT count(*) FROM public.reservation)          AS reservas,
  (SELECT count(*) FROM public.ticket)               AS tiquetes,
  (SELECT count(*) FROM public.payment)              AS pagos,
  (SELECT count(*) FROM public.invoice)              AS facturas,
  (SELECT count(*) FROM public.miles_transaction)    AS millas;
"@

    docker exec $ContainerName psql `
      -U $DbUser -d $DbName `
      -P pager=off `
      -c $queryCanon
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo verificacion de integridad del seed canonico."
    }

    Write-Host ""
    Write-Host "      -> Seed volumetrico"
    $queryVol = @"
SELECT
  (SELECT count(*) FROM public.flight  WHERE flight_number IN ('FY120','FY220','FY712'))
    AS vuelos_q2_2026,
  (SELECT count(*) FROM public.person  WHERE person_id::text LIKE '90000000%')
    AS personas_vol,
  (SELECT count(*) FROM public.customer WHERE customer_id::text LIKE '93000000%')
    AS clientes_vol,
  (SELECT count(*) FROM public.reservation WHERE reservation_code LIKE 'RES-VOL%')
    AS reservas_vol,
  (SELECT count(*) FROM public.ticket WHERE ticket_number LIKE 'TKT-VOL%')
    AS tickets_vol,
  (SELECT count(*) FROM public.ticket_segment ts
     JOIN public.ticket t ON t.ticket_id = ts.ticket_id
   WHERE t.ticket_number LIKE 'TKT-VOL%')
    AS ticket_segments_vol,
  (SELECT count(*) FROM public.seat_assignment sa
     JOIN public.ticket_segment ts ON ts.ticket_segment_id = sa.ticket_segment_id
     JOIN public.ticket t ON t.ticket_id = ts.ticket_id
   WHERE t.ticket_number LIKE 'TKT-VOL2-%')
    AS seat_assignments_vol2,
  (SELECT count(*) FROM public.baggage
   WHERE baggage_tag LIKE 'BAG-VOL2-%')
    AS baggage_vol2,
  (SELECT count(*) FROM public.check_in ci
     JOIN public.ticket_segment ts ON ts.ticket_segment_id = ci.ticket_segment_id
     JOIN public.ticket t ON t.ticket_id = ts.ticket_id
   WHERE t.ticket_number LIKE 'TKT-VOL2-%')
    AS checkins_vol2,
  (SELECT count(*) FROM public.boarding_pass
   WHERE boarding_pass_code LIKE 'BP-VOL2-%')
    AS boarding_passes_vol2,
  (SELECT count(*) FROM public.boarding_validation bv
     JOIN public.boarding_pass bp ON bp.boarding_pass_id = bv.boarding_pass_id
   WHERE bp.boarding_pass_code LIKE 'BP-VOL2-%')
    AS boarding_validations_vol2,
  (SELECT count(*) FROM public.payment WHERE payment_reference LIKE 'PAY-VOL%')
    AS pagos_vol,
  (SELECT count(*) FROM public.payment_transaction
   WHERE transaction_reference LIKE 'TXN-VOL2-%')
    AS payment_tx_vol2,
  (SELECT count(*) FROM public.invoice  WHERE invoice_number LIKE 'INV-VOL%')
    AS facturas_vol,
  (SELECT count(*) FROM public.refund WHERE refund_reference LIKE 'RFD-VOL2-%')
    AS refunds_vol2;
"@

    docker exec $ContainerName psql `
      -U $DbUser -d $DbName `
      -P pager=off `
      -c $queryVol
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo verificacion del seed volumetrico."
    }

    Write-Host ""
    Write-Host "      -> Minimos obligatorios"
    Assert-PositiveCount -Label "country"        -Sql "SELECT count(*) FROM public.country;"
    Assert-PositiveCount -Label "airline"        -Sql "SELECT count(*) FROM public.airline;"
    Assert-PositiveCount -Label "airport"        -Sql "SELECT count(*) FROM public.airport;"
    Assert-PositiveCount -Label "aircraft"       -Sql "SELECT count(*) FROM public.aircraft;"
    Assert-PositiveCount -Label "flight"         -Sql "SELECT count(*) FROM public.flight;"
    Assert-PositiveCount -Label "person"         -Sql "SELECT count(*) FROM public.person;"
    Assert-PositiveCount -Label "customer"       -Sql "SELECT count(*) FROM public.customer;"
    Assert-PositiveCount -Label "reservation"    -Sql "SELECT count(*) FROM public.reservation;"
    Assert-PositiveCount -Label "ticket"         -Sql "SELECT count(*) FROM public.ticket;"
    Assert-PositiveCount -Label "payment"        -Sql "SELECT count(*) FROM public.payment;"
    Assert-PositiveCount -Label "invoice"        -Sql "SELECT count(*) FROM public.invoice;"
    Assert-PositiveCount -Label "miles_tx"       -Sql "SELECT count(*) FROM public.miles_transaction;"
    Assert-MinCount -Label "vuelos_q2_2026"       -Sql "SELECT count(*) FROM public.flight WHERE flight_number IN ('FY120','FY220','FY712');" -MinExpected 117
    Assert-MinCount -Label "personas_vol"         -Sql "SELECT count(*) FROM public.person WHERE person_id::text LIKE '90000000%';" -MinExpected 300
    Assert-MinCount -Label "clientes_vol"         -Sql "SELECT count(*) FROM public.customer WHERE customer_id::text LIKE '93000000%';" -MinExpected 250
    Assert-MinCount -Label "reservas_vol"         -Sql "SELECT count(*) FROM public.reservation WHERE reservation_code LIKE 'RES-VOL%';" -MinExpected 1000
    Assert-MinCount -Label "tickets_vol"          -Sql "SELECT count(*) FROM public.ticket WHERE ticket_number LIKE 'TKT-VOL%';" -MinExpected 1000
    Assert-MinCount -Label "ticket_segments_vol"  -Sql "SELECT count(*) FROM public.ticket_segment ts JOIN public.ticket t ON t.ticket_id = ts.ticket_id WHERE t.ticket_number LIKE 'TKT-VOL%';" -MinExpected 1000
    Assert-MinCount -Label "seat_assignments_vol" -Sql "SELECT count(*) FROM public.seat_assignment sa JOIN public.ticket_segment ts ON ts.ticket_segment_id = sa.ticket_segment_id JOIN public.ticket t ON t.ticket_id = ts.ticket_id WHERE t.ticket_number LIKE 'TKT-VOL2-%';" -MinExpected 1000
    Assert-MinCount -Label "baggage_vol2"         -Sql "SELECT count(*) FROM public.baggage WHERE baggage_tag LIKE 'BAG-VOL2-%';" -MinExpected 1000
    Assert-MinCount -Label "checkins_vol2"        -Sql "SELECT count(*) FROM public.check_in ci JOIN public.ticket_segment ts ON ts.ticket_segment_id = ci.ticket_segment_id JOIN public.ticket t ON t.ticket_id = ts.ticket_id WHERE t.ticket_number LIKE 'TKT-VOL2-%';" -MinExpected 1000
    Assert-MinCount -Label "boarding_passes_vol2" -Sql "SELECT count(*) FROM public.boarding_pass WHERE boarding_pass_code LIKE 'BP-VOL2-%';" -MinExpected 1000
    Assert-MinCount -Label "boarding_valid_vol2"  -Sql "SELECT count(*) FROM public.boarding_validation bv JOIN public.boarding_pass bp ON bp.boarding_pass_id = bv.boarding_pass_id WHERE bp.boarding_pass_code LIKE 'BP-VOL2-%';" -MinExpected 1000
    Assert-MinCount -Label "pagos_vol"            -Sql "SELECT count(*) FROM public.payment WHERE payment_reference LIKE 'PAY-VOL%';" -MinExpected 1000
    Assert-MinCount -Label "payment_tx_vol2"      -Sql "SELECT count(*) FROM public.payment_transaction WHERE transaction_reference LIKE 'TXN-VOL2-%';" -MinExpected 1300
    Assert-MinCount -Label "facturas_vol"         -Sql "SELECT count(*) FROM public.invoice WHERE invoice_number LIKE 'INV-VOL%';" -MinExpected 1000
    Assert-MinCount -Label "refunds_vol2"         -Sql "SELECT count(*) FROM public.refund WHERE refund_reference LIKE 'RFD-VOL2-%';" -MinExpected 100

    Write-Host ""
    Write-Host "[8/9] Aplicando baseline local de seguridad..."
    & $SecurityHardeningPath -ContainerName $ContainerName -DbUser $DbUser -DbName $DbName
    if (-not $?) {
        throw "Fallo al aplicar hardening de seguridad local."
    }

    & $OperationalLoginsProvisionPath `
        -ContainerName $ContainerName `
        -DbAdminUser $DbUser `
        -DbName $DbName
    if (-not $?) {
        throw "Fallo al provisionar logins operativos locales."
    }

    if (Test-Path -LiteralPath $DelegatedUsersCsvPath) {
        & $DelegatedUsersProvisionPath `
            -ContainerName $ContainerName `
            -DbAdminUser $DbUser `
            -DbName $DbName `
            -UsersCsvPath $DelegatedUsersCsvPath | Out-Null
        if (-not $?) {
            throw "Fallo al provisionar usuarios delegados locales."
        }
        Write-Host ("      Usuarios delegados cargados desde: {0}" -f $DelegatedUsersCsvPath)
    }
    else {
        Write-Host ("      No se detecto archivo de usuarios delegados: {0}" -f $DelegatedUsersCsvPath)
    }

    & $BootstrapAdminConfinementPath `
        -ContainerName $ContainerName `
        -DbUser $DbUser `
        -DbName $DbName
    if (-not $?) {
        throw "Fallo al confinar admin bootstrap local."
    }

    & $OperationalLoginsValidationPath `
        -ContainerName $ContainerName `
        -DbAdminUser $DbUser `
        -DbName $DbName `
        -EvidencePath $OperationalLoginsEvidencePath | Out-Null
    if (-not $?) {
        throw "Fallo la validacion de logins operativos locales."
    }

    & $LeastPrivilegeValidationPath `
        -ContainerName $ContainerName `
        -DbName $DbName `
        -EvidencePath $LeastPrivilegeEvidencePath | Out-Null
    if (-not $?) {
        throw "Fallo la validacion de menor privilegio operativo local."
    }

    & $BootstrapAdminValidationPath `
        -ContainerName $ContainerName `
        -DbAdminUser $DbUser `
        -DbName $DbName `
        -EvidencePath $BootstrapAdminEvidencePath | Out-Null
    if (-not $?) {
        throw "Fallo la validacion del admin bootstrap local."
    }

    & $SecurityAuditPath `
        -ContainerName $ContainerName `
        -DbUser $DbUser `
        -DbName $DbName `
        -EvidencePath $SecurityAuditEvidencePath | Out-Null
    if (-not $?) {
        throw "Fallo la auditoria de seguridad local."
    }

    Write-Host "      Baseline de seguridad, logins operativos, admin bootstrap confinado, menor privilegio y auditoria aplicados."

    Write-Host ""
    Write-Host "[9/9] Estado del contenedor:"
    docker ps --filter "name=$ContainerName" --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"

    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  Instalacion completada con baseline DDL+migraciones, datos, seguridad y logins operativos verificados."
    Write-Host "  Conexion admin break-glass: docker exec -it $ContainerName psql -U $DbUser -d $DbName"
    Write-Host "  Password admin: usa POSTGRES_PASSWORD desde infra/docker/.env o variable local."
    Write-Host "  Nota: el admin bootstrap queda bloqueado por TCP y solo disponible por socket interno."
    Write-Host "  Si ves 'pg_hba.conf rejects connection ... user `"$DbUser`"' desde el host, el rechazo es esperado."
    Write-Host "  Conexion host RO: psql -h $HostBindIp -p $HostPort -U $ReadOnlyLogin -d $DbName"
    Write-Host "  Conexion host RW: psql -h $HostBindIp -p $HostPort -U $RuntimeLogin -d $DbName"
    Write-Host "  Conexion host AUDIT: psql -h $HostBindIp -p $HostPort -U $AuditLogin -d $DbName"
    Write-Host "  Passwords operativos: usa FLY_APP_RO_PASSWORD / FLY_APP_RW_PASSWORD / FLY_APP_AUDIT_PASSWORD desde infra/docker/.env."
    Write-Host "  Archivo local usuarios delegados: $DelegatedUsersCsvPath"
    Write-Host "  Evidencia admin bootstrap: $BootstrapAdminEvidencePath"
    Write-Host "  Evidencia menor privilegio: $LeastPrivilegeEvidencePath"
    Write-Host "  Evidencia seguridad: $SecurityAuditEvidencePath"
    Write-Host "  Evidencia logins operativos: $OperationalLoginsEvidencePath"
    Write-Host "======================================================"
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    Show-Diagnostics
    exit 1
}
