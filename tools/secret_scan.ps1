param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "== RxPro secret scan =="

function Get-RelativePathForGit {
  param([Parameter(Mandatory = $true)][string]$FullPath)

  $rootWithSeparator = $root.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  $full = [System.IO.Path]::GetFullPath($FullPath)
  if (-not $full.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $full
  }

  return $full.Substring($rootWithSeparator.Length).Replace('\', '/')
}

function Test-GitTracked {
  param([Parameter(Mandatory = $true)][System.IO.FileInfo]$File)

  $relative = Get-RelativePathForGit -FullPath $File.FullName
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    git ls-files --error-unmatch -- $relative *> $null
    return $LASTEXITCODE -eq 0
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
}

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

$blockedFileNames = @(
  'key.properties',
  'local.properties',
  'google-places-api.txt',
  'google-palaces-api.txt'
)

$blockedFilePatterns = @(
  '*.jks',
  '*.keystore',
  '*.p12',
  '*.pem'
)

$files = Get-ChildItem -Recurse -File |
  Where-Object {
    $_.FullName -notmatch '\\.git\\|\\build\\|\\.dart_tool\\|\\.codex_tmp\\|functions\\node_modules\\|emulator_rules_lab\\node_modules\\' -and
    $_.FullName -notmatch '\\.codex_push_worktree\\|\\_debug_freeze_[^\\]*\\' -and
    $allowListedFiles -notcontains $_.FullName.ToLowerInvariant()
}

$hits = @()
foreach ($file in $files) {
  $name = $file.Name
  $skipContentScan = $false
  if ($blockedFileNames -contains $name) {
    if (Test-GitTracked -File $file) {
      $hits += "$($file.FullName): forbidden tracked local secret file"
    }
    $skipContentScan = $true
  }

  if (-not $skipContentScan) {
    foreach ($pattern in $blockedFilePatterns) {
      if ($name -like $pattern) {
        if (Test-GitTracked -File $file) {
          $hits += "$($file.FullName): forbidden tracked signing or secret file"
        }
        $skipContentScan = $true
        break
      }
    }
  }

  if ($skipContentScan) { continue }

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
