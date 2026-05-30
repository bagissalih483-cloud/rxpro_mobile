# 9+ Quality Execution Status

Last updated: 2026-05-30

## Completed in code

- Android application id and namespace moved from `com.example.rxpro_mobile` to `com.fix.mobile`.
- Release signing now fails closed unless `android/key.properties` is configured.
- Release gate script added: `tools/release_gate_check.ps1`.
- Secret scan added and wired into CI quality gate.
- Legal documents screen, draft KVKK/privacy/terms texts, registration acceptance, legal menu entry, and account deletion request flow added.
- New registrations now persist legal acceptance version, timestamp, KVKK notice, terms, privacy policy, and explicit consent flags on the private user document.
- Firestore `users/{uid}` reads restricted to the owner.
- `publicProfiles`, `users_private`, and `accountDeletionRequests` rules added.
- `businessStaff.inviteCode` based read fallback removed.
- Appointment booking moved to deterministic slot lock transaction.
- Manual business appointment creation also uses the slot lock transaction.
- Slot id generation moved into a domain policy with tests.
- Firestore rules emulator test scaffold added for private users, public profiles, invite code reads, appointment slot creation, and account deletion requests.
- Storage unknown-path public read closed; known public asset paths remain readable.
- Storage rules tests added for public path reads, owner uploads, non-owner
  blocking, content-type blocking, profile ownership, and stricter 2 MB
  avatar/logo upload limits.
- Notification preferences flow added: users can manage push, appointment,
  message, campaign, and system notification categories from the account area.
  Firestore rules allow only the owner to read/write their preference document,
  and Cloud Functions skip push delivery for disabled categories.
- Firebase rules test runner added: `tools/run_rules_tests.ps1`.
- CI quality gate now runs Firebase Firestore and Storage rules tests when Flutter is not skipped.
- Public Firestore/Storage surfaces, Firebase config risk, and App Check production plan documented in `docs/SECURITY_PUBLIC_DATA_AND_APP_CHECK_PLAN.md`.
- Firebase App Check client bootstrap added with debug providers for local
  builds, Play Integrity for Android release, and App Attest with DeviceCheck
  fallback for Apple release. Firebase Console enforcement remains an external
  production switch.
- Release gate now also blocks if `pubspec.lock` does not contain
  `firebase_app_check`, preventing a stale dependency lock from slipping into a
  release attempt.
- iOS signing handoff helper added:
  `tools/set_ios_development_team.ps1`. It updates the Runner build
  configurations once the real 10-character Apple Team ID is known.
- Places, Routes, campaign AI, and business analysis AI functions now require authenticated callers and user-based rate limits.
- Function rate-limit and abuse-log collections are server-only; client access is denied by rules and covered by emulator tests.
- Minimum admin/moderation page added for platform admins: claim request review and function abuse-log visibility.
- Platform admin rules added for claim review and abuse-log read access.
- Content report moderation added for business profile post reports.
- Admin audit log collection and write path added for claim/report moderation actions.
- Post report rules now allow only the reporting user to create/read their own report while platform admins can review it.
- Admin moderation now includes user block/unblock records, abuse-log block actions, and admin-only rules for `moderationBlocks`.
- Review reporting and admin review moderation added: users can report reviews, admins can resolve/reject reports, hide reviews, restore reviews, and audit those actions.
- Campaign reporting and admin campaign moderation added: users can report campaign content, admins can resolve/reject reports, hide/restore campaigns, and audit those actions.
- Campaign lists now filter moderator-hidden campaigns out of the customer-visible feed.
- Customer-visible Turkish text fixes applied in the touched booking/explore/legal paths.
- Cloud Functions active AI error messages and fallback labels corrected.
- Analytics event contract added in `docs/ANALYTICS_EVENT_CONTRACT.md`.
- Registration completion, Discover business open, business claim submission, successful appointment booking, campaign view/create/report, message send, and finance action events are wired through the central observability service.
- Appointment status transition policy added for customer/business cancellation and no-show state decisions.
- Customer cancellation now writes canonical `cancelledByUser` status fields, avoids repeated cancellation of terminal appointments, and logs `appointment_cancelled`.
- Customer, business, and staff no-show/cancellation flows now release deterministic appointment slot locks so cancelled/no-show slots can be booked again.
- Business cancellation now writes canonical `cancelledByBusiness` and logs `appointment_cancelled`.
- Staff no-show now uses the central state transition policy and logs `appointment_cancelled` with actor role `staff`.
- Release gate now reports all current release blockers in one run instead of stopping at the first missing external asset.
- Runtime/debug helper scripts now default to the production package id `com.fix.mobile` instead of the old starter id.
- Functions business-analysis fallback messages and the newly touched campaign/admin screens were cleaned for Turkish text quality.
- Text quality gate added to CI to block new mojibake markers in runtime Dart/JS files, with explicit allowlist only for legacy normalizer tables.
- Text quality gate now reads runtime Dart/JS files as strict UTF-8 and checks
  broader Turkish mojibake markers instead of depending on the terminal's
  default code page.
- Rules test runner and CI native-command execution now fail hard on non-zero exit codes instead of trusting printed output.
- Historical release readiness checklist updated so it no longer claims an old release APK/package baseline is production-current.
- One-command honest status reporter added: `tools/quality_status_report.ps1`.
- External production readiness gate added:
  `tools/external_production_readiness_check.ps1`. It blocks a 9+ claim until
  release gates, App Check lock state, required handoff docs, and the manual
  production verification checklist are closed.
- Manual external verification checklist added:
  `docs/PRODUCTION_EXTERNAL_VERIFICATION.md`.
- Release mode now silences `debugPrint` globally at bootstrap so diagnostic logs and uid-like values are not printed in production builds.
- General hard-coded 500-record query debt was removed from runtime Dart/Functions code: directory loading, story follow lookup, business profile fallback lookup, appointment conflict checks, and bulk-message target collection now use cursor pages or named bounded live windows.
- Secret scan now explicitly allowlists Firebase public config files on both Android and iOS while continuing to block private keys and server/API secrets elsewhere.
- Android release APK was verified from the user's normal PowerShell session:
  `build\app\outputs\flutter-apk\app-release.apk`.
- Flutter 3.44 built-in Kotlin migration was applied for the app module:
  legacy `kotlin-android` app plugin and `kotlinOptions` were removed, and the
  release gate now blocks regressions.
- Direct Firebase feature-surface debt was reduced from 8 files to 5 files by
  moving staff invite, story, and push token/session logic under data/repository
  boundaries.
- Firebase rules tests now use a 30 second Mocha timeout so emulator startup
  latency does not produce false red builds.
- Cloud Functions modularization started: accounting callables and bulk message
  sending were extracted from `functions/index.js` into dedicated modules while
  preserving their public endpoint names.
- Cloud Functions modularization continued: Places/Routes, AI generation, push
  notifications, scheduled reminders, bulk messaging, and accounting now live in
  dedicated modules while preserving public endpoint names.
- `functions/index.js` was reduced to 193 lines and now acts mainly as shared
  bootstrap/helper plus module registration.
- Explore list/error/empty/skeleton rendering was extracted into
  `HomeExploreContentList`; `public_home` no longer appears in the >30KB feature
  large-file report.
- Customer campaign presentation widgets were moved into
  `customer_campaigns_widgets.dart`, preserving the page library while removing
  campaigns from the >30KB feature large-file report.
- Manual appointment sheet UI was moved into
  `appointment_entry_manual_sheet.dart`, preserving the appointment entry
  library while removing appointments from the >30KB feature large-file report.
- `main.dart` was split into bootstrap, role-gate, and shell part files under
  `lib/app/`; the root entrypoint is now a small bootstrap-only file.
- A central `AppRouteCatalog` was added for named routes, unknown-route fallback,
  and push-notification deep-link navigation. Notification taps now use named
  routes instead of building destination pages inside the push service.
- `AppRouteCatalog` was expanded for account/admin/legal/notification/staff
  shortcut pages, and the account menu now opens those pages through named
  routes instead of direct `MaterialPageRoute` calls.
- Story viewer and business profile post creation flows now also use named
  routes with typed route arguments, reducing direct route construction in
  customer-visible feed/profile paths.
- Image uploads now fail fast on oversized files, apply role metadata, use
  explicit upload/download timeouts, and cache public images for a longer stable
  window. This reduces production cost and list-screen jank risk while the
  thumbnail pipeline is still being planned.
- Thumbnail generation added for business story and business intro/profile-post
  image uploads. New writes store `thumbnailUrl`, and customer-visible post
  lists prefer thumbnails before falling back to full-size media URLs.
- Storage emulator tests now cover generated thumbnail uploads and public reads
  for business intro/story media paths, including non-owner denial.
- Business media upload paths are now owner-scoped
  (`{root}/{ownerUid}/{businessId}/{fileName}`) so new uploads can be authorized
  directly with `request.auth.uid` instead of depending on Storage-to-Firestore
  cross-service ownership lookups.
- Push notification token/session ownership Firestore logic was moved into
  `RxPushNotificationSessionRepository`, reducing the approved direct Firebase
  surface to 5 files.
- Public Firestore read surfaces are now tracked in `docs/PUBLIC_DATA_MATRIX.md`
  and enforced by `tools/public_data_matrix_check.ps1` in the CI quality gate.
- Imported Şanlıurfa/Mardin directory data remains public-readable while client
  writes are denied; live Google Places operational scripts were removed from
  the mobile release path.
- Finance writes and service pricing edits now require owner scope or explicit
  finance/service permissions, and emulator rules cover both paths.
- Explore filtering/sorting and customer appointment status classification were
  moved into domain policies with focused tests.
- Message compose state, message unread-badge decisions, and notification
  center scope state now sit behind small controllers/policies with focused
  tests.
- Message thread state for read marking, send, recall, and open/close actions
  now sits behind `MessageThreadController` with a focused fake-data-source
  test, reducing state logic inside `MessagesInboxPage`.
- Realtime notification Firestore writes were moved behind
  `RxNotificationRepository`; `RxNotificationService` is now a facade and the
  direct Firebase architecture budget was tightened from 5 files to 4 files.
- Follow-cache warmup and business-directory Firestore reads were moved behind
  repository boundaries. The direct Firebase architecture budget is now tightened
  again as part of the staged reduction.
- Current-user state auth/document reads were moved behind
  `CurrentUserStateRepository`; this continued the staged direct Firebase
  surface reduction.
- App session user/business document reads were moved behind
  `AppSessionRepository`; the direct Firebase architecture budget is now
  tightened to 0 approved core files.
- Appointment slot release now exposes a pure slot-id calculation so cancelled
  or no-show rebooking behavior can be tested without Firestore mocks.
- Business profile booking date/time/staff-service suitability decisions were
  moved into a domain policy with focused tests, and the booking widgets were
  split into a separate part so feature large-file budget stays green.
- Discover/Explore business loading state now sits behind
  `HomeExploreController`; load-error/completion state, nearest area detection,
  repeated-location-query decisions, filtered list derivation, and category
  counts are covered by controller/policy boundaries with focused tests.
- Business appointment dashboard date parsing, cancellation/passive
  classification, staff/customer/service label selection, time labels, and day
  capacity calculations now sit in `BusinessAppointmentDashboardPolicy` with a
  focused domain test. That policy also now owns schedule bounds,
  visible-month filtering, and staff fallback/deduplication.
- Business profile edit fallback/validation/readiness behavior and account
  profile edit validation/normalization/verification text now sit in focused
  policy classes with domain tests.
- Manual appointment staff normalization, selected-staff fallback, date/time
  formatting, duration clamping, and form validation now sit in
  `BusinessManualAppointmentPolicy` with a focused domain test.
- Business service management display normalization, active/passive
  classification, price/duration/session validation, and save payload creation
  now sit in `BusinessServiceFormPolicy` with a focused domain test.
- Business product/stok display normalization, numeric parsing/formatting,
  low-stock detection, stock summary calculation, and product form validation
  now sit in `BusinessProductPolicy` with a focused domain test.

## External blockers

- iOS signing team, push, and Crashlytics must be verified on a real device.
- Play Store and App Store privacy/support URLs must be finalized.
- Firebase App Check production enablement requires Firebase Console work.
- The Android release gate currently passes with `-SkipIos`, but the actual APK
  should still be rebuilt and smoke-tested from normal PowerShell after the
  latest dependency/code changes.

## Verified in this Codex session

- `tools/quality_check.ps1 -SkipFlutter` passed.
- `tools/secret_scan.ps1` passed.
- `tools/text_quality_check.ps1` passed and is wired into `tools/ci_quality_check.ps1`.
- `node --check functions/index.js` passed.
- `node --check functions/modules/accounting.js` passed.
- `node --check functions/modules/bulk_messaging.js` passed.
- `node --check functions/modules/directory.js` passed.
- `node --check functions/modules/ai_generation.js` passed.
- `node --check functions/modules/notifications.js` passed.
- `tools/ci_quality_check.ps1` and `tools/quality_check.ps1` now check every
  `functions/**/*.js` file outside `node_modules`, not only `functions/index.js`.
- `node --check emulator_rules_lab/tests/firestore.rules.test.js` passed.
- `node --check emulator_rules_lab/tests/storage.rules.test.js` passed.
- `tools/run_rules_tests.ps1` passed with 29 Firestore/Storage emulator rules
  tests after public data, App Check-adjacent abuse surfaces, finance writes,
  and service pricing permission guards.
- `tools/run_rules_tests.ps1` now validates the native test command exit code.
- `npm audit --omit=dev` for the emulator rules lab reported 0 production
  dependency vulnerabilities. Full dev audit still reports Firebase CLI/Mocha
  tooling advisories, so those should be treated as local test-tooling debt, not
  mobile runtime exposure.
- `tools/ci_quality_check.ps1 -SkipFlutter -SkipRules` passed, including
  architecture, text quality, secret scan, public data matrix, and Functions
  syntax.
- `tools/release_gate_check.ps1 -SkipIos` passed.
- `tools/feature_architecture_report.ps1 -FailOnLargeFiles` passed with 0
  feature files over 30KB.
- `git diff --check` passed; only Git line-ending warnings were reported.
- After adding `MessageThreadController`, `tools/ci_quality_check.ps1
  -SkipFlutter -SkipRules`, `tools/release_gate_check.ps1 -SkipIos`,
  `tools/feature_architecture_report.ps1 -FailOnLargeFiles`,
  `tools/text_quality_check.ps1`, and `git diff --check` passed.
- After moving realtime notification writes behind a repository,
  `tools/architecture_check.ps1`, `tools/ci_quality_check.ps1 -SkipFlutter
  -SkipRules`, `tools/release_gate_check.ps1 -SkipIos`,
  `tools/feature_architecture_report.ps1 -FailOnLargeFiles`,
  `tools/run_rules_tests.ps1`, and `git diff --check` passed. Firestore/Storage
  emulator rules remain at 29 passing tests.
- After moving follow-cache and business-directory reads behind repositories,
  `tools/architecture_check.ps1`, `tools/ci_quality_check.ps1 -SkipFlutter
  -SkipRules`, `tools/release_gate_check.ps1 -SkipIos`,
  `tools/feature_architecture_report.ps1 -FailOnLargeFiles`, and
  `git diff --check` passed. The architecture gate now reports only 2 direct
  Firebase core surfaces outside repository/service/domain.
- After moving current-user state reads behind a repository,
  `tools/architecture_check.ps1`, `tools/ci_quality_check.ps1 -SkipFlutter
  -SkipRules`, `tools/feature_architecture_report.ps1 -FailOnLargeFiles`, and
  `git diff --check` passed. The architecture gate now reports only 1 direct
  Firebase core surface outside repository/service/domain.
- After moving app-session reads behind a repository,
  `tools/architecture_check.ps1`, `tools/ci_quality_check.ps1 -SkipFlutter
  -SkipRules`, `tools/release_gate_check.ps1 -SkipIos`,
  `tools/feature_architecture_report.ps1 -FailOnLargeFiles`, and
  `git diff --check` passed. The architecture gate now reports 0 direct
  Firebase surfaces outside repository/service/domain.
- After moving Discover/Explore loading state into a controller,
  `tools/architecture_check.ps1`, `tools/ci_quality_check.ps1 -SkipFlutter
  -SkipRules`, `tools/feature_architecture_report.ps1 -FailOnLargeFiles`, and
  `git diff --check` passed.
- After moving business appointment dashboard decisions into a domain policy,
  `tools/architecture_check.ps1`, `tools/ci_quality_check.ps1 -SkipFlutter
  -SkipRules`, `tools/feature_architecture_report.ps1 -FailOnLargeFiles`, and
  `git diff --check` passed.
- After expanding business appointment dashboard policy coverage for schedule
  bounds, visible-month filtering, and staff fallback/deduplication,
  `tools/architecture_check.ps1`, `tools/ci_quality_check.ps1 -SkipFlutter
  -SkipRules`, `tools/feature_architecture_report.ps1 -FailOnLargeFiles`,
  `tools/release_gate_check.ps1 -SkipIos`, and `git diff --check` passed.
- After moving business profile edit fallback/validation/readiness decisions
  into a domain policy with a focused test, `tools/architecture_check.ps1`,
  `tools/ci_quality_check.ps1 -SkipFlutter -SkipRules`,
  `tools/feature_architecture_report.ps1 -FailOnLargeFiles`,
  `tools/release_gate_check.ps1 -SkipIos`, and `git diff --check` passed.
- After moving account profile edit validation/normalization/verification text
  into a domain policy with a focused test, `tools/architecture_check.ps1`,
  `tools/ci_quality_check.ps1 -SkipFlutter -SkipRules`,
  `tools/feature_architecture_report.ps1 -FailOnLargeFiles`,
  `tools/release_gate_check.ps1 -SkipIos`, and `git diff --check` passed.
- After moving manual appointment staff/date/time/duration/form decisions into
  a domain policy with a focused test, `tools/architecture_check.ps1`,
  `tools/ci_quality_check.ps1 -SkipFlutter -SkipRules`,
  `tools/feature_architecture_report.ps1 -FailOnLargeFiles`,
  `tools/release_gate_check.ps1 -SkipIos`, and `git diff --check` passed.
- After moving business service management display/form/payload decisions into
  a domain policy with a focused test, `tools/architecture_check.ps1`,
  `tools/ci_quality_check.ps1 -SkipFlutter -SkipRules`,
  `tools/feature_architecture_report.ps1 -FailOnLargeFiles`,
  `tools/release_gate_check.ps1 -SkipIos`, and `git diff --check` passed.
- After moving business product/stok display/form/summary decisions into a
  domain policy with a focused test, `tools/architecture_check.ps1`,
  `tools/ci_quality_check.ps1 -SkipFlutter -SkipRules`,
  `tools/feature_architecture_report.ps1 -FailOnLargeFiles`,
  `tools/release_gate_check.ps1 -SkipIos`, and `git diff --check` passed.
- Full `tools/release_gate_check.ps1` failed only because iOS
  `DEVELOPMENT_TEAM` is missing.
- `tools/quality_status_report.ps1` can be used to see feature architecture,
  internal quality, and release external gate status together.
- `tools/create_clean_source_zip.ps1` creates and verifies a clean source zip
  without build output, caches, `.git`, or signing secrets.
- `tools/restore_android_release_secrets.ps1` restores local Android signing
  secrets from the external desktop backup when a release build is needed.
- `tools/release_gate_check.ps1` now correctly fails while Android signing files
  are not restored locally, and will still report the iOS development team
  blocker after Android signing is restored.
- Runtime search no longer finds hard-coded 500-record query caps in `lib/` or `functions/`.
- Direct Dart SDK invocation works when Dart app data is redirected into `.codex_tmp`, but `dart format` still needs read access to the user's existing Pub cache because the project analysis options include `flutter_lints`.
- `flutter test --no-pub` passed in the redirected Codex Flutter environment
  with 81 tests.
- `tools/feature_architecture_report.ps1` now reports 0 feature files over 30KB.

## Not verified here

- Latest focused Flutter test execution in this Codex shell timed out without
  output; rerun Flutter analyze/test/build from the user's normal PowerShell.
- `dart format` also timed out in this Codex shell; rerun formatting/analyze in
  normal PowerShell before the final release commit if Flutter reports style or
  analyzer issues.
- `flutter build apk --release` should be run by the user in normal PowerShell after code changes; the Codex sandbox can hit Gradle/SDK permission limits that are not app defects.
- iOS release cannot pass until Firebase plist and Apple signing team are configured.

## Current quality estimate

Against a Facebook-level reference score of 10, the project is still not above 9.
Current estimate after these hardening passes: about 8.9 overall when release
operations and product maturity are included. Code/security alone scores higher,
but Facebook-level comparison must include real-device operations, store readiness,
and production monitoring.

The largest blockers to 9+ are still:

- iOS signing and store readiness are blocked by Apple Developer team setup.
- Android build was verified from user PowerShell before clean zip handoff.
  Future build verification should stay in normal PowerShell using
  `tools\restore_android_release_secrets.ps1` and then
  `tools\user_release_build.ps1`, or the raw Flutter commands.
- Admin/moderation now covers claim review, function abuse logs, post reports, review reports, campaign reports, content hide/restore, audit logging, and user block/unblock, but richer abuse dashboards and store-ready moderation operations are not complete.
- Analytics/Crashlytics bootstrap and a starter funnel are wired, including campaign view/create/report, message send, and finance action tracking, but dashboards and release DebugView verification remain incomplete.
- Appointment cancellation/no-show now has a central policy and slot-lock release path for customer, business, and staff flows, but it still needs Flutter test/build and real-device booking/rebooking smoke verification.
- Routing/state architecture is still mixed.
- Cloud Functions are now modularized at the major-section level; remaining
  backend work is more about TypeScript migration, deeper unit tests, runtime
  deployment verification, quotas, dashboards, and alerting.
- Feature-level large Dart files over 30KB are cleared, and `main.dart` has been
  split. The remaining architecture debt is now more about routing/state
  standardization than raw file size.
- Real-device iOS/Android smoke, push, Crashlytics, App Check enforcement, and store privacy validation remain open.
- Media upload hardening is started, but true 10-grade media still needs server
  or build-time thumbnail generation and thumbnail-first list rendering.
