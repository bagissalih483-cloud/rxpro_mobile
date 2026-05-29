param(
  [string]$ExpectedAndroidPackage = "com.fix.mobile",
  [string]$ExpectedIosBundleId = "com.fix.mobile",
  [switch]$SkipAndroid,
  [switch]$SkipIos
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Fail($message) {
  $script:Failures += $message
}

Write-Host "== RxPro release gate check =="
$Failures = @()

if (-not $SkipAndroid) {
  $gradleFile = Join-Path $root 'android/app/build.gradle.kts'
  if (-not (Test-Path $gradleFile)) {
    Fail "android/app/build.gradle.kts is missing."
  } else {
    $gradle = Get-Content $gradleFile -Raw
    if ($gradle -notmatch "applicationId\s*=\s*`"$ExpectedAndroidPackage`"") {
      Fail "Android applicationId must be $ExpectedAndroidPackage."
    }
    if ($gradle -match 'signingConfigs\.getByName\("debug"\)') {
      Fail "Release build still uses debug signing."
    }
    if ($gradle -match 'id\("kotlin-android"\)|id\("org\.jetbrains\.kotlin\.android"\)') {
      Fail "Android app still applies the legacy Kotlin Gradle Plugin. Migrate to Flutter built-in Kotlin."
    }
    if ($gradle -match 'kotlinOptions\s*\{') {
      Fail "Android app still uses legacy kotlinOptions. Use kotlin.compilerOptions for Flutter built-in Kotlin."
    }
  }

  $gradlePropertiesPath = Join-Path $root 'android/gradle.properties'
  if (-not (Test-Path $gradlePropertiesPath)) {
    Fail "android/gradle.properties is missing."
  } else {
    $gradleProperties = Get-Content $gradlePropertiesPath -Raw
    if ($gradleProperties -notmatch "(?m)^android\.builtInKotlin\s*=\s*true\s*$") {
      Fail "android.builtInKotlin must be true after the Flutter 3.44 built-in Kotlin migration."
    }
    if ($gradleProperties -notmatch "(?m)^android\.newDsl\s*=\s*false\s*$") {
      Fail "android.newDsl should stay false until Flutter/plugin AGP DSL migration is complete."
    }
  }

  $googleServicesPath = Join-Path $root 'android/app/google-services.json'
  if (-not (Test-Path $googleServicesPath)) {
    Fail "android/app/google-services.json is missing."
  } else {
    $googleServices = Get-Content $googleServicesPath -Raw
    if ($googleServices -notmatch "`"package_name`"\s*:\s*`"$ExpectedAndroidPackage`"") {
      Fail "android/app/google-services.json does not match $ExpectedAndroidPackage. Download a new Firebase Android config."
    }
  }

  $pubspecPath = Join-Path $root 'pubspec.yaml'
  if (-not (Test-Path $pubspecPath)) {
    Fail "pubspec.yaml is missing."
  } else {
    $pubspec = Get-Content $pubspecPath -Raw
    if ($pubspec -notmatch "(?m)^\s*firebase_app_check\s*:") {
      Fail "firebase_app_check dependency is missing. Firebase App Check must be wired before production release."
    }
  }

  $pubspecLockPath = Join-Path $root 'pubspec.lock'
  if (-not (Test-Path $pubspecLockPath)) {
    Fail "pubspec.lock is missing. Run flutter pub get before release."
  } else {
    $pubspecLock = Get-Content $pubspecLockPath -Raw
    if ($pubspecLock -notmatch "(?m)^\s*firebase_app_check\s*:") {
      Fail "pubspec.lock does not include firebase_app_check. Run flutter pub get before release."
    }
  }

  $appCheckBootstrapPath = Join-Path $root 'lib/core/security/firebase_app_check_bootstrap.dart'
  if (-not (Test-Path $appCheckBootstrapPath)) {
    Fail "Firebase App Check bootstrap file is missing."
  } else {
    $appCheckBootstrap = Get-Content $appCheckBootstrapPath -Raw
    if ($appCheckBootstrap -notmatch 'AndroidProvider\.playIntegrity') {
      Fail "Firebase App Check Android release provider must use Play Integrity."
    }
    if ($appCheckBootstrap -notmatch 'AppleProvider\.appAttestWithDeviceCheckFallback') {
      Fail "Firebase App Check Apple release provider must use App Attest with DeviceCheck fallback."
    }
  }

  $keyPropertiesPath = Join-Path $root 'android/key.properties'
  if (-not (Test-Path $keyPropertiesPath)) {
    Fail "android/key.properties is missing. Release signing is intentionally blocked until it is configured."
  } else {
    $keyProperties = Get-Content $keyPropertiesPath -Raw
    foreach ($key in @('storeFile', 'storePassword', 'keyAlias', 'keyPassword')) {
      if ($keyProperties -notmatch "(?m)^$key\s*=") {
        Fail "android/key.properties is missing $key."
      }
    }
    if ($keyProperties -match 'CHANGE_ME|TODO|debug|androiddebugkey') {
      Fail "android/key.properties appears to contain placeholder/debug signing values."
    }
  }
}

if (-not $SkipIos) {
  $plistPath = Join-Path $root 'ios/Runner/GoogleService-Info.plist'
  if (-not (Test-Path $plistPath)) {
    Fail "ios/Runner/GoogleService-Info.plist is missing."
  }

  $xcodeProjectPath = Join-Path $root 'ios/Runner.xcodeproj/project.pbxproj'
  if (-not (Test-Path $xcodeProjectPath)) {
    Fail "ios/Runner.xcodeproj/project.pbxproj is missing."
  } else {
    $xcodeProject = Get-Content $xcodeProjectPath -Raw
    if ($xcodeProject -notmatch "PRODUCT_BUNDLE_IDENTIFIER = $ExpectedIosBundleId;") {
      Fail "iOS bundle id must be $ExpectedIosBundleId."
    }
    if ($xcodeProject -notmatch 'DEVELOPMENT_TEAM = [A-Z0-9]+;') {
      Fail "iOS DEVELOPMENT_TEAM is not configured for release signing."
    }
  }

  if (-not (Test-Path (Join-Path $root 'ios/Runner/PrivacyInfo.xcprivacy'))) {
    Fail "ios/Runner/PrivacyInfo.xcprivacy is missing."
  }

  if (-not (Test-Path (Join-Path $root 'ios/Runner/Runner.entitlements'))) {
    Fail "ios/Runner/Runner.entitlements is missing."
  }
}

if ($Failures.Count -gt 0) {
  Write-Host "Release gate blockers:" -ForegroundColor Yellow
  foreach ($failure in $Failures) {
    Write-Host " - $failure" -ForegroundColor Yellow
  }
  Write-Error "Release gate failed with $($Failures.Count) blocker(s)."
}

Write-Host "Release gate check completed."
