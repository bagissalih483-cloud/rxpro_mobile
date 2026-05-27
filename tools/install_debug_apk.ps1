param(
  [string]$ProjectRoot = "C:\Users\Casper\Desktop\rxpro_mobile",
  [string]$PackageName = "com.example.rxpro_mobile"
)

$ErrorActionPreference = "Stop"

function Get-AdbCommand {
  $adb = Get-Command adb -ErrorAction SilentlyContinue
  if ($adb) {
    return $adb.Source
  }

  $candidates = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:ANDROID_HOME\platform-tools\adb.exe",
    "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe",
    "C:\Android\platform-tools\adb.exe",
    "C:\platform-tools\adb.exe"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
      return $candidate
    }
  }

  throw "adb.exe bulunamadi. Android SDK platform-tools kurulu olmali veya adb PATH'e eklenmeli."
}

if (!(Test-Path -LiteralPath $ProjectRoot)) {
  throw "Proje klasoru bulunamadi: $ProjectRoot"
}

Set-Location $ProjectRoot
$Adb = Get-AdbCommand

Write-Host "=== fix debug APK kurulum ===" -ForegroundColor Cyan
Write-Host "ADB: $Adb" -ForegroundColor DarkGray

& $Adb devices
$DeviceLines = & $Adb devices | Select-String -Pattern "`tdevice"
if (!$DeviceLines) {
  throw "Telefon bagli gorunmuyor. USB hata ayiklama iznini kontrol et."
}

Write-Host ""
Write-Host "Guncel debug APK build ediliyor..." -ForegroundColor Cyan
flutter build apk --debug

$ApkPath = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-debug.apk"
if (!(Test-Path -LiteralPath $ApkPath)) {
  throw "APK bulunamadi: $ApkPath"
}

Write-Host ""
Write-Host "Eski uygulama durduruluyor ve guncel APK kuruluyor..." -ForegroundColor Cyan
& $Adb shell am force-stop $PackageName | Out-Null
& $Adb install -r $ApkPath

Write-Host ""
Write-Host "=== KURULUM TAMAM ===" -ForegroundColor Green
Write-Host "APK: $ApkPath" -ForegroundColor Green
