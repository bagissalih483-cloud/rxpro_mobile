param(
  [string]$ProjectRoot = "C:\Users\Casper\Desktop\rxpro_mobile",
  [string]$OutRoot = "C:\Users\Casper\Desktop\RxPro_Audit_Packages",
  [string]$PackageName = "com.fix.mobile",
  [string]$ActivityName = "com.fix.mobile/.MainActivity",
  [int]$CaptureSeconds = 60,
  [int]$TailLines = 12000,
  [bool]$SafeRenderMode = $false
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

function Invoke-AdbToFile {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string[]]$Arguments
  )

  try {
    & $script:Adb @Arguments 2>&1 |
      Out-File -FilePath $FilePath -Encoding utf8
  } catch {
    "COMMAND FAILED: adb $($Arguments -join ' ')" |
      Out-File -FilePath $FilePath -Encoding utf8
    $_ | Out-File -FilePath $FilePath -Encoding utf8 -Append
  }
}

if (!(Test-Path -LiteralPath $ProjectRoot)) {
  throw "Proje klasoru bulunamadi: $ProjectRoot"
}

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogDir = Join-Path $OutRoot "FREEZE_RUNTIME_DEBUG_$Stamp"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$script:Adb = Get-AdbCommand
Set-Location $ProjectRoot

$DevicesLog = Join-Path $LogDir "01_adb_devices.txt"
$LaunchLog = Join-Path $LogDir "02_launch.txt"
$FilteredLog = Join-Path $LogDir "03_filtered_logcat.txt"
$FullLog = Join-Path $LogDir "04_full_logcat_tail.txt"
$ActivityTopLog = Join-Path $LogDir "05_activity_top.txt"
$ActivityAllLog = Join-Path $LogDir "06_activity_all.txt"
$GfxLog = Join-Path $LogDir "07_gfxinfo.txt"
$MemLog = Join-Path $LogDir "08_meminfo.txt"
$CpuLog = Join-Path $LogDir "09_cpuinfo.txt"
$WindowLog = Join-Path $LogDir "10_window.txt"
$PackageLog = Join-Path $LogDir "11_package.txt"
$AnrLog = Join-Path $LogDir "12_anr_trace_probe.txt"
$ScreenshotPath = Join-Path $LogDir "13_screen.png"
$ThreadsLog = Join-Path $LogDir "14_threads.txt"
$SummaryLog = Join-Path $LogDir "00_readme.txt"
$ZipPath = "$LogDir.zip"

Write-Host "=== fix runtime freeze debug ===" -ForegroundColor Cyan
Write-Host "ADB: $Adb" -ForegroundColor DarkGray
Write-Host "Log klasoru: $LogDir" -ForegroundColor Green

& $Adb devices | Tee-Object -FilePath $DevicesLog
$DeviceLines = & $Adb devices | Select-String -Pattern "`tdevice"
if (!$DeviceLines) {
  throw "Telefon bagli gorunmuyor. USB hata ayiklama iznini kontrol et."
}

@"
Package: $PackageName
Activity: $ActivityName
CaptureSeconds: $CaptureSeconds
TailLines: $TailLines
SafeRenderMode: $SafeRenderMode
StartedAt: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Talimat:
1. Script uygulamayi yeniden baslatir.
2. Telefonda donma yasadigin ekrani tekrar olustur.
3. Bu zip dosyasini Codex'e gonder.
"@ | Out-File -FilePath $SummaryLog -Encoding utf8

Write-Host ""
Write-Host "Log temizleniyor ve uygulama yeniden baslatiliyor..." -ForegroundColor Cyan
& $Adb logcat -c 2>&1 | Tee-Object -FilePath $LaunchLog
& $Adb shell am force-stop $PackageName 2>&1 |
  Tee-Object -FilePath $LaunchLog -Append

$StartArgs = @("shell", "am", "start", "-W")
if ($SafeRenderMode) {
  $StartArgs += @(
    "--ez", "enable-software-rendering", "true",
    "--ez", "enable-impeller", "false"
  )
}
$StartArgs += @("-n", $ActivityName)

& $Adb @StartArgs 2>&1 |
  Tee-Object -FilePath $LaunchLog -Append

if ($LASTEXITCODE -ne 0) {
  Write-Host "Activity launch basarisiz gorundu. Monkey fallback deneniyor..." -ForegroundColor Yellow
  & $Adb shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1 2>&1 |
    Tee-Object -FilePath $LaunchLog -Append
}

Write-Host ""
Write-Host "$CaptureSeconds saniye izleniyor. Bu sirada telefonda donan akisi tekrar et." -ForegroundColor Yellow
Start-Sleep -Seconds $CaptureSeconds

Write-Host ""
Write-Host "Runtime loglari aliniyor..." -ForegroundColor Cyan

Invoke-AdbToFile -FilePath $FullLog -Arguments @(
  "logcat", "-d", "-v", "threadtime"
)

Select-String -Path $FullLog -Pattern @(
  $PackageName,
  "Flutter",
  "I/flutter",
  "Dart",
  "Exception",
  "Error",
  "FATAL EXCEPTION",
  "AndroidRuntime",
  "Firebase",
  "Firestore",
  "GoogleApi",
  "Choreographer",
  "Skipped",
  "Input dispatch",
  "ANR",
  "Application Not Responding",
  "FIX_EXPLORE",
  "FIX_SESSION",
  "FIX_",
  "RxPro"
) | Out-File -FilePath $FilteredLog -Encoding utf8

Invoke-AdbToFile -FilePath $ActivityTopLog -Arguments @(
  "shell", "dumpsys", "activity", "top"
)
Invoke-AdbToFile -FilePath $ActivityAllLog -Arguments @(
  "shell", "dumpsys", "activity", "activities"
)
Invoke-AdbToFile -FilePath $GfxLog -Arguments @(
  "shell", "dumpsys", "gfxinfo", $PackageName
)
Invoke-AdbToFile -FilePath $MemLog -Arguments @(
  "shell", "dumpsys", "meminfo", $PackageName
)
Invoke-AdbToFile -FilePath $CpuLog -Arguments @(
  "shell", "dumpsys", "cpuinfo"
)
Invoke-AdbToFile -FilePath $WindowLog -Arguments @(
  "shell", "dumpsys", "window", "windows"
)
Invoke-AdbToFile -FilePath $PackageLog -Arguments @(
  "shell", "dumpsys", "package", $PackageName
)

$AppPid = (& $Adb shell pidof $PackageName 2>$null).Trim()
if ($AppPid) {
  Invoke-AdbToFile -FilePath $ThreadsLog -Arguments @(
    "shell", "ps", "-T", "-p", $AppPid
  )
} else {
  "PID bulunamadi: $PackageName" | Out-File -FilePath $ThreadsLog -Encoding utf8
}

$RemoteScreenshot = "/sdcard/rxpro_freeze_screen_$Stamp.png"
try {
  & $Adb shell screencap -p $RemoteScreenshot 2>&1 | Out-Null
  & $Adb pull $RemoteScreenshot $ScreenshotPath 2>&1 | Out-Null
  & $Adb shell rm $RemoteScreenshot 2>&1 | Out-Null
} catch {
  "SCREENSHOT FAILED: $($_.Exception.Message)" |
    Out-File -FilePath "$ScreenshotPath.txt" -Encoding utf8
}

@"
=== dumpsys activity anr ===
"@ | Out-File -FilePath $AnrLog -Encoding utf8
& $Adb shell dumpsys activity anr 2>&1 |
  Out-File -FilePath $AnrLog -Encoding utf8 -Append

@"

=== /data/anr listing probe ===
"@ | Out-File -FilePath $AnrLog -Encoding utf8 -Append
& $Adb shell ls -la /data/anr 2>&1 |
  Out-File -FilePath $AnrLog -Encoding utf8 -Append

if (Test-Path -LiteralPath $ZipPath) {
  Remove-Item -LiteralPath $ZipPath -Force
}

Compress-Archive -Path (Join-Path $LogDir "*") -DestinationPath $ZipPath -Force

Write-Host ""
Write-Host "=== DEBUG PAKETI HAZIR ===" -ForegroundColor Green
Write-Host $ZipPath -ForegroundColor Green
