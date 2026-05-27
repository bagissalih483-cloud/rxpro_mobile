param(
  [string[]]$Paths = @("lib", "functions", "docs", "README.md"),
  [switch]$CountOnly
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$mojibakeChars = @(
  [char]0x00C3,
  [char]0x00C4,
  [char]0x00C5,
  [char]0x00E2,
  [char]0x00F0,
  [char]0xFFFD
)
$pattern = ($mojibakeChars | ForEach-Object {
  [regex]::Escape([string]$_)
}) -join "|"
$commonArgs = @(
  "--glob", "!functions/node_modules/**",
  "--glob", "!build/**",
  "--glob", "!.dart_tool/**",
  "--glob", "!.git/**",
  "--glob", "!android/.gradle/**",
  "--glob", "!ios/Pods/**"
)

Write-Host "== RxPro mojibake scan =="

$rg = Get-Command rg -ErrorAction SilentlyContinue

if ($rg) {
  if ($CountOnly) {
    & rg --count $pattern @Paths @commonArgs
  } else {
    & rg --line-number $pattern @Paths @commonArgs
  }

  if ($LASTEXITCODE -eq 1) {
    Write-Host "No mojibake signatures found."
    exit 0
  }

  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  exit 0
}

Write-Host "rg not found; using PowerShell fallback scan."

$excludedFragments = @(
  "\functions\node_modules\",
  "\build\",
  "\.dart_tool\",
  "\.git\",
  "\android\.gradle\",
  "\ios\Pods\"
)

$candidateFiles = @()
foreach ($path in $Paths) {
  if (-not (Test-Path $path)) {
    continue
  }

  $item = Get-Item $path
  if ($item.PSIsContainer) {
    $candidateFiles += Get-ChildItem -Path $item.FullName -Recurse -File
  } else {
    $candidateFiles += $item
  }
}

$candidateFiles = @(
  $candidateFiles |
    Where-Object {
      $fullName = $_.FullName
      -not ($excludedFragments | Where-Object { $fullName.Contains($_) })
    }
)

$matches = @(
  $candidateFiles |
    ForEach-Object {
      Select-String -LiteralPath $_.FullName -Pattern $pattern -ErrorAction SilentlyContinue
    }
)

if ($matches.Count -eq 0) {
  Write-Host "No mojibake signatures found."
  exit 0
}

if ($CountOnly) {
  $matches |
    Group-Object Path |
    Sort-Object Name |
    ForEach-Object {
      $relative = $_.Name.Substring($root.Length).TrimStart('\', '/') -replace '/', '\'
      Write-Host "$relative`:$($_.Count)"
    }
} else {
  $matches |
    ForEach-Object {
      $relative = $_.Path.Substring($root.Length).TrimStart('\', '/') -replace '/', '\'
      Write-Host "$relative`:$($_.LineNumber):$($_.Line)"
    }
}
