param(
  [string]$ProjectRoot = "C:\Users\Casper\Desktop\rxpro_mobile"
)

$ErrorActionPreference = "Stop"

function Write-Section($Title) {
  Write-Host ""
  Write-Host "=== $Title ===" -ForegroundColor Cyan
}

function Test-File($Path, $Ok, $Missing) {
  if (Test-Path -LiteralPath $Path) {
    Write-Host "[OK] $Ok" -ForegroundColor Green
  } else {
    Write-Host "[EKSIK] $Missing" -ForegroundColor Yellow
  }
}

Write-Section "fix App Store Hazirlik Kontrolu"
Write-Host "Proje: $ProjectRoot"

$iosRunner = Join-Path $ProjectRoot "ios\Runner"
$xcodeProject = Join-Path $ProjectRoot "ios\Runner.xcodeproj\project.pbxproj"
$firebaseOptions = Join-Path $ProjectRoot "lib\firebase_options.dart"

Write-Section "Dosya Kontrolleri"
Test-File `
  -Path (Join-Path $iosRunner "GoogleService-Info.plist") `
  -Ok "GoogleService-Info.plist bulundu." `
  -Missing "GoogleService-Info.plist yok. Firebase Console'da com.fix.mobile iOS app olusturup dosyayi ios\Runner altina koy."

Test-File `
  -Path (Join-Path $iosRunner "PrivacyInfo.xcprivacy") `
  -Ok "PrivacyInfo.xcprivacy bulundu." `
  -Missing "PrivacyInfo.xcprivacy yok. App Store privacy manifest dosyasini ekle."

Test-File `
  -Path (Join-Path $iosRunner "Runner.entitlements") `
  -Ok "Runner.entitlements bulundu." `
  -Missing "Runner.entitlements yok. Push notification icin aps-environment ekle."

Test-File `
  -Path (Join-Path $ProjectRoot "ios\Podfile") `
  -Ok "Podfile bulundu." `
  -Missing "Podfile yok. Mac'te pod install icin standart Flutter iOS Podfile ekle."

Write-Section "Bundle ID Kontrolleri"
if (Test-Path -LiteralPath $xcodeProject) {
  $projectText = Get-Content -LiteralPath $xcodeProject -Raw
  if ($projectText -match "PRODUCT_BUNDLE_IDENTIFIER = com\.fix\.mobile;") {
    Write-Host "[OK] Xcode bundle id com.fix.mobile." -ForegroundColor Green
  } else {
    Write-Host "[EKSIK] Xcode bundle id com.fix.mobile degil. Runner target bundle id'yi com.fix.mobile yap." -ForegroundColor Yellow
  }

  if ($projectText -match "DEVELOPMENT_TEAM = ") {
    Write-Host "[OK] DEVELOPMENT_TEAM proje dosyasinda gorunuyor." -ForegroundColor Green
  } else {
    Write-Host "[DIS ADIM] DEVELOPMENT_TEAM secili degil. Mac'te Xcode > Runner target > Signing & Capabilities > Team sec." -ForegroundColor Yellow
  }
}

if (Test-Path -LiteralPath $firebaseOptions) {
  $firebaseText = Get-Content -LiteralPath $firebaseOptions -Raw
  if ($firebaseText -match "iosBundleId: 'com\.fix\.mobile'") {
    Write-Host "[OK] firebase_options.dart iOS bundle id com.fix.mobile." -ForegroundColor Green
  } else {
    Write-Host "[EKSIK] firebase_options.dart iOS bundle id com.fix.mobile degil." -ForegroundColor Yellow
  }
}

Write-Section "Mac'te Calistirilacak Komutlar"
Write-Host "1. flutter clean"
Write-Host "2. flutter pub get"
Write-Host "3. cd ios"
Write-Host "4. pod install"
Write-Host "5. cd .."
Write-Host "6. flutter build ipa --release --build-name 1.0.0 --build-number 1"

Write-Section "App Store Connect'te Doldurulacaklar"
Write-Host "- App name: fix"
Write-Host "- Bundle ID: com.fix.mobile"
Write-Host "- Privacy Policy URL"
Write-Host "- Support URL"
Write-Host "- App Privacy labels"
Write-Host "- Ekran goruntuleri"
Write-Host "- Demo bireysel ve isletme hesabi"

Write-Host ""
Write-Host "Kontrol tamamlandi." -ForegroundColor Cyan
