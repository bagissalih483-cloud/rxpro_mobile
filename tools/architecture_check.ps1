param(
  [int]$MaxDirectSurface = 8,
  [switch]$WarnOnly
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "== RxPro architecture check =="

$pattern = "FirebaseFirestore\.instance|FirebaseAuth\.instance|FieldValue\.|SetOptions\(|\.collection\("
$allowedBoundaryPattern = "\\data\\|\\services\\|\\service\\|\\domain\\|repository\.dart"

function Convert-ToRelativeRepoPath {
  param([string]$Path)

  $relative = $Path.Substring($root.Length).TrimStart('\', '/')
  return $relative -replace '/', '\'
}

$rg = Get-Command rg -ErrorAction SilentlyContinue

if ($rg) {
  $direct = @(
    & rg -l $pattern lib\features lib\core lib\main.dart --glob "*.dart" |
      & rg -v $allowedBoundaryPattern
  )
} else {
  Write-Host "rg not found; using PowerShell fallback scan."

  $candidateFiles = @()
  foreach ($path in @("lib\features", "lib\core")) {
    if (Test-Path $path) {
      $candidateFiles += Get-ChildItem -Path $path -Recurse -Filter *.dart -File
    }
  }
  if (Test-Path "lib\main.dart") {
    $candidateFiles += Get-Item "lib\main.dart"
  }

  $direct = @(
    $candidateFiles |
      Where-Object {
        Select-String -LiteralPath $_.FullName -Pattern $pattern -Quiet
      } |
      ForEach-Object { Convert-ToRelativeRepoPath $_.FullName } |
      Where-Object { $_ -notmatch $allowedBoundaryPattern }
  )
}

$allowedDirect = @(
  "lib\core\app_state\current_user_state_service.dart",
  "lib\core\app_state\follow_cache_warmup_service.dart",
  "lib\core\businesses\business_directory_cache_service.dart",
  "lib\core\realtime\rx_notification_service.dart",
  "lib\core\realtime\rx_push_notification_service.dart",
  "lib\core\session\app_session_controller.dart",
  "lib\features\staff_invites\staff_invite_service.dart",
  "lib\features\stories\business_story_service.dart"
)

$unexpected = @(
  $direct |
    Where-Object { $allowedDirect -notcontains $_ }
)

Write-Host "Direct Firebase surface outside repository/service/domain: $($direct.Count)"

if ($direct.Count -gt $MaxDirectSurface) {
  Write-Host "Allowed maximum: $MaxDirectSurface"
  $direct | Sort-Object | ForEach-Object { Write-Host " - $_" }

  if (-not $WarnOnly) {
    throw "Direct Firebase surface exceeded the architecture budget."
  }
}

if ($unexpected.Count -gt 0) {
  Write-Host "Unexpected direct Firebase files:"
  $unexpected | Sort-Object | ForEach-Object { Write-Host " - $_" }

  if (-not $WarnOnly) {
    throw "Unexpected direct Firebase access outside approved infrastructure surfaces."
  }
}

$featureRootsWithData = @(
  Get-ChildItem -Path lib\features -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName "data") } |
    ForEach-Object { $_.Name }
)

Write-Host "Features with data boundaries: $($featureRootsWithData.Count)"
Write-Host "Architecture check completed."
