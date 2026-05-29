param(
  [string]$ChecklistPath = "docs\PRODUCTION_EXTERNAL_VERIFICATION.md",
  [switch]$Json
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$fullPath = Join-Path $root $ChecklistPath
if (-not (Test-Path -LiteralPath $fullPath)) {
  throw "Checklist not found: $ChecklistPath"
}

$currentSection = 'Uncategorized'
$sections = [ordered]@{}

foreach ($line in Get-Content -LiteralPath $fullPath) {
  $heading = [regex]::Match($line, '^\s*##\s+(.+?)\s*$')
  if ($heading.Success) {
    $currentSection = $heading.Groups[1].Value.Trim()
    if (-not $sections.Contains($currentSection)) {
      $sections[$currentSection] = [ordered]@{
        Done = 0
        Open = 0
        OpenItems = @()
      }
    }
    continue
  }

  $item = [regex]::Match($line, '^\s*-\s*\[( |x|X)\]\s+(.+?)\s*$')
  if (-not $item.Success) {
    continue
  }

  if (-not $sections.Contains($currentSection)) {
    $sections[$currentSection] = [ordered]@{
      Done = 0
      Open = 0
      OpenItems = @()
    }
  }

  $status = $item.Groups[1].Value
  $text = $item.Groups[2].Value.Trim()
  if ($status -match 'x|X') {
    $sections[$currentSection].Done += 1
  } else {
    $sections[$currentSection].Open += 1
    $sections[$currentSection].OpenItems += $text
  }
}

$totalDone = 0
$totalOpen = 0
$sectionSummaries = @()

foreach ($sectionName in $sections.Keys) {
  $section = $sections[$sectionName]
  $done = [int]$section.Done
  $open = [int]$section.Open
  $total = $done + $open
  if ($total -eq 0) {
    continue
  }

  $totalDone += $done
  $totalOpen += $open
  $sectionSummaries += [pscustomobject]@{
    name = $sectionName
    done = $done
    open = $open
    total = $total
    openItems = @($section.OpenItems)
  }
}

$grandTotal = $totalDone + $totalOpen
$result = [pscustomobject]@{
  checklistPath = $ChecklistPath
  done = $totalDone
  open = $totalOpen
  total = $grandTotal
  sections = $sectionSummaries
}

if ($Json) {
  $result | ConvertTo-Json -Depth 6
  if ($totalOpen -gt 0) {
    exit 1
  }
  exit 0
}

Write-Host "== RxPro manual production verification status =="

foreach ($section in $sectionSummaries) {
  Write-Host ""
  Write-Host "$($section.name): $($section.done)/$($section.total) complete, $($section.open) open"
  foreach ($openItem in $section.OpenItems | Select-Object -First 5) {
    Write-Host " - $openItem"
  }
  if ($section.open -gt 5) {
    Write-Host " - ... $($section.open - 5) more"
  }
}

Write-Host ""
Write-Host "Total: $totalDone/$grandTotal complete, $totalOpen open"

if ($totalOpen -gt 0) {
  exit 1
}
