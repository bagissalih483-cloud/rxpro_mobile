# RxPro Mobile

RxPro Mobile is a Flutter/Firebase service marketplace app for guest discovery, individual customers, corporate owners, linked staff, appointments, campaigns, messaging, notifications and finance/accounting flows.

## Quality Baseline

Current clean baseline:

- `flutter analyze`: no issues in the user environment.
- `flutter test`: passing.
- `flutter build apk --release`: passing.
- `tools/architecture_check.ps1`: passing with 8 approved direct Firebase infrastructure surfaces.

## Local Commands

Fast architecture/backend check:

```powershell
powershell -ExecutionPolicy Bypass -File tools\quality_check.ps1 -SkipFlutter
```

Visible text encoding scan:

```powershell
powershell -ExecutionPolicy Bypass -File tools\mojibake_scan.ps1 -CountOnly
```

Feature architecture report:

```powershell
powershell -ExecutionPolicy Bypass -File tools\feature_architecture_report.ps1
```

Full local check:

```powershell
powershell -ExecutionPolicy Bypass -File tools\quality_check.ps1
```

Release APK:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## CI

GitHub Actions workflow:

```text
.github/workflows/flutter_quality.yml
```

CI entrypoint:

```powershell
powershell -ExecutionPolicy Bypass -File tools\ci_quality_check.ps1
```

## Architecture

Core architecture docs live under:

```text
docs/project_index/
```

Key files:

- `rxpro_target_architecture.md`
- `rxpro_working_algorithm.md`
- `rxpro_professional_audit_20260526.md`
- `rxpro_release_readiness_checklist.md`

## Release Notes

Do not ship production until package ids, signing, iOS Firebase plist, Firebase rules tests, CI green run, Crashlytics release validation and flow-level Analytics events are complete.
