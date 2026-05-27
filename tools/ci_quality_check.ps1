param(
  [switch]$SkipFlutter,
  [switch]$SkipFunctions,
  [switch]$SkipBuild,
  [switch]$EnforceFormat
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "== RxPro CI quality gate =="

Write-Host "Checking architecture boundaries..."
powershell -ExecutionPolicy Bypass -File tools\architecture_check.ps1

if (-not $SkipFunctions) {
  Write-Host "Checking Cloud Functions syntax..."
  node --check functions/index.js
}

if (-not $SkipFlutter) {
  Write-Host "Resolving Flutter dependencies..."
  flutter pub get

  if ($EnforceFormat) {
    Write-Host "Checking Dart format..."
    dart format --output=none --set-exit-if-changed lib test
  } else {
    Write-Host "Normalizing Dart format..."
    dart format lib test
  }

  Write-Host "Analyzing Flutter project..."
  flutter analyze

  Write-Host "Running tests..."
  flutter test

  if (-not $SkipBuild) {
    Write-Host "Building debug APK..."
    flutter build apk --debug
  }
}

Write-Host "CI quality gate completed."
