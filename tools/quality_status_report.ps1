param(
  [switch]$SkipInternalGate,
  [switch]$SkipReleaseGate,
  [switch]$SkipArchitectureReport,
  [switch]$SkipExternalProductionReadiness,
  [switch]$IncludeManualStatusJson,
  [switch]$SkipRules
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Invoke-Gate {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$ScriptPath,
    [string[]]$Arguments = @()
  )

  Write-Host ""
  Write-Host "== $Name ==" -ForegroundColor Cyan
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $output = & powershell -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  $output | ForEach-Object { Write-Host $_ }

  if ($exitCode -eq 0) {
    Write-Host "${Name}: PASS" -ForegroundColor Green
  } else {
    Write-Host "${Name}: FAIL (exit $exitCode)" -ForegroundColor Yellow
  }

  return [pscustomobject]@{
    Name = $Name
    ExitCode = $exitCode
    Passed = $exitCode -eq 0
  }
}

Write-Host "== RxPro 9+ quality status report ==" -ForegroundColor Cyan
Write-Host "This report is honest by design: release is not 9+ until both internal and external gates pass."

$results = @()

if (-not $SkipArchitectureReport) {
  $results += Invoke-Gate `
    -Name "Feature architecture budget" `
    -ScriptPath (Join-Path $root 'tools\feature_architecture_report.ps1') `
    -Arguments @('-FailOnLargeFiles')
}

if (-not $SkipInternalGate) {
  $internalArguments = @('-SkipFlutter')
  if ($SkipRules) {
    $internalArguments += '-SkipRules'
  }

  $results += Invoke-Gate `
    -Name "Internal quality gate" `
    -ScriptPath (Join-Path $root 'tools\ci_quality_check.ps1') `
    -Arguments $internalArguments
}

if (-not $SkipReleaseGate) {
  $results += Invoke-Gate `
    -Name "Release external gate" `
    -ScriptPath (Join-Path $root 'tools\release_gate_check.ps1')
}

if (-not $SkipExternalProductionReadiness) {
  $results += Invoke-Gate `
    -Name "External production readiness" `
    -ScriptPath (Join-Path $root 'tools\external_production_readiness_check.ps1')
}

if ($IncludeManualStatusJson) {
  Write-Host ""
  Write-Host "== Manual verification JSON ==" -ForegroundColor Cyan
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $manualJson = & powershell `
      -ExecutionPolicy Bypass `
      -File (Join-Path $root 'tools\production_manual_status.ps1') `
      -Json 2>&1
    $manualJsonExitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  $manualJson | ForEach-Object { Write-Host $_ }
  $results += [pscustomobject]@{
    Name = "Manual verification status"
    ExitCode = $manualJsonExitCode
    Passed = $manualJsonExitCode -eq 0
  }
}

$failed = @($results | Where-Object { -not $_.Passed })
$skippedCritical = @()
if ($SkipReleaseGate) {
  $skippedCritical += "Release external gate"
}
if ($SkipExternalProductionReadiness) {
  $skippedCritical += "External production readiness"
}

Write-Host ""
Write-Host "== Summary ==" -ForegroundColor Cyan
if ($failed.Count -eq 0 -and $results.Count -gt 0 -and $skippedCritical.Count -eq 0) {
  Write-Host "Status: 9+ candidate, pending full Flutter analyze/test/build evidence." -ForegroundColor Green
  exit 0
}

Write-Host "Status: Not 9+ yet." -ForegroundColor Yellow
foreach ($item in $failed) {
  Write-Host " - $($item.Name) failed." -ForegroundColor Yellow
}
foreach ($item in $skippedCritical) {
  Write-Host " - $item was skipped." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Minimum next step: clear every release external gate blocker, then run:"
Write-Host "  flutter analyze"
Write-Host "  flutter test"
Write-Host "  flutter build apk --release"
Write-Host "  real-device Android/iOS smoke, Crashlytics and Analytics DebugView checks"

exit 1
