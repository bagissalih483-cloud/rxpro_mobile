param(
  [string]$OutputPath,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $OutputPath = Join-Path (Split-Path -Parent $root) "rxpro_mobile_clean_$timestamp.zip"
}

$outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $outputFullPath
if (-not (Test-Path $outputDirectory)) {
  New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

if (Test-Path $outputFullPath) {
  if (-not $Force) {
    throw "Output zip already exists: $outputFullPath. Re-run with -Force to overwrite it."
  }
  Remove-Item -LiteralPath $outputFullPath -Force
}

$excludedDirectories = @(
  '.git',
  '.dart_tool',
  '.dart_appdata',
  '.dart_localappdata',
  '.codex_tmp',
  '.codex_push_worktree',
  '.idea',
  '.firebase',
  '.gradle',
  '.kotlin',
  '.pub',
  '.pub-cache',
  'build',
  'coverage',
  'node_modules',
  'RxPro_Audit_Packages'
)

$excludedDirectoryPrefixes = @(
  '_debug_freeze_',
  'EXPLORE_FREEZE_DEBUG_',
  'FREEZE_RUNTIME_DEBUG_',
  'migrate_working_dir'
)

$excludedFileNames = @(
  '.env',
  'firebase-debug.log',
  'firestore-debug.log',
  'google-places-api.txt',
  'google-palaces-api.txt',
  'key.properties',
  'local.properties',
  'ui-debug.log'
)

$excludedFilePatterns = @(
  '*.bak',
  '*.bak_*',
  '*.jks',
  '*.keystore',
  '*.log',
  '*.p12',
  '*.pem',
  '*.tmp',
  '*.zip',
  'app.*.map.json',
  'app.*.symbols'
)

function Get-RelativeArchivePath {
  param([Parameter(Mandatory = $true)][string]$FullPath)

  $rootWithSeparator = $root.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  $full = [System.IO.Path]::GetFullPath($FullPath)
  if (-not $full.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Path is outside the workspace: $full"
  }

  return $full.Substring($rootWithSeparator.Length).Replace('\', '/')
}

function Test-ExcludedPath {
  param([Parameter(Mandatory = $true)][System.IO.FileInfo]$File)

  $relative = Get-RelativeArchivePath -FullPath $File.FullName
  $segments = $relative -split '/'

  foreach ($segment in $segments) {
    if ($excludedDirectories -contains $segment) {
      return $true
    }
    foreach ($prefix in $excludedDirectoryPrefixes) {
      if ($segment.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
      }
    }
  }

  $name = $File.Name
  if ($excludedFileNames -contains $name) {
    return $true
  }

  if ($name.StartsWith('.env.', [System.StringComparison]::OrdinalIgnoreCase)) {
    return $true
  }

  foreach ($pattern in $excludedFilePatterns) {
    if ($name -like $pattern) {
      return $true
    }
  }

  return $false
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$files = Get-ChildItem -Path $root -Recurse -Force -File |
  Where-Object { -not (Test-ExcludedPath -File $_) } |
  Sort-Object FullName

$archive = [System.IO.Compression.ZipFile]::Open($outputFullPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
  foreach ($file in $files) {
    $entryName = Get-RelativeArchivePath -FullPath $file.FullName
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName) | Out-Null
  }
} finally {
  $archive.Dispose()
}

$forbiddenEntries = @()
$archive = [System.IO.Compression.ZipFile]::OpenRead($outputFullPath)
try {
  foreach ($entry in $archive.Entries) {
    $segments = $entry.FullName -split '/'
    if ($segments | Where-Object { $excludedDirectories -contains $_ }) {
      $forbiddenEntries += $entry.FullName
      continue
    }
    if ($entry.Name -eq 'key.properties' -or $entry.Name -eq 'local.properties' -or $entry.Name -like '*.jks' -or $entry.Name -like '*.keystore' -or $entry.Name -like '*.p12' -or $entry.Name -like '*.pem') {
      $forbiddenEntries += $entry.FullName
    }
  }
} finally {
  $archive.Dispose()
}

if ($forbiddenEntries.Count -gt 0) {
  $forbiddenEntries | ForEach-Object { Write-Error "Forbidden zip entry: $_" }
  throw "Clean zip verification failed."
}

$item = Get-Item $outputFullPath
Write-Host "Clean source zip ready:"
Write-Host "  $($item.FullName)"
Write-Host "  $([math]::Round($item.Length / 1MB, 2)) MB"
Write-Host "  $($files.Count) entries"
