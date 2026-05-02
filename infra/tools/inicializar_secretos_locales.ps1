param(
    [string]$EnvPath,
    [string]$EnvExamplePath,
    [int]$PasswordLength = 32,
    [int]$MinPasswordLength = 24,
    [switch]$RotatePassword
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$ValidationScript = Join-Path $ScriptDir "validar_secretos_locales.ps1"

if ([string]::IsNullOrWhiteSpace($EnvPath)) {
    $EnvPath = Join-Path $RepoRoot "infra\docker\.env"
}

if ([string]::IsNullOrWhiteSpace($EnvExamplePath)) {
    $EnvExamplePath = Join-Path $RepoRoot "infra\docker\.env.example"
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

function Get-RandomInt {
    param([int]$MaxExclusive)

    $bytes = [byte[]]::new(4)
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    $value = [BitConverter]::ToUInt32($bytes, 0)
    return [int]($value % [uint32]$MaxExclusive)
}

function Get-RandomChar {
    param([char[]]$Chars)
    return $Chars[(Get-RandomInt -MaxExclusive $Chars.Length)]
}

function New-StrongSecret {
    param([int]$Length)

    if ($Length -lt 24) {
        throw "La longitud de secreto debe ser al menos 24 caracteres."
    }

    $upper = "ABCDEFGHJKLMNPQRSTUVWXYZ".ToCharArray()
    $lower = "abcdefghijkmnopqrstuvwxyz".ToCharArray()
    $digits = "23456789".ToCharArray()
    $safe = "@%+=_-".ToCharArray()
    $all = ($upper + $lower + $digits + $safe)

    $chars = [System.Collections.Generic.List[char]]::new()
    $chars.Add((Get-RandomChar -Chars $upper))
    $chars.Add((Get-RandomChar -Chars $lower))
    $chars.Add((Get-RandomChar -Chars $digits))
    $chars.Add((Get-RandomChar -Chars $safe))

    while ($chars.Count -lt $Length) {
        $chars.Add((Get-RandomChar -Chars $all))
    }

    for ($i = $chars.Count - 1; $i -gt 0; $i--) {
        $swapIndex = Get-RandomInt -MaxExclusive ($i + 1)
        $temp = $chars[$i]
        $chars[$i] = $chars[$swapIndex]
        $chars[$swapIndex] = $temp
    }

    return (-join $chars)
}

function Mask-Secret {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "(vacio)"
    }

    if ($Value.Length -le 8) {
        return ("*" * $Value.Length)
    }

    return "{0}***{1}" -f $Value.Substring(0, 4), $Value.Substring($Value.Length - 4)
}

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Inicializacion de Secretos Locales"
    Write-Host "======================================================"
    Write-Host ("  Env local: {0}" -f $EnvPath)
    Write-Host ""

    if (-not (Test-Path -LiteralPath $EnvExamplePath)) {
        throw "Archivo template no encontrado: $EnvExamplePath"
    }

    if (-not (Test-Path -LiteralPath $ValidationScript)) {
        throw "Validador de secretos no encontrado: $ValidationScript"
    }

    $placeholderSecret = "local_change_me_before_shared_use"
    $minRuntimeLength = [Math]::Max($MinPasswordLength, 24)
    $passwordKeys = @(
        "POSTGRES_PASSWORD",
        "FLY_APP_RW_PASSWORD",
        "FLY_APP_RO_PASSWORD",
        "FLY_APP_AUDIT_PASSWORD"
    )

    $baseMap = Get-EnvMap -Path $EnvExamplePath
    $envExists = Test-Path -LiteralPath $EnvPath
    $localMap = if ($envExists) { Get-EnvMap -Path $EnvPath } else { [ordered]@{} }

    foreach ($key in $localMap.Keys) {
        $baseMap[$key] = $localMap[$key]
    }

    if (-not $baseMap.Contains("POSTGRES_DB")) { $baseMap["POSTGRES_DB"] = "flydb" }
    if (-not $baseMap.Contains("POSTGRES_USER")) { $baseMap["POSTGRES_USER"] = "fly_admin" }
    if (-not $baseMap.Contains("POSTGRES_BIND_IP")) { $baseMap["POSTGRES_BIND_IP"] = "127.0.0.1" }
    if (-not $baseMap.Contains("POSTGRES_PORT")) { $baseMap["POSTGRES_PORT"] = "5435" }
    if (-not $baseMap.Contains("FLY_APP_RW_USER")) { $baseMap["FLY_APP_RW_USER"] = "fly_local_rw" }
    if (-not $baseMap.Contains("FLY_APP_RO_USER")) { $baseMap["FLY_APP_RO_USER"] = "fly_local_ro" }
    if (-not $baseMap.Contains("FLY_APP_AUDIT_USER")) { $baseMap["FLY_APP_AUDIT_USER"] = "fly_local_audit" }
    if (-not $baseMap.Contains("TZ")) { $baseMap["TZ"] = "America/Bogota" }
    if (-not $baseMap.Contains("PGTZ")) { $baseMap["PGTZ"] = "America/Bogota" }

    $regeneratedKeys = @()
    foreach ($key in $passwordKeys) {
        $currentValue = if ($baseMap.Contains($key)) { [string]$baseMap[$key] } else { "" }
        $mustGenerate = (-not $envExists) -or $RotatePassword -or [string]::IsNullOrWhiteSpace($currentValue) -or ($currentValue -eq $placeholderSecret) -or ($currentValue.Length -lt $minRuntimeLength)
        if ($mustGenerate) {
            $baseMap[$key] = New-StrongSecret -Length $PasswordLength
            $regeneratedKeys += $key
        }
    }

    $envDir = Split-Path -Parent $EnvPath
    $null = New-Item -ItemType Directory -Force -Path $envDir

    if ($envExists -and $regeneratedKeys.Count -gt 0) {
        $backupDir = Join-Path $RepoRoot "infra\runtime\secret_backups"
        $null = New-Item -ItemType Directory -Force -Path $backupDir
        $backupPath = Join-Path $backupDir ("docker_env_backup_{0}.env" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
        Copy-Item -LiteralPath $EnvPath -Destination $backupPath -Force
        Write-Host ("[OK] Backup previo escrito en: {0}" -f $backupPath)
    }

    $lines = @(
        "# Archivo local no versionado generado por inicializar_secretos_locales.ps1"
        "# Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")"
        "POSTGRES_DB=$($baseMap["POSTGRES_DB"])"
        "POSTGRES_USER=$($baseMap["POSTGRES_USER"])"
        "POSTGRES_PASSWORD=$($baseMap["POSTGRES_PASSWORD"])"
        "POSTGRES_BIND_IP=$($baseMap["POSTGRES_BIND_IP"])"
        "POSTGRES_PORT=$($baseMap["POSTGRES_PORT"])"
        "FLY_APP_RW_USER=$($baseMap["FLY_APP_RW_USER"])"
        "FLY_APP_RW_PASSWORD=$($baseMap["FLY_APP_RW_PASSWORD"])"
        "FLY_APP_RO_USER=$($baseMap["FLY_APP_RO_USER"])"
        "FLY_APP_RO_PASSWORD=$($baseMap["FLY_APP_RO_PASSWORD"])"
        "FLY_APP_AUDIT_USER=$($baseMap["FLY_APP_AUDIT_USER"])"
        "FLY_APP_AUDIT_PASSWORD=$($baseMap["FLY_APP_AUDIT_PASSWORD"])"
        "TZ=$($baseMap["TZ"])"
        "PGTZ=$($baseMap["PGTZ"])"
    )

    Set-Content -Path $EnvPath -Value $lines -Encoding UTF8

    Write-Host ("[OK] Archivo local listo: {0}" -f $EnvPath)
    Write-Host ("[OK] Password runtime: {0}" -f (Mask-Secret -Value [string]$baseMap["POSTGRES_PASSWORD"]))
    Write-Host ("[OK] Password app rw: {0}" -f (Mask-Secret -Value [string]$baseMap["FLY_APP_RW_PASSWORD"]))
    Write-Host ("[OK] Password app ro: {0}" -f (Mask-Secret -Value [string]$baseMap["FLY_APP_RO_PASSWORD"]))
    Write-Host ("[OK] Password app audit: {0}" -f (Mask-Secret -Value [string]$baseMap["FLY_APP_AUDIT_PASSWORD"]))
    Write-Host ("[OK] Longitudes generadas: admin={0}, rw={1}, ro={2}, audit={3}" -f `
        ([string]$baseMap["POSTGRES_PASSWORD"]).Length, `
        ([string]$baseMap["FLY_APP_RW_PASSWORD"]).Length, `
        ([string]$baseMap["FLY_APP_RO_PASSWORD"]).Length, `
        ([string]$baseMap["FLY_APP_AUDIT_PASSWORD"]).Length)

    & $ValidationScript -EnvPath $EnvPath -EnvExamplePath $EnvExamplePath -MinPasswordLength $MinPasswordLength | Out-Null
    if (-not $?) {
        throw "La validacion posterior de secretos locales fallo."
    }

    Write-Host "[OK] Secretos locales inicializados y validados."
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
