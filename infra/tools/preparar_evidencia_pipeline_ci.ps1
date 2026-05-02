param(
    [string]$PrimaryBranch = "",
    [string]$ReleaseBranch = "",
    [string]$CommitSha = "",
    [string]$OutputPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Get-GitOutput {
    param(
        [string[]]$Arguments
    )

    $result = & git @Arguments 2>$null
    if (-not $?) {
        throw ("No fue posible ejecutar git {0}" -f ($Arguments -join " "))
    }

    return ($result | Out-String).Trim()
}

if ([string]::IsNullOrWhiteSpace($PrimaryBranch)) {
    $PrimaryBranch = "codex/develop"
}

if ([string]::IsNullOrWhiteSpace($ReleaseBranch)) {
    $ReleaseBranch = Get-GitOutput -Arguments @("branch", "--show-current")
}

if ([string]::IsNullOrWhiteSpace($CommitSha)) {
    $CommitSha = Get-GitOutput -Arguments @("rev-parse", "HEAD")
}

$shortSha = if ($CommitSha.Length -ge 7) { $CommitSha.Substring(0, 7) } else { $CommitSha }
$today = Get-Date -Format "yyyy-MM-dd"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repoRoot ("docs\validacion\EVIDENCIA_PIPELINE_CI_REMOTO_{0}.md" -f $today)
}

$workflowPath = ".github/workflows/db-gate.yml"
$repoUrl = "https://github.com/code-dev-projects/fly-manager"
$actionsUrl = "$repoUrl/actions"
$workflowUrl = "$repoUrl/actions/workflows/db-gate.yml"
$commitUrl = "$repoUrl/commit/$CommitSha"
$primaryBranchUrl = "$repoUrl/tree/$PrimaryBranch"
$releaseBranchUrl = "$repoUrl/tree/$ReleaseBranch"

$lines = @(
    ("# Evidencia Pipeline CI Remoto ({0})" -f $today),
    "",
    "## 1. Identificacion del run",
    "",
    ("- Fecha: {0}" -f $today),
    ('- Commit SHA: `{0}`' -f $CommitSha),
    ('- Commit corto: `{0}`' -f $shortSha),
    '- Workflow: `db-gate`',
    '- Proveedor CI: `GitHub Actions`',
    ('- Rama primaria publicada: `{0}`' -f $PrimaryBranch),
    ('- Rama release publicada: `{0}`' -f $ReleaseBranch),
    "- Responsable de validacion: pendiente de completar",
    "",
    "## 2. Publicacion confirmada",
    "",
    ('- Commit remoto esperado en ambas ramas: `{0}`' -f $shortSha),
    ("- URL Actions: {0}" -f $actionsUrl),
    ("- URL Workflow: {0}" -f $workflowUrl),
    ("- URL Commit: {0}" -f $commitUrl),
    ("- URL Rama primaria: {0}" -f $primaryBranchUrl),
    ("- URL Rama release: {0}" -f $releaseBranchUrl),
    "",
    "## 3. Estado del primer run remoto",
    "",
    "- Estado general: pendiente de confirmacion remota",
    "- Quick Gate: pendiente",
    "- Full DB Gate: pendiente",
    "- Run ID / URL: pendiente de completar",
    "- Divergencias runner/local: sin evidencia aun",
    "",
    "## 4. Pre-chequeo local previo al push",
    "",
    "- Commit local confirmado y publicado.",
    "- Arbol de trabajo local limpio al momento de preparar esta evidencia.",
    '- Gate documental local previo (`-SkipDocker`): en verde.',
    "",
    "## 5. Hallazgos",
    "",
    "- Desde este entorno no fue posible inspeccionar el workflow remoto sin autenticacion GitHub.",
    "- La verificacion definitiva del primer run queda pendiente de lectura en GitHub Actions.",
    "",
    "## 6. Siguiente paso",
    "",
    '1. Abrir GitHub Actions sobre `db-gate`.',
    '2. Confirmar el resultado de `Quick Gate` y `Full DB Gate`.',
    "3. Completar esta evidencia con el URL del run y cualquier ajuste runner/local."
)

Set-Content -Path $OutputPath -Value $lines -Encoding UTF8

Write-Host ""
Write-Host "======================================================"
Write-Host "  FLY Manager - Preparacion de Evidencia Pipeline CI"
Write-Host "======================================================"
Write-Host ("  Archivo: {0}" -f $OutputPath)
Write-Host ("  Commit:  {0}" -f $CommitSha)
Write-Host ("  Branch:  {0}" -f $ReleaseBranch)
Write-Host ("  Primary: {0}" -f $PrimaryBranch)
Write-Host ""
Write-Host "[OK] Evidencia base del pipeline preparada."
