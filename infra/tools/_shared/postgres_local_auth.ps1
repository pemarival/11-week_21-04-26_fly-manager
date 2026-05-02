function Get-FlyRepoRoot {
    param([string]$ScriptPath)

    if ([string]::IsNullOrWhiteSpace($ScriptPath)) {
        throw "ScriptPath es requerido para resolver el repo root."
    }

    return (Resolve-Path (Join-Path (Split-Path -Parent $ScriptPath) "..\..")).Path
}

function Get-LocalEnvMap {
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
            throw "Formato invalido en archivo .env: $Path"
        }

        $key = $trimmed.Substring(0, $separator).Trim()
        $value = $trimmed.Substring($separator + 1)
        $map[$key] = $value
    }

    return $map
}

function Resolve-DbPasswordFromMap {
    param(
        [hashtable]$EnvMap,
        [string]$DbUser
    )

    if ([string]::IsNullOrWhiteSpace($DbUser)) {
        return $null
    }

    $pairs = @(
        @{ user_key = "POSTGRES_USER"; pass_key = "POSTGRES_PASSWORD" }
        @{ user_key = "FLY_APP_RW_USER"; pass_key = "FLY_APP_RW_PASSWORD" }
        @{ user_key = "FLY_APP_RO_USER"; pass_key = "FLY_APP_RO_PASSWORD" }
        @{ user_key = "FLY_APP_AUDIT_USER"; pass_key = "FLY_APP_AUDIT_PASSWORD" }
    )

    foreach ($pair in $pairs) {
        if ($EnvMap.Contains($pair.user_key) -and $EnvMap.Contains($pair.pass_key)) {
            if ([string]$EnvMap[$pair.user_key] -eq $DbUser) {
                return [string]$EnvMap[$pair.pass_key]
            }
        }
    }

    return $null
}

function Resolve-DbLoginContext {
    param(
        [ValidateSet("admin", "rw", "ro", "audit")]
        [string]$Mode,
        [string]$ScriptPath,
        [string]$EnvPath,
        [string]$DbUser,
        [string]$DbPassword,
        [string]$DbName
    )

    $repoRoot = Get-FlyRepoRoot -ScriptPath $ScriptPath
    if ([string]::IsNullOrWhiteSpace($EnvPath)) {
        $EnvPath = Join-Path $repoRoot "infra\docker\.env"
    }

    $envMap = Get-LocalEnvMap -Path $EnvPath

    if ([string]::IsNullOrWhiteSpace($DbName)) {
        if ($envMap.Contains("POSTGRES_DB")) {
            $DbName = [string]$envMap["POSTGRES_DB"]
        } elseif (-not [string]::IsNullOrWhiteSpace($env:POSTGRES_DB)) {
            $DbName = $env:POSTGRES_DB
        } else {
            $DbName = "flydb"
        }
    }

    $loginMode = $Mode
    if (-not [string]::IsNullOrWhiteSpace($DbUser)) {
        if ([string]::IsNullOrWhiteSpace($DbPassword)) {
            $DbPassword = Resolve-DbPasswordFromMap -EnvMap $envMap -DbUser $DbUser
        }

        if ([string]::IsNullOrWhiteSpace($DbPassword)) {
            throw "No se pudo resolver password para el usuario indicado: $DbUser"
        }

        $loginMode = "explicit"
    } else {
        switch ($Mode) {
            "admin" {
                $DbUser = if ($envMap.Contains("POSTGRES_USER")) { [string]$envMap["POSTGRES_USER"] } elseif (-not [string]::IsNullOrWhiteSpace($env:POSTGRES_USER)) { $env:POSTGRES_USER } else { "fly_admin" }
                $DbPassword = if ($envMap.Contains("POSTGRES_PASSWORD")) { [string]$envMap["POSTGRES_PASSWORD"] } else { $null }
            }
            "rw" {
                $DbUser = if ($envMap.Contains("FLY_APP_RW_USER")) { [string]$envMap["FLY_APP_RW_USER"] } else { "fly_local_rw" }
                $DbPassword = if ($envMap.Contains("FLY_APP_RW_PASSWORD")) { [string]$envMap["FLY_APP_RW_PASSWORD"] } else { $null }
            }
            "ro" {
                $DbUser = if ($envMap.Contains("FLY_APP_RO_USER")) { [string]$envMap["FLY_APP_RO_USER"] } else { "fly_local_ro" }
                $DbPassword = if ($envMap.Contains("FLY_APP_RO_PASSWORD")) { [string]$envMap["FLY_APP_RO_PASSWORD"] } else { $null }
            }
            "audit" {
                $DbUser = if ($envMap.Contains("FLY_APP_AUDIT_USER")) { [string]$envMap["FLY_APP_AUDIT_USER"] } else { "fly_local_audit" }
                $DbPassword = if ($envMap.Contains("FLY_APP_AUDIT_PASSWORD")) { [string]$envMap["FLY_APP_AUDIT_PASSWORD"] } else { $null }
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($DbUser)) {
        throw "No se pudo resolver usuario de conexion para el modo: $Mode"
    }

    if ([string]::IsNullOrWhiteSpace($DbPassword)) {
        throw "No se pudo resolver password para el modo de conexion: $Mode"
    }

    return [pscustomobject]@{
        RepoRoot   = $repoRoot
        EnvPath    = $EnvPath
        EnvMap     = $envMap
        DbUser     = $DbUser
        DbPassword = $DbPassword
        DbName     = $DbName
        LoginMode  = $loginMode
    }
}

function Invoke-ContainerPsql {
    param(
        [string]$ContainerName,
        [string]$DbUser,
        [string]$DbPassword,
        [string]$Database,
        [string[]]$Arguments
    )

    if ([string]::IsNullOrWhiteSpace($DbPassword)) {
        throw "DbPassword es requerido para conexion psql sobre TCP."
    }

    $dockerArgs = @(
        "exec"
        "-e"
        "PGPASSWORD=$DbPassword"
        "-e"
        "PGCONNECT_TIMEOUT=5"
        $ContainerName
        "psql"
        "-h"
        "127.0.0.1"
        "-U"
        $DbUser
        "-d"
        $Database
    )

    if ($Arguments) {
        $dockerArgs += $Arguments
    }

    $output = & docker @dockerArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo psql para usuario $DbUser sobre $Database."
    }

    return $output
}

function Invoke-ContainerPsqlScalar {
    param(
        [string]$ContainerName,
        [string]$DbUser,
        [string]$DbPassword,
        [string]$Database,
        [string]$Sql
    )

    $raw = Invoke-ContainerPsql `
        -ContainerName $ContainerName `
        -DbUser $DbUser `
        -DbPassword $DbPassword `
        -Database $Database `
        -Arguments @("-q", "-t", "-A", "-c", $Sql)

    return (($raw | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n").Trim()
}

function Invoke-ContainerPsqlRows {
    param(
        [string]$ContainerName,
        [string]$DbUser,
        [string]$DbPassword,
        [string]$Database,
        [string]$Sql
    )

    $rows = Invoke-ContainerPsql `
        -ContainerName $ContainerName `
        -DbUser $DbUser `
        -DbPassword $DbPassword `
        -Database $Database `
        -Arguments @("-q", "-t", "-A", "-F", "|", "-c", $Sql)

    return ,@($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}
