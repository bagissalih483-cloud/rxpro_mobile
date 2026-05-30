param(
  [switch]$SkipTests,
  [switch]$UseAppCheckDebugProvider,
  [string]$BuildName = "1.0.0",
  [string]$BuildNumber = "1"
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
  )

  & $Command @Arguments
  $exitCode = $LASTEXITCODE
  if ($exitCode -ne 0) {
    throw "Command failed with exit code ${exitCode}: $Command $($Arguments -join ' ')"
  }
}

Write-Host "== fix Android release build =="
Write-Host "Project: $root"

Invoke-Checked flutter pub get

$pubspecPath = Join-Path $root 'pubspec.yaml'
$lockPath = Join-Path $root 'pubspec.lock'
if ((Get-Content -LiteralPath $pubspecPath -Raw) -match '(?m)^\s*firebase_app_check\s*:') {
  if (-not (Test-Path -LiteralPath $lockPath) -or
      (Get-Content -LiteralPath $lockPath -Raw) -notmatch '(?m)^\s*firebase_app_check:') {
    throw "firebase_app_check is declared but pubspec.lock was not updated. Run flutter pub get again and resolve dependency errors before release."
  }
}

Invoke-Checked flutter analyze

if (-not $SkipTests) {
  Invoke-Checked flutter test
}

Invoke-Checked powershell -ExecutionPolicy Bypass -File tools\release_gate_check.ps1 -SkipIos

$buildArgs = @(
  'build',
  'apk',
  '--release',
  '--build-name',
  $BuildName,
  '--build-number',
  $BuildNumber
)

if ($UseAppCheckDebugProvider) {
  Write-Host "Using Firebase App Check debug provider for this local APK."
  $buildArgs += '--dart-define=RXPRO_APP_CHECK_DEBUG=true'
}

Invoke-Checked flutter @buildArgs

$apk = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path $apk)) {
  throw "Release APK was not found at $apk"
}

$item = Get-Item $apk
Write-Host "Release APK ready:"
Write-Host "  $($item.FullName)"
Write-Host "  $([math]::Round($item.Length / 1MB, 2)) MB"
