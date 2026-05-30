# Quality 10 Gap Analysis

Last updated: 2026-05-30

Facebook-level reference score: 10. Current realistic RxPro score: about 8.9.

## P0 - must close before calling it 9+

- iOS release signing is not complete: `DEVELOPMENT_TEAM` is missing.
- Android real-device smoke must be run from the produced release APK.
- iOS real-device smoke must verify Firebase, push, Crashlytics, and login flows.
- Crashlytics release test crash and Analytics DebugView must be verified.
- Firebase App Check client bootstrap is now wired in code and release gate
  checks the dependency/provider setup. Firebase Console enforcement must still
  be enabled for production apps after real-device smoke.
- External production readiness is now enforced by
  `tools/external_production_readiness_check.ps1` and
  `docs/PRODUCTION_EXTERNAL_VERIFICATION.md`; open manual verification items
  intentionally keep the score below 9+.
- Manual verification progress is summarized by
  `tools/production_manual_status.ps1`; it currently reports 30 open items.
  `tools/external_production_readiness_check.ps1` prints that grouped summary
  before failing on open manual items.
- `tools/quality_status_report.ps1` can include the manual status JSON and now
  stays fail-closed when release/external gates are skipped or manual items are
  open.
- Play Store and App Store privacy/support URLs must be final.
- Android release gating passes with `-SkipIos`, but the APK must still be
  rebuilt and smoke-tested from normal PowerShell after the latest changes.

## P1 - needed to move from 9 candidate to 10-grade engineering

- Cloud Functions are split into major modules: directory/Routes, AI generation,
  notifications/reminders, bulk messaging, and accounting. The next 10-grade
  backend step is TypeScript migration, focused function tests, deployment smoke,
  quota alarms, and runtime dashboards.
- Feature-level Dart files over 30KB are now cleared. `main.dart` is split into
  bootstrap, role-gate, and shell parts. The next Flutter architecture gains
  should come from state standardization and deeper workflow test coverage, not
  more raw file splitting.
- Admin moderation filtering now has a small domain policy and focused test
  file, so the queue search/status behavior is no longer presentation-only.
- Concrete feature routing now goes through `AppRouteCatalog`, and the
  architecture gate blocks new direct `MaterialPageRoute` regressions outside
  the catalog or approved generic helpers.
- State management is still mixed between `setState`, `FutureBuilder`,
  `StreamBuilder`, and service calls. Discover/Explore business loading,
  business profile edit, and account profile edit now have first
  controller/policy boundaries, but the wider app still needs the same pattern
  applied to the rest of appointment entry and remaining operational screens.
- Notifications gained a first controller boundary for scope resolution,
  notification stream selection, and read actions. The controller now depends on
  a small data-source contract and has a focused test file. Summary copy,
  unread count, and route decisions are now covered by a domain view policy.
  Riverpod is not added yet because the dependency is not present and `pub get`
  still needs a clean local run.
- Direct Firebase access outside repository/service/domain boundaries is now
  closed by the architecture gate with a 0-file budget.
- Analytics events are wired, but dashboards and funnel alerts are not verified.
- Admin/moderation now has shared search, status filtering, SLA age indicators,
  audit-log support notes, and an in-panel playbook for the main moderation
  queues. Filtered bulk status actions exist for claim, post-report,
  review-report, and campaign-report queues, with confirmation before applying
  changes. Admin audit logs are visible in the panel; broader bulk operations
  are still basic.
- Notification preferences are now implemented in the account UI, protected by
  rules, and respected by push Cloud Functions. Remaining notification maturity
  still needs real-device foreground/background/badge verification.
- `path_provider_android` remains pinned by dependency override; this should be
  revisited after Android native dependency compatibility is stable.

## P2 - polish and scale work

- Image upload now has client-side size ceilings, upload timeouts, cache
  headers, metadata, and thumbnail generation for story/profile-post images.
  Story rails and profile posts prefer thumbnail URLs where available. The
  remaining 10-grade gap is running/reviewing the older-media thumbnail audit,
  adding real thumbnail generation for queued legacy media, and extending
  thumbnail-first rendering to every legacy image surface.
- Performance profiling should be run for startup, explore, appointment booking,
  messaging, and business dashboard flows.
- Pilot city/category data quality should be curated before wide launch.
- Store screenshots, demo accounts, and support workflows should be prepared.

## Work started in this pass

- Android built-in Kotlin migration applied for Flutter 3.44 future compatibility.
- Release gate now blocks legacy app-level Kotlin Gradle Plugin regressions.
- Android release build responsibility moved to normal user PowerShell.
- Added `tools/user_release_build.ps1` for repeatable local release verification.
- Release gate now supports Android-only or iOS-only checks; the Android helper
  uses `-SkipIos` so Apple signing does not block APK verification.
- Updated external dependency and quality status docs to reflect the verified APK
  and the remaining iOS-only release gate.
- Extracted accounting callables into `functions/modules/accounting.js`.
- Extracted bulk message sending into `functions/modules/bulk_messaging.js`.
- Reduced `functions/index.js` to 1947 lines and verified all Functions syntax
  checks plus the CI quality gate.
- Extracted Explore list rendering into `HomeExploreContentList`; the feature
  architecture report dropped from 3 large files to 2.
- Extracted customer campaign UI helpers and the manual appointment sheet into
  separate Dart part files; the feature architecture report now shows 0 large
  files over 30KB.
- Split `main.dart` into `lib/app/fix_bootstrap_app.dart`,
  `lib/app/role_gate_shell.dart`, and `lib/app/main_shells.dart`; `main.dart`
  is now 63 lines.
- Extracted Places/Routes, AI generation, push notifications, and scheduled
  reminders from `functions/index.js`; `functions/index.js` is now 193 lines.
- Strengthened CI so every Functions JS file is syntax-checked, not only the
  index file.
- Added repeatable clean source zip creation and Android release signing
  handoff scripts so source review packages stay clean while release builds stay
  fail-closed until secrets are restored locally.
- Expanded the central routing catalog across concrete app screens and added an
  architecture gate to prevent direct `MaterialPageRoute` regressions.
- Hardened image upload behavior with file-size limits, upload/download
  timeouts, cache headers, role metadata, and thumbnail generation.
- Added thumbnail-first story rail rendering and thumbnail preview while full
  story media loads.
- Added shared admin moderation search and status filters for claim, report,
  abuse-log, and block queues.
- Added SLA age indicators to claim, post-report, review-report, and
  campaign-report moderation cards.
- Added audit-log support notes to admin moderation actions so reviewers can
  leave traceable operational context.
- Added an in-panel moderation playbook and split admin presentation helpers so
  the large-file architecture budget stays at 0.
- Added filtered bulk status actions for claim, post-report, review-report, and
  campaign-report moderation queues.
- Added confirmation before filtered bulk moderation actions are applied.
- Added an admin audit-log panel so support notes and reviewer decisions are
  visible without leaving the moderation surface.
- Extracted admin moderation filtering into a domain policy with a focused test
  file.
- Added `npm run audit:media-thumbnails` as a dry-run-first Firebase Admin
  script to find older media records that still need thumbnail backfill.
- Added `tools/production_manual_status.ps1` to group external manual
  verification blockers by Android, iOS, and Firebase/store/operations.
- Wired the manual status summary into the external production readiness check
  so the failing gate shows grouped remaining work.
- Added `-IncludeManualStatusJson` and `-SkipRules` support to the honest
  quality status reporter without allowing skipped gates to be reported as 9+.
- Started the state-management migration on notifications by extracting
  `NotificationCenterController` from the page.
- Made the notification controller testable through a data-source contract and
  added a focused controller test.
- Extracted notification center view decisions into a domain policy with a
  focused test.
- Moved push notification token/session ownership reads and writes behind a
  repository boundary as part of the earlier direct Firebase surface reduction.
- Moved realtime notification writes, follow-cache warmup reads,
  business-directory reads, and current-user state reads behind repository
  boundaries.
- Moved app-session user/business document reads behind a repository boundary.
  The direct Firebase architecture budget is now 0 approved core files.
- Moved Discover/Explore business loading, load-error/completion state, nearest
  area detection, and repeated-location-query decisions into
  `HomeExploreController` with a focused controller test.
- Moved business appointment dashboard date/status/name/capacity decisions into
  `BusinessAppointmentDashboardPolicy` with a focused domain test.
- Moved business appointment dashboard schedule bounds, visible-month
  appointment filtering, and staff list fallback/deduplication into
  `BusinessAppointmentDashboardPolicy` with expanded focused tests.
- Moved business profile edit field fallback, optional email/website
  validation, required field validation, and storefront readiness scoring into
  `BusinessProfileEditPolicy` with a focused domain test.
- Moved account profile edit validation, write-input normalization, and
  verification summary text into `AccountUserProfilePolicy` with a focused
  domain test.
- Moved manual appointment staff normalization, selected-staff fallback,
  date/time formatting, duration clamping, and form validation into
  `BusinessManualAppointmentPolicy` with a focused domain test.
- Moved business service form display normalization, active/passive
  classification, price/duration/session validation, and save payload creation
  into `BusinessServiceFormPolicy` with a focused domain test.
- Moved business product display normalization, numeric parsing/formatting,
  low-stock detection, stock summary calculation, and product form validation
  into `BusinessProductPolicy` with a focused domain test.
