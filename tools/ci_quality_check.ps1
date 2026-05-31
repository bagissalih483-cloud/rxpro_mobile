param(
  [switch]$SkipFlutter,
  [switch]$SkipFunctions,
  [switch]$SkipRules,
  [switch]$SkipBuild,
  [switch]$SkipStateScaleBudget,
  [switch]$EnforceFormat
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "== RxPro CI quality gate =="

function Invoke-CheckedCommand {
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

Write-Host "Checking architecture boundaries..."
Invoke-CheckedCommand powershell -ExecutionPolicy Bypass -File tools\architecture_check.ps1

Write-Host "Checking user-visible text quality..."
Invoke-CheckedCommand powershell -ExecutionPolicy Bypass -File tools\text_quality_check.ps1

Write-Host "Running secret scan..."
Invoke-CheckedCommand powershell -ExecutionPolicy Bypass -File tools\secret_scan.ps1

Write-Host "Checking public data matrix..."
Invoke-CheckedCommand powershell -ExecutionPolicy Bypass -File tools\public_data_matrix_check.ps1

if (-not $SkipStateScaleBudget) {
  Write-Host "Checking state and scalability budgets..."
  Invoke-CheckedCommand powershell -ExecutionPolicy Bypass -File tools\state_scalability_budget_check.ps1
}

if (-not $SkipFunctions) {
  Write-Host "Checking Cloud Functions syntax..."
  $functionJsFiles = Get-ChildItem -Path functions -Recurse -Filter *.js -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' }
  foreach ($file in $functionJsFiles) {
    Invoke-CheckedCommand node --check $file.FullName
  }
}

if (-not $SkipRules) {
  Write-Host "Running Firebase rules tests..."
  Invoke-CheckedCommand powershell -ExecutionPolicy Bypass -File tools\run_rules_tests.ps1
}

if (-not $SkipFlutter) {
  Write-Host "Resolving Flutter dependencies..."
  Invoke-CheckedCommand flutter pub get

  if ($EnforceFormat) {
    Write-Host "Checking Dart format..."
    Invoke-CheckedCommand dart format --output=none --set-exit-if-changed lib test
  } else {
    Write-Host "Normalizing Dart format..."
    Invoke-CheckedCommand dart format lib test
  }

  Write-Host "Analyzing Flutter project..."
  Invoke-CheckedCommand flutter analyze

  Write-Host "Running tests..."
  Invoke-CheckedCommand flutter test

  if (-not $SkipBuild) {
    Write-Host "Building debug APK..."
    Invoke-CheckedCommand flutter build apk --debug
  }
}

Write-Host "CI quality gate completed."
