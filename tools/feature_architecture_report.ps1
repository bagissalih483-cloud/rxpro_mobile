param(
  [int]$LargeFileKb = 30,
  [switch]$FailOnLargeFiles,
  [switch]$FailOnMissingPresentation
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$featuresRoot = Join-Path $root 'lib\features'
$testRoot = Join-Path $root 'test\features'

Write-Host "== RxPro feature architecture report =="

$features = Get-ChildItem -Path $featuresRoot -Directory | Sort-Object Name
$rows = foreach ($feature in $features) {
  $featurePath = $feature.FullName
  $dartFiles = Get-ChildItem -Path $featurePath -Recurse -Filter *.dart
  $largeFiles = @($dartFiles | Where-Object { $_.Length -gt ($LargeFileKb * 1024) })
  $featureTestPath = Join-Path $testRoot $feature.Name
  $testFiles = if (Test-Path $featureTestPath) {
    @(Get-ChildItem -Path $featureTestPath -Recurse -Filter *.dart)
  } else {
    @()
  }

  [PSCustomObject]@{
    Feature = $feature.Name
    DartFiles = @($dartFiles).Count
    HasData = Test-Path (Join-Path $featurePath 'data')
    HasDomain = Test-Path (Join-Path $featurePath 'domain')
    HasPresentation = Test-Path (Join-Path $featurePath 'presentation')
    TestFiles = @($testFiles).Count
    LargeFiles = $largeFiles.Count
  }
}

$rows | Format-Table -AutoSize

$largeFileRows = Get-ChildItem -Path $featuresRoot -Recurse -Filter *.dart |
  Where-Object { $_.Length -gt ($LargeFileKb * 1024) } |
  Sort-Object Length -Descending |
  Select-Object @{Name='Kb';Expression={[math]::Round($_.Length / 1KB, 1)}}, FullName

if ($largeFileRows) {
  Write-Host ""
  Write-Host "Large Dart files over ${LargeFileKb}KB:"
  $largeFileRows | Format-Table -AutoSize
}

$missingPresentation = @($rows | Where-Object { -not $_.HasPresentation })
$largeFileCount = @($largeFileRows).Count

Write-Host ""
Write-Host "Features: $($rows.Count)"
Write-Host "Features without presentation: $($missingPresentation.Count)"
Write-Host "Large files over ${LargeFileKb}KB: $largeFileCount"

if ($FailOnMissingPresentation -and $missingPresentation.Count -gt 0) {
  throw "Feature presentation boundary is missing in $($missingPresentation.Count) feature(s)."
}

if ($FailOnLargeFiles -and $largeFileCount -gt 0) {
  throw "$largeFileCount Dart file(s) exceed the ${LargeFileKb}KB budget."
}
