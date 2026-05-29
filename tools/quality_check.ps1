param(
  [switch]$SkipFlutter,
  [switch]$SkipFunctions
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "== RxPro quality check =="

Write-Host "Checking architecture boundaries..."
powershell -ExecutionPolicy Bypass -File tools\architecture_check.ps1

if (-not $SkipFunctions) {
  Write-Host "Checking Cloud Functions syntax..."
  $functionJsFiles = Get-ChildItem -Path functions -Recurse -Filter *.js -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' }
  foreach ($file in $functionJsFiles) {
    node --check $file.FullName
    if ($LASTEXITCODE -ne 0) {
      throw "Cloud Functions syntax check failed: $($file.FullName)"
    }
  }
}

if (-not $SkipFlutter) {
  Write-Host "Formatting Dart files..."
  flutter format lib test

  Write-Host "Analyzing Flutter project..."
  flutter analyze

  Write-Host "Running tests..."
  flutter test
}

Write-Host "Quality check completed."
