Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$workflowPath = Join-Path $repoRoot ".github\workflows\db-gate.yml"
$promotionPolicyPath = Join-Path $repoRoot "docs\validacion\POLITICA_PROMOCION_DB_RELEASE_GUARD.md"
$promotionChecklistPath = Join-Path $repoRoot "docs\validacion\CHECKLIST_PROMOCION_CI_DB.md"
$evidenceDir = Join-Path $repoRoot "docs\validacion"

function Assert-FileExists {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
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

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Validacion de Control de Promocion CI"
    Write-Host "======================================================"
    Write-Host ""

    Assert-FileExists -Path $workflowPath
    Assert-FileExists -Path $promotionPolicyPath
    Assert-FileExists -Path $promotionChecklistPath

    $latestEvidence = Get-ChildItem -Path $evidenceDir -File -Filter "EVIDENCIA_PIPELINE_CI_REMOTO_*.md" |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1

    if (-not $latestEvidence) {
        throw "No existe evidencia remota de pipeline en docs/validacion."
    }

    Assert-TextFound -Path $workflowPath -Pattern "name:\s*db-gate" -Message "El workflow oficial db-gate no esta definido."
    Assert-TextFound -Path $workflowPath -Pattern "name:\s*Quick Gate" -Message "El job Quick Gate no esta definido."
    Assert-TextFound -Path $workflowPath -Pattern "name:\s*Full DB Gate" -Message "El job Full DB Gate no esta definido."

    Assert-TextFound -Path $promotionPolicyPath -Pattern "Quick Gate" -Message "La politica de promocion no exige Quick Gate."
    Assert-TextFound -Path $promotionPolicyPath -Pattern "Full DB Gate" -Message "La politica de promocion no exige Full DB Gate."

    Assert-TextFound -Path $promotionChecklistPath -Pattern 'Estado del gate:\s*.*OK' -Message "El checklist de promocion no esta en OK."
    Assert-TextFound -Path $promotionChecklistPath -Pattern 'Bloqueantes abiertos:\s*.*0' -Message "El checklist de promocion reporta bloqueantes abiertos."

    Assert-TextFound -Path $latestEvidence.FullName -Pattern "Estado general:\s*verde" -Message "La evidencia remota no declara estado general verde."
    Assert-TextFound -Path $latestEvidence.FullName -Pattern "Quick Gate:\s*verde" -Message "La evidencia remota no declara Quick Gate en verde."
    Assert-TextFound -Path $latestEvidence.FullName -Pattern "Full DB Gate:\s*verde" -Message "La evidencia remota no declara Full DB Gate en verde."

    Write-Host ("[OK] Workflow oficial: {0}" -f $workflowPath)
    Write-Host ("[OK] Politica de promocion: {0}" -f $promotionPolicyPath)
    Write-Host ("[OK] Checklist de promocion: {0}" -f $promotionChecklistPath)
    Write-Host ("[OK] Evidencia remota validada: {0}" -f $latestEvidence.FullName)
    Write-Host ""
    Write-Host "[OK] Control de promocion CI validado."
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
