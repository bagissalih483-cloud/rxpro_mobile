param(
  [switch]$SkipTests,
  [switch]$SkipAnalyze,
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$OutRoot = "C:\Users\Casper\Desktop\RxPro_Audit_Packages"
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogDir = Join-Path $OutRoot "APK_TEST_INSTALL_$Stamp"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$PubGetLog = Join-Path $LogDir "01_flutter_pub_get.txt"
$TestLog = Join-Path $LogDir "02_flutter_test.txt"
$AnalyzeLog = Join-Path $LogDir "03_flutter_analyze.txt"
$BuildLog = Join-Path $LogDir "04_flutter_build_apk.txt"
$InstallLog = Join-Path $LogDir "05_adb_install_launch.txt"
$RuntimeLog = Join-Path $LogDir "06_runtime_logcat.txt"

function Get-AdbCommand {
  $existing = Get-Command adb -ErrorAction SilentlyContinue
  if ($existing) {
    return $existing.Source
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

  throw "adb bulunamadi. Android SDK platform-tools kurulu olmali veya adb PATH'e eklenmeli."
}

$AdbPath = Get-AdbCommand
$AdbCommand = '"' + $AdbPath + '"'

function Invoke-LoggedCommand {
  param(
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(Mandatory = $true)][string]$LogPath
  )

  $output = & cmd.exe /c "$Command 2>&1"
  $exitCode = $LASTEXITCODE
  $output | Tee-Object -FilePath $LogPath -Append

  return $exitCode
}

function Get-AndroidApplicationId {
  $gradlePath = Join-Path $ProjectRoot "android\app\build.gradle.kts"
  if (!(Test-Path $gradlePath)) {
    return "com.example.rxpro_mobile"
  }

  $match = Select-String `
    -Path $gradlePath `
    -Pattern 'applicationId\s*=\s*"([^"]+)"' `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

  if ($match -and $match.Matches.Count -gt 0) {
    return $match.Matches[0].Groups[1].Value
  }

  return "com.example.rxpro_mobile"
}

Write-Host "=== RXPRO TEST + APK BUILD + TELEFONA KURULUM ===" -ForegroundColor Cyan

Set-Location $ProjectRoot

if (!(Test-Path "pubspec.yaml")) {
  Write-Host "HATA: pubspec.yaml bulunamadi. Yanlis klasordesin." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "=== CIHAZ KONTROLU ===" -ForegroundColor Cyan
$deviceExit = Invoke-LoggedCommand -Command "$AdbCommand devices" -LogPath $InstallLog
if ($deviceExit -ne 0) {
  Write-Host "HATA: adb devices komutu basarisiz." -ForegroundColor Red
  exit 1
}

$DeviceLines = & $AdbPath devices | Select-String -Pattern "`tdevice"
if (!$DeviceLines) {
  Write-Host "HATA: Telefon bagli gorunmuyor." -ForegroundColor Red
  Write-Host "Telefonda USB hata ayiklama acik olmali ve ekrandaki izin kabul edilmeli." -ForegroundColor Yellow
  exit 1
}

Write-Host "Telefon bulundu." -ForegroundColor Green

Write-Host ""
Write-Host "=== FLUTTER PUB GET ===" -ForegroundColor Cyan
$pubExit = Invoke-LoggedCommand -Command "flutter pub get" -LogPath $PubGetLog
if ($pubExit -ne 0) {
  Write-Host "HATA: flutter pub get basarisiz." -ForegroundColor Red
  exit 1
}

if (!$SkipTests) {
  Write-Host ""
  Write-Host "=== FLUTTER TEST ===" -ForegroundColor Cyan
  $testExit = Invoke-LoggedCommand -Command "flutter test" -LogPath $TestLog
  if ($testExit -ne 0) {
    Write-Host "HATA: flutter test basarisiz. APK build durduruldu." -ForegroundColor Red
    Write-Host "Log: $TestLog" -ForegroundColor Yellow
    exit 1
  }
} else {
  "Skipped by -SkipTests" | Set-Content -Path $TestLog
}

$AnalyzeExit = 0
if (!$SkipAnalyze) {
  Write-Host ""
  Write-Host "=== FLUTTER ANALYZE ===" -ForegroundColor Cyan
  $AnalyzeExit = Invoke-LoggedCommand -Command "flutter analyze" -LogPath $AnalyzeLog
  if ($AnalyzeExit -ne 0) {
    Write-Host "UYARI: flutter analyze issue buldu ama build devam edecek." -ForegroundColor Yellow
    Write-Host "Analyze log: $AnalyzeLog" -ForegroundColor Yellow
  } else {
    Write-Host "Analyze temiz gorunuyor." -ForegroundColor Green
  }
} else {
  "Skipped by -SkipAnalyze" | Set-Content -Path $AnalyzeLog
}

$ApkPath = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-debug.apk"
if (!$SkipBuild) {
  Write-Host ""
  Write-Host "=== APK BUILD ===" -ForegroundColor Cyan
  $buildExit = Invoke-LoggedCommand -Command "flutter build apk --debug" -LogPath $BuildLog
  if ($buildExit -ne 0) {
    Write-Host "HATA: APK build basarisiz." -ForegroundColor Red
    Write-Host "Build log: $BuildLog" -ForegroundColor Yellow
    exit 1
  }
} else {
  "Skipped by -SkipBuild" | Set-Content -Path $BuildLog
}

if (!(Test-Path $ApkPath)) {
  Write-Host "HATA: APK dosyasi bulunamadi: $ApkPath" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "=== APK OLUSTU ===" -ForegroundColor Green
Write-Host $ApkPath -ForegroundColor Green

Write-Host ""
Write-Host "=== APK TELEFONA KURULUYOR ===" -ForegroundColor Cyan
$installExit = Invoke-LoggedCommand -Command "$AdbCommand install -r `"$ApkPath`"" -LogPath $InstallLog
if ($installExit -ne 0) {
  Write-Host "HATA: APK telefona kurulamadı." -ForegroundColor Red
  Write-Host "Install log: $InstallLog" -ForegroundColor Yellow
  exit 1
}

Write-Host ""
Write-Host "=== UYGULAMA ACILIYOR ===" -ForegroundColor Cyan
$PackageName = Get-AndroidApplicationId
$ActivityName = "$PackageName/.MainActivity"
$launchExit = Invoke-LoggedCommand `
  -Command "$AdbCommand shell am start -W -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n $ActivityName" `
  -LogPath $InstallLog

if ($launchExit -eq 0) {
  Write-Host ""
  Write-Host "=== APK KURULDU VE UYGULAMA TELEFONDA ACILDI ===" -ForegroundColor Green
} else {
  Write-Host ""
  Write-Host "APK kuruldu ama uygulama otomatik acilamamis olabilir." -ForegroundColor Yellow
  Write-Host "Package/activity kontrol gerekebilir: $ActivityName" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== ACILIS LOGU ALINIYOR ===" -ForegroundColor Cyan
Start-Sleep -Seconds 4
Invoke-LoggedCommand `
  -Command "$AdbCommand logcat -d -t 500 -v time" `
  -LogPath $RuntimeLog | Out-Null
Write-Host "Runtime log: $RuntimeLog" -ForegroundColor Green

Write-Host ""
Write-Host "=== LOG KLASORU ===" -ForegroundColor Cyan
Write-Host $LogDir -ForegroundColor Green

Write-Host ""
Write-Host "=== OZET ===" -ForegroundColor Cyan
if ($SkipTests) {
  Write-Host "flutter test: ATLANDI" -ForegroundColor Yellow
} else {
  Write-Host "flutter test: BASARILI" -ForegroundColor Green
}

if ($SkipAnalyze) {
  Write-Host "flutter analyze: ATLANDI" -ForegroundColor Yellow
} elseif ($AnalyzeExit -eq 0) {
  Write-Host "flutter analyze: TEMIZ" -ForegroundColor Green
} else {
  Write-Host "flutter analyze: ISSUE VAR, LOGA BAK" -ForegroundColor Yellow
}

Write-Host "APK build: BASARILI" -ForegroundColor Green
Write-Host "APK kurulum: BASARILI" -ForegroundColor Green
Write-Host "Acilis logu: $RuntimeLog" -ForegroundColor Green
