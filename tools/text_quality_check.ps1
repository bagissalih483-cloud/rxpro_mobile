param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "== RxPro text quality check =="

$patterns = @(
  [string][char]0x00C3,
  [string][char]0x00C4,
  [string][char]0x00C5,
  [string][char]0x00C2,
  "$([char]0x00E2)$([char]0x20AC)$([char]0x2122)",
  "$([char]0x00E2)$([char]0x20AC)$([char]0x0153)",
  "$([char]0x00E2)$([char]0x20AC)",
  "$([char]0x00EF)$([char]0x00BF)$([char]0x00BD)",
  [string][char]0xFFFD
)

$allowedFiles = @(
  'lib\core\businesses\business_category.dart',
  'lib\core\businesses\business_location_data.dart',
  'lib\core\businesses\business_directory_cache_service.dart'
) | ForEach-Object { (Join-Path $root $_).ToLowerInvariant() }

$roots = @(
  (Join-Path $root 'lib'),
  (Join-Path $root 'functions')
)

$files = @()
foreach ($path in $roots) {
  if (Test-Path -LiteralPath $path) {
    $files += Get-ChildItem -LiteralPath $path -Recurse -File |
      Where-Object {
        $_.Extension -in @('.dart', '.js') -and
        $_.FullName -notmatch '\\node_modules\\' -and
        $allowedFiles -notcontains $_.FullName.ToLowerInvariant()
      }
  }
}

$hits = @()
$utf8 = New-Object System.Text.UTF8Encoding $false, $true
foreach ($file in $files) {
  try {
    $text = [System.IO.File]::ReadAllText($file.FullName, $utf8)
  } catch {
    $relative = $file.FullName.Substring($root.Length).TrimStart('\', '/')
    $hits += "${relative}:1: file is not valid strict UTF-8"
    continue
  }

  $lineNumber = 0
  foreach ($line in ($text -split "`r?`n")) {
    $lineNumber++
    foreach ($pattern in $patterns) {
      if ($line.Contains($pattern)) {
        $relative = $file.FullName.Substring($root.Length).TrimStart('\', '/')
        $hits += "${relative}:${lineNumber}: suspicious mojibake marker '$pattern'"
        break
      }
    }
  }
}

if ($hits.Count -gt 0) {
  $hits | Sort-Object | ForEach-Object { Write-Error $_ }
  throw "Text quality check failed."
}

Write-Host "Text quality check completed."
