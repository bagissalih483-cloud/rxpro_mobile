# GitHub Actions Release Setup

This project has three GitHub Actions entry points:

- `Flutter Quality Gate`: source quality, rules, syntax and test gates.
- `Android Release Artifact`: signed Android APK/AAB artifacts.
- `iOS Release Build Gate`: macOS/Xcode no-codesign iOS release build.

## Android secrets

Add these repository secrets in GitHub:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Create the keystore base64 value locally with PowerShell:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("C:\Users\Casper\Desktop\rxpro_mobile\android\rxpro-upload-keystore.jks")
) | Set-Clipboard
```

Paste the clipboard value into `ANDROID_UPLOAD_KEYSTORE_BASE64`.
Do not commit `android/key.properties` or `.jks` files.

## Android artifact run

In GitHub:

1. Open `Actions`.
2. Select `Android Release Artifact`.
3. Click `Run workflow`.
4. Choose:
   - `apk` for direct device install testing.
   - `aab` for Play Console upload.
   - `both` when preparing a full release handoff.
5. Use `app_check_debug=true` only for sideload/local test builds.

Production Play/TestFlight style builds should keep `app_check_debug=false`.

## iOS build gate

`iOS Release Build Gate` runs on GitHub macOS runners and executes:

- `flutter pub get`
- `flutter analyze`
- optional Flutter tests
- iOS static release gate without signing enforcement
- `flutter build ios --release --no-codesign`

This does not require an iPhone, but it is not a store-ready IPA. It proves that
the iOS project compiles on Xcode.

## iOS signed IPA boundary

A signed IPA still needs Apple signing material:

- Apple Developer Team ID
- Distribution certificate
- Certificate password
- Provisioning profile for `com.fix.mobile`
- Export options plist

Those must be configured as GitHub Secrets before adding an App Store/TestFlight
IPA workflow. A real iPhone/iPad smoke test is still required before calling iOS
production readiness complete.
