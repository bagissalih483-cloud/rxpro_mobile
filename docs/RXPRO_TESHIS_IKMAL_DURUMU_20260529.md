# RxPro PDF diagnosis implementation status

Last updated: 2026-05-30

This file maps `RxPro_Yapilmasi_Gerekenler_Teshis_Tedavi.pdf` to the current
codebase after the latest hardening pass.

## Closed or materially improved in code

- Firebase App Check client bootstrap is wired:
  - Debug provider for local Android/iOS/macOS.
  - Play Integrity for Android release.
  - App Attest with DeviceCheck fallback for Apple release.
  - Release gate now checks App Check dependency and providers.
- Firestore/Storage rules are materially hardened and covered by emulator tests.
- Appointment slot locking and cancellation/no-show lock release policies exist.
- Large feature files over 30 KB are currently cleared.
- Cloud Functions are split into modules and syntax-checked by CI.
- Clean source zip and release signing handoff scripts exist.
- Manual production verification can be summarized by category with
  `tools\production_manual_status.ps1`, and the external readiness gate now
  prints that grouped summary before failing on open manual items.
- `tools\quality_status_report.ps1` can include manual-status JSON and remains
  fail-closed when critical release/external gates are skipped.
- Notification preferences are implemented:
  - Account UI entry.
  - Owner-only Firestore rules.
  - Push Cloud Function preference filtering.
  - Emulator test coverage.
- Media upload is hardened with size ceilings, timeouts, cache headers, and
  stricter Storage rules. Story and profile-post flows now generate thumbnails;
  story rail/viewer and profile-post lists prefer thumbnails where available.
- Older media thumbnail backfill now has a dry-run-first audit script:
  `npm run audit:media-thumbnails` from the `functions` directory.
- Legal documents, consent, account deletion request, and moderation/reporting
  foundations exist.
- Route construction is now centralized through `AppRouteCatalog` for concrete
  app screens. The architecture gate fails new direct `MaterialPageRoute`
  regressions outside the catalog or approved generic helpers.
- Admin moderation has shared search and status filters across claim, report,
  abuse-log, and block queues. The main moderation queues also have SLA age
  indicators, audit-log support notes, and an in-panel playbook.
- Claim, post-report, review-report, and campaign-report queues have filtered
  bulk status actions with explicit confirmation.
- Admin audit logs are visible inside the moderation panel, so reviewer
  decisions and support notes are easier to follow.
- Admin moderation filtering now has a domain policy and focused test file,
  reducing presentation-only logic.
- Notification center state handling has started moving out of the widget into
  `NotificationCenterController`. The controller now has a data-source contract
  and focused test file. Notification center summary/empty-state/route behavior
  now has a domain view policy and focused test; Riverpod is still not added
  because the dependency is not present and dependency resolution must be run
  locally.
- Discover/Explore business loading state has started moving out of the widget
  into `HomeExploreController`. The controller owns load/error/completion state,
  nearest area detection, repeated-location-query decisions, and filtered list
  derivation, with a focused controller test.
- Business appointment dashboard row parsing, schedule bounds,
  visible-month filtering, staff fallback/deduplication, and capacity decisions
  now sit in `BusinessAppointmentDashboardPolicy`, with a focused domain test
  for modern and legacy appointment field formats.
- Business profile edit fallback selection, optional email/website validation,
  required field validation, and profile readiness scoring now sit in
  `BusinessProfileEditPolicy`, with a focused domain test.
- Account profile edit validation, write-input normalization, and verification
  summary text now sit in `AccountUserProfilePolicy`, with a focused domain
  test.
- Manual appointment staff normalization, selected-staff fallback, date/time
  formatting, duration clamping, and form validation now sit in
  `BusinessManualAppointmentPolicy`, with a focused domain test.
- Business service management display normalization, active/passive
  classification, price/duration/session validation, and save payload creation
  now sit in `BusinessServiceFormPolicy`, with a focused domain test.
- Business product/stok display normalization, numeric parsing/formatting,
  low-stock detection, stock summary calculation, and product form validation
  now sit in `BusinessProductPolicy`, with a focused domain test.
- Direct Firebase core architecture debt has been reduced further: notification
  writes, follow-cache warmup reads, business-directory reads, and current-user
  state reads now sit behind repository boundaries. App-session user/business
  document reads now sit behind a repository as well. The architecture gate
  currently allows 0 approved direct core surfaces outside
  repository/service/domain.

## Still open before honestly calling it 9+

- iOS release signing: `DEVELOPMENT_TEAM` is still missing.
- Firebase App Check Console enforcement must be enabled after real-device smoke.
- Flutter dependency resolution must be run from normal PowerShell after adding
  `firebase_app_check`:

```powershell
Set-Location "C:\Users\Casper\Desktop\rxpro_mobile"
flutter pub get
```

- `flutter analyze`, `flutter test`, and release build must be re-run after
  dependency resolution.
- `tools\production_manual_status.ps1` currently reports 30 open manual
  production verification items.
- Android and iOS real-device smoke must verify:
  - Login/register/reset.
  - Discover.
  - Booking/rebooking/cancel/no-show.
  - Messaging.
  - Foreground/background/terminated push.
  - Badge/read state.
  - Crashlytics test crash.
  - Analytics DebugView.
- Store privacy/support URLs and screenshots must be finalized.
- Google Places production secret, quota, cache health-check, and cost dashboard
  must be validated in the live Firebase/GCP project.
- Firebase/GCP budget and quota alerts must be enabled outside code.

## Main remaining code/product gaps

- State management is still mixed. Discover, notifications, messages, business
  profile edit, and account profile edit now have first controller/policy
  boundaries; manual appointment form decisions have also moved into a policy.
  Business service and product/stok form decisions have also moved into
  policies. The next valuable refactor is the remaining appointment entry state
  and other
  operational forms, then completing these controllers into a provider-backed
  pattern after dependency resolution.
- Two approved generic navigation helpers remain for legacy/debug entry points,
  but concrete feature navigation is now guarded by the route catalog.
- Notification preference UI exists, but real-device behavior still needs
  foreground/background/badge smoke.
- Older media still needs the thumbnail audit run against the live project,
  reviewed, then followed by real thumbnail generation for queued legacy media.
  Every legacy image surface still needs thumbnail-first review.
- Admin/moderation still needs richer operational tooling: broader content
  action batching and deeper support workflow analytics.
- Cloud Functions still need TypeScript migration or focused unit tests,
  structured deployment smoke, and runtime dashboards.
- Package id / final brand identity decision remains a business decision before
  public launch.

## Current honest score

The PDF's 6.8-7.2 score appears to describe the earlier project state. After the
implemented security, rules, release gate, architecture, App Check, notification
preference, media hardening, and routing centralization work, the codebase is
stronger than that.

Still, without iOS signing, App Check enforcement, real-device push/Crashlytics
verification, store readiness, and live quota monitoring, it is not honest to
call the product fully above 9 for broad production. It is roughly an 8.9/10
candidate today, with the remaining gap dominated by external production
validation and a few architecture/UX maturity items.
