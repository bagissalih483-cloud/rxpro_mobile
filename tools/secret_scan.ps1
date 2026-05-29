param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "== RxPro secret scan =="

$blocked = @(
  '-----BEGIN PRIVATE KEY-----',
  '-----BEGIN RSA PRIVATE KEY-----',
  'AIza[0-9A-Za-z_-]{30,}',
  'sk-[A-Za-z0-9_-]{20,}',
  'xox[baprs]-[A-Za-z0-9-]{20,}'
)

$allowListedFiles = @(
  'android/app/google-services.json',
  'ios/Runner/GoogleService-Info.plist',
  'lib/firebase_options.dart',
  'docs/RELEASE_EXTERNAL_DEPENDENCIES.md',
  'tools/secret_scan.ps1'
) | ForEach-Object { (Join-Path $root $_).ToLowerInvariant() }

$files = Get-ChildItem -Recurse -File |
  Where-Object {
    $_.FullName -notmatch '\\.git\\|\\build\\|\\.dart_tool\\|\\.codex_tmp\\|functions\\node_modules\\|emulator_rules_lab\\node_modules\\' -and
    $_.FullName -notmatch '\\.codex_push_worktree\\|\\_debug_freeze_[^\\]*\\' -and
    $allowListedFiles -notcontains $_.FullName.ToLowerInvariant()
  }

$hits = @()
foreach ($file in $files) {
  $text = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
  if ($null -eq $text) { continue }
  foreach ($pattern in $blocked) {
    if ($text -match $pattern) {
      $hits += "$($file.FullName): pattern $pattern"
    }
  }
}

if ($hits.Count -gt 0) {
  $hits | ForEach-Object { Write-Error $_ }
  throw "Secret scan failed."
}

Write-Host "Secret scan completed."
