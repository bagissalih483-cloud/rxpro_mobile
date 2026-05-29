# RxPro Release Readiness Checklist

This checklist is the current release gate. Older 64U clean-baseline notes are
historical; the current commercial release decision must use the checks below.

## Current Clean Baseline

- `tools/ci_quality_check.ps1 -SkipFlutter`: PASS in Codex environment.
- Firestore/Storage emulator rules: PASS, 17 tests.
- Secret scan: PASS.
- Cloud Functions syntax: PASS.
- Text quality check: PASS for runtime Dart/JS surfaces.
- `flutter analyze`, `flutter test`, and `flutter build apk --release`: not
  currently trusted from the Codex environment and must be rerun locally after
  external Firebase/signing files are supplied.
- `tools/release_gate_check.ps1`: FAIL until the external release assets below
  are provided.

## Required Before Production Release

1. Replace `android/app/google-services.json` with a Firebase config whose
   Android package is `com.fix.mobile`.
2. Create a real Android upload/release keystore and local
   `android/key.properties`.
3. Add the iOS Firebase config at `ios/Runner/GoogleService-Info.plist`.
4. Configure Apple Developer Team / `DEVELOPMENT_TEAM` for `com.fix.mobile`.
5. Run `tools/release_gate_check.ps1` until it passes.
6. Run `flutter analyze`, `flutter test`, and `flutter build apk --release`
   locally with the real external files.
7. Validate Crashlytics delivery from a real release build.
8. Validate Analytics DebugView on a real Android/iOS release candidate.
9. Enable Firebase App Check production enforcement after debug tokens are
   removed.
10. Finalize Play Store / App Store privacy and support URLs.
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
- user-visible text quality for runtime Dart/JS files,
- secret scan,
- Cloud Functions syntax,
- Firebase emulator rules tests,
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
powershell -ExecutionPolicy Bypass -File tools\text_quality_check.ps1
```

Feature architecture report:

```powershell
powershell -ExecutionPolicy Bypass -File tools\feature_architecture_report.ps1
```

## Local Fast Checks

Use this when iterating quickly:

```powershell
powershell -ExecutionPolicy Bypass -File tools\ci_quality_check.ps1 -SkipFlutter
powershell -ExecutionPolicy Bypass -File tools\release_gate_check.ps1
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
- Firebase Android/iOS config matches `com.fix.mobile`.
- Crash/error reporting is verified from a release build.
