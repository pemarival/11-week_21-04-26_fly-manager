param(
    [switch]$SkipDocker,
    [switch]$IncludeCodePaths
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$dockerScript = Join-Path $repoRoot "infra\docker\recrear_instalacion_limpia.ps1"
$docsScript = Join-Path $repoRoot "infra\tools\validar_rutas_docs.ps1"
$regressionScript = Join-Path $repoRoot "infra\tools\ejecutar_regresion_post_seed.ps1"
$migrationValidationScript = Join-Path $repoRoot "infra\tools\validar_migraciones.ps1"
$secretsInitScript = Join-Path $repoRoot "infra\tools\inicializar_secretos_locales.ps1"
$secretsValidationScript = Join-Path $repoRoot "infra\tools\validar_secretos_locales.ps1"
$securityHardeningScript = Join-Path $repoRoot "infra\tools\endurecer_seguridad_postgres_local.ps1"
$bootstrapAdminConfinementScript = Join-Path $repoRoot "infra\tools\confinar_admin_bootstrap_local.ps1"
$operationalLoginsProvisionScript = Join-Path $repoRoot "infra\tools\provisionar_logins_operativos_locales.ps1"
$operationalLoginsValidationScript = Join-Path $repoRoot "infra\tools\validar_logins_operativos_locales.ps1"
$leastPrivilegeValidationScript = Join-Path $repoRoot "infra\tools\validar_menor_privilegio_operativo_local.ps1"
$bootstrapAdminValidationScript = Join-Path $repoRoot "infra\tools\validar_admin_bootstrap_local.ps1"
$securityAuditScript = Join-Path $repoRoot "infra\tools\auditar_seguridad_postgres_local.ps1"
$promotionGuardValidationScript = Join-Path $repoRoot "infra\tools\validar_control_promocion_ci.ps1"
$checklistPath = Join-Path $repoRoot "docs\validacion\CHECKLIST_RELEASE_ARQUITECTONICO.md"
$notePath = Join-Path $repoRoot "docs\planes\NOTA_EJECUTIVA_PRE_RELEASE_2026-03-19.md"

function Invoke-Step {
    param(
        [string]$Label,
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host ("[GATE] {0}" -f $Label)
    & $Action
    Write-Host ("[OK] {0}" -f $Label)
}

function Assert-FileExists {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Archivo requerido no encontrado: $Path"
    }
}

function Assert-TextFound {
    param(
        [string]$Path,
        [string]$Pattern,
        [string]$Message
    )

    if (-not (Select-String -Path $Path -Pattern $Pattern -Quiet)) {
        throw $Message
    }
}

Write-Host ""
Write-Host "======================================================"
Write-Host "  FLY Manager - Gate Arquitectonico (Release/Post-Release)"
Write-Host "======================================================"
Write-Host ("  Repo: {0}" -f $repoRoot)
Write-Host ""

Invoke-Step -Label "Verificacion de archivos base" -Action {
    Assert-FileExists -Path $docsScript
    Assert-FileExists -Path $regressionScript
    Assert-FileExists -Path $migrationValidationScript
    Assert-FileExists -Path $secretsInitScript
    Assert-FileExists -Path $secretsValidationScript
    Assert-FileExists -Path $securityHardeningScript
    Assert-FileExists -Path $bootstrapAdminConfinementScript
    Assert-FileExists -Path $operationalLoginsProvisionScript
    Assert-FileExists -Path $operationalLoginsValidationScript
    Assert-FileExists -Path $leastPrivilegeValidationScript
    Assert-FileExists -Path $bootstrapAdminValidationScript
    Assert-FileExists -Path $securityAuditScript
    Assert-FileExists -Path $promotionGuardValidationScript
    Assert-FileExists -Path $checklistPath
    Assert-FileExists -Path $notePath
    if (-not $SkipDocker) {
        Assert-FileExists -Path $dockerScript
    }
}

Invoke-Step -Label "Validacion de migraciones versionadas" -Action {
    & $migrationValidationScript
    if (-not $?) {
        throw "Fallo la validacion de migraciones versionadas."
    }
}

Invoke-Step -Label "Validacion de secretos locales" -Action {
    & $secretsValidationScript | Out-Null
    if (-not $?) {
        throw "Fallo la validacion de secretos locales."
    }
}

if (-not $SkipDocker) {
    Invoke-Step -Label "Validacion tecnica DDL base + migraciones + seeds + gates" -Action {
        & $dockerScript
        if (-not $?) {
            throw "Fallo la validacion tecnica de datos."
        }
    }

    Invoke-Step -Label "Regresion SQL post-seed" -Action {
        & $regressionScript
        if (-not $?) {
            throw "Fallo la regresion SQL post-seed."
        }
    }

    Invoke-Step -Label "Validacion de logins operativos locales" -Action {
        & $operationalLoginsValidationScript | Out-Null
        if (-not $?) {
            throw "Fallo la validacion de logins operativos locales."
        }
    }

    Invoke-Step -Label "Validacion de menor privilegio operativo local" -Action {
        & $leastPrivilegeValidationScript | Out-Null
        if (-not $?) {
            throw "Fallo la validacion de menor privilegio operativo local."
        }
    }

    Invoke-Step -Label "Validacion de confinamiento admin bootstrap local" -Action {
        & $bootstrapAdminValidationScript | Out-Null
        if (-not $?) {
            throw "Fallo la validacion de admin bootstrap local."
        }
    }

    Invoke-Step -Label "Auditoria de seguridad local" -Action {
        & $securityAuditScript | Out-Null
        if (-not $?) {
            throw "Fallo la auditoria de seguridad local."
        }
    }
} else {
    Write-Host "[WARN] Se omitio la validacion Docker por parametro -SkipDocker."
}

Invoke-Step -Label "Validacion de rutas documentales" -Action {
    if ($IncludeCodePaths) {
        & $docsScript -IncludeCodePaths
    } else {
        & $docsScript
    }
    if (-not $?) {
        throw "Fallo la validacion de rutas documentales."
    }
}

Invoke-Step -Label "Validacion de control de promocion CI" -Action {
    & $promotionGuardValidationScript
    if (-not $?) {
        throw "Fallo la validacion de control de promocion CI."
    }
}

Invoke-Step -Label "Chequeo de consistencia documental minima" -Action {
    Assert-TextFound `
        -Path $checklistPath `
        -Pattern "APTO PARA PRE-RELEASE|RELEASE CONGELADO" `
        -Message "El checklist no refleja estado de corte valido (pre-release o release congelado)."

    Assert-TextFound `
        -Path $checklistPath `
        -Pattern 'Bloqueantes abiertos:\s*`0`' `
        -Message "El checklist no refleja bloqueantes en cero."

    Assert-TextFound `
        -Path $notePath `
        -Pattern "APTO PARA PRE-RELEASE|RELEASE CONGELADO" `
        -Message "La nota ejecutiva no refleja estado de corte valido (pre-release o release congelado)."
}

Write-Host ""
Write-Host "======================================================"
Write-Host "  GATE ARQUITECTONICO: OK"
Write-Host "  Siguiente paso: commit manual y/o control de corte"
Write-Host "======================================================"
Write-Host ""
Write-Host "Comando sugerido para corte rapido:"
Write-Host "  .\infra\tools\ejecutar_gate_pre_release.ps1"
Write-Host ""
Write-Host "Comando sugerido si quieres omitir Docker y validar solo documental:"
Write-Host "  .\infra\tools\ejecutar_gate_pre_release.ps1 -SkipDocker"
Write-Host ""
Write-Host "Auditoria estricta opcional (puede reportar referencias historicas como faltantes):"
Write-Host "  .\infra\tools\ejecutar_gate_pre_release.ps1 -SkipDocker -IncludeCodePaths"
