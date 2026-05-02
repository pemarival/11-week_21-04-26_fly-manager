param(
    [string]$EnvPath,
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$DbAdminUser,
    [string]$DbName,
    [string[]]$LoginNames,
    [string[]]$Passwords,
    [string[]]$DelegatedRoles = @("fly_app_ddl", "fly_app_dml"),
    [string]$UsersCsvPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$SecretsValidationScript = Join-Path $ScriptDir "validar_secretos_locales.ps1"
$DefaultUsersCsvPath = Join-Path $RepoRoot "infra\runtime\security\delegated_users_local.csv"

if ([string]::IsNullOrWhiteSpace($EnvPath)) {
    $EnvPath = Join-Path $RepoRoot "infra\docker\.env"
}

if ([string]::IsNullOrWhiteSpace($DbAdminUser)) {
    $DbAdminUser = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_USER)) { "fly_admin" } else { $env:POSTGRES_USER }
}

if ([string]::IsNullOrWhiteSpace($DbName)) {
    $DbName = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_DB)) { "flydb" } else { $env:POSTGRES_DB }
}

if ([string]::IsNullOrWhiteSpace($UsersCsvPath)) {
    $UsersCsvPath = $DefaultUsersCsvPath
}

function Assert-SafeRoleName {
    param(
        [string]$Value,
        [string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or ($Value -notmatch '^[a-z][a-z0-9_]{2,62}$')) {
        throw "$Label invalido. Usa solo minusculas, numeros y underscore."
    }
}

function Assert-SafeLoginName {
    param(
        [string]$Value,
        [string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or ($Value -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]{0,62}$')) {
        throw "$Label invalido. Usa solo letras, numeros, punto, guion y underscore."
    }
}

function Escape-SqlLiteral {
    param([string]$Value)
    return $Value.Replace("'", "''")
}

function Quote-SqlIdentifier {
    param([string]$Value)
    return '"' + $Value.Replace('"', '""') + '"'
}

function Get-RowValue {
    param(
        [pscustomobject]$Row,
        [string[]]$CandidateNames
    )

    foreach ($name in $CandidateNames) {
        $property = $Row.PSObject.Properties[$name]
        if (($null -ne $property) -and (-not [string]::IsNullOrWhiteSpace([string]$property.Value))) {
            return [string]$property.Value
        }
    }

    return ""
}

function Resolve-DelegatedUsersFromCsv {
    param(
        [string]$Path,
        [string[]]$DefaultRoles
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Archivo de usuarios delegados no encontrado: $Path"
    }

    $rows = @(
        Import-Csv -Path $Path | Where-Object {
            $emailValue = Get-RowValue -Row $_ -CandidateNames @("correo_institucional", "email", "correo")
            $documentValue = Get-RowValue -Row $_ -CandidateNames @("identificacion", "documento", "document_id")
            (-not [string]::IsNullOrWhiteSpace($emailValue)) -or (-not [string]::IsNullOrWhiteSpace($documentValue))
        }
    )

    if ($rows.Count -eq 0) {
        throw "El archivo de usuarios delegados no contiene filas utilizables."
    }

    $resolved = @()
    for ($index = 0; $index -lt $rows.Count; $index++) {
        $row = [pscustomobject]$rows[$index]
        $lineNumber = $index + 2

        $email = (Get-RowValue -Row $row -CandidateNames @("correo_institucional", "email", "correo")).Trim()
        $documentId = (Get-RowValue -Row $row -CandidateNames @("identificacion", "documento", "document_id")).Trim()
        $explicitLogin = (Get-RowValue -Row $row -CandidateNames @("login_name", "usuario", "user")).Trim()
        $explicitPassword = (Get-RowValue -Row $row -CandidateNames @("password", "clave")).Trim()
        $rolesRaw = (Get-RowValue -Row $row -CandidateNames @("roles", "delegated_roles")).Trim()

        if ([string]::IsNullOrWhiteSpace($email)) {
            throw "Fila $lineNumber sin correo_institucional."
        }

        if ([string]::IsNullOrWhiteSpace($documentId)) {
            throw "Fila $lineNumber sin identificacion."
        }

        $loginName = if ([string]::IsNullOrWhiteSpace($explicitLogin)) {
            # Si tiene @, extraer la parte antes del @ en minusculas; si no, usar el valor completo TAL CUAL
            if ($email.IndexOf("@") -ge 1) {
                $email.Substring(0, $email.IndexOf("@")).Trim().ToLowerInvariant()
            }
            else {
                $email.Trim()
            }
        }
        else {
            $explicitLogin.Trim()
        }

        $password = if ([string]::IsNullOrWhiteSpace($explicitPassword)) {
            $documentId
        }
        else {
            $explicitPassword
        }

        $roles = if ([string]::IsNullOrWhiteSpace($rolesRaw)) {
            @($DefaultRoles)
        }
        else {
            @($rolesRaw -split '[,;|]' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        }

        if ($roles.Count -eq 0) {
            throw "Fila $lineNumber sin roles delegados utilizables."
        }

        $resolved += [pscustomobject]@{
            LoginName = $loginName
            Password = $password
            DelegatedRoles = @($roles)
            Email = $email
            DocumentId = $documentId
        }
    }

    return $resolved
}

function Invoke-PsqlFile {
    param(
        [string]$LocalPath,
        [string]$RemotePath
    )

    docker cp $LocalPath "${ContainerName}:$RemotePath" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo docker cp al transferir SQL de provision de usuarios delegados."
    }

    try {
        docker exec $ContainerName psql -v ON_ERROR_STOP=1 -U $DbAdminUser -d $DbName -f $RemotePath | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo psql al provisionar usuarios delegados."
        }
    }
    finally {
        docker exec $ContainerName rm -f $RemotePath | Out-Null
    }
}

function Invoke-PsqlScalar {
    param([string]$Sql)

    $raw = docker exec $ContainerName psql -t -A -U $DbAdminUser -d postgres -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo consulta escalar de validacion post-provision."
    }

    return $raw.Trim()
}

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Provision Usuarios Delegados Locales"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base: {0}" -f $DbName)
    Write-Host ""

    if (-not (Test-Path -LiteralPath $SecretsValidationScript)) {
        throw "Validador de secretos no encontrado: $SecretsValidationScript"
    }

    & $SecretsValidationScript -EnvPath $EnvPath | Out-Null
    if (-not $?) {
        throw "La validacion de secretos locales fallo antes de provisionar usuarios delegados."
    }

    $delegatedRoleArray = @($DelegatedRoles)
    if (($null -eq $DelegatedRoles) -or ($delegatedRoleArray.Count -eq 0)) {
        throw "Debes indicar al menos un rol delegado."
    }

    foreach ($roleName in $delegatedRoleArray) {
        Assert-SafeRoleName -Value $roleName -Label "DelegatedRole"
    }

    $provisioningEntries = @()
    $manualMode = ($null -ne $LoginNames) -and (@($LoginNames).Count -gt 0)
    if ($manualMode) {
        $loginArray = @($LoginNames)
        $passwordArray = @($Passwords)

        if (($null -eq $Passwords) -or ($passwordArray.Count -eq 0)) {
            throw "Debes indicar al menos un Passwords."
        }
        if ($loginArray.Count -ne $passwordArray.Count) {
            throw "La cantidad de LoginNames debe coincidir con la cantidad de Passwords."
        }

        for ($index = 0; $index -lt $loginArray.Count; $index++) {
            $provisioningEntries += [pscustomobject]@{
                LoginName = [string]$loginArray[$index]
                Password = [string]$passwordArray[$index]
                DelegatedRoles = @($delegatedRoleArray)
                Email = ""
                DocumentId = ""
            }
        }
    }
    else {
        $provisioningEntries = @(Resolve-DelegatedUsersFromCsv -Path $UsersCsvPath -DefaultRoles $delegatedRoleArray)
        Write-Host ("  Fuente CSV: {0}" -f $UsersCsvPath)
        Write-Host ("  Filas utiles detectadas: {0}" -f $provisioningEntries.Count)
    }

    $normalizedLogins = @()
    $roleUnion = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $provisioningEntries.Count; $index++) {
        $entry = [pscustomobject]$provisioningEntries[$index]
        $loginName = [string]$entry.LoginName
        $password = [string]$entry.Password
        $entryRoles = @($entry.DelegatedRoles)

        Assert-SafeLoginName -Value $loginName -Label ("LoginNames[{0}]" -f $index)
        if ([string]::IsNullOrWhiteSpace($password)) {
            throw ("Passwords[{0}] no puede estar vacio." -f $index)
        }
        if ($loginName -eq $DbAdminUser) {
            throw ("El login delegado {0} no puede reutilizar el usuario administrativo." -f $loginName)
        }
        if ($entryRoles.Count -eq 0) {
            throw ("DelegatedRoles[{0}] no puede estar vacio." -f $index)
        }

        foreach ($roleName in $entryRoles) {
            Assert-SafeRoleName -Value $roleName -Label ("DelegatedRoles[{0}]" -f $index)
            if (-not $roleUnion.Contains($roleName)) {
                $roleUnion.Add($roleName) | Out-Null
            }
        }

        $normalizedLogins += $loginName
    }

    if ((@($normalizedLogins | Sort-Object -Unique).Count) -ne $normalizedLogins.Count) {
        throw "Los LoginNames deben ser distintos entre si."
    }

    $quotedDbName = Quote-SqlIdentifier -Value $DbName
    $rolePresenceChecks = @()
    foreach ($roleName in $roleUnion) {
        $rolePresenceChecks += "  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$(Escape-SqlLiteral -Value $roleName)') THEN"
        $rolePresenceChecks += "    RAISE EXCEPTION 'Rol delegado requerido no existe: $roleName';"
        $rolePresenceChecks += "  END IF;"
    }

    $sqlLines = @()
    $sqlLines += "DO `$precheck$"
    $sqlLines += "BEGIN"
    $sqlLines += $rolePresenceChecks
    $sqlLines += "END"
    $sqlLines += "`$precheck$;"
    $sqlLines += ""

    for ($index = 0; $index -lt $provisioningEntries.Count; $index++) {
        $entry = [pscustomobject]$provisioningEntries[$index]
        $loginName = [string]$entry.LoginName
        $password = [string]$entry.Password
        $entryRoles = @($entry.DelegatedRoles)
        $quotedLoginName = Quote-SqlIdentifier -Value $loginName
        $escapedLoginName = Escape-SqlLiteral -Value $loginName
        $escapedPassword = Escape-SqlLiteral -Value $password

        $sqlLines += "DO `$provision$"
        $sqlLines += "BEGIN"
        $sqlLines += "  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$escapedLoginName') THEN"
        $sqlLines += "    CREATE ROLE $quotedLoginName LOGIN PASSWORD '$escapedPassword';"
        $sqlLines += "  END IF;"
        $sqlLines += "END"
        $sqlLines += "`$provision$;"
        $sqlLines += ""
        $sqlLines += "ALTER ROLE $quotedLoginName WITH LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION PASSWORD '$escapedPassword';"
        $sqlLines += "ALTER ROLE $quotedLoginName IN DATABASE $quotedDbName SET search_path TO public;"
        $sqlLines += "ALTER ROLE $quotedLoginName RESET default_transaction_read_only;"

        foreach ($roleName in $entryRoles) {
            $quotedRoleName = Quote-SqlIdentifier -Value $roleName
            $sqlLines += "GRANT $quotedRoleName TO $quotedLoginName;"
        }

        $roleListLiteral = ($entryRoles -join ", ")
        $sqlLines += "COMMENT ON ROLE $quotedLoginName IS 'Login delegado local con roles: $roleListLiteral';"
        $sqlLines += ""
    }

    $localSqlPath = Join-Path ([System.IO.Path]::GetTempPath()) ("codex_pg_delegated_users_{0}.sql" -f [guid]::NewGuid().ToString("N"))
    $remoteSqlPath = "/tmp/{0}" -f ([System.IO.Path]::GetFileName($localSqlPath))
    Set-Content -Path $localSqlPath -Value ($sqlLines -join "`r`n") -Encoding UTF8

    try {
        Invoke-PsqlFile -LocalPath $localSqlPath -RemotePath $remoteSqlPath
    }
    finally {
        if (Test-Path -LiteralPath $localSqlPath) {
            Remove-Item -LiteralPath $localSqlPath -Force
        }
    }

    foreach ($entry in $provisioningEntries) {
        $loginName = [string]$entry.LoginName
        $escapedLoginName = Escape-SqlLiteral -Value $loginName
        $present = Invoke-PsqlScalar -Sql "SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$escapedLoginName');"
        if ($present -ne "t") {
            throw "La validacion post-provision detecto usuario faltante: $loginName."
        }

        foreach ($roleName in @($entry.DelegatedRoles)) {
            $roleMembership = Invoke-PsqlScalar -Sql "SELECT pg_has_role('$escapedLoginName', '$(Escape-SqlLiteral -Value $roleName)', 'member');"
            if ($roleMembership -ne "t") {
                throw "La validacion post-provision detecto membresia faltante para $loginName -> $roleName."
            }
        }
    }

    Write-Host ("[OK] Usuarios delegados provisionados: {0}" -f ($normalizedLogins -join ", "))
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
