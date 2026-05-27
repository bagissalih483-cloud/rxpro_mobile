param(
  [string]$ProjectId = "rxpro-mobile-202605172210",
  [string]$Region = "europe-west1",
  [string]$FunctionName = "searchNearbyDirectoryBusinesses",
  [switch]$LiveSample
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
  # Older shells can ignore output encoding setup safely.
}

function Get-JsonValue {
  param(
    [object]$Object,
    [string]$Name,
    [string]$Fallback = "-"
  )

  if ($null -eq $Object) {
    return $Fallback
  }

  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property -or $null -eq $property.Value) {
    return $Fallback
  }

  return [string]$property.Value
}

function Limit-Text {
  param(
    [string]$Value,
    [int]$MaxLength = 96
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return "-"
  }

  $singleLine = $Value -replace "\s+", " "
  if ($singleLine.Length -le $MaxLength) {
    return $singleLine
  }

  return "$($singleLine.Substring(0, $MaxLength - 3))..."
}

$url = "https://$Region-$ProjectId.cloudfunctions.net/$FunctionName"
$payload = if ($LiveSample) {
  @{
    data = @{
      latitude = 37.9144
      longitude = 40.2306
      radiusMeters = 1500
      categoryId = "beauty_care"
      limit = 3
      debug = $true
    }
  }
} else {
  @{
    data = @{
      healthCheck = $true
    }
  }
}

$temp = New-TemporaryFile
try {
  $payload | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $temp -Encoding UTF8
  $response = & curl.exe -sS -4 --ssl-no-revoke `
    -H "Content-Type: application/json" `
    --data-binary "@$temp" `
    $url

  if ($LASTEXITCODE -ne 0) {
    throw "curl failed with exit code $LASTEXITCODE"
  }

  $json = $response | ConvertFrom-Json
  if ($json.error) {
    $details = ""
    if ($json.error.details) {
      $details = " Details: $($json.error.details | ConvertTo-Json -Depth 8 -Compress)"
    }
    throw "Function returned error: $($json.error.status) - $($json.error.message)$details"
  }

  if (!$json.result) {
    throw "Function response did not include a result payload."
  }

  if (!$LiveSample -and $json.result.secretConfigured -ne $true) {
    throw "Function is deployed, but GOOGLE_PLACES_API_KEY secret is not configured."
  }

  if (!$LiveSample -and $json.result.secretLooksValid -ne $true) {
    throw "GOOGLE_PLACES_API_KEY secret exists, but it does not look like a valid Google API key. Store only the raw API key value."
  }

  if ($LiveSample) {
    $items = @()
    if ($null -ne $json.result.PSObject.Properties["items"] -and $null -ne $json.result.items) {
      $items = @($json.result.items)
    }

    Write-Host "Places live sample passed." -ForegroundColor Green
    Write-Host "Source: $(Get-JsonValue $json.result "source")"
    Write-Host "Category: $(Get-JsonValue $json.result "categoryId")"
    Write-Host "Radius meters: $(Get-JsonValue $json.result "radiusMeters")"
    Write-Host "Items returned: $($items.Count)"

    $items | Select-Object -First 5 | ForEach-Object {
      $name = Limit-Text (Get-JsonValue $_ "name") 42
      $category = Limit-Text (Get-JsonValue $_ "category") 28
      $rating = Get-JsonValue $_ "ratingAvg"
      $address = Limit-Text (Get-JsonValue $_ "address") 76
      Write-Host " - $name | $category | rating=$rating | $address"
    }
  } else {
    $categories = @()
    if ($null -ne $json.result.PSObject.Properties["supportedCategories"] -and $null -ne $json.result.supportedCategories) {
      $categories = @($json.result.supportedCategories)
    }

    Write-Host "Places function health-check passed." -ForegroundColor Green
    Write-Host "Source: $(Get-JsonValue $json.result "source")"
    Write-Host "Revision: $(Get-JsonValue $json.result "revision")"
    Write-Host "Secret configured: $(Get-JsonValue $json.result "secretConfigured")"
    Write-Host "Secret looks valid: $(Get-JsonValue $json.result "secretLooksValid")"
    Write-Host "Supported categories: $($categories -join ', ')"
  }
} finally {
  Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
}
