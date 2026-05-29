# RxPro release external dependencies

The codebase now blocks unsafe production release builds until the following
external assets are provided.

## Android

- Package id: `com.fix.mobile`
- Confirm the Firebase Android config matches `com.fix.mobile`:
  - `android/app/google-services.json`
- Create or restore `android/key.properties` locally. Do not commit it. For the
  clean source handoff it was moved outside the project folder to
  `C:\Users\Casper\Desktop\rxpro_release_secrets_backup`.
- Restore Android release signing files before a local release build:
  `powershell -ExecutionPolicy Bypass -File tools\restore_android_release_secrets.ps1`.
- Flutter 3.44 built-in Kotlin migration is applied in the app Gradle file.
- Confirm `tools/release_gate_check.ps1` no longer reports Android blockers.

Example shape:

```properties
storeFile=C:/secure/rxpro-upload-keystore.jks
storePassword=CHANGE_ME
keyAlias=rxpro-upload
keyPassword=CHANGE_ME
```

The Gradle release build intentionally fails when `android/key.properties` is
missing so a debug-signed release cannot be produced by accident.

## iOS

- Bundle id: `com.fix.mobile`
- Confirm the Firebase iOS config exists at:
  - `ios/Runner/GoogleService-Info.plist`
- Configure APNs and release signing in Apple Developer / Xcode.
- Set the Runner target `DEVELOPMENT_TEAM` in Xcode.
- If the Apple Team ID is known, the project can also be updated from
  PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File tools\set_ios_development_team.ps1 -TeamId YOURTEAMID
```

- Confirm `tools/release_gate_check.ps1` no longer reports iOS blockers.

## Current blocker summary

As of the latest local checks, Android release gating passes when iOS is skipped:

```powershell
powershell -ExecutionPolicy Bypass -File tools\release_gate_check.ps1 -SkipIos
```

Full production release is still blocked by:

- missing iOS `DEVELOPMENT_TEAM`.
- open real-device, Crashlytics, Analytics, App Check enforcement, and store
  URL confirmations listed in `docs\PRODUCTION_EXTERNAL_VERIFICATION.md`.

## Validation

Run before store submission:

```powershell
powershell -ExecutionPolicy Bypass -File tools\quality_status_report.ps1
powershell -ExecutionPolicy Bypass -File tools\release_gate_check.ps1
powershell -ExecutionPolicy Bypass -File tools\external_production_readiness_check.ps1
flutter analyze
flutter test
flutter build apk --release
```

For a one-command local Android release check on the developer machine:

```powershell
powershell -ExecutionPolicy Bypass -File tools\user_release_build.ps1
```

That script intentionally runs the release gate with `-SkipIos`, because Windows
Android APK builds should not be blocked by the separate Apple signing team setup.
