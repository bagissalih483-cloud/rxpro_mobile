param(
  [string]$KeyFile = "C:\Users\Casper\Desktop\google-palaces-api.txt",
  [string]$SecretName = "GOOGLE_PLACES_API_KEY"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path -LiteralPath $KeyFile)) {
  throw "API key dosyasi bulunamadi: $KeyFile"
}

$text = Get-Content -LiteralPath $KeyFile -Raw
$match = [regex]::Match($text, "AIza[0-9A-Za-z_-]{20,}")

if (!$match.Success) {
  throw "Dosyada AIza ile baslayan gecerli Google API key bulunamadi."
}

$firebase = Get-Command firebase -ErrorAction SilentlyContinue
if (!$firebase) {
  throw "Firebase CLI bu PowerShell oturumunda bulunamadi. Firebase CLI calisan terminalde bu scripti tekrar calistirin."
}

Push-Location (Join-Path (Split-Path -Parent $PSScriptRoot) "functions")
try {
  $match.Value | & $firebase.Source functions:secrets:set $SecretName
  if ($LASTEXITCODE -ne 0) {
    throw "firebase functions:secrets:set basarisiz oldu. ExitCode=$LASTEXITCODE"
  }
} finally {
  Pop-Location
}

Write-Host "$SecretName secret dosyadan guncellendi. API key ekrana yazdirilmadi." -ForegroundColor Green
