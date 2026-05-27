# RxPro Professional Audit - 2026-05-26

This audit answers: "What should this project have to feel like a serious Instagram/Facebook-like service app, and what is still missing?"

## Executive Verdict

RxPro is no longer just a simple Flutter prototype. The core product surface is broad: guest discovery, individual users, corporate owners, linked staff, appointments, campaigns, messages, notifications, finance/accounting, business profiles, stories and posts.

The last service/repository work moved the project in the right direction. Direct Firebase access outside approved infrastructure surfaces is now controlled by `tools/architecture_check.ps1` and currently sits at 8 approved files. That is a strong architectural step.

The project is not yet production-professional. The remaining gap is less about "one more page" and more about release discipline, safety, testability, backend hardening, observability, media/feed scalability and codebase hygiene.

## Current Measured State

- Dart files under `lib` and `test`: 203.
- Test files: 10.
- Feature roots: 17.
- Features with `data` boundary: 13.
- Features with `domain` boundary: 3.
- Features with `presentation` boundary: 6.
- Approved direct Firebase infrastructure surface: 8 files.
- Android Firebase config exists: `android/app/google-services.json`.
- iOS Firebase plist is missing: `ios/Runner/GoogleService-Info.plist`.
- Firestore/Storage rules exist under `infra/rules`.
- Root `firebase.json` points to `infra/rules`.
- GitHub Actions / CI workflow has been added, but it still needs a committed remote green run.
- Git repository state is still not committed in this environment.
- Release signing is still debug signing in Android release config.
- App identifiers still use `com.example.*` in Android/iOS/macOS/Linux/Windows metadata.
- App metadata was partially cleaned, but package identifiers still need production values.
- Crashlytics/global error capture and basic Analytics app-open/screen observer wiring are now connected in app bootstrap; flow-level Analytics event contracts are still missing.
- There are many mojibake/encoding artifacts such as `Ã`, `Ä`, `Å` in app/backend text.
- `functions/index.js` is a large monolith around 41 KB.
- Several UI pages are very large; the biggest page is above 77 KB.
- Current large Dart file count above 30 KB: 2.

## What This Project Should Have Professionally

### 1. Product System

RxPro should be treated as a service marketplace plus social graph product:

- Guest discovery flow.
- Individual customer account.
- Corporate owner account.
- Linked staff account.
- Business profile, posts, stories, campaigns and reviews.
- Appointment booking and staff execution.
- Messaging/chat.
- Notifications and push.
- Finance/accounting side effects.
- Moderation, abuse reports, blocking, privacy controls and admin review.
- Media upload pipeline for images/videos.
- Analytics, retention, conversion and operational metrics.

The app should not be managed as a set of unrelated screens. Every visible action should belong to a domain flow and have a data owner, permission model, notification side effect and test strategy.

### 2. Code Architecture

Target professional tree:

```text
lib/
  app/
    bootstrap/
    routing/
    shell/
  core/
    firebase/
    firestore/
    session/
    realtime/
    theme/
    uploads/
  shared/
    widgets/
    formatters/
    validators/
    ui_state/
  features/
    <feature>/
      presentation/
        pages/
        widgets/
      application/
        controllers/
        use_cases/
      domain/
        models/
        policies/
      data/
        repositories/
        dto/
        mappers/
      services/
        side_effects/
```

Current project already has `core` and `features`, and many `data` folders. The missing professional layer is consistency: most screens still sit directly under feature roots, application controllers are not standard, presentation folders are not in use, and some domains have no pure model/policy layer.

Do not move everything at once. The correct method is feature-by-feature migration after each feature has repository/service boundaries and tests.

### 3. Backend Architecture

The backend should not remain one broad `functions/index.js`.

Expected end state:

```text
functions/
  src/
    shared/
      auth.js
      firestore.js
      validation.js
      errors.js
    modules/
      campaigns/
      business_analysis/
      notifications/
      appointments/
      accounting/
      moderation/
      media/
  index.js
```

Each function should have:

- Strict auth/context validation.
- Input schema validation.
- Rate limiting or abuse protection where needed.
- Structured logs.
- Idempotency for financial and notification side effects.
- Tests for callable/request functions.
- Explicit region, timeout and memory.
- Secrets managed through Firebase secret params.

### 4. Security And Privacy

Required before a serious release:

- Firebase App Check for Android/iOS/Web.
- Firestore rules emulator tests.
- Storage rules emulator tests.
- Staff/owner/customer access matrix tests.
- Message participant tests.
- Finance/accounting permission tests.
- Public content write restrictions.
- Report/block/moderation flow.
- Audit fields on sensitive writes.
- Secrets and API keys isolated from client-side usage.
- Production/staging Firebase project separation.

Rules exist, but tests are not yet wired as a release gate. For a social/service app, rules without automated tests are not enough.

### 5. Release And Operations

A professional mobile app should have:

- Real package IDs, not `com.example.*`.
- Android release keystore and signing config.
- iOS bundle id, team and provisioning setup.
- iOS `GoogleService-Info.plist`.
- Versioning and build number policy.
- CI workflow for format/analyze/test/build sanity.
- Firebase deploy checklist.
- Store release checklist.
- Crashlytics initialized before `runApp`.
- Global Flutter/Dart error capture.
- Analytics events for auth, discovery, booking, campaign, message and finance flows.
- Environment separation: dev, staging, production.

Current release posture is not ready: CI is scaffolded but not yet proven on a committed remote run, package ids are starter ids, Android release uses debug signing, and iOS Firebase plist is absent.

### 6. Test Strategy

Current test count is too low for the size and risk of the project.

Minimum professional baseline:

- Pure unit tests for domain policies and mappers.
- Repository tests with fake or emulator-backed Firestore.
- Rules tests for owner/staff/customer/public access.
- Widget tests for critical screens in empty/loading/error/success states.
- Smoke/integration tests for:
  - login and session role gate,
  - appointment booking,
  - staff start/complete flow,
  - notification center,
  - message send/read,
  - finance record generation,
  - campaign AI generation fallback.
- Cloud Functions tests for input validation, auth checks and idempotency.

Test priority should follow risk, not file count. Appointment, messaging, notifications, staff workspace and finance should be protected first.

### 7. Feed, Social Graph And Media Scalability

An Instagram/Facebook-like app needs more than posts on a screen:

- Follow graph source of truth.
- Feed fan-out or feed read model strategy.
- Cursor pagination everywhere.
- Media compression, thumbnail generation and size limits.
- Video upload and playback strategy.
- Content moderation and report queues.
- Blocked users/businesses.
- Notification preferences.
- Push token lifecycle cleanup.
- Cost-aware chat strategy.
- Search/index strategy for businesses, services and campaigns.

Some foundations exist, but the full scalable feed/media/moderation model is not complete.

## Main Professional Gaps

### P0 - Must Fix Before Serious Release

1. Full local quality run must stay green in the real user environment:
   - format,
   - analyze,
   - tests,
   - Android build.
2. First Git commit must be created so the project has a stable baseline.
3. Android package id and iOS bundle id must be changed from `com.example.*` to a real production id.
4. Android release signing must stop using debug signing.
5. iOS Firebase plist must be added.
6. Firestore/Storage rules must be emulator-tested.
7. Crashlytics must be validated on a real release build and flow-level Analytics events must be added.
8. Encoding/mojibake text must be cleaned in app and functions.
9. CI must pass from a clean committed checkout.

### P1 - Architecture Hardening

1. Keep the current direct Firebase budget at 8 or lower.
2. Add adapter/facade tests around the remaining 8 infrastructure Firebase surfaces.
3. Move large feature screens gradually into `presentation/pages`, `presentation/widgets`, `application`, `domain`, and `data`.
4. Split monolithic page files:
   - `business_profile_page.dart`,
   - `staff_workspace_page.dart`,
   - `business_appointment_management_page.dart` is now below 30 KB after the 65J presentation split.
5. Introduce typed route ownership or a routing layer before navigation becomes harder to maintain.
6. Introduce a consistent controller/use-case layer for high-risk screens.

### P2 - Backend And Data Hardening

1. Split `functions/index.js` into modules.
2. Add function tests.
3. Add request/callable validation helpers.
4. Add idempotency to finance and notification side effects.
5. Add scheduled cleanup jobs:
   - expired stories,
   - invalid FCM tokens,
   - stale drafts,
   - old notifications,
   - abandoned sessions.
6. Expand indexes beyond the current notification-focused set.
7. Maintain a data dictionary as a release artifact.
8. Complete discovery geo-index operations:
   - run the dry-run-first backfill script against old/imported business records,
   - lock Firestore index definitions,
   - add emulator tests for indexed nearby discovery and legacy fallback.

### P3 - Product Completeness

1. Real bulk messaging backend flow.
2. Real SMS/password reset flow.
3. Accounting PDF/Excel export completion.
4. Recurring expenses and edit flows.
5. Profile intro video upload/publish.
6. Notification preference settings.
7. Moderation dashboard or admin workflow.
8. Blocking/reporting enforcement across feed, messages and profile.
9. Better public search/filtering beyond the new nearby geo-index foundation.
10. Offline/error recovery polish.

### P4 - UX, Brand And Store Readiness

1. Replace starter names in README, manifest, web, desktop and metadata.
2. Add proper app icon/splash/store assets.
3. Add localization strategy instead of hard-coded mixed text.
4. Run accessibility pass:
   - tap targets,
   - contrast,
   - text scaling,
   - empty/error states,
   - screen reader labels.
5. Add screenshot and store listing checklist.

## High-Risk Files

These files are too large and should be split after their behavior is locked by tests:

- `lib/features/businesses/business_profile_page.dart`
- `lib/features/businesses/staff_workspace_page.dart`

These are product-critical. Refactor them only in narrow slices.

## Recommended Work Order

1. Lock baseline:
   - commit current project,
   - run full quality/build locally,
   - record result in patch ledger.
2. Release foundation:
   - real package ids,
   - signing,
   - iOS plist,
   - Crashlytics,
   - CI green run.
3. Security foundation:
   - rules emulator tests,
   - App Check,
   - access matrix tests.
4. Backend foundation:
   - split functions,
   - validation helpers,
   - function tests.
5. Feature hardening:
   - appointments,
   - messaging,
   - notifications,
   - staff workspace,
   - finance/accounting.
6. Social-scale hardening:
   - feed pagination,
   - media pipeline,
   - moderation,
   - blocking/reporting.
7. UX/store finish:
   - localization,
   - accessibility,
   - app icon/splash,
   - store metadata.

## Final Professional Bar

The project should be considered professional only when:

- The build is reproducible from a clean checkout.
- CI passes on every change.
- Firestore/Storage rules are test-protected.
- App identifiers and signing are production-grade.
- Crash/error/analytics instrumentation is active.
- Critical flows have tests and smoke coverage.
- Large screen files are being reduced behind feature boundaries.
- Backend functions are modular and validated.
- Feed/media/moderation flows are designed for scale and abuse resistance.
- Patch ledger and locked lines are updated after every major change.

## Current Decision

Do not do a broad folder-tree rewrite today. The codebase is still too sensitive for a mass move.

The correct professional move is:

1. Freeze the current architecture boundary.
2. Make quality/build/release gates reliable.
3. Add rules/function tests.
4. Then migrate feature folders one domain at a time.
