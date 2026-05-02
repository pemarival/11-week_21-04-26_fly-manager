param(
    [string]$RepoRoot = "",
    [switch]$IncludeCodePaths
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$targets = @(
    "docs",
    "reports",
    "architecture\canvas",
    "app\landing\index.html"
)

$allFiles = New-Object System.Collections.Generic.List[string]

foreach ($target in $targets) {
    $absoluteTarget = Join-Path $RepoRoot $target
    if (-not (Test-Path $absoluteTarget)) {
        continue
    }

    $item = Get-Item $absoluteTarget
    if ($item.PSIsContainer) {
        Get-ChildItem -Path $absoluteTarget -Recurse -File |
            Where-Object { $_.Extension -in @(".md", ".html") } |
            ForEach-Object { $allFiles.Add($_.FullName) }
    } else {
        $allFiles.Add($item.FullName)
    }
}

$ignorePrefixes = @(
    "http://",
    "https://",
    "mailto:",
    "javascript:",
    "#"
)

$results = New-Object System.Collections.Generic.List[object]

function Should-IgnorePath {
    param([string]$PathValue)

    if (-not $PathValue) { return $true }
    foreach ($prefix in $ignorePrefixes) {
        if ($PathValue.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Add-ReferenceResult {
    param(
        [string]$SourceFile,
        [int]$LineNumber,
        [string]$RawReference
    )

    if (Should-IgnorePath -PathValue $RawReference) {
        return
    }

    $cleanRef = $RawReference.Trim()
    if (-not $cleanRef) { return }

    # Ignore querystring/hash fragments in local files.
    $cleanRef = $cleanRef.Split("#")[0].Split("?")[0]
    if (-not $cleanRef) { return }

    $resolvedPath = $null
    $exists = $false

    if ([System.IO.Path]::IsPathRooted($cleanRef)) {
        $resolvedPath = $cleanRef
    } else {
        $baseDir = Split-Path -Parent $SourceFile
        $resolvedPath = [System.IO.Path]::GetFullPath((Join-Path $baseDir $cleanRef))
    }

    $exists = Test-Path $resolvedPath

    $results.Add([PSCustomObject]@{
        file      = $SourceFile
        line      = $LineNumber
        reference = $RawReference
        resolved  = $resolvedPath
        exists    = $exists
    })
}

foreach ($file in $allFiles) {
    $lineNo = 0
    foreach ($line in Get-Content $file) {
        $lineNo += 1

        foreach ($m in [regex]::Matches($line, '\[[^\]]+\]\((?<p>[^)]+)\)')) {
            Add-ReferenceResult -SourceFile $file -LineNumber $lineNo -RawReference $m.Groups["p"].Value
        }

        foreach ($m in [regex]::Matches($line, '(?:href|src)\s*=\s*"(?<p>[^"]+)"')) {
            Add-ReferenceResult -SourceFile $file -LineNumber $lineNo -RawReference $m.Groups["p"].Value
        }

        if ($IncludeCodePaths) {
            foreach ($m in [regex]::Matches($line, '`(?<p>(?:\.\./|[A-Za-z0-9_\-./]+)\.(?:md|sql|html|ps1|css|js))`')) {
                Add-ReferenceResult -SourceFile $file -LineNumber $lineNo -RawReference $m.Groups["p"].Value
            }
        }
    }
}

$distinct = @($results |
    Group-Object file, line, reference, resolved |
    ForEach-Object { $_.Group[0] })

$missing = @($distinct | Where-Object { -not $_.exists })

Write-Host ""
Write-Host "== Validacion de rutas documentales =="
Write-Host ("Repositorio: {0}" -f $RepoRoot)
Write-Host ("Referencias evaluadas: {0}" -f ($distinct.Count))
Write-Host ("Referencias faltantes: {0}" -f ($missing.Count))
Write-Host ""

if ($missing.Count -gt 0) {
    $missing |
        Sort-Object file, line |
        Select-Object file, line, reference, resolved |
        Format-Table -AutoSize
    exit 1
}

Write-Host "[OK] No se encontraron rutas faltantes."
exit 0
