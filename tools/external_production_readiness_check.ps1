param(
  [switch]$SkipIos,
  [switch]$SkipManualConfirmations
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$failures = @()
$warnings = @()

function Add-Failure($Message) {
  $script:failures += $Message
}

function Add-Warning($Message) {
  $script:warnings += $Message
}

function Test-Contains {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Pattern,
    [Parameter(Mandatory = $true)][string]$Failure
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    Add-Failure "$Path is missing."
    return
  }

  $text = Get-Content -LiteralPath $Path -Raw
  if ($text -notmatch $Pattern) {
    Add-Failure $Failure
  }
}

Write-Host "== RxPro external production readiness check =="

$pubspecPath = Join-Path $root 'pubspec.yaml'
$lockPath = Join-Path $root 'pubspec.lock'
if (Test-Path -LiteralPath $pubspecPath) {
  $pubspec = Get-Content -LiteralPath $pubspecPath -Raw
  if ($pubspec -match '(?m)^\s*firebase_app_check\s*:') {
    Test-Contains `
      -Path $lockPath `
      -Pattern '(?m)^\s*firebase_app_check:' `
      -Failure 'pubspec.yaml declares firebase_app_check but pubspec.lock does not. Run flutter pub get before release.'
  }
} else {
  Add-Failure 'pubspec.yaml is missing.'
}

Test-Contains `
  -Path (Join-Path $root 'lib/core/security/firebase_app_check_bootstrap.dart') `
  -Pattern 'AndroidProvider\.playIntegrity' `
  -Failure 'Android App Check release provider is not Play Integrity.'

Test-Contains `
  -Path (Join-Path $root 'lib/core/security/firebase_app_check_bootstrap.dart') `
  -Pattern 'AppleProvider\.appAttestWithDeviceCheckFallback' `
  -Failure 'Apple App Check release provider is not App Attest with DeviceCheck fallback.'

$releaseArgs = @('-ExecutionPolicy', 'Bypass', '-File', (Join-Path $root 'tools\release_gate_check.ps1'))
if ($SkipIos) {
  $releaseArgs += '-SkipIos'
}

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
  $releaseOutput = & powershell @releaseArgs 2>&1
  $releaseExitCode = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}
$releaseOutput | ForEach-Object { Write-Host $_ }
if ($releaseExitCode -ne 0) {
  Add-Failure 'Release gate is not clean. See release gate output above.'
}

$requiredDocs = @(
  'docs\APP_STORE_PRIVACY_LABEL_DRAFT.md',
  'docs\CLEAN_ZIP_AND_SECRET_HANDOFF.md',
  'docs\FIX_APPSTORE_RELEASE_CHECKLIST.md',
  'docs\RELEASE_EXTERNAL_DEPENDENCIES.md',
  'docs\SECURITY_PUBLIC_DATA_AND_APP_CHECK_PLAN.md',
  'docs\PRODUCTION_EXTERNAL_VERIFICATION.md'
)

foreach ($relativePath in $requiredDocs) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $relativePath))) {
    Add-Failure "$relativePath is missing."
  }
}

if (-not $SkipManualConfirmations) {
  $manualPath = Join-Path $root 'docs\PRODUCTION_EXTERNAL_VERIFICATION.md'
  $hasManualStatusSummary = Test-Path -LiteralPath (Join-Path $root 'tools\production_manual_status.ps1')
  if (Test-Path -LiteralPath $manualPath) {
    $manualText = Get-Content -LiteralPath $manualPath -Raw
    $openItems = [regex]::Matches($manualText, '(?m)^\s*-\s*\[\s\]\s+(.+)$')
    if ($openItems.Count -gt 0) {
      Add-Failure "Manual production verification still has $($openItems.Count) open item(s)."
      if (-not $hasManualStatusSummary) {
        foreach ($item in $openItems | Select-Object -First 8) {
          Add-Warning "Open manual item: $($item.Groups[1].Value)"
        }
        if ($openItems.Count -gt 8) {
          Add-Warning "Additional open manual items: $($openItems.Count - 8)"
        }
      }
    }
  }

  $manualStatusPath = Join-Path $root 'tools\production_manual_status.ps1'
  if (Test-Path -LiteralPath $manualStatusPath) {
    Write-Host ""
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
      $manualStatusOutput = & powershell -ExecutionPolicy Bypass -File $manualStatusPath 2>&1
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
    $manualStatusOutput | ForEach-Object { Write-Host $_ }
  }
}

if ($warnings.Count -gt 0) {
  Write-Host ""
  Write-Host "Readiness warnings:" -ForegroundColor Yellow
  foreach ($warning in $warnings) {
    Write-Host " - $warning" -ForegroundColor Yellow
  }
}

if ($failures.Count -gt 0) {
  Write-Host ""
  Write-Host "Production readiness blockers:" -ForegroundColor Yellow
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Yellow
  }
  Write-Error "External production readiness failed with $($failures.Count) blocker(s)."
}

Write-Host "External production readiness check completed."
