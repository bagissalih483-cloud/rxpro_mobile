param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[A-Z0-9]{10}$')]
  [string]$TeamId,

  [string]$ExpectedBundleId = 'com.fix.mobile'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $root 'ios\Runner.xcodeproj\project.pbxproj'

if (-not (Test-Path -LiteralPath $projectPath)) {
  throw "Xcode project file was not found: $projectPath"
}

$text = [System.IO.File]::ReadAllText($projectPath)
if ($text -notmatch "PRODUCT_BUNDLE_IDENTIFIER = $([regex]::Escape($ExpectedBundleId));") {
  throw "Expected Runner bundle id was not found: $ExpectedBundleId"
}

if ($text -match 'DEVELOPMENT_TEAM = [A-Z0-9]+;') {
  $updated = [regex]::Replace(
    $text,
    'DEVELOPMENT_TEAM = [A-Z0-9]+;',
    "DEVELOPMENT_TEAM = $TeamId;"
  )
} else {
  $updated = $text -replace
    "PRODUCT_BUNDLE_IDENTIFIER = $([regex]::Escape($ExpectedBundleId));",
    "PRODUCT_BUNDLE_IDENTIFIER = $ExpectedBundleId;`r`n`t`t`t`tDEVELOPMENT_TEAM = $TeamId;"
}

$teamCount = [regex]::Matches($updated, "DEVELOPMENT_TEAM = $TeamId;").Count
if ($teamCount -lt 3) {
  throw "Expected at least 3 Runner build configurations to receive DEVELOPMENT_TEAM, but found $teamCount."
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($projectPath, $updated, $utf8NoBom)

Write-Host "iOS DEVELOPMENT_TEAM set to $TeamId for $teamCount build configuration(s)."
Write-Host "Run: powershell -ExecutionPolicy Bypass -File tools\release_gate_check.ps1"
