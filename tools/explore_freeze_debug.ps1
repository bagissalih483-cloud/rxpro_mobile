$ErrorActionPreference = "Stop"

param(
  [string]$ProjectRoot = "C:\Users\Casper\Desktop\rxpro_mobile",
  [string]$OutRoot = "C:\Users\Casper\Desktop\RxPro_Audit_Packages",
  [string]$PackageName = "com.fix.mobile",
  [string]$ActivityName = "com.fix.mobile/.MainActivity",
  [int]$CaptureSeconds = 40
)

function Get-AdbCommand {
  $adb = Get-Command adb -ErrorAction SilentlyContinue
  if ($adb) {
    return $adb.Source
  }

  $candidates = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:ANDROID_HOME\platform-tools\adb.exe",
    "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
      return $candidate
    }
  }

  throw "adb.exe bulunamadi. Android SDK platform-tools PATH icinde olmali."
}

if (!(Test-Path -LiteralPath $ProjectRoot)) {
  throw "Proje klasoru bulunamadi: $ProjectRoot"
}

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogDir = Join-Path $OutRoot "EXPLORE_FREEZE_DEBUG_$Stamp"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$Adb = Get-AdbCommand
Set-Location $ProjectRoot

Write-Host "=== fix Explore freeze debug ===" -ForegroundColor Cyan
Write-Host "Log klasoru: $LogDir" -ForegroundColor Green

& $Adb devices | Tee-Object -FilePath (Join-Path $LogDir "01_adb_devices.txt")
$deviceLines = & $Adb devices | Select-String -Pattern "`tdevice"
if (!$deviceLines) {
  throw "Telefon bagli gorunmuyor. USB hata ayiklama iznini kontrol edin."
}

& $Adb logcat -c
& $Adb shell am force-stop $PackageName | Out-Null

Write-Host "Uygulama aciliyor..." -ForegroundColor Cyan
& $Adb shell am start -W -n $ActivityName |
  Tee-Object -FilePath (Join-Path $LogDir "02_launch.txt")

Write-Host "Simdi telefonda Kesfet ekraninda donma yapan islemi tekrar edin." -ForegroundColor Yellow
Write-Host "$CaptureSeconds saniye log kaydedilecek..." -ForegroundColor Yellow
Start-Sleep -Seconds $CaptureSeconds

$fullLog = Join-Path $LogDir "03_logcat_full.txt"
$filteredLog = Join-Path $LogDir "04_logcat_filtered.txt"

& $Adb logcat -d | Tee-Object -FilePath $fullLog | Out-Null

Select-String -Path $fullLog -Pattern @(
  "FIX_EXPLORE",
  "Choreographer",
  "Skipped",
  "I/flutter",
  "Dart",
  "Exception",
  "Error",
  "FirebaseException",
  "ANR",
  "Input dispatch",
  "FusedLocation",
  "GoogleApiManager",
  "FirebaseContextProvider",
  $PackageName
) | Set-Content -Path $filteredLog -Encoding UTF8

& $Adb shell dumpsys gfxinfo $PackageName |
  Tee-Object -FilePath (Join-Path $LogDir "05_gfxinfo.txt") | Out-Null
& $Adb shell dumpsys meminfo $PackageName |
  Tee-Object -FilePath (Join-Path $LogDir "06_meminfo.txt") | Out-Null
& $Adb shell dumpsys cpuinfo |
  Tee-Object -FilePath (Join-Path $LogDir "07_cpuinfo.txt") | Out-Null
& $Adb shell dumpsys activity activities |
  Tee-Object -FilePath (Join-Path $LogDir "08_activity.txt") | Out-Null
& $Adb shell dumpsys package $PackageName |
  Tee-Object -FilePath (Join-Path $LogDir "09_package.txt") | Out-Null

$zipPath = "$LogDir.zip"
if (Test-Path -LiteralPath $zipPath) {
  Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -Path (Join-Path $LogDir "*") -DestinationPath $zipPath

Write-Host ""
Write-Host "=== Debug paketi hazir ===" -ForegroundColor Green
Write-Host $zipPath -ForegroundColor Green
