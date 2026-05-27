# RxPro Release Readiness Checklist

This checklist is the practical release gate after the 64U clean-analyze baseline.

## Current Clean Baseline

- `flutter analyze`: PASS, no issues in the user environment.
- `flutter test`: PASS, 16 tests in the user environment.
- `flutter build apk --release`: PASS, APK generated at `build/app/outputs/flutter-apk/app-release.apk`.
- `tools/architecture_check.ps1`: PASS, direct Firebase surface remains 8 approved infrastructure files.
- `tools/quality_check.ps1 -SkipFlutter`: PASS.

## Required Before Production Release

1. Create the first Git commit from the current clean baseline.
2. Push to a remote repository and enable `.github/workflows/flutter_quality.yml`.
3. Replace starter package ids:
   - Android: `com.example.rxpro_mobile`
   - iOS/macOS: `com.example.rxproMobile`
   - desktop/web metadata where applicable.
4. Configure Android release signing with a production keystore.
5. Add real iOS `GoogleService-Info.plist` under `ios/Runner/`.
6. Run Firebase rules validation and emulator tests before deploying rules.
7. Validate Crashlytics delivery from a real release build.
8. Add Analytics event contracts for auth, discovery, booking, campaign, message and finance flows.
9. Add staging/production Firebase project separation.
10. Complete visible mojibake/encoding cleanup across auth, appointments, notifications and business profile screens.
11. Run manual smoke tests on a real device:
    - login and role gate,
    - guest explore,
    - appointment booking,
    - staff start/complete,
    - notifications,
    - messaging,
    - finance/accounting,
    - campaign creation.

## CI Gate

The CI workflow runs:

```powershell
powershell -ExecutionPolicy Bypass -File tools\ci_quality_check.ps1
```

The gate checks:

- architecture boundaries,
- Cloud Functions syntax,
- Flutter dependency resolution,
- Dart formatting normalization,
- Flutter analyze,
- Flutter tests,
- debug APK build.

For a stricter formatting policy, run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\ci_quality_check.ps1 -EnforceFormat
```

Encoding scan:

```powershell
powershell -ExecutionPolicy Bypass -File tools\mojibake_scan.ps1 -CountOnly
```

Feature architecture report:

```powershell
powershell -ExecutionPolicy Bypass -File tools\feature_architecture_report.ps1
```

## Local Fast Checks

Use this when iterating quickly:

```powershell
powershell -ExecutionPolicy Bypass -File tools\quality_check.ps1 -SkipFlutter
flutter analyze
flutter test
flutter build apk --release
```

## Release Decision

Do not ship production until:

- CI is green from a clean checkout.
- Release signing is production-grade.
- Firebase rules are tested.
- The app no longer uses starter package ids.
- Crash/error reporting is verified from a release build.
