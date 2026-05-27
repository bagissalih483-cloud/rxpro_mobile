# RxPro Locked Lines

> Bu dosya 56A Project Index Foundation ile oluÅŸturuldu. AÄŸÄ±r audit/log/zip Ã§Ä±ktÄ±larÄ± proje iÃ§ine deÄŸil C:\Users\Casper\Desktop\RxPro_Audit_Packages iÃ§ine alÄ±nÄ±r.

## Kilitli / Stabil Hatlar

| Kademe | ModÃ¼l | Kilit NoktasÄ± | Not |
|---|---|---|---|
| 52H | BusinessAnalysis | Repository hattÄ± | Gereksiz dokunma yok |
| 52O | PostInteraction | like/save/report repository hattÄ± | FavoriteFeed/PostInteraction dikkatli |
| 52Z | BusinessProfile | read-stream repository hattÄ± | UI davranÄ±ÅŸÄ± korunmalÄ± |
| 53G | CustomerAppointments | read-stream repository hattÄ± | Randevu Ã§ekirdeÄŸi hassas |
| 53N | FavoriteFeed | read-only repository hattÄ± | Feed/interaction ayrÄ±mÄ± korunmalÄ± |
| 54B | FixLoginGate | role-write repository wiring | Auth/session/navigation korunmalÄ± |
| 54L | CustomerNotifications | notifications stream/mark read/mark all read repository | Push/FCM/Cloud Functions Ã§ekirdeÄŸine dokunma |
| 54U | RegisteredBusinesses | load + session cache repository migration | BusinessOwnerHub/StaffWorkspace navigation korunmalÄ± |
| 55A | BusinessStaffManage | _staffRepository.watchBusinessStaff(widget.businessId) | Read-stream kilitli |
| 55D | BusinessStaffManage | _staffRepository.ensureBusinessAccessCode(...) | Access-code kilitli |
| 55G | BusinessStaffManage | _staffRepository.deleteStaffDocument(doc.reference) | Delete-flow kilitli |
| 55M/55N | StaffFormPage | _staffFormRepository.upsertBusinessStaff(...) + ddBusinessStaffActivityLog(...) | Save-flow kilitli |

## Genel Kural

- Notification/push/FCM Ã§ekirdeÄŸi kÃ¶r patch ile aÃ§Ä±lmayacak.
- MessagesInboxPage ve BusinessAppointmentManagementPage gibi hassas/stabil gÃ¶vdeler Ã¶nce exact audit olmadan patchlenmeyecek.
- Production Firestore rules/index/functions deploy yapÄ±lmayacak.
- Her yeni migration iÃ§in Ã¶nce exact audit, sonra kÃ¼Ã§Ã¼k patch, sonra final lock audit.

| 56G | BusinessProfile | _reviewsRepository.watchBusinessReviews(businessId: widget.businessId) | Reviews read-stream kilitli; _sendReview, _refreshRatingSummary, _currentUserDocStream dokunulmadÄ± |

## 56P / 56Q Lock - BusinessProfileEditEntry Resolver Wiring

- `business_profile_edit_entry_page.dart`: resolver import and `_resolverRepository` field must remain.
- `_loadOwnedBusiness` must use `_resolverRepository.resolveOwnedBusinessId(uid: user.uid, email: user.email)`.
- Do not remove `_queryBusinessIdByField` / `_matchesUser` / cleanup helpers in the same patch as resolver wiring.
- Do not combine this line with BusinessProfileEditPage save/storage, reviews, PostInteraction, FavoriteFeed, notification/push, rules/index/functions.

## 56T/56U - BusinessProfileEditEntry resolver cleanup no-build smoke lock
- Date: 20260525_003809
- Scope: lib/features/business/pages/business_profile_edit_entry_page.dart
- Locked decision: PASS / NO_BUILD
- _loadOwnedBusiness uses BusinessProfileEditEntryResolverRepository.resolveOwnedBusinessId(uid: user.uid, email: user.email).
- Removed unused legacy helper methods from page: _queryBusinessIdByField, _matchesUser, _clean.
- Removed direct Firestore import from page.
- Preserved UI state, edit navigation and resolver repository boundary.
- No changes to BusinessProfileEditPage save/storage, reviews, PostInteraction, FavoriteFeed, notification/push/FCM, messages/chat, appointment core, finance core, staff_workspace, rules/index/functions.

## 57D_BUSINESS_PROFILE_EDIT_PAGE_REPOSITORY_MIGRATION_LOCK

Status: NO-BUILD SMOKE LOCK / PASS  
Scope: lib/features/business/pages/business_profile_edit_page.dart and lib/features/business/data/business_profile_edit_repository.dart

Locked facts:
- BusinessProfileEditPage load flow uses BusinessProfileEditRepository.fetchBusinessProfile.
- BusinessProfileEditPage save-info flow uses BusinessProfileEditRepository.updateBusinessProfileInfo.
- BusinessProfileEditPage logo URL write uses BusinessProfileEditRepository.updateBusinessLogoUrl.
- BusinessProfileEditPage cover URL write uses BusinessProfileEditRepository.updateBusinessCoverUrl.
- Direct Firestore tokens/imports were removed from BusinessProfileEditPage.
- Upload/pick UI flow remains on page and is intentionally not moved in this step.
- Build skipped by current no-build iteration policy; batch/final build is pending.


## 57J - BusinessActivityLogs read-stream repository wiring smoke/index lock (no build)
- Date: 20260525_010951
- Scope: business_activity_logs_page.dart read-stream migration to BusinessStaffRepository.watchBusinessActivityLogs.
- Build: skipped by current no-build batch policy.
- Result: PASS.

## 57O - AccountingPermissions read-stream repository lock (no-build)
- Date: 20260525_012530
- Scope: lib/features/accounting/pages/accounting_permissions_page.dart
- Repository: lib/features/accounting/data/accounting_permission_repository.dart
- Locked behavior: users/{uid} permission/session read stream is served through AccountingPermissionRepository.watchUserPermissionData.
- Preserved fields: role, activeBusinessId, permissions.
- Direct page Firestore users stream removed.
- Build: skipped; no-build smoke/index lock. Next batch build required before wider lock.

### 57Q LOCK - BusinessActivityLogsPage read-stream migration
- business_activity_logs_page.dart: _logsStream() must stay on BusinessStaffRepository.watchBusinessActivityLogs(...).
- Keep Timestamp handling and UI cards unchanged.
- Do not add write flow to this page without a new exact audit.

- 59O note: Protected domains remain locked: Notification/push/FCM, messages/chat, appointment core, finance core, staff_workspace, Firestore rules/index/functions.

## 64A - Campaign Service Wiring

- Scope: campaign list, AI campaign publish, bulk message draft.
- New service boundary: `lib/features/campaigns/campaign_service.dart`.
- UI pages now call CampaignService instead of writing campaign/bulk-message Firestore payloads directly.
- Repository remains the only campaign Firestore data access point.
- Notification/push core behavior was not changed; campaign publish still uses the existing notification service boundary.
- Full Flutter analyzer/build could not be completed in this sandbox because Dart/Flutter tooling needed user-profile cache/state access and later timed out.

## 64B - Business Products Service Wiring

- Scope: stock/product business context, product list stream, active/public toggles, save and delete.
- New repository boundary: `lib/features/businesses/data/business_products_repository.dart`.
- New service boundary: `lib/features/businesses/services/business_products_service.dart`.
- `business_products_page.dart` no longer opens FirebaseAuth/FirebaseFirestore directly for product context or writes.
- UI still maps product snapshots to existing cards; visual behavior was kept.
- Full Flutter analyzer/build remains pending for a normal local environment.

## 64C - Business Product Movement Service Wiring

- Scope: product sale/purchase movement create flow and recent movement stream.
- New model boundary: `lib/features/business_analysis/business_product_movement_models.dart`.
- New repository boundary: `lib/features/business_analysis/data/business_product_movement_repository.dart`.
- New service boundary: `lib/features/business_analysis/services/business_product_movement_service.dart`.
- `business_product_movement_page.dart` no longer imports Cloud Firestore or writes/streams Firestore directly.
- Existing BusinessAnalysisRepository read/reporting line was not changed.
- Targeted Dart tooling could not complete in this sandbox because the Pub cache under user AppData is inaccessible; static page-boundary audit passed.

## 64D - Business Profile Post Create Service Wiring

- Scope: business profile intro post create flow.
- New repository boundary: `lib/features/business/data/business_profile_post_create_repository.dart`.
- New service boundary: `lib/features/business/services/business_profile_post_create_service.dart`.
- `business_profile_post_create_page.dart` no longer imports FirebaseAuth/FirebaseFirestore or creates Firestore documents directly.
- Image pick/upload behavior remains in the page via the existing upload service; post metadata persistence moved behind the service boundary.
- Service preflight checks signed-in user before image upload to avoid orphan uploaded media when auth is missing.
- Targeted Dart tooling could not complete in this sandbox because the Pub cache under user AppData is inaccessible; static page-boundary audit passed.

## 64E - Service Wiring Verification Checkpoint

- Real Dart/Flutter tooling remained blocked by user AppData/Pub cache access in this sandbox.
- Direct page-boundary scans completed successfully for the service-wired pages.
- `node --check functions/index.js` completed successfully.
- Git status check could not run because the workspace is not a Git repository.
- Full APK build remains pending.

## 64F - Professional Hardening Foundation

- Scope: project hygiene, platform metadata, local quality command.
- `.gitignore` now excludes Firebase local state, debug logs, local env files and `functions/node_modules`.
- `android/.gitignore` now allows Gradle wrapper files to be tracked for reproducible Android builds.
- Android manifest app label is `RxPro`, production `INTERNET` permission is declared and XML formatting was normalized.
- iOS `Info.plist` display name is `RxPro` and camera/photo/location usage descriptions are present.
- `tools/quality_check.ps1` added for local format/analyze/test/functions syntax checks.
- `docs/project_index/rxpro_professional_hardening_plan.md` added as the remaining production-readiness tracker.
- Android manifest and iOS plist XML parse checks passed.
- Git repository was initialized, but this sandbox denied later writes to `.git/index` and `.git/config`; first commit remains a local-user action.

## 64G - Business Live Flow Repository Wiring

- Scope: live flow read streams for appointments, staff and activity logs.
- New repository boundary: `lib/features/businesses/data/business_live_flow_repository.dart`.
- `business_live_flow_page.dart` no longer imports Cloud Firestore or opens Firestore streams directly.
- UI behavior remains summary-only; write flows were not added.
- Added pure model tests for live-flow status mapping.

## 64H - Test Coverage Increment

- Added `test/features/business_analysis/business_product_movement_models_test.dart`.
- Added `test/features/businesses/data/business_live_flow_repository_test.dart`.
- Added `test/features/businesses/data/business_duration_analytics_repository_test.dart`.
- Test file count increased from 3 to 6.
- Tests target pure mapping logic so they remain stable without Firebase emulator setup.

## 64I - Business Duration Analytics Repository Wiring

- Scope: duration analytics completed appointment read stream.
- New repository boundary: `lib/features/businesses/data/business_duration_analytics_repository.dart`.
- `business_duration_analytics_page.dart` no longer imports Cloud Firestore or opens Firestore streams directly.
- Existing UI summary and suggestion behavior was preserved.
- Added pure model tests for completed/duration fallback mapping.

## 64J - Remaining Gaps Inventory

- Added `docs/project_index/rxpro_remaining_gaps.md`.
- Current direct Firebase surface outside repository/service/domain paths is 29 files.
- Remaining gaps are classified across service migration, product features, platform/release and tests.
- Protected domains still require exact audit before patching.

## 64K - Home Explore Badge/Session Repository Wiring

- Scope: public home unread message/notification badges and signed-in checks.
- New repository boundaries:
  - `lib/features/public_home/data/home_explore_badge_repository.dart`
  - `lib/features/public_home/data/home_explore_session_repository.dart`
- `home_explore_page.dart` no longer imports FirebaseAuth/FirebaseFirestore or opens Firestore streams directly.
- Existing navigation, guest gating and badge behavior were preserved.
- Current direct Firebase surface outside repository/service/domain paths is now 28 files.

## 64L - Business Profile Post Interaction Card Session/State Wiring

- Scope: business profile post like/save/report interaction card.
- New session boundary: `lib/features/business/data/business_profile_post_session_repository.dart`.
- `BusinessProfilePostInteractionRepository` now exposes bool streams for like/save active state.
- `business_profile_post_interactive_card.dart` no longer imports FirebaseAuth, Cloud Firestore or document snapshot types.
- Existing like, save and report behavior was preserved.

## 64M - Small UI Session Boundary Cleanup

- Scope: fix login, accounting permission session card, profile edit entry, favorite feed and customer notification page session access.
- `fix_login_gate_page.dart` now delegates corporate business context lookup to `FixLoginGateRepository`.
- `accounting_permissions_page.dart`, `business_profile_edit_entry_page.dart`, `favorite_feed_page.dart` and `customer_notifications_page.dart` no longer call FirebaseAuth directly.
- `favorite_feed_page.dart` removed an unused Firestore document factory from the UI layer.

## 64N - Campaign AI Service Boundary

- Scope: AI campaign draft generation endpoint call.
- `CampaignService.generateCampaignAi` owns Firebase project id, id-token and HTTP request details.
- `campaign_ai_create_safe_page.dart` no longer imports FirebaseAuth/FirebaseCore/http/json directly.
- Existing local fallback and publish service flow were preserved.

## 64O - Notification Center Repository Wiring

- Scope: notification center scope resolution, read stream, visibility filtering and sorting.
- New repository boundary: `lib/features/notifications/data/notification_center_repository.dart`.
- `notification_center_page.dart` now renders `NotificationCenterItem` models and delegates mark-read operations through the repository.
- Direct Firebase surface outside repository/service/domain paths is now 20 files.

## 64P - Business Role Resolver Repository Facade

- Scope: legacy business role resolver consumed by entry pages.
- New model boundary: `lib/features/business_role/business_role_result.dart`.
- New repository boundary: `lib/features/business_role/data/business_role_repository.dart`.
- `business_role_resolver.dart` remains as a compatibility facade and no longer imports Firebase or Firestore directly.
- Direct Firebase surface outside repository/service/domain paths is now 19 files.

## 64Q - High-Traffic UI Service Boundary Lock

- Messages, appointment entry/customer actions, business appointment management, business staff management, staff task/workspace, account entry/main shell and business profile review/follow flows now avoid direct Firebase access from UI/root files.
- New repository/service boundaries own the Firestore/Auth write and read mechanics for those flows.
- `main.dart` now uses `AuthService` instead of direct FirebaseAuth instance calls.
- Direct Firebase surface outside repository/service/domain paths is now 8 files.
- The remaining 8 files are service/core infrastructure surfaces and should be handled with adapter/facade tests rather than broad UI migrations.
- `tools/quality_check.ps1 -SkipFlutter` passed; full Flutter/Dart tooling remains blocked by sandbox/runtime constraints.

## 64R - Architecture Check Lock

- `tools/architecture_check.ps1` is the executable architecture budget for direct Firebase access.
- `tools/quality_check.ps1` must keep running architecture check before function syntax and Flutter checks.
- Target tree and operating algorithm are documented in:
  - `docs/project_index/rxpro_target_architecture.md`
  - `docs/project_index/rxpro_working_algorithm.md`
- New UI/root files must not call `FirebaseFirestore.instance`, `FirebaseAuth.instance`, `FieldValue`, `SetOptions`, or `.collection(` directly unless the approved infrastructure allowlist is intentionally updated and locked.

## 64S - Professional Audit Lock

- `docs/project_index/rxpro_professional_audit_20260526.md` is the current professional readiness audit.
- Do not start a broad folder-tree rewrite before quality/build, rules tests, release identifiers and backend safety gates are stable.
- Next architecture moves should be feature-by-feature with tests around appointments, messages, notifications, staff workspace and finance/accounting.

## 64T - Staff Workspace Completion Build Lock

- `StaffWorkspaceRepository.completeAppointment()` accepts nullable `workDurationMinutes`.
- Do not force a fake zero duration when start time cannot be calculated.
- Only write `workDurationMinutes` and `durationSource` when the calculated duration is non-null and non-negative.
- User release build passed after this fix: `build/app/outputs/flutter-apk/app-release.apk`.

## 64U - Analyze Cleanup Lock

- Keep `uuid` as a direct dependency while `MessagingService` imports `package:uuid/uuid.dart`.
- Do not reintroduce deprecated `DropdownButtonFormField.value`, `withOpacity`, `desiredAccuracy`, or `Switch.activeColor`.
- Parked legacy UI helpers in appointment/profile files are intentionally ignored instead of deleted until those flows are refactored with tests.

## 64V - CI Quality Gate Lock

- `tools/ci_quality_check.ps1` is the CI entrypoint and should remain aligned with local quality expectations.
- `.github/workflows/flutter_quality.yml` must run the project quality gate before release branches are trusted.
- A clean `flutter analyze` is now the baseline; new warnings/info should be treated as regressions.
- Do not mark the app production-ready until CI passes from a committed checkout and release identifiers/signing/Firebase plist/rules tests are complete.

## 64W - App Observability Lock

- Keep `main()` wrapped with the guarded root zone.
- Keep Flutter framework and platform dispatcher errors routed through `AppObservabilityService`.
- Do not send Crashlytics data from unsupported desktop/web platforms without an explicit compatibility pass.
- Flow-level Analytics events should be added through the observability boundary rather than scattered direct plugin calls.

## 64X - Text Encoding Cleanup Lock

- Campaign AI and business analysis AI must use the clean prompt builders, not the old mojibake prompt blocks.
- Phone password reset screen visible strings are clean Turkish and should not regress to mojibake.
- Accounting callable/validator user-facing error messages are clean Turkish.
- Continue encoding cleanup by feature slice; do not run a blind global replacement across source and generated files.

## 64Y - Feature Architecture Slice Lock

- Use `tools/feature_architecture_report.ps1` to track presentation boundaries, tests and large page files.
- `lib/features/auth/phone_password_reset_flow_page.dart` is now a compatibility export.
- The real password reset page lives under `lib/features/auth/presentation/pages/`.
- Continue feature migrations in narrow slices with compatibility exports or import updates.

## 64Z - Local Tooling Compatibility Lock

- `tools/architecture_check.ps1` must work even when `rg` is not installed.
- `tools/mojibake_scan.ps1` must work even when `rg` is not installed.
- Keep `AppObservabilityService` free of the unnecessary `dart:ui` import while `PlatformDispatcher` is available through Flutter foundation.

## 65A - Auth Presentation Split Lock

- `FixLoginGatePage` lives under `lib/features/auth/presentation/pages/`.
- `lib/features/auth/fix_login_gate_page.dart` remains a compatibility export until imports are migrated deliberately.
- Login gate guest actions and brand header live under `lib/features/auth/presentation/widgets/`.
- Auth feature should stay at 0 files above the 30KB large-file budget.

## 65B - Public Home Account Entry Split Lock

- `AccountEntryPage` lives under `lib/features/public_home/presentation/pages/`.
- `lib/features/public_home/account_entry_page.dart` remains a compatibility export until imports are migrated deliberately.
- Account entry cards and menu UI live under `lib/features/public_home/presentation/widgets/`.
- Account entry context data lives under `lib/features/public_home/presentation/models/`.
- Preserve scoped session business id/category resolution in `AccountEntryContext.fromSession()`.
- Public home should stay at 0 files above the 30KB large-file budget.

## 65C - Business Analysis Presentation Split Lock

- `BusinessAnalysisPage` lives under `lib/features/business_analysis/presentation/pages/`.
- `lib/features/business_analysis/business_analysis_page.dart` remains a compatibility export until imports are migrated deliberately.
- `BusinessProductMovementPage` lives under `lib/features/business_analysis/presentation/pages/`.
- `lib/features/business_analysis/business_product_movement_page.dart` remains a compatibility export until imports are migrated deliberately.
- Business analysis cards/sections live under `presentation/widgets/`.
- Business analysis view models live under `presentation/models/`.
- AI callable access must stay behind `BusinessAnalysisAiService`.
- Date parsing, period filtering, revenue computation and local AI fallback report logic must stay behind `BusinessAnalysisComputationService`.
- Business analysis should stay at 0 files above the 30KB large-file budget.

## 65D - Appointments Presentation Split Lock

- `AppointmentEntryPage` lives under `lib/features/appointments/presentation/pages/`.
- `CustomerAppointmentsPage` lives under `lib/features/appointments/presentation/pages/`.
- `lib/features/appointments/appointment_entry_page.dart` and `lib/features/appointments/customer_appointments_page.dart` remain compatibility exports until imports are migrated deliberately.
- Appointment dashboard daily flow, heatmap and legend widgets live under `lib/features/appointments/presentation/widgets/`.
- Customer appointment tabs, empty state and status line widgets live under `lib/features/appointments/presentation/widgets/`.
- Appointment dashboard lightweight view models live under `lib/features/appointments/presentation/models/`.
- Appointments should stay at 0 files above the 30KB large-file budget.
- Keep `BusinessAnalysisComputationService` covered by pure tests when changing analysis/date/quantity logic.

## 65E - Business Finance Presentation Split Lock

- `BusinessFinancePage` lives under `lib/features/businesses/presentation/pages/`.
- `lib/features/businesses/business_finance_page.dart` remains a compatibility export until imports are migrated deliberately.
- Finance display models live under `lib/features/businesses/presentation/models/`.
- Finance reusable cards/sections live under `lib/features/businesses/presentation/widgets/`.
- Finance formatting helpers live under `lib/features/businesses/presentation/utils/` and should stay covered by pure tests.

## 65F - Business Staff Management Split Lock

- `BusinessStaffManagePage` lives under `lib/features/businesses/presentation/pages/`.
- `StaffFormPage` lives under `lib/features/businesses/presentation/pages/business_staff_form_page.dart`.
- `lib/features/businesses/business_staff_manage_page.dart` remains a compatibility export until imports are migrated deliberately.
- Staff group/card UI lives under `lib/features/businesses/presentation/widgets/business_staff_manage_widgets.dart`.
- Staff permission payload, service matching and invite code generation behavior must not be changed during presentation-only splits.

## 65G - Accounting Sales Presentation Split Lock

- `AccountingSalesPage` lives under `lib/features/accounting/presentation/pages/`.
- `lib/features/accounting/pages/accounting_sales_page.dart` remains a compatibility export until imports are migrated deliberately.
- Sales wizard UI lives under `lib/features/accounting/presentation/widgets/accounting_sales_widgets.dart`.
- Sales wizard/catalog lightweight models live under `lib/features/accounting/presentation/models/accounting_sales_models.dart`.
- Accounting sales draft validation must remain behind `AccountingDraftValidator`.

## 65H - Location Discovery Lock

- Business location parsing lives in `lib/core/businesses/business_location_data.dart`.
- Directions launching lives in `lib/core/businesses/business_directions_service.dart`.
- Explore cards live in `lib/features/public_home/presentation/widgets/home_explore_business_cards.dart`.
- Google Places imported records must remain display-safe as directory-only unless member/claimed/owner signals are present.
- Directory-only records should not open a full business profile; they should prioritize directions.
- Business profile edit should persist both scalar coordinate fields and `location` GeoPoint when a business captures its location.
- Keep public_home at 0 files above the 30KB large-file budget when adding discovery UI.

## 65I - Location Geo Index Lock

- Geohash encoding and nearby-prefix logic live in `lib/core/businesses/business_geo_index.dart`.
- Business location writes must persist `geoHash`, `geoHash4`, `geoHash5`, `geoHash6` and `geoHash7` together with coordinates.
- Explore discovery should try the geohash-indexed nearby query when user location exists.
- Keep the broad cache fallback until all legacy/imported business records are backfilled with geohash fields.
- Radius changes in discovery must refresh the indexed query when current user location exists.
- `functions/scripts/backfillBusinessGeoIndex.js` must stay dry-run-first; production writes require explicit `--write`.
- Add Firestore composite/index configuration and emulator coverage before treating geo discovery as production complete.

## 65J - Business Appointment Management Split Lock

- `business_appointment_management_page.dart` should stay below the 30KB large-file budget.
- Customer direct-message UI lives in `lib/features/businesses/presentation/pages/business_customer_direct_message_page.dart`.
- Appointment summary card, status pill, customer info row and quick customer profile sheet live in `lib/features/businesses/presentation/widgets/business_appointment_management_widgets.dart`.
- Keep appointment cancel/postpone/conflict/repository behavior in the root page unchanged until covered by focused tests.
