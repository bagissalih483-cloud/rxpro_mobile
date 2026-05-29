param(
  [string]$BackupDirectory = "C:\Users\Casper\Desktop\rxpro_release_secrets_backup"
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$backupFullPath = [System.IO.Path]::GetFullPath($BackupDirectory)
if (-not (Test-Path $backupFullPath)) {
  throw "Backup directory was not found: $backupFullPath"
}

$requiredFiles = @(
  @{ Source = 'key.properties'; Destination = 'android\key.properties' },
  @{ Source = 'fix-release-key.jks'; Destination = 'android\app\fix-release-key.jks' },
  @{ Source = 'rxpro-upload-keystore.jks'; Destination = 'android\rxpro-upload-keystore.jks' }
)

foreach ($file in $requiredFiles) {
  $source = Join-Path $backupFullPath $file.Source
  if (-not (Test-Path $source)) {
    throw "Required backup file was not found: $source"
  }
}

foreach ($file in $requiredFiles) {
  $source = Join-Path $backupFullPath $file.Source
  $destination = Join-Path $root $file.Destination
  $destinationDirectory = Split-Path -Parent $destination
  if (-not (Test-Path $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory | Out-Null
  }
  Copy-Item -LiteralPath $source -Destination $destination -Force
}

Write-Host "Android release signing files were restored locally."
Write-Host "They are intentionally ignored by git and must not be shared in source zips."
