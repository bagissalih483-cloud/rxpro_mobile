

## 57Y_TEST_STRATEGY_INDEX_UPDATE

- Type: documentation / project index / test backlog.
- Source behavior changed: NO.
- Purpose: Added automatic test infrastructure plan to project work area after 57R and 57X locks.
- New/updated doc: docs/rxpro_test_strategy.md.
- Decision: Unit tests should start before the next high-risk migrations; integration tests can wait until later final stabilization.
- Priority: service/repository/policy unit tests first, widget tests second, integration tests third.


## 58B - Test Foundation Lock
- Date: 20260525_094812
- Type: test foundation lock / documentation update.
- Source behavior changed: NO.
- Targeted unit tests: PASS.
- Build decision: PASS.

## 58G - Messaging Cost & Provider Strategy Index Update
- Type: documentation/index update only.
- Source app behavior changed: NO.
- Build: SKIPPED.
- Production deploy: NO.
- Decision: messaging/chat is a separate scalability risk domain; keep Firebase for core business data, keep chat behind provider boundary, do not migrate chat blindly.

## 58I - BusinessProfile current user stream final lock + build
- BusinessProfileRepository.watchCurrentUserDocument helper foundation is preserved.
- usiness_profile_page.dart _currentUserDocStream() delegates to repository helper.
- Reviews/rating, follow, appointment core and messaging/chat were not changed.
- Targeted unit tests and release build are part of this lock.

## 58I REV1 - BusinessProfile current-user stream final lock
- Final lock/build for BusinessProfilePage current-user stream repository migration.
- _currentUserDocStream() uses BusinessProfileRepository.watchCurrentUserDocument.
- Reviews/rating/follow/appointment/messaging unchanged.

## 58I REV8 - BusinessProfile current-user stream final lock
- Repository helper BusinessProfileRepository.watchCurrentUserDocument verified.
- BusinessProfilePage._currentUserDocStream verified as wired to repository helper.
- Reviews/rating/follow/appointment/messaging were not migrated in this step.
- Analyze intentionally skipped in REV8 because existing analyze issues are known and unrelated to this lock.
- Targeted tests exit code: 0; build exit code: 0.

## 64Q - High-Traffic UI Service Boundary Sprint
- Appointment, messaging, staff, account, main shell and business profile Firebase access moved behind repository/service boundaries.
- Direct Firebase surface outside repository/service/domain paths is now 8 files.
- Remaining direct files are service/core infrastructure surfaces.
- `tools/quality_check.ps1 -SkipFlutter` passed; full Flutter/Dart tooling remains blocked in this sandbox.

## 64R - Architecture Tree and Operating Algorithm Enforcement
- Added `tools/architecture_check.ps1`.
- `tools/quality_check.ps1` now runs the architecture boundary check.
- Added target tree and operating algorithm docs under `docs/project_index/`.
- Architecture check passed with 8 approved infrastructure files.

## 64S - Professional Product and Release Audit
- Added `docs/project_index/rxpro_professional_audit_20260526.md`.
- Updated remaining gaps and hardening plan with release, security, CI, package id, signing, Crashlytics, App Check, feed/media/moderation and codebase hygiene gaps.
- Source behavior changed: NO.
- Production deploy: NO.

## 64T - Staff Workspace Release Build Fix
- Fixed nullable `workDurationMinutes` compile failure in `StaffWorkspaceRepository.completeAppointment()`.
- Release build passed in user environment.
- `flutter test`: PASS, 16 tests.
- APK: `build/app/outputs/flutter-apk/app-release.apk`, 61.2 MB.
- Production deploy: NO.

## 64U - Analyze Debt Cleanup Pass
- Cleaned deprecated Flutter API usage, dropdown `initialValue` migration, direct `uuid` dependency, low-risk lint issues and remaining analyze signatures from the latest 8-issue report.
- Static architecture and skip-Flutter quality checks passed.
- User environment `flutter analyze`: PASS, no issues found.
- Production deploy: NO.

## 64V - CI Quality Gate And Release Readiness Lock
- Added CI quality entrypoint: `tools/ci_quality_check.ps1`.
- Added GitHub Actions workflow: `.github/workflows/flutter_quality.yml`.
- Added release readiness checklist under `docs/project_index/`.
- Updated README and professional audit docs to reflect the new quality baseline.
- Local skip-Flutter CI gate passed with architecture check and Cloud Functions syntax check.
- Production deploy: NO.

## 64W - App Observability Bootstrap
- Added `AppObservabilityService` for Crashlytics/global error capture and basic Analytics wiring.
- Wrapped app bootstrap in a guarded root zone.
- Synchronized auth user id into observability providers.
- Local skip-Flutter CI gate passed; full Flutter analyze should be rerun in the user environment.
- Production deploy: NO.

## 64X - Visible Text And AI Prompt Encoding Cleanup
- Added clean Turkish prompt builders for campaign AI and business analysis AI.
- Routed live backend AI calls to clean prompts and clean fallback messages.
- Cleaned the visible phone password reset flow text.
- Cleaned accounting TypeScript callable/validator error messages.
- Added `tools/mojibake_scan.ps1` for controlled encoding scans.
- Node syntax and skip-Flutter CI gate passed.
- Production deploy: NO.

## 64Y - Feature Architecture Report And First Presentation Slice
- Added `tools/feature_architecture_report.ps1`.
- Moved password reset flow into `lib/features/auth/presentation/pages/`.
- Kept old auth import path as a compatibility export.
- Added widget test for password reset labels and step transitions.
- Skip-Flutter CI gate passed; targeted Flutter test timed out in this sandbox and should be run in the user environment.
- Production deploy: NO.

## 64Z - User Quality Run Follow-Up
- User widget test passed and full Flutter tests passed with 17 tests.
- Removed the only reported analyze issue: unnecessary `dart:ui` import.
- Added PowerShell fallback scans so architecture/mojibake tools no longer require `rg`.
- Skip-Flutter CI gate passed after the fix.
- Production deploy: NO.

## 65A - Auth Presentation Page Split
- User full quality gate was green before this split: analyze no issues, 17 tests, CI completed.
- Moved `FixLoginGatePage` into auth presentation/pages with a compatibility export.
- Extracted guest actions and brand header into auth presentation/widgets.
- Cleaned visible login/register Turkish strings.
- Auth now has 0 Dart files above 30KB; project large-file count is now 10.
- Skip-Flutter CI gate passed.
- Production deploy: NO.

## 65B - Public Home Account Entry Presentation Split
- Moved the real account entry page into public_home presentation/pages with a compatibility export.
- Extracted account cards, account menu scaffold, lightweight profile/settings pages and account context models.
- Public home now has 0 Dart files above 30KB; project large-file count is now 9.
- Feature architecture report passed and skip-Flutter CI gate passed.
- Flutter format/analyze timed out in this sandbox; rerun the full user quality gate before build.
- Production deploy: NO.

## 65C - Business Analysis Presentation And Service Split
- Moved the real business analysis page into presentation/pages with a compatibility export.
- Moved the business product movement page into presentation/pages with a compatibility export.
- Extracted analysis widgets, view models, AI callable service and computation service.
- Cleaned business analysis visible text encoding in this feature slice.
- Business analysis now has 0 Dart files above 30KB; project large-file count is now 8.
- Feature architecture report passed and skip-Flutter CI gate passed.
- Full Flutter analyze/test should be rerun in the user environment.
- Production deploy: NO.

## 65D - Appointments Presentation Split And Analysis Service Test
- Added pure tests for `BusinessAnalysisComputationService`.
- Moved appointment entry and customer appointments pages into appointments presentation/pages with compatibility exports.
- Extracted dashboard views/models and customer appointment UI widgets.
- Updated imports in main, push notifications and public home to the new appointment presentation paths.
- Appointments now has 0 Dart files above 30KB; project large-file count is now 6.
- Feature architecture report passed and skip-Flutter CI gate passed.
- Targeted Flutter test timed out in this sandbox; run the full quality gate in the user environment.
- Production deploy: NO.

## 65E - Business Finance Presentation Split And Formatter Test
- Moved the real business finance page into businesses presentation/pages with a compatibility export.
- Extracted finance widgets, view models and formatter helpers under businesses presentation.
- Added focused pure tests for finance formatter behavior.
- Businesses now has a presentation boundary; project large-file count is now 5.
- Feature architecture report passed and skip-Flutter CI gate passed.
- Full Flutter analyze/test should be rerun in the user environment.
- Production deploy: NO.

## 65F - Business Staff Management Presentation Split
- Moved the real staff management page into businesses presentation/pages with a compatibility export.
- Split staff create/edit form into its own presentation page.
- Extracted staff group/card UI widgets under businesses presentation.
- Updated business owner hub and public home imports to the new presentation page path.
- Project large-file count is now 4; businesses large-file count is now 3.
- Feature architecture report passed and skip-Flutter CI gate passed.
- Full Flutter analyze/test should be rerun in the user environment.
- Production deploy: NO.

## 65G - Accounting Sales Presentation Split
- Moved the real accounting sales page into accounting presentation/pages with a compatibility export.
- Extracted sales wizard widgets and lightweight wizard/catalog models under accounting presentation.
- Updated accounting shell import to the new presentation page path.
- Accounting now has a presentation boundary and 0 files above 30KB.
- Project large-file count is now 3; features without presentation is now 11.
- Feature architecture report passed and skip-Flutter CI gate passed.
- Full Flutter analyze/test should be rerun in the user environment.
- Production deploy: NO.

## 65H - Location Discovery And Directions Flow
- Added shared business location parsing for direct coordinates, Firestore GeoPoint and Google Places geometry/address/map fields.
- Added Google Maps directions launching from discovery cards.
- Extended discovery sorting with smart recommendation, nearest, rating/popularity, category and A-Z modes.
- Added member-aware discovery cards: members keep profile/photo/rating actions; directory-only records stay compact and directions-focused.
- Added business-side location capture in the business profile edit screen and persisted coordinate fields plus GeoPoint.
- Added pure tests for location parsing and distance calculation.
- Public home remains at 0 files above 30KB after extracting explore cards.
- Feature architecture report passed and skip-Flutter CI gate passed.
- Targeted Flutter test timed out in this sandbox; run the full quality gate in the user environment.
- Production deploy: NO.

## 65I - Location Geo Index Query Foundation
- Added pure geohash encoding, prefix payload and neighboring-prefix helpers for Firestore-friendly nearby discovery.
- Added Firestore field constants for `geoHash`, `geoHash4`, `geoHash5`, `geoHash6`, `geoHash7`, `locationUpdatedAt` and `locationSource`.
- Business location saves now persist geohash prefixes together with coordinates and GeoPoint.
- Discovery now uses indexed nearby business queries when user location is available, then falls back to the existing cache for legacy/imported records.
- Radius changes refresh the indexed nearby query when a user location exists.
- Added a dry-run-first Firebase Admin backfill script for old/imported business records: `npm run backfill:business-geo-index -- --limit=50`, then `-- --write` when reviewed.
- Added pure tests for known coordinate encoding, prefix payloads, radius precision and nearby prefix coverage.
- Project counts are now 194 `lib` Dart files, 11 `test` Dart files, 3 large Dart files above 30KB and 11 features without presentation.
- Feature architecture report passed and skip-Flutter CI gate passed.
- Backfill script syntax check passed.
- Dart format and targeted Flutter tests timed out in this sandbox; run the full quality gate in the user environment.
- Production deploy: NO.

## 65J - Business Appointment Management Presentation Split
- Extracted the customer direct-message page into businesses presentation/pages.
- Extracted appointment summary, status pill, customer info row and quick customer profile sheet into businesses presentation/widgets.
- Removed unused legacy appointment summary helpers from the root page.
- `business_appointment_management_page.dart` is now below the 30KB budget.
- Project counts are now 196 `lib` Dart files, 11 `test` Dart files, 2 large Dart files above 30KB and 11 features without presentation.
- Feature architecture report passed and skip-Flutter CI gate passed.
- New appointment presentation slices mojibake scan passed.
- Dart format and Flutter analyze timed out in this sandbox; run the full quality gate in the user environment.
- Production deploy: NO.

## 65K - Business Analysis Local AI Compile Fix
- Fixed `BusinessAnalysisComputationService.localAiReport` so it accepts the `periodLabel`, `periodMode` and `anchorDate` values already passed by the page.
- Resolves the compile error where `periodLabel` was referenced as an undefined getter inside the service.
- Skip-Flutter CI gate passed and the touched service mojibake scan passed.
- Targeted Flutter test timed out in this sandbox; rerun the full quality gate in the user environment.
- Production deploy: NO.

## 65L - Analyze Account Entry And Widget Key Cleanup
- Imported the account mode extension into `account_entry_page.dart` so `accountMode.isCorporate` resolves.
- Removed the unused `_displayNameOf` helper from `account_entry_page.dart`.
- Added `super.key` to public widget constructors flagged by analyze in appointment, business analysis and public home presentation slices.
- Skip-Flutter CI gate passed, feature architecture report passed and touched-slice mojibake scan passed.
- Targeted Flutter analyze timed out in this sandbox; rerun full analyze in the user environment.
- Production deploy: NO.

## 65M - Google Places Live Directory And Seed Index Foundation
- Added callable Cloud Function `searchNearbyDirectoryBusinesses` in `europe-west1`.
- Discovery now merges RxPro member businesses with live Google Places directory-only businesses when user location is available.
- Google API key stays server-side through `GOOGLE_PLACES_API_KEY`.
- Category selection now reloads the live nearby search.
- Added dry-run-first seed script `functions/scripts/seedGooglePlacesDirectoryIndex.js` for large-city minimum index creation.
- Added parser test coverage for Google Places live directory payloads.
- Node syntax checks passed for `functions/index.js` and the seed script.
- Dart/Flutter commands timed out in this environment; rerun full format/analyze/test locally.
- Production deploy: pending secret and Functions deploy.

## 65N - Places Runtime Healthcheck And Business Claim Requests
- Live endpoint was reachable, but the currently deployed function returned `500 INTERNAL`; deployment exists, runtime/config needs the new patch redeployed.
- Added safe `GOOGLE_PLACES_API_KEY` secret reading and callable `healthCheck` support.
- Wrapped Google Places request failures into structured callable errors.
- Added debug live-sample mode and fallback type groups for Nearby Search category validation issues.
- Added `tools/check_places_function.ps1` for post-deploy validation.
- Added `businessClaimRequests` collection constant and Firestore rules for user-owned pending claim requests.
- Added `HomeExploreClaimRepository`.
- Directory-only discovery cards now show `Bu işletme benim` and create a pending claim request.
- Node syntax, skip-Flutter CI gate and feature architecture report passed.
- Flutter analyze/test timed out in this environment; rerun locally.

## 65O - Places Secret Automation And Live Check Cleanup
- Added `tools/set_places_secret_from_file.ps1` to read the desktop key file and update the Firebase `GOOGLE_PLACES_API_KEY` secret without printing the key.
- User-side deploy and live check now pass; `searchNearbyDirectoryBusinesses` returned real `google_places_live` businesses for the `beauty_care` sample.
- Cleaned `tools/check_places_function.ps1` so live checks print a compact summary instead of dumping the full Google Places JSON response.
- The `firebase-functions@latestpowershell` terminal line was only an accidental pasted command; the later real function check passed.
- Full Flutter analyze/test and APK smoke test should be rerun after the next app-side changes.

## 65P - App Display Name Rebrand To fi
- Earlier changed Android and iOS install-visible app names to `fi`; superseded by 65X where the publish name is corrected to `fix`.
- Updated Flutter app title, notification fallback title/channel name, iOS permission prompt brand text, web/PWA title, and desktop window metadata.
- Cleaned remaining user-facing brand text in campaign fallback, finance PDF title, account fallback and accounting checklist.
- Kept package identity stable: Android `applicationId`, iOS bundle identifier, Firebase package config and `pubspec.yaml` Dart package name were not changed.
- Kept schema fields such as `isRxProMember` unchanged for data compatibility.
- Web manifest JSON, iOS plist XML and skip-Flutter quality gate passed.
- `dart format` timed out in this environment; rerun full Flutter format/analyze/test locally before release build.

## 65Q - Turkish UX Copy And Istanbul Explore Starter
- Cleaned Turkish character corruption in messages, campaign management, AI campaign creation, bulk message, guest login sheet, explore cards and shared category labels.
- Reworked messages UX language by role: business owners manage individual user messages, individual users message businesses.
- Explore now has an Istanbul starter discovery when user location is not available, so the first screen is not empty before the user grants location or optimizes filters.
- Category/radius changes now refresh starter discovery as well as location-based discovery.
- Existing schemas and compatibility fields such as `isRxProMember` were preserved.
- Targeted mojibake scan and skip-Flutter quality gate passed.
- Flutter format/analyze/test timed out in this environment; rerun locally before APK build.

## 65R - Test Inventory And Connected UX Cleanup
- Re-measured coverage surface: 198 `lib` Dart files and 13 `test` Dart files, so test-to-source file ratio is still only about 6.6%.
- Added campaign model tests for `BulkMessageDraftInput` ready-draft payloads and `CampaignFieldReaders` fallback/date parsing.
- Connected business campaign cards to a usable detail bottom sheet instead of leaving the business campaign list as summary-only.
- Changed bulk message drafts from `not_connected` to `draft_ready` and cleaned the screen copy so it reflects a safe ready-for-approval draft flow.
- Removed visible dead controls from accounting report/receivable/expense previews and the campaign AI preview card.
- Cleaned remaining real mojibake in business profile edit, product management, notification center, role normalization comments and related business surfaces.
- Current structural gaps remain: 2 Dart files above 30KB, 11 features without presentation directories, and accounting write flows still gated behind the planned secure Cloud Function layer.
- Verification: targeted mojibake scan passed, feature architecture report passed, `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild` passed.
- Sandbox limitation: `dart --version`, `dart format` and targeted `flutter test` timed out in this environment; rerun locally before APK build.

## 65S - Large Page Split To Professional Feature Slices
- Split `business_profile_page.dart` from a 77.6KB root page into a small page shell plus focused profile header, intro, booking and reviews part files.
- Split `staff_workspace_page.dart` from a 53.7KB root page into a small page shell plus focused permissions, actions and widget part files.
- All new business profile/staff workspace part files stay under the 30KB large-file budget.
- Feature architecture report now shows `Large files over 30KB: 0`.
- Current count after the split is 205 `lib` Dart files and 13 `test` Dart files; test ratio is still only about 6.3%, so the next quality push should be tests and remaining feature boundaries.
- Targeted mojibake scan passed.
- `tools/feature_architecture_report.ps1` passed.
- `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild` passed.
- Sandbox limitation: full `dart format`, `flutter analyze` and `flutter test` should still be rerun locally.

## 65T - Category And Session Role Test Coverage
- Added `BusinessCategories` tests for Turkish normalization, dynamic fallback selection, selected-category matching and Firestore compatibility fields.
- Expanded `SessionRolePolicy` tests for modern individual precedence, linked-staff active/inactive resolution and owner UID authority.
- Current count is now 205 `lib` Dart files and 14 `test` Dart files; test-to-source file ratio improved to about 6.8%.
- Feature architecture report passed with `Large files over 30KB: 0`.
- `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild` passed.
- Sandbox limitation: full Flutter test execution should still be rerun locally.

## 65U - Staff Workspace Analyze Cleanup
- Fixed analyzer issue from the staff workspace split by moving `_toggle` back into the actual `State` subclass so `setState` is used from a valid instance member.
- Qualified `_staffExpenseLiveWriteEnabled` with `_StaffWorkspacePageState` inside the staff actions extension.
- User-side test run before this patch reported `00:04 +42: All tests passed!`.
- Local skip-Flutter quality gate and feature architecture report passed again; `Large files over 30KB: 0` remains true.
- Sandbox limitation: `flutter analyze --no-pub` timed out locally in this environment, so rerun `flutter analyze` on the user machine to confirm the two reported issues are gone.

## 65V - Business Customer CRM And Segment Bulk Messaging
- Added `businessCustomers` as a first-class Firestore collection constant and allowed it through business-scoped Firestore rules.
- Added `BusinessCustomerRepository` and pure segmentation helpers that merge manual customer records with appointment-derived customer history.
- Added a corporate `Müşteri Defteri` page with manual customer entry, search, status/segment filtering, customer note/classification updates and appointment-history metrics.
- Connected the business owner hub and staff workspace customer permission action to the new customer panel.
- Extended `BulkMessageCreatePage` and `BulkMessageDraftInput` so selected customer segments open a business-bound draft with audience metadata and estimated target count.
- Added unit coverage for customer segmentation and manual/appointment record merge behavior.
- Inventory after patch: 207 `lib` Dart files, 15 `test` Dart files, and `Large files over 30KB: 0`.
- Verification: skip-Flutter CI gate passed, feature architecture report passed, targeted mojibake scan passed.
- Sandbox limitation: `dart format`, `flutter analyze --no-pub` and targeted Flutter test timed out in this environment; rerun full Flutter quality gate locally before APK build.

## 65W - Startup Freeze Guard And APK Launch Diagnostics
- Startup freeze guard added; app-name correction is superseded by 65X where the publish name is set to `fix`.
- Changed app startup so push notification initialization and follow-cache warmup run after the first frame instead of blocking the first visible screen.
- Made push notification initialization timeout-safe around permission, first token sync and initial message reads.
- Changed observability initialization so Crashlytics setup no longer blocks the first frame.
- Cleaned the remaining visible login copy from `fix hesabınla devam et` to `fi hesabınla devam et`.
- Hardened `tools/apk_test_install.ps1` so it can find `adb.exe` from Android SDK paths, launches with `am start`, and saves a post-launch `06_runtime_logcat.txt`.
- Verification: PowerShell script syntax check passed, skip-Flutter CI gate passed, targeted mojibake scan passed.

## 65X - Published App Name Correction To fix
- Corrected the install-visible and publish-visible app name from `fi` to `fix`.
- Updated Android label, iOS display/bundle name, iOS permission prompts, Flutter `MaterialApp.title`, web/PWA metadata, macOS/Linux/Windows desktop titles and Android notification fallback/channel name.
- Renamed the Flutter root widget from `FiApp` to `FixApp` for consistency.
- Package/application identifiers were intentionally preserved for Firebase and installed-app compatibility.
- Verification: skip-Flutter CI gate passed, touched-file mojibake scan passed, exact brand spot-check passed.
- Sandbox limitation: `flutter analyze --no-pub` timed out in this environment; rerun locally after rebuild.

## 65Y - Explore Freeze Stabilization
- Reviewed `EXPLORE_FREEZE_DEBUG_20260526_160023.zip`; the app launched and stayed visible, but logcat showed skipped frames on the main thread during cold start and early explore interaction.
- Reworked `HomeExplorePage` so the first frame is not blocked by immediate location/directory work; starter discovery now starts after the first frame and silent location lookup is delayed.
- Kept previous explore results on screen while category/radius refreshes run, with a small progress indicator instead of a blocking full-screen wait.
- Added ticket-based stale-load protection so older directory requests cannot overwrite newer filter results.
- Added timeout guards for silent location reads, manual location fetch, Firestore business directory queries and Google Places callable requests.
- Added `FIX_EXPLORE_*` debug markers for the next device log package: load start/done/fail, directory starter merge count and Places callable duration.
- Added `tools/explore_freeze_debug.ps1` so the next device run can capture launch, logcat, gfx/mem/cpu/activity and filtered `FIX_EXPLORE_*` lines in one zip.
- Split shared explore header/empty-state widgets into `home_explore_shell_widgets.dart`; feature architecture report is back to `Large files over 30KB: 0`.
- Verification limitation: `dart format` and targeted `flutter test` timed out in this environment; rerun the local PowerShell APK/debug flow and share the new log if any freeze remains.

## 65Z - PDF Audit Follow-up: Session And Cache Hardening
- Reviewed `RxPro_Performans_Mimari_Eksiklik_Raporu_26_Mayis_2026.pdf` and `rxpro_mimari_analiz.pdf`; the strongest still-valid findings are session/state duality, explore performance, SharedPreferences overhead, pagination/test/backend modularity and release readiness.
- Removed `CurrentUserStateService` from `HomeExplorePage`; the explore header now reads the active user name from `AppSessionScope`, reducing dual-session drift risk in the highest-traffic public screen.
- Kept unread badges on their repository streams and removed the old current-user fallback from the explore header.
- Changed `AppCacheService` to cache the `SharedPreferences.getInstance()` future instead of reopening the instance for every read/write.
- Verification: skip-Flutter CI gate passed, feature architecture report passed and `Large files over 30KB: 0` remains true.
- Remaining high-priority report items: AppSession migration for other old-state consumers, function modularization, cursor pagination, media cache pipeline, emulator/rules/function tests and release signing/applicationId.

## 66A - Explore Algorithm Fallback Repair
- Reviewed the end-to-end explore flow from `HomeExplorePage` through `BusinessDirectoryCacheService`, Firestore directory reads, Google Places live directory calls, category normalization and card rendering.
- Fixed the startup race where the Istanbul starter directory and delayed silent-location refresh could overlap; the starter directory now completes first, then location-based refresh runs after it.
- Protected the visible list from being wiped by an empty later refresh, so a failed or empty nearby query no longer turns a populated starter explore page into an empty screen.
- Changed the position-based explore fallback: if nearby Firestore and live Places both return no items, the app now falls back to the same starter directory instead of returning only the raw local business list.
- Kept the explore shell visible during first load and filter reloads; the screen now shows a non-blocking loading/empty state instead of a full-screen spinner.
- Added legacy mojibake cleanup for Google Places/directory payload text and expanded category normalization coverage for garbled Turkish labels.
- Added tests for category mojibake normalization and directory item text cleanup.
- Verification: `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild` passed and `tools/feature_architecture_report.ps1` passed with `Large files over 30KB: 0`.
- Sandbox limitation: full Flutter analyze/test should be rerun locally before the next APK build.

## 66B - Explore Radius And Card Semantics Tightening
- Changed the location-based explore algorithm so an empty nearby result stays empty instead of falling back to the Istanbul starter directory; this makes 5 km and 50 km filters represent the selected location/radius truthfully.
- Manual location refresh and radius changes now switch sorting to distance so the nearest businesses are presented first after the user asks for location-based discovery.
- Force refreshes and location-based refreshes now replace the visible directory even when the result is empty, preventing stale wider-radius results from staying on screen.
- Silent automatic location refreshes still preserve the starter list if they find no nearby result, so the first screen does not blank itself before the user explicitly filters by location/radius.
- Clarified the empty state for location-based searches with a radius-specific message.
- Updated explore cards so the business name is shown in strong uppercase, proximity is labelled as `Çok yakın`, `Yakın`, `Orta mesafe` or `Uzak`, and the map CTA reads `Yol tarifi al`.
- Made live Google Places calls intentionally limited to the supported marketplace categories: beauty/care, health/clinic and sport/fitness. Other categories remain available for member/Firestore records but are not queried from Places yet.
- Updated the Places Cloud Function so `Tümü` fans out across supported category groups instead of depending on one 20-result mixed query.
- Expanded Google type classification for `medical_center`, `yoga_studio` and pilates-like entries.
- Verification: skip-Flutter CI gate passed and feature architecture report passed with `Large files over 30KB: 0`.

## 66C - Places Query Expansion And Radius Narrowing
- Narrowed the default explore radius from 25 km to 10 km and capped the UI radius slider at 50 km instead of 100 km.
- Increased the mobile Places request target from 20 results to 80 results with controlled `maxSearchCalls` budgeting.
- Reworked the Cloud Function from category-level fan-out to type-level fan-out; supported Google place types are queried separately, deduplicated by place id, sorted by distance and capped before returning to the app.
- `Tümü` now interleaves supported beauty/care, health/clinic and sport/fitness types so one dense category cannot consume the whole response.
- Places fan-out calls run in parallel inside the Cloud Function to avoid making the user wait for 8-12 sequential Google requests.
- Increased Places callable/client timeout guards to 12 seconds to match the wider search.
- Important policy note: Google Places content should not be treated as a permanent import database. Store/claim owned business data in RxPro; for Google directory records, keep `placeId` as the durable key and use short-lived query/display caches.
- Verification: skip-Flutter CI gate passed and feature architecture report passed with `Large files over 30KB: 0`.

## 66D - District Discovery Index And Query Gate
- Added a Google Places directory snapshot index through `businessPlaceIndex`; live Places results are now tagged with category, address, city, district, area label, coordinates, geohash prefixes, Google place id and a 30-day cache policy.
- Added `placeQueryBuckets` metadata for district/category/radius query batches so repeated discovery work can lean on RxPro's own indexed place ids instead of treating every screen load as a cold Google query.
- Changed nearby discovery to merge member businesses, cached directory businesses and fresh Google results, deduplicating by `placeId` and preferring claimed/RxPro member records.
- Added a database-first guard: if the local district/category index already has enough nearby cards, the app serves that index without opening another Google live call.
- Restricted client writes to `businessPlaceIndex` and `placeQueryBuckets`; both collections are public-readable but server-owned.
- Added a 1 km location-query gate: pressing `Konum al` inside the same 1 km area keeps the current result list instead of firing another live Places query.
- Kept the UI radius as a local filter while the live location package fetches a wider 50 km set, so 5 km/10 km/50 km changes can be resolved from the same cached result package.
- Split explore search/category controls and location-query policy out of the main page; `HomeExplorePage` is back under the 30 KB file budget.
- Directory-only business cards now show uppercase business name, category/location/proximity metadata and a full-width `Yol tarifi al` action.
- Cached district `areaLabel` values now feed the visible card location label before falling back to raw address text.
- Added unit coverage for the 1 km location-query policy.
- Verification: skip-Flutter CI gate passed, Cloud Functions syntax check passed, feature architecture report passed with `Large files over 30KB: 0`.
- Sandbox limitation: targeted Flutter test timed out in this environment; rerun full `flutter analyze` and `flutter test` locally before APK build.
- Deploy required: `firebase deploy --only functions:searchNearbyDirectoryBusinesses,firestore:rules`.

## 66E - UI Design System First Pass
- Reviewed the three UI/UX PDF notes and consolidated the shared direction: role-based simplification, semantic status colors, standard components, skeleton loading, counted category chips and clearer Explore cards.
- Expanded `RxColors` with production semantic tones for success, warning, danger and premium states without changing the existing brand primary color.
- Added shared UI primitives: `RxSectionHeader`, `RxStatusChip`, `RxEmptyState` and `RxSkeletonCard`.
- Changed the Explore empty/error state to use the shared `RxEmptyState` standard.
- Added category count badges to the Explore category row so filters communicate how many results are available in the current search/radius context.
- Added skeleton cards for the first Explore load instead of relying only on a linear progress indicator.
- Extracted Explore category counting into a domain helper so `HomeExplorePage` stays under the 30 KB budget.
- Added unit coverage for category count behavior.
- Verification: skip-Flutter CI gate passed and feature architecture report passed with `Large files over 30KB: 0`.
- Sandbox limitation: targeted `dart analyze` timed out in this environment; rerun full `flutter analyze` and `flutter test` locally.

## 66F - Explore Category Visual Identity
- Added a dedicated category visual style model for Explore so every marketplace category has a stable pastel card/chip identity.
- Applied category colors to business cards and category chips: beauty/care uses a soft pink identity, health/clinic stays clean white with green medical accents, sport/fitness uses light blue, consulting uses premium purple, organization uses amber and education uses indigo.
- Member business cards now keep their richer profile actions while adopting the category background, border and accent color.
- Directory-only cards now inherit category color too, but remain simpler with the route-first `Yol tarifi al` action.
- Category chips now include icons and count badges colored from the same category identity.
- Added unit coverage for category-to-style mapping.
- Verification: skip-Flutter CI gate passed and feature architecture report passed with `Large files over 30KB: 0`.
- Local retest required: rerun `flutter analyze` and `flutter test`.

## 66G - Corporate Owner Overview Panel
- Added a modern corporate owner summary panel above the older accordion menu so business owners see a quick operating overview before drilling into modules.
- The panel includes a 2x2 action/metric grid for appointments, customer messaging, campaigns and profile completion.
- Added quick actions for appointment management, bulk messaging and finance/operation details.
- Added a testable `AccountOwnerOverviewModel` that computes profile completion and active/review status from business profile data.
- Connected the panel to existing business modules without changing routing contracts.
- Added unit coverage for owner overview status and profile completion behavior.
- Verification: skip-Flutter CI gate passed and feature architecture report passed with `Large files over 30KB: 0`.
- Local retest required: rerun `flutter analyze` and `flutter test`.

## 66H - Messaging UI Role-Aware Modernization
- Added a testable `MessageUiPolicy` so topic labels, status labels, role-specific input hints, empty states and read receipts are controlled from one domain helper.
- Added shared messaging UI widgets for the inbox header, loading skeletons, thread context panel, closed-thread notice and fixed message input bar.
- Updated the messages inbox so business owners see a corporate inbox context and individuals see a direct `Yeni Mesaj` action without mixing the two workflows.
- Reworked thread list cards with unread state, topic/status chips, clearer hierarchy and safer truncation.
- Reworked conversation screens with a role-aware context panel, modern message bubbles, closed/open state messaging and a stable bottom input bar.
- Added unit coverage for role-aware message UI policy behavior.
- Verification: skip-Flutter CI gate passed and feature architecture report passed with `Large files over 30KB: 0`.
- Sandbox limitation: targeted Flutter test timed out in this environment.
- Local retest required: rerun `flutter analyze` and `flutter test`.

## 66I - Campaign AI UTF-8 Response Hardening
- Added a dedicated `CampaignAiResponseDecoder` that decodes Cloud Function responses from raw UTF-8 bytes before JSON parsing.
- Changed the campaign AI request body to send explicit UTF-8 bytes.
- This prevents Turkish campaign text like `Mayıs`, `Sağlık`, `güzellik` and `randevu alın` from being corrupted when an HTTP response omits or misreports charset metadata.
- Added unit coverage for Turkish UTF-8 campaign response decoding.
- Verification: skip-Flutter CI gate passed, feature architecture report passed with `Large files over 30KB: 0`, and source scan found no literal mojibake markers.
- Local retest required: rerun `flutter analyze` and `flutter test`.

## 66J - Customer Ledger Direct Message Integration
- Added a testable `BusinessCustomerActionPolicy` for customer-card actions and customer-segment bulk message audience labels.
- Connected `BusinessCustomersPage` customer cards to `BusinessCustomerDirectMessagePage` when the record has a linked individual user id.
- Preserved manual customers as CRM/segmentation records; manual records without a linked user id are not shown a one-to-one DM action.
- Added linked-customer count metadata to bulk message drafts created from customer segment filters.
- Hardened `BusinessCustomerMessageRepository` writes so business-to-customer messages now include sender uid/name, unread flags, topic/status, read receipt fields and modern `messageThreads` compatibility fields.
- Updated message model parsing to normalize Firestore `Timestamp` values into sortable ISO strings while preserving local ISO fallbacks.
- Extracted customer-card metric and segment badge widgets to keep `business_customers_page.dart` below the large-file budget.
- Added unit coverage for customer action policy and message model date parsing.
- Verification: skip-Flutter CI gate passed, feature architecture report passed with `Large files over 30KB: 0`, and source scan found no literal mojibake markers.
- Local retest required: rerun `flutter analyze` and `flutter test`.

## 66K - Bulk Message Draft Visibility
- Split campaign collection visibility so business campaign management reads both published campaigns and `bulkMessageDrafts`, while customer campaign discovery still reads only published campaign collections.
- Bulk message drafts created from the customer ledger now appear in the business campaign management draft workflow instead of being hidden after save.
- Normalized bulk draft cards so category reads `Toplu mesaj`, description falls back to a message-specific empty state and the target/channel appears in the detail metadata line.
- Added test coverage to keep bulk message draft collections business-only.
- Verification: skip-Flutter CI gate passed and feature architecture report passed with `Large files over 30KB: 0`.
- Local retest required: rerun `flutter analyze` and `flutter test`.

## 66L - Bulk Message Dispatch Foundation
- Added the callable Cloud Function `sendBulkMessageDraft` for owner-authorized, consent-gated bulk message delivery.
- The function collects linked `businessCustomers`, respects segment metadata, filters customers without explicit campaign/bulk-message consent, writes app notifications and records sent/no-target status back on the draft.
- Added Flutter service support for invoking the callable and parsing send results.
- Business campaign detail sheets now show a `Toplu Mesajı Gönder` action for ready bulk-message drafts and refresh the list after both draft creation and delivery.
- Customer notification feeds now include `bulkMessage` notifications instead of filtering them away.
- Customer ledger manual/classification forms now store campaign/bulk-message consent fields, and eligible linked customers are marked on customer cards.
- Added unit coverage for send-result parsing and bulk-message eligibility merging.
- Removed an unreachable mojibake fallback block from the campaign Cloud Function path; the active campaign prompt/fallback remains on the clean UTF-8 builder.
- Verification: skip-Flutter CI gate passed, Cloud Functions syntax check passed, feature architecture report passed with `Large files over 30KB: 0`.
- Local retest required: rerun `flutter analyze` and `flutter test`; deploy required with `firebase deploy --only functions:sendBulkMessageDraft`.

## 66M - Bulk Message Production Hardening
- Hardened `sendBulkMessageDraft` with an atomic claim step so the same draft cannot be sent twice by rapid taps or concurrent requests.
- Added `attemptId`, `alreadySent` and `alreadySending` response metadata so Flutter can show deterministic send-state feedback.
- Added deterministic notification document ids per draft/customer pair to prevent duplicate customer notifications on retries.
- Added `bulkMessageSendLogs` audit records for each send attempt with sender, business, draft, target count, delivered count and final status.
- Added stale `sending` recovery and `send_failed` retry support so an interrupted send attempt does not leave the draft permanently blocked.
- Business campaign draft filtering now treats `send_failed` as retryable and shows failed bulk drafts with a clear `Hata` state.
- Bulk-message cards and detail sheets now show delivery summaries such as `12 hedef / 12 bildirim`.
- Extracted the business campaign item view model into the campaign domain layer so `business_campaigns_page.dart` stays below the 30 KB file budget.
- Extended send-result model tests for attempt metadata and already-sent parsing.
- Verification: skip-Flutter CI gate passed, Cloud Functions syntax check passed, feature architecture report passed with `Large files over 30KB: 0`.
- Local retest required: rerun `flutter analyze` and `flutter test`; deploy required with `firebase deploy --only functions:sendBulkMessageDraft`.

## 66N - Explore Route Distance Clarity
- Added the callable Cloud Function `calculateBusinessRouteInfo` using Google Routes `computeRoutes` so Explore can fetch actual driving route distance and duration separately from straight-line proximity.
- Added a Flutter route-distance service with a 15-minute in-memory cache keyed by coarse user location and business destination.
- Explore cards now label coordinate distance as `Yaklaşık ... yakınında` and show `Araçla ... · ...` route information for the first visible nearby cards when user location is available.
- Directory-only Google Places cards keep the route-first flow but can now display real route distance without turning every listing into a full RxPro member profile.
- Added `tools/check_route_function.ps1` for deployed health-check and live route sample validation.
- The fast radius filter and sorting still use coordinate distance for performance; route distance is presentation guidance, not the expensive list filter.
- Added unit coverage for route distance and duration formatting.
- Verification: Cloud Functions syntax check passed.
- Local retest required: rerun `flutter analyze` and `flutter test`; deploy required with `firebase deploy --only functions:calculateBusinessRouteInfo`.
- Google Cloud requirement: enable Routes API for the same API key/Cloud project before live route distance can appear.

## 66O - Login Brand Banner and Explore Header Refresh
- Moved the supplied Fix promotional artwork into the login brand area as a compact clipped banner instead of placing it on Explore.
- Added reusable Fix wordmark, verified wordmark and user-initial avatar widgets for product-wide header consistency.
- Reworked the Explore top bar into a compact app header: verified Fix mark, user profile circle, greeting/name, message icon and notification icon.
- Kept Explore content density intact by avoiding a large marketing banner above the discovery list.
- Verification: skip-Flutter CI gate passed and feature architecture report passed with `Large files over 30KB: 0`.
- Local retest required: rerun `flutter analyze` and `flutter test`.

## 66P - Explore Control Panel Modernization
- Replaced the old form-like Explore filter panel with a compact mobile control panel.
- Location state now uses a clearer visual header with a location/city icon and a tonal `Konum al` action.
- Radius remains a slider, but now has a fixed `km` badge so the selected scan range is more readable.
- Sort selection moved from a dropdown to horizontal mode chips: `Akıllı`, `Yakın`, `Puan`, `Kategori`, `A-Z`.
- The control UI was extracted into `HomeExploreControlPanel` to keep `home_explore_page.dart` small and preserve feature boundaries.
- Local retest required: rerun `flutter analyze` and `flutter test`.

## 66Q - Login Form Componentization
- Extracted login form primitives into `FixSegmentedTabs`, `FixRememberPasswordTile`, `FixLoginPanel`, `FixFlowInfo`, `FixInput` and `fixInputDecoration`.
- Replaced the older private login tab/panel/input classes with shared, reusable widgets.
- Modernized login role/action controls with icon-backed segmented buttons and cleaner panel/input styling.
- Cleaned visible Turkish login copy in the active form path.
- Reduced `fix_login_gate_page.dart` from roughly 29 KB to roughly 22 KB, keeping it away from the large-file threshold.
- Local retest required: rerun `flutter analyze` and `flutter test`.

## 66R - Test Regression Fixes
- Rebuilt `BusinessCategories` with clean Turkish labels/keywords and a hardened legacy-encoding normalizer.
- Category matching now accepts both clean labels such as `Güzellik & Bakım` and legacy payloads such as `GÃ¼zellik & BakÄ±m`.
- Adjusted message repository date parsing so Firestore `Timestamp` and epoch values normalize to UTC ISO strings while local ISO fallbacks stay local.
- Verification: skip-Flutter CI gate passed and feature architecture report passed with `Large files over 30KB: 0`.
- Local retest required: rerun `flutter test`; targeted Flutter test execution timed out in this environment.

## 66S - UI Action System and Corporate Flow Cleanup
- Made Explore's location sort a pinned primary action: `Konum al ve yakınları sırala` before location and `Konuma göre sırala` after location.
- Kept the secondary sort modes as compact chips while removing the distance mode from the horizontal chip row so it cannot disappear off-screen.
- Directory-only Explore cards now show approximate proximity as its own visible chip instead of burying distance inside the address line.
- Added a reusable corporate command panel to the account screen with direct actions for appointments, customers, bulk message, messages, profile and operations.
- Added a `customers` business-module route from the account entry page so the new customer command opens the real customer ledger.
- Rebuilt the Business Owner Hub home as a cleaner Fix business center with quick action cards and grouped management sections.
- Added owner-hub routes for `bulkMessage`, `campaigns`, `pos` and `products`, reducing dead or inconsistent navigation paths.
- Extracted the customer ledger header into `BusinessCustomerHeaderPanel` and rebuilt `business_customers_page.dart` below the large-file threshold after modernizing its primary actions.
- Verification: skip-Flutter CI gate passed and feature architecture report passed with `Large files over 30KB: 0`.
- Local retest required: rerun `flutter analyze` and `flutter test`; `dart format`/Flutter commands timed out in this Codex environment.

## 66T - Remaining Action Wiring and Settings Cleanup
- Replaced the placeholder `Devamlılık` account action with the live customer ledger so repeat-visit tracking starts from real customer segments.
- Connected `Tanıtım / Paylaşım İçerikleri` to the business story creation flow through the account-entry business module router.
- Added the `stories` account-entry route using the resolved business id, name, logo and category.
- Rebuilt the lightweight app settings page as a real local preference screen backed by `SharedPreferences`.
- Added notification, campaign update and route-distance toggles; the Explore route chip now respects the route-distance preference before calling the route service.
- Connected staff quick actions to real campaign/story and finance pages instead of showing future-package placeholders.
- Replaced the product stock tab placeholder with a real `BusinessStockLedgerList` that summarizes current product stock, low-stock status and stock value.
- Extracted the stock ledger into `business_stock_ledger_list.dart` to keep `business_products_page.dart` under the large-file budget.
- Verification: skip-Flutter CI gate passed and feature architecture report passed with `Large files over 30KB: 0`.
- Local retest required: rerun `flutter analyze` and `flutter test`.
