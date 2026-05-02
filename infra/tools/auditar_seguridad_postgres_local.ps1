param(
    [string]$EvidencePath,
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$DbUser,
    [string]$DbName,
    [string]$RuntimeRole = "fly_app_rw",
    [string]$ReadOnlyRole = "fly_app_ro",
    [string]$AuditRole = "fly_app_audit"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$ComposePath = Join-Path $RepoRoot "infra\docker\docker-compose.yml"
$EnvExamplePath = Join-Path $RepoRoot "infra\docker\.env.example"
$LocalEnvPath = Join-Path $RepoRoot "infra\docker\.env"

if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
    $EvidencePath = Join-Path $RepoRoot "docs\validacion\EVIDENCIA_AUDITORIA_SEGURIDAD_LOCAL_2026-03-20.md"
}

if ([string]::IsNullOrWhiteSpace($DbUser)) {
    $DbUser = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_USER)) { "fly_admin" } else { $env:POSTGRES_USER }
}

if ([string]::IsNullOrWhiteSpace($DbName)) {
    $DbName = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_DB)) { "flydb" } else { $env:POSTGRES_DB }
}

function Invoke-PsqlScalar {
    param(
        [string]$Database,
        [string]$Sql
    )
    $raw = docker exec $ContainerName psql -t -A -U $DbUser -d $Database -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo consulta escalar de auditoria de seguridad."
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
        throw "Fallo consulta tabular de auditoria de seguridad."
    }
    return ,@($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
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

function Get-EnvMap {
    param([string]$Path)

    $map = [ordered]@{}
    if (-not (Test-Path -LiteralPath $Path)) {
        return $map
    }

    foreach ($line in Get-Content -Path $Path) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) {
            continue
        }

        $separator = $trimmed.IndexOf("=")
        if ($separator -lt 1) {
            continue
        }

        $key = $trimmed.Substring(0, $separator).Trim()
        $value = $trimmed.Substring($separator + 1)
        $map[$key] = $value
    }

    return $map
}

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Auditoria Seguridad PostgreSQL Local"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base: {0}" -f $DbName)
    Write-Host ("  Evidencia: {0}" -f $EvidencePath)
    Write-Host ""

    $publicTables = [int](Invoke-PsqlScalar -Database $DbName -Sql "SELECT count(*) FROM pg_tables WHERE schemaname = 'public';")
    $superuserLogins = [int](Invoke-PsqlScalar -Database "postgres" -Sql "SELECT count(*) FROM pg_roles WHERE rolcanlogin AND rolsuper;")
    $rolePresence = [int](Invoke-PsqlScalar -Database "postgres" -Sql "SELECT count(*) FROM pg_roles WHERE rolname IN ('$RuntimeRole', '$ReadOnlyRole', '$AuditRole');")
    $publicDbConnect = Invoke-PsqlScalar -Database "postgres" -Sql @"
SELECT EXISTS (
  SELECT 1
  FROM pg_database d,
       LATERAL aclexplode(COALESCE(d.datacl, acldefault('d', d.datdba))) acl
  WHERE d.datname = '$DbName'
    AND acl.grantee = 0
    AND acl.privilege_type = 'CONNECT'
);
"@
    $publicSchemaUsage = Invoke-PsqlScalar -Database $DbName -Sql @"
SELECT EXISTS (
  SELECT 1
  FROM pg_namespace n,
       LATERAL aclexplode(COALESCE(n.nspacl, acldefault('n', n.nspowner))) acl
  WHERE n.nspname = 'public'
    AND acl.grantee = 0
    AND acl.privilege_type = 'USAGE'
);
"@
    $publicSchemaCreate = Invoke-PsqlScalar -Database $DbName -Sql @"
SELECT EXISTS (
  SELECT 1
  FROM pg_namespace n,
       LATERAL aclexplode(COALESCE(n.nspacl, acldefault('n', n.nspowner))) acl
  WHERE n.nspname = 'public'
    AND acl.grantee = 0
    AND acl.privilege_type = 'CREATE'
);
"@

    $runtimeSelect = [int](Invoke-PsqlScalar -Database $DbName -Sql "SELECT count(*) FROM information_schema.role_table_grants WHERE table_schema = 'public' AND grantee = '$RuntimeRole' AND privilege_type = 'SELECT';")
    $runtimeInsert = [int](Invoke-PsqlScalar -Database $DbName -Sql "SELECT count(*) FROM information_schema.role_table_grants WHERE table_schema = 'public' AND grantee = '$RuntimeRole' AND privilege_type = 'INSERT';")
    $runtimeUpdate = [int](Invoke-PsqlScalar -Database $DbName -Sql "SELECT count(*) FROM information_schema.role_table_grants WHERE table_schema = 'public' AND grantee = '$RuntimeRole' AND privilege_type = 'UPDATE';")
    $runtimeDelete = [int](Invoke-PsqlScalar -Database $DbName -Sql "SELECT count(*) FROM information_schema.role_table_grants WHERE table_schema = 'public' AND grantee = '$RuntimeRole' AND privilege_type = 'DELETE';")
    $readonlySelect = [int](Invoke-PsqlScalar -Database $DbName -Sql "SELECT count(*) FROM information_schema.role_table_grants WHERE table_schema = 'public' AND grantee = '$ReadOnlyRole' AND privilege_type = 'SELECT';")
    $auditSelect = [int](Invoke-PsqlScalar -Database $DbName -Sql "SELECT count(*) FROM information_schema.role_table_grants WHERE table_schema = 'public' AND grantee = '$AuditRole' AND privilege_type = 'SELECT';")
    $auditHasPgReadStats = if ($rolePresence -ge 3) {
        Invoke-PsqlScalar -Database "postgres" -Sql "SELECT pg_has_role('$AuditRole', 'pg_read_all_stats', 'member');"
    } else {
        "f"
    }
    $superuserLoginRows = Invoke-PsqlRows -Database "postgres" -Sql "SELECT rolname FROM pg_roles WHERE rolcanlogin AND rolsuper ORDER BY rolname;"
    $superuserLoginNames = @(
        $superuserLoginRows |
            ForEach-Object { $_.Split("|")[0].Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    $bootstrapAdminRetained = @($superuserLoginNames) -contains $DbUser
    $unexpectedSuperuserLoginNames = @($superuserLoginNames | Where-Object { $_ -ne $DbUser })
    $unexpectedSuperuserCount = $unexpectedSuperuserLoginNames.Count
    $hbaFile = Invoke-PsqlScalar -Database $DbName -Sql "SHOW hba_file;"
    $hbaContent = docker exec $ContainerName cat $hbaFile
    if ($LASTEXITCODE -ne 0) {
        throw "No fue posible leer pg_hba.conf desde el contenedor."
    }
    $hbaJoined = ($hbaContent -join "`n")
    $bootstrapAdminRejectIpv4 = $hbaJoined -match "(?m)^\s*host\s+all\s+$([regex]::Escape($DbUser))\s+0\.0\.0\.0/0\s+reject\s*$"
    $bootstrapAdminRejectIpv6 = $hbaJoined -match "(?m)^\s*host\s+all\s+$([regex]::Escape($DbUser))\s+::/0\s+reject\s*$"

    $composeContent = if (Test-Path -LiteralPath $ComposePath) { Get-Content -Path $ComposePath -Raw } else { "" }
    $envExampleContent = if (Test-Path -LiteralPath $EnvExamplePath) { Get-Content -Path $EnvExamplePath -Raw } else { "" }
    $localEnvExists = Test-Path -LiteralPath $LocalEnvPath
    $localEnvMap = Get-EnvMap -Path $LocalEnvPath
    $legacyWeakPasswordPresent = ($composeContent -match 'fly_admin_123') -or ($envExampleContent -match 'fly_admin_123')
    $placeholderPasswordPresent = ($composeContent -match 'local_change_me_before_shared_use') -or ($envExampleContent -match 'local_change_me_before_shared_use')
    $composeSupportsLoopbackBind = $composeContent -match '\$\{POSTGRES_BIND_IP:-127\.0\.0\.1\}:\$\{POSTGRES_PORT:-5435\}:5432'
    $effectiveBindIp = if ($localEnvMap.Contains("POSTGRES_BIND_IP") -and (-not [string]::IsNullOrWhiteSpace([string]$localEnvMap["POSTGRES_BIND_IP"]))) { [string]$localEnvMap["POSTGRES_BIND_IP"] } else { "127.0.0.1" }
    $effectivePort = if ($localEnvMap.Contains("POSTGRES_PORT") -and (-not [string]::IsNullOrWhiteSpace([string]$localEnvMap["POSTGRES_PORT"]))) { [string]$localEnvMap["POSTGRES_PORT"] } else { "5435" }
    $portBoundToLoopback = @("127.0.0.1") -contains $effectiveBindIp

    $controls = @(
        [pscustomobject]@{
            control = "public_connect_revoked"
            observed = $publicDbConnect
            expected = "false"
            status = $(if ($publicDbConnect -eq "f") { "OK" } else { "FALLA" })
            note = "PUBLIC no debe conservar CONNECT sobre la base"
        }
        [pscustomobject]@{
            control = "public_schema_create_revoked"
            observed = $publicSchemaCreate
            expected = "false"
            status = $(if ($publicSchemaCreate -eq "f") { "OK" } else { "FALLA" })
            note = "PUBLIC no debe poder crear en schema public"
        }
        [pscustomobject]@{
            control = "public_schema_usage_revoked"
            observed = $publicSchemaUsage
            expected = "false"
            status = $(if ($publicSchemaUsage -eq "f") { "OK" } else { "FALLA" })
            note = "PUBLIC no debe conservar USAGE abierto en schema public"
        }
        [pscustomobject]@{
            control = "least_privilege_roles_present"
            observed = $rolePresence
            expected = "3"
            status = $(if ($rolePresence -eq 3) { "OK" } else { "FALLA" })
            note = "Roles base de runtime, readonly y audit deben existir"
        }
        [pscustomobject]@{
            control = "runtime_rw_grants_complete"
            observed = "$runtimeSelect/$runtimeInsert/$runtimeUpdate/$runtimeDelete"
            expected = "$publicTables/$publicTables/$publicTables/$publicTables"
            status = $(if (($runtimeSelect -eq $publicTables) -and ($runtimeInsert -eq $publicTables) -and ($runtimeUpdate -eq $publicTables) -and ($runtimeDelete -eq $publicTables)) { "OK" } else { "FALLA" })
            note = "Runtime debe tener DML completo sobre tablas public"
        }
        [pscustomobject]@{
            control = "readonly_select_grants_complete"
            observed = $readonlySelect
            expected = $publicTables
            status = $(if ($readonlySelect -eq $publicTables) { "OK" } else { "FALLA" })
            note = "Readonly debe tener SELECT sobre todas las tablas public"
        }
        [pscustomobject]@{
            control = "audit_select_grants_complete"
            observed = $auditSelect
            expected = $publicTables
            status = $(if ($auditSelect -eq $publicTables) { "OK" } else { "FALLA" })
            note = "Audit debe tener SELECT sobre todas las tablas public"
        }
        [pscustomobject]@{
            control = "audit_role_has_pg_read_all_stats"
            observed = $auditHasPgReadStats
            expected = "true"
            status = $(if ($auditHasPgReadStats -eq "t") { "OK" } else { "FALLA" })
            note = "Audit debe poder leer estadisticas globales"
        }
        [pscustomobject]@{
            control = "bootstrap_admin_superuser_retained"
            observed = $bootstrapAdminRetained
            expected = "true"
            status = $(if ($bootstrapAdminRetained) { "OK" } else { "FALLA" })
            note = "El bootstrap admin debe permanecer superuser por restriccion del motor"
        }
        [pscustomobject]@{
            control = "bootstrap_admin_tcp_reject_ipv4_present"
            observed = $bootstrapAdminRejectIpv4
            expected = "true"
            status = $(if ($bootstrapAdminRejectIpv4) { "OK" } else { "FALLA" })
            note = "Debe existir regla reject IPv4 para el bootstrap admin"
        }
        [pscustomobject]@{
            control = "bootstrap_admin_tcp_reject_ipv6_present"
            observed = $bootstrapAdminRejectIpv6
            expected = "true"
            status = $(if ($bootstrapAdminRejectIpv6) { "OK" } else { "FALLA" })
            note = "Debe existir regla reject IPv6 para el bootstrap admin"
        }
        [pscustomobject]@{
            control = "unexpected_superuser_login_count"
            observed = $unexpectedSuperuserCount
            expected = "0"
            status = $(if ($unexpectedSuperuserCount -eq 0) { "OK" } else { "FALLA" })
            note = "No deben existir logins superuser adicionales al bootstrap admin"
        }
        [pscustomobject]@{
            control = "repo_weak_password_literal_removed"
            observed = $legacyWeakPasswordPresent
            expected = "false"
            status = $(if (-not $legacyWeakPasswordPresent) { "OK" } else { "RIESGO" })
            note = "No debe permanecer la clave literal legacy en archivos versionados"
        }
        [pscustomobject]@{
            control = "local_env_secret_present"
            observed = $localEnvExists
            expected = "true recomendado"
            status = $(if ($localEnvExists) { "OK" } else { "RIESGO" })
            note = "Se recomienda definir POSTGRES_PASSWORD en infra/docker/.env"
        }
        [pscustomobject]@{
            control = "compose_password_placeholder_present"
            observed = $placeholderPasswordPresent
            expected = "true"
            status = $(if ($placeholderPasswordPresent) { "OK" } else { "RIESGO" })
            note = "El repo debe sugerir placeholder y no una clave operativa real"
        }
        [pscustomobject]@{
            control = "compose_supports_loopback_bind"
            observed = $composeSupportsLoopbackBind
            expected = "true"
            status = $(if ($composeSupportsLoopbackBind) { "OK" } else { "FALLA" })
            note = "docker-compose debe soportar bind local a loopback por defecto"
        }
        [pscustomobject]@{
            control = "host_port_bound_to_loopback"
            observed = "$effectiveBindIp`:$effectivePort"
            expected = "127.0.0.1:<puerto>"
            status = $(if ($portBoundToLoopback) { "OK" } else { "RIESGO" })
            note = "El puerto publicado debe quedar confinado a loopback local"
        }
    )

    $failedControls = @($controls | Where-Object { $_.status -eq "FALLA" })
    $riskControls = @($controls | Where-Object { $_.status -eq "RIESGO" })

    $roleRowsRaw = Invoke-PsqlRows -Database "postgres" -Sql "SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin FROM pg_roles WHERE rolname IN ('$DbUser', '$RuntimeRole', '$ReadOnlyRole', '$AuditRole') ORDER BY rolname;"
    $roleRows = foreach ($row in $roleRowsRaw) {
        $parts = $row.Split("|")
        [pscustomobject]@{
            role_name = $parts[0]
            superuser = $parts[1]
            create_role = $parts[2]
            create_db = $parts[3]
            can_login = $parts[4]
        }
    }

    $summaryRows = @(
        [pscustomobject]@{ metric = "public_tables"; value = $publicTables }
        [pscustomobject]@{ metric = "hard_fail_controls"; value = $failedControls.Count }
        [pscustomobject]@{ metric = "risk_controls"; value = $riskControls.Count }
        [pscustomobject]@{ metric = "superuser_login_roles"; value = $superuserLogins }
        [pscustomobject]@{ metric = "unexpected_superuser_logins"; value = $(if ($unexpectedSuperuserCount -eq 0) { "none" } else { $unexpectedSuperuserLoginNames -join "," }) }
        [pscustomobject]@{ metric = "local_env_exists"; value = $localEnvExists }
        [pscustomobject]@{ metric = "effective_bind_scope"; value = "$effectiveBindIp`:$effectivePort" }
        [pscustomobject]@{ metric = "bootstrap_admin_hba_file"; value = $hbaFile }
    )

    $summaryTable = New-MarkdownTable -Rows $summaryRows -Headers @("metric", "value")
    $controlsTable = New-MarkdownTable -Rows $controls -Headers @("control", "observed", "expected", "status", "note")
    $rolesTable = New-MarkdownTable -Rows $roleRows -Headers @("role_name", "superuser", "create_role", "create_db", "can_login")

    $evidenceDir = Split-Path -Parent $EvidencePath
    $null = New-Item -ItemType Directory -Force -Path $evidenceDir

    $content = @"
# Evidencia de Auditoria de Seguridad Local (2026-03-20)

## Objetivo

Auditar el estado de privilegios, roles, secretos locales y superficie de
exposicion del PostgreSQL de desarrollo despues del endurecimiento progresivo
completado hasta S4.6.

## Contexto de ejecucion

- Fecha de ejecucion: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
- Contenedor: $ContainerName
- Base auditada: $DbName
- Role admin actual: $DbUser
- Roles de minimo privilegio esperados: $RuntimeRole, $ReadOnlyRole, $AuditRole
- Archivo HBA auditado: $hbaFile

## Resumen observado

$summaryTable

## Roles relevantes

$rolesTable

## Controles de seguridad

$controlsTable

## Resultado

- Estado general: $(if ($failedControls.Count -eq 0) { "AUDITORIA SIN FALLAS BLOQUEANTES" } else { "AUDITORIA CON FALLAS" })
- Fallas bloqueantes: $($failedControls.Count)
- Riesgos controlados: $($riskControls.Count)
- Bootstrap admin aislado por TCP: $(if ($bootstrapAdminRejectIpv4 -and $bootstrapAdminRejectIpv6) { "SI" } else { "NO" })
"@

    Set-Content -Path $EvidencePath -Value $content -Encoding UTF8

    Write-Host ("[OK] Evidencia escrita en: {0}" -f $EvidencePath)

    if ($failedControls.Count -gt 0) {
        throw ("La auditoria de seguridad detecto {0} fallas bloqueantes." -f $failedControls.Count)
    }

    Write-Output ([pscustomobject]@{
        evidence_path = $EvidencePath
        failed_controls = $failedControls.Count
        risk_controls = $riskControls.Count
    })
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
