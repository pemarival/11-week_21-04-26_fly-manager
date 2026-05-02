param(
    [string]$EvidencePath,
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$EnvPath,
    [string]$DbName,
    [string]$DbUser,
    [string]$DbPassword,
    [string]$ReadDbUser,
    [string]$ReadDbPassword,
    [string]$WriteDbUser,
    [string]$WriteDbPassword,
    [switch]$SkipWriteProbe,
    [switch]$SkipWarmup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$AuthHelperPath = Join-Path $ScriptDir "_shared\postgres_local_auth.ps1"
if (-not (Test-Path -LiteralPath $AuthHelperPath)) {
    throw "Helper de autenticacion no encontrado: $AuthHelperPath"
}
. $AuthHelperPath

if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
    $EvidencePath = Join-Path $RepoRoot "docs\validacion\EVIDENCIA_BASELINE_PERFORMANCE_LOCAL_2026-03-19.md"
}

if (-not [string]::IsNullOrWhiteSpace($DbUser) -and [string]::IsNullOrWhiteSpace($ReadDbUser)) {
    $ReadDbUser = $DbUser
}

if (-not [string]::IsNullOrWhiteSpace($DbPassword) -and [string]::IsNullOrWhiteSpace($ReadDbPassword)) {
    $ReadDbPassword = $DbPassword
}

if (-not [string]::IsNullOrWhiteSpace($DbUser) -and [string]::IsNullOrWhiteSpace($WriteDbUser)) {
    $WriteDbUser = $DbUser
}

if (-not [string]::IsNullOrWhiteSpace($DbPassword) -and [string]::IsNullOrWhiteSpace($WriteDbPassword)) {
    $WriteDbPassword = $DbPassword
}

$readLoginContext = Resolve-DbLoginContext `
    -Mode "ro" `
    -ScriptPath $MyInvocation.MyCommand.Path `
    -EnvPath $EnvPath `
    -DbUser $ReadDbUser `
    -DbPassword $ReadDbPassword `
    -DbName $DbName

$writeLoginContext = Resolve-DbLoginContext `
    -Mode "rw" `
    -ScriptPath $MyInvocation.MyCommand.Path `
    -EnvPath $readLoginContext.EnvPath `
    -DbUser $WriteDbUser `
    -DbPassword $WriteDbPassword `
    -DbName $readLoginContext.DbName

$EnvPath = $readLoginContext.EnvPath
$DbName = $readLoginContext.DbName

if ($writeLoginContext.DbName -ne $DbName) {
    throw "El login de escritura apunta a una base distinta al baseline de lectura."
}

function Invoke-ExplainAnalyze {
    param(
        [string]$Name,
        [string]$Sql,
        [string]$DbUser,
        [string]$DbPassword
    )

    $localTempPath = Join-Path ([System.IO.Path]::GetTempPath()) ("codex_perf_{0}_{1}.sql" -f $Name, [guid]::NewGuid().ToString("N"))
    $remoteTempPath = "/tmp/{0}" -f ([System.IO.Path]::GetFileName($localTempPath))

    $sqlContent = @"
\pset tuples_only on
\pset format unaligned
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
$Sql
"@

    Set-Content -Path $localTempPath -Value $sqlContent -Encoding UTF8

    try {
        docker cp $localTempPath "${ContainerName}:$remoteTempPath" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo docker cp para consulta de performance: $Name"
        }

        $raw = Invoke-ContainerPsql `
            -ContainerName $ContainerName `
            -DbUser $DbUser `
            -DbPassword $DbPassword `
            -Database $DbName `
            -Arguments @("-X", "-q", "-f", $remoteTempPath)

        $jsonText = (($raw | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n").Trim()
        return ($jsonText | ConvertFrom-Json)[0]
    }
    finally {
        if (Test-Path -LiteralPath $localTempPath) {
            Remove-Item -LiteralPath $localTempPath -Force
        }
        docker exec $ContainerName rm -f $remoteTempPath | Out-Null
    }
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

$queries = @(
    [pscustomobject]@{
        metric_name = "flight_board_search"
        login_mode = "ro"
        threshold_ms = 20.0
        note = "Lectura operativa de vuelos por fecha con join de aeropuertos"
        sql = @"
SELECT
  f.flight_number,
  f.service_date,
  fs.segment_number,
  ao.iata_code AS origin_iata,
  ad.iata_code AS destination_iata,
  fs.scheduled_departure_at
FROM public.flight f
JOIN public.flight_segment fs ON fs.flight_id = f.flight_id
JOIN public.airport ao ON ao.airport_id = fs.origin_airport_id
JOIN public.airport ad ON ad.airport_id = fs.destination_airport_id
WHERE f.service_date BETWEEN DATE '2026-04-01' AND DATE '2026-06-30'
ORDER BY f.service_date, f.flight_number, fs.segment_number
LIMIT 100
"@
    }
    [pscustomobject]@{
        metric_name = "customer_itinerary_join"
        login_mode = "ro"
        threshold_ms = 45.0
        note = "Join critico de reserva, venta, ticket, segmento y vuelo"
        sql = @"
SELECT
  r.reservation_code,
  t.ticket_number,
  concat_ws(' ', p.first_name, p.last_name) AS passenger_name,
  f.flight_number,
  ao.iata_code AS origin_iata,
  ad.iata_code AS destination_iata,
  fs.scheduled_departure_at
FROM public.reservation r
JOIN public.customer c ON c.customer_id = r.booked_by_customer_id
JOIN public.person p ON p.person_id = c.person_id
JOIN public.sale s ON s.reservation_id = r.reservation_id
JOIN public.ticket t ON t.sale_id = s.sale_id
JOIN public.ticket_segment ts ON ts.ticket_id = t.ticket_id
JOIN public.flight_segment fs ON fs.flight_segment_id = ts.flight_segment_id
JOIN public.flight f ON f.flight_id = fs.flight_id
JOIN public.airport ao ON ao.airport_id = fs.origin_airport_id
JOIN public.airport ad ON ad.airport_id = fs.destination_airport_id
WHERE r.booked_by_customer_id = (
  SELECT booked_by_customer_id
  FROM public.reservation
  GROUP BY booked_by_customer_id
  ORDER BY count(*) DESC, booked_by_customer_id
  LIMIT 1
)
ORDER BY r.booked_at DESC, t.ticket_number, ts.segment_sequence_no
LIMIT 200
"@
    }
    [pscustomobject]@{
        metric_name = "financial_reconciliation_join"
        login_mode = "ro"
        threshold_ms = 45.0
        note = "Conciliacion de venta, pago, transaccion e invoice"
        sql = @"
SELECT
  s.sale_code,
  p.payment_reference,
  pt.transaction_reference,
  i.invoice_number,
  p.amount,
  pt.processed_at
FROM public.sale s
JOIN public.payment p ON p.sale_id = s.sale_id
LEFT JOIN public.payment_transaction pt ON pt.payment_id = p.payment_id
LEFT JOIN public.invoice i ON i.sale_id = s.sale_id
WHERE s.sold_at >= TIMESTAMPTZ '2025-01-01 00:00:00-05'
ORDER BY s.sold_at DESC, p.payment_reference, pt.processed_at
LIMIT 300
"@
    }
    [pscustomobject]@{
        metric_name = "loyalty_ledger_customer"
        login_mode = "ro"
        threshold_ms = 25.0
        note = "Ledger de millas por cliente con join de persona"
        sql = @"
SELECT
  la.account_number,
  mt.transaction_type,
  mt.miles_delta,
  mt.occurred_at,
  concat_ws(' ', pe.first_name, pe.last_name) AS customer_name
FROM public.loyalty_account la
JOIN public.customer c ON c.customer_id = la.customer_id
JOIN public.person pe ON pe.person_id = c.person_id
JOIN public.miles_transaction mt ON mt.loyalty_account_id = la.loyalty_account_id
WHERE la.customer_id = (
  SELECT la2.customer_id
  FROM public.loyalty_account la2
  JOIN public.miles_transaction mt2 ON mt2.loyalty_account_id = la2.loyalty_account_id
  GROUP BY la2.customer_id
  ORDER BY count(*) DESC, la2.customer_id
  LIMIT 1
)
ORDER BY mt.occurred_at DESC
LIMIT 200
"@
    }
    [pscustomobject]@{
        metric_name = "boarding_flow_join"
        login_mode = "ro"
        threshold_ms = 35.0
        note = "Join de check-in, boarding pass, validation y vuelo"
        sql = @"
SELECT
  bp.boarding_pass_code,
  bv.validated_at,
  ci.checked_in_at,
  f.flight_number,
  ao.iata_code AS origin_iata,
  ad.iata_code AS destination_iata
FROM public.boarding_validation bv
JOIN public.boarding_pass bp ON bp.boarding_pass_id = bv.boarding_pass_id
JOIN public.check_in ci ON ci.check_in_id = bp.check_in_id
JOIN public.ticket_segment ts ON ts.ticket_segment_id = ci.ticket_segment_id
JOIN public.flight_segment fs ON fs.flight_segment_id = ts.flight_segment_id
JOIN public.flight f ON f.flight_id = fs.flight_id
JOIN public.airport ao ON ao.airport_id = fs.origin_airport_id
JOIN public.airport ad ON ad.airport_id = fs.destination_airport_id
ORDER BY bv.validated_at DESC
LIMIT 200
"@
    }
    [pscustomobject]@{
        metric_name = "temp_write_select_into"
        login_mode = "rw"
        threshold_ms = 25.0
        note = "Write baseline seguro en tabla temporal de sesion con login RW"
        sql = @"
SELECT
  g AS seq_id,
  repeat('x', 64) AS payload
INTO TEMP TABLE tmp_perf_write_probe
FROM generate_series(1, 1000) AS g
"@
    }
)

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Baseline Performance Local"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base: {0}" -f $DbName)
    Write-Host ("  Login lectura: {0} (RO)" -f $readLoginContext.DbUser)
    Write-Host ("  Login escritura: {0} (RW)" -f $writeLoginContext.DbUser)
    Write-Host ("  Evidencia: {0}" -f $EvidencePath)
    Write-Host ""

    $results = @()
    $queryBatch = if ($SkipWriteProbe) { @($queries | Where-Object { $_.login_mode -ne "rw" }) } else { $queries }
    foreach ($queryDef in $queryBatch) {
        $activeLoginContext = if ($queryDef.login_mode -eq "rw") { $writeLoginContext } else { $readLoginContext }

        Write-Host ("[RUN] {0}" -f $queryDef.metric_name)
        if (-not $SkipWarmup) {
            $null = Invoke-ExplainAnalyze `
                -Name ($queryDef.metric_name + "_warmup") `
                -Sql $queryDef.sql `
                -DbUser $activeLoginContext.DbUser `
                -DbPassword $activeLoginContext.DbPassword
        }

        $plan = Invoke-ExplainAnalyze `
            -Name $queryDef.metric_name `
            -Sql $queryDef.sql `
            -DbUser $activeLoginContext.DbUser `
            -DbPassword $activeLoginContext.DbPassword

        $status = if ([double]$plan."Execution Time" -le [double]$queryDef.threshold_ms) { "OK" } else { "FALLA" }

        $results += [pscustomobject]@{
            metric_name = $queryDef.metric_name
            login_mode = $queryDef.login_mode.ToUpperInvariant()
            login_used = $activeLoginContext.DbUser
            execution_ms = [math]::Round([double]$plan."Execution Time", 3)
            planning_ms = [math]::Round([double]$plan."Planning Time", 3)
            threshold_ms = [double]$queryDef.threshold_ms
            actual_rows = [int64]$plan.Plan."Actual Rows"
            shared_hit_blocks = [int64]($plan.Plan."Shared Hit Blocks" | ForEach-Object { $_ })
            shared_read_blocks = [int64]($plan.Plan."Shared Read Blocks" | ForEach-Object { $_ })
            shared_written_blocks = [int64]($plan.Plan."Shared Written Blocks" | ForEach-Object { $_ })
            status = $status
            note = $queryDef.note
        }
    }

    $failed = @($results | Where-Object { $_.status -ne "OK" })
    $summaryRows = @(
        [pscustomobject]@{ metric = "queries_measured"; value = $results.Count }
        [pscustomobject]@{ metric = "queries_failed"; value = $failed.Count }
        [pscustomobject]@{ metric = "warmup_enabled"; value = (-not $SkipWarmup) }
        [pscustomobject]@{ metric = "write_probe_enabled"; value = (-not $SkipWriteProbe) }
        [pscustomobject]@{ metric = "read_login"; value = $readLoginContext.DbUser }
        [pscustomobject]@{ metric = "write_login"; value = $(if ($SkipWriteProbe) { "N/A" } else { $writeLoginContext.DbUser }) }
        [pscustomobject]@{ metric = "dataset_reference_reservation_rows"; value = 1223 }
        [pscustomobject]@{ metric = "dataset_reference_ticket_rows"; value = 1223 }
    )

    $summaryTable = New-MarkdownTable -Rows $summaryRows -Headers @("metric", "value")
    $resultsTable = New-MarkdownTable -Rows $results -Headers @("metric_name", "login_mode", "login_used", "execution_ms", "planning_ms", "threshold_ms", "actual_rows", "shared_hit_blocks", "shared_read_blocks", "shared_written_blocks", "status", "note")

    $evidenceDir = Split-Path -Parent $EvidencePath
    $null = New-Item -ItemType Directory -Force -Path $evidenceDir

    $content = @"
# Evidencia de Baseline Performance Local (2026-03-19)

## Objetivo

Medir una linea base de performance local sobre consultas operativas reales de
FLY Manager, usando `EXPLAIN ANALYZE` con buffers para lectura, joins criticos y
una prueba de escritura segura sobre tabla temporal.

## Contexto de ejecucion

- Fecha de ejecucion: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
- Contenedor: $ContainerName
- Base medida: $DbName
- Login lectura (RO): $($readLoginContext.DbUser)
- Login escritura (RW): $(if ($SkipWriteProbe) { "N/A" } else { $writeLoginContext.DbUser })
- Warmup previo: $(-not $SkipWarmup)

## Resumen observado

$summaryTable

## Resultados por consulta

$resultsTable

## Resultado

- Estado general: $(if ($failed.Count -eq 0) { "BASELINE OK" } else { "BASELINE CON DESVIACIONES" })
- Consultas evaluadas: $($results.Count)
- Consultas fuera de umbral: $($failed.Count)
"@

    Set-Content -Path $EvidencePath -Value $content -Encoding UTF8

    Write-Host ""
    Write-Host ("[OK] Evidencia escrita en: {0}" -f $EvidencePath)

    if ($failed.Count -gt 0) {
        throw ("El baseline reporto {0} consultas fuera de umbral." -f $failed.Count)
    }

    Write-Output ([pscustomobject]@{
        evidence_path = $EvidencePath
        measured_queries = $results.Count
        failed_queries = $failed.Count
        read_db_user = $readLoginContext.DbUser
        write_db_user = $(if ($SkipWriteProbe) { $null } else { $writeLoginContext.DbUser })
    })
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
