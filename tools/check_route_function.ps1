param(
  [string]$ProjectId = "rxpro-mobile-202605172210",
  [string]$Region = "europe-west1",
  [string]$FunctionName = "calculateBusinessRouteInfo",
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

$url = "https://$Region-$ProjectId.cloudfunctions.net/$FunctionName"
$payload = if ($LiveSample) {
  @{
    data = @{
      originLatitude = 37.9144
      originLongitude = 40.2306
      destinationLatitude = 37.9203
      destinationLongitude = 40.2191
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

  if ($LiveSample) {
    Write-Host "Route live sample passed." -ForegroundColor Green
    Write-Host "Source: $(Get-JsonValue $json.result "source")"
    Write-Host "Travel mode: $(Get-JsonValue $json.result "travelMode")"
    Write-Host "Distance meters: $(Get-JsonValue $json.result "distanceMeters")"
    Write-Host "Duration seconds: $(Get-JsonValue $json.result "durationSeconds")"
  } else {
    if ($json.result.secretConfigured -ne $true) {
      throw "Function is deployed, but GOOGLE_PLACES_API_KEY secret is not configured."
    }

    if ($json.result.secretLooksValid -ne $true) {
      throw "GOOGLE_PLACES_API_KEY secret does not look valid. Store only the raw API key value."
    }

    Write-Host "Route function health-check passed." -ForegroundColor Green
    Write-Host "Source: $(Get-JsonValue $json.result "source")"
    Write-Host "Revision: $(Get-JsonValue $json.result "revision")"
    Write-Host "Secret configured: $(Get-JsonValue $json.result "secretConfigured")"
    Write-Host "Secret looks valid: $(Get-JsonValue $json.result "secretLooksValid")"
  }
} finally {
  Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
}
