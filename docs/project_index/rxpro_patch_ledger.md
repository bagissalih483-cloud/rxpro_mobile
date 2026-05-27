# RxPro Patch Ledger

| Kademe | Ã–zet | Durum |
|---|---|---|
| 54U | RegisteredBusinesses repository migration final lock | PASS |
| 54V | Global service gap refresh | PASS |
| 55A | BusinessStaffManage read-stream repository wiring | PASS |
| 55D | BusinessStaffManage access-code repository wiring | PASS |
| 55G | BusinessStaffManage delete-flow repository wiring | PASS |
| 55K | BusinessStaffRepository save/upsert helper foundation | PASS |
| 55M/55N | StaffFormPage save-flow repository wiring + final lock | PASS |
| 55O | BusinessStaffManage module final closure | PASS |
| 56A | Project Index Foundation | THIS RUN |

## Not

Bu ledger kÄ±sa Ã¶zet iÃ§indir. DetaylÄ± audit paketleri C:\Users\Casper\Desktop\RxPro_Audit_Packages altÄ±nda tutulur.

| 56G | BusinessProfile reviews read-stream repository wiring + final lock | PASS |

## 56P / 56Q - BusinessProfileEditEntry Resolver Wiring

- Date: 20260525_002730
- Status: smoke-pass, no-build project index update
- Page: `C:\Users\Casper\Desktop\rxpro_mobile\lib\features\business\pages\business_profile_edit_entry_page.dart`
- Repository: `C:\Users\Casper\Desktop\rxpro_mobile\lib\features\business\data\business_profile_edit_entry_resolver_repository.dart`
- Change: `_loadOwnedBusiness` now resolves owned business id through `BusinessProfileEditEntryResolverRepository.resolveOwnedBusinessId(uid: user.uid, email: user.email)`.
- Scope guard: UI state and navigation remain in the page; old helper methods are preserved for later cleanup; no production rules/index/functions deploy.

## 56T/56U - BusinessProfileEditEntry unused helpers cleanup + smoke audit
- Date: 20260525_003809
- Type: no-build cleanup + smoke audit + project_index update
- Result: PASS
- Changed behavior: resolver responsibility remains in repository; page kept UI state/navigation only.
- Build: skipped by current no-build intermediate workflow.
- Follow-up: take build only at module/final lock batch.

### 57D | BusinessProfileEditPage repository migration no-build lock

- Result: PASS
- Build: SKIPPED_NO_BUILD
- Updated: 20260525_005240
- Scope: 56X repository foundation, 56Y load wiring, 56Z logo/cover URL write wiring, 57A save-info write wiring, 57B cleanup, 57C REV1 smoke.
- Preserved: UI state, form validation, snackbar/navigation, image picking/upload flow.
- Excluded: production rules/index/functions deploy, notification/push/FCM, messages/chat, appointment core, finance core, staff_workspace.


## 57J - BusinessActivityLogs read-stream repository wiring smoke/index lock (no build)
- Date: 20260525_010951
- Scope: business_activity_logs_page.dart read-stream migration to BusinessStaffRepository.watchBusinessActivityLogs.
- Build: skipped by current no-build batch policy.
- Result: PASS.

## 57O - AccountingPermissions smoke/index update (no-build)
- 57M REV1 repository foundation PASS.
- 57N REV2 page stream wiring PASS.
- 57O smoke recheck PASS.
- No production deploy. No rules/index/functions changes. Build skipped.

### 57Q - BusinessActivityLogs read-stream repository migration smoke/index
- Date: 20260525_013539
- Scope: business_activity_logs_page.dart read-stream migration verification and project_index update.
- Status: NO-BUILD SMOKE LOCK.
- Verified: BusinessStaffRepository.watchBusinessActivityLogs helper present; page uses repository; direct businessActivityLogs collection removed; no write flow introduced.
- Build: skipped by current workflow.
- 20260525_160343 - 59B: business_profile_edit_entry_page.dart analyzer-confirmed unused import cleanup; no build; no production deploy.

- 20260525_161018 - 59C: business_directory_cache_service.dart analyzer-confirmed unused dart:math import cleanup; no build; no production deploy.

- 20260525_161538 - 59C REV1: repaired missed dart:math as math unused import cleanup in business_directory_cache_service.dart; no build; no production deploy.

- 20260525_161835 - 59D: business_profile_edit_page.dart analyzer-confirmed unused registered_businesses_page import cleanup; no build; no production deploy.

- 20260525_161959 - 59E: business_profile_post_create_page.dart analyzer-confirmed unused registered_businesses_page import cleanup; no build; no production deploy.

- 20260525_162432 - 59F REV1: accounting_permissions_page.dart analyzer-confirmed unused cloud_firestore import cleanup with PS 5.1 UTF8NoBOM-compatible writer; no build; no production deploy.

## 59G_BUSINESS_PROFILE_POST_INTERACTIVE_CARD_UNUSED_IMPORT_CLEANUP_NOBUILD - 20260525_162621
- Scope: analyzer-confirmed unused import cleanup.
- Target: $TargetRel
- Removed: $ImportLine
- Build: skipped.
- Production deploy: no.
- Analyze after: error=0, warning=63, info=107.

## 59L - Project index update after 59A-59K analyze cleanup/build lock (20260525_165418)

- Scope: documentation/index update only.
- Source code changed in this step: no.
- Build in this step: skipped.
- Production deploy: no.
- Locked/protected domains respected: notification/push/FCM, messages/chat, appointment core, finance core, staff_workspace, Firestore rules/index/functions.
- Previous build lock: 59K REV1 PASS_BUILD_LOCK.
- APK: C:\Users\Casper\Desktop\rxpro_mobile\build\app\outputs\flutter-apk\app-debug.apk
- APK size bytes: 193801212
- Analyze after 59K REV1: error=0, warning=51, info=107, total=158.
- Cleanup block result: 59A 179 total -> 59K REV1 158 total; 21 analyzer issues reduced.
- Notes:
  - 59I REV3 code state accepted as successful despite false-fail reporting, because role imports were removed and analyze reached 167 total.
  - 59J batch removed 9 unused imports and reached 158 total.
  - 59K REV1 build passed and APK was produced.
- Next recommended step: 59M select next low-risk analyze debt batch, avoiding protected domains and deprecated/info migrations unless explicitly selected.


### 59O - Project index update after 59N build lock (2026-05-25 16:59:49)
- Scope: docs/project_index only.
- Input baseline: 59N PASS_BUILD_LOCK after 59M batch cleanup.
- Recorded baseline: 0 error / 43 warning / 107 info / 150 total.
- Recorded build result: PASS, APK created.
- Source code changed: NO.
- Build run in this step: NO.
- Production deploy: NO.
- Next recommended stage: 59P remaining warning classification / safe batch planning.
## 59R - Project index update after 59Q build lock (2026-05-25 17:06:32)

- Stage: 59R_PROJECT_INDEX_UPDATE_AFTER_59Q_NOBUILD
- Source code changed: NO
- Build: SKIPPED_NO_BUILD
- Production deploy: NO
- Last build lock: 59Q_BUILD_LOCK_AFTER_59P
- Last build status: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- Analyze baseline after 59Q: 0 error / 38 warning / 107 info / 145 total
- Cleanup block summary:
  - 59A baseline: 0 error / 72 warning / 107 info / 179 total
  - 59K REV1 build lock: 0 error / 51 warning / 107 info / 158 total, build PASS
  - 59N build lock: 0 error / 43 warning / 107 info / 150 total, build PASS
  - 59P safe unused import autofix: 5 unused imports removed
  - 59Q build lock: 0 error / 38 warning / 107 info / 145 total, build PASS
- Current continuation recommendation:
  - Next safe step: 59S remaining warning classification audit or targeted safe cleanup.
  - Avoid protected domains without exact audit: notification/push/FCM, messages/chat, appointment core, finance core, staff_workspace, Firestore rules/index/functions.
  - Deprecated/info debt should be handled separately from build gates.
## 59V Project Index Update After 59U - 20260525_171742

- Scope: Documentation/index/ledger update only.
- Source code changed: NO.
- Build: skipped in this step.
- Production deploy: NO.
- Last verified build lock: 59U_BUILD_LOCK_AFTER_59T.
- 59U build status: PASS_BUILD_LOCK.
- APK verified at build lock: build\app\outputs\flutter-apk\app-debug.apk.
- Current analyze baseline after 59U:
  - Error: 0
  - Warning: 35
  - Info: 107
  - Total: 142
- Cleanup progress from 59A baseline:
  - 59A total: 179
  - 59U total: 142
  - Reduction: 37 issues
- Protected/high-risk areas remain restricted:
  - Notification/push/FCM
  - messages/chat/messaging
  - appointment core
  - finance core
  - staff_workspace
  - Firestore rules/index/functions
- Next recommended step:
  - 59W remaining warning candidate audit or a very small safe cleanup batch outside protected domains.
## 59Z - Project index update after 59Y build lock
- Date: 20260525_172737
- Scope: docs/project_index bookkeeping only.
- Source code changed: NO.
- Production deploy: NO.
- Last code cleanup: 59X safe unused local variable cleanup.
- Last build lock: 59Y_BUILD_LOCK_AFTER_59X.
- Build result: PASS.
- Analyze baseline: 0 error / 32 warning / 107 info / 139 total.
- APK: build\app\outputs\flutter-apk\app-debug.apk.
- Notes: Warning cleanup line is build-safe as of 59Y. Remaining warnings must stay classified before further edits; protected domains remain locked unless exact audit is performed.

## 60D - Project index update after 60C build lock (20260525_174728)

- Source code changed: NO
- Build: SKIPPED in this step
- Production deploy: NO
- Last build lock: 60C_BUILD_LOCK_AFTER_60B_REV5
- Last build status: PASS
- APK: build\app\outputs\flutter-apk\app-debug.apk
- APK size bytes: 193791066
- Analyze baseline after 60C:
  - error: 0
  - warning: 30
  - info: 107
  - total: 137
- 60B REV5 result:
  - business_staff_manage_page FirestoreCollections import/state repaired
  - mojibake markers cleaned
  - _col unused warning cleaned
- Protected-domain rule remains active:
  - appointment / appointments
  - notification / notifications
  - messages / messaging / chat
  - finance core
  - staff_workspace
  - firestore rules / indexes / functions
- Next recommended step: 60E remaining warning candidate audit or small protected-domain exact audit only.


---

## 60J - Project index update after 60I build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_60I
- 60I build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- Analyze baseline: 0 error / 24 warning / 107 info / 131 total
- 60H_REV6 cleanup: 9 unused private declarations removed from protected-outside files
- Changed code files in cleanup:
  - lib\features\favorites\favorite_feed_page.dart
  - lib\features\public_home\account_entry_page.dart
- Next route: return to main product checklist; analyze cleanup parked unless explicitly requested.

---

## 61E - Project index update after 61D build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_61D
- 61D build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- Analyze baseline: 0 error / 24 warning / 107 info / 131 total
- 61C campaign foundation: CampaignModels + CampaignRepository added
- Created code files:
  - lib\features\campaigns\campaign_models.dart
  - lib\features\campaigns\campaign_repository.dart
- UI wiring: not yet applied
- Production deploy: false
- Protected domains touched: false
- Next route: 61F exact campaigns UI wiring audit only.

---

## 61I - Project index update after 61H build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_61H
- 61H build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- 61G campaign customer read/list wiring completed.
- 61G_FIX_REV2 exact repair completed.
- Changed code files:
  - lib\features\campaigns\customer_campaigns_page.dart
  - lib\features\campaigns\campaign_models.dart
- customer_campaigns_page.dart no longer uses direct FirebaseFirestore.instance/cloud_firestore.
- customer campaign read path uses CampaignRepository.listCustomerCampaigns().
- Production deploy: false
- Protected domains touched: false
- Next route: 61J campaigns business page exact audit only.

---

## 61M - Project index update after 61L build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_61L
- 61L build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- 61K business campaigns read/list wiring completed.
- Changed code file:
  - lib\features\campaigns\business_campaigns_page.dart
- business_campaigns_page.dart _load() uses CampaignRepository.listBusinessCampaigns().
- _BusinessCampaignItem.fromRecord(CampaignRecord) added.
- _unpublish() direct Firestore intentionally left for later exact audit.
- cloud_firestore import intentionally remains for _unpublish()/legacy fromDoc.
- Production deploy: false
- Protected domains touched: false
- Next route: 61N business campaigns unpublish exact audit only.

---

## 61Q - Project index update after 61P build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_61P
- 61P build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- 61O business campaigns unpublish wiring completed.
- Changed code file:
  - lib\features\campaigns\business_campaigns_page.dart
- business_campaigns_page.dart _load() uses CampaignRepository.listBusinessCampaigns().
- business_campaigns_page.dart _unpublish() uses CampaignRepository.markCampaignPassive().
- Direct FirebaseFirestore/cloud_firestore removed from business_campaigns_page.dart.
- Legacy _BusinessCampaignItem.fromDoc/_first/_date removed.
- Production deploy: false
- Protected domains touched: false
- Next route: 61R campaign_ai_create_safe exact audit only or 62A broader checklist candidate audit.

---

## 61U - Project index update after 61T build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_61T
- 61T build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- 61S campaign AI create business context wiring completed.
- Changed code file:
  - lib\features\campaigns\campaign_ai_create_safe_page.dart
- _resolveBusinessContext() uses CampaignRepository.resolveOwnedBusinessForCurrentUser().
- _publishCampaign() direct Firestore create flow intentionally left untouched.
- AI HTTP/FirebaseAuth token flow intentionally left untouched.
- Production deploy: false
- Protected domains touched: false
- Next route: prefer 62A broader checklist audit, or 61V exact audit for campaign_ai_create_safe_page _publishCampaign().

---

## 62F - Project index update after 62E build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_62E
- 62E build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- 62D business owner hub resolve repository wiring completed.
- Changed code files:
  - lib\features\businesses\business_owner_hub_page.dart
  - lib\features\businesses\data\registered_business_gateway_repository.dart
- business_owner_hub_page.dart _resolveBusiness() uses RegisteredBusinessGatewayRepository.resolveOwnerHubBusiness().
- Direct cloud_firestore/firebase_auth references removed from business_owner_hub_page.dart.
- RegisteredBusinessGatewayRepository gained hasCurrentUser, resolveOwnerHubBusiness(), and ResolvedRegisteredBusiness.
- Target warning remaining: unused _nameOf in business_owner_hub_page.dart.
- Production deploy: false
- Protected domains touched: false
- Next route: tiny cleanup 62G for _nameOf or broader businesses next safe audit.

---

## 62I - Project index update after 62H build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_62H
- 62H build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- 62D owner hub resolve repository wiring completed.
- 62G_REV4 restored State.build inside _BusinessOwnerHubPageState after exact audit.
- Changed code files:
  - lib\features\businesses\business_owner_hub_page.dart
  - lib\features\businesses\data\registered_business_gateway_repository.dart
- business_owner_hub_page.dart:
  - _resolveBusiness() uses RegisteredBusinessGatewayRepository.resolveOwnerHubBusiness().
  - State.build exists inside _BusinessOwnerHubPageState.
  - State.build uses _gatewayRepository.hasCurrentUser and _resolveBusiness().
  - _nameOf removed.
  - direct cloud_firestore/firebase_auth references removed.
- RegisteredBusinessGatewayRepository:
  - hasCurrentUser added.
  - resolveOwnerHubBusiness() added.
  - ResolvedRegisteredBusiness added.
- Target analyze lines after 62H: 0.
- Production deploy: false.
- Protected domains touched: false.
- Lesson: stop and exact-audit after verification uncertainty; avoid broad block-removal helpers.
- Next route: 62J businesses next safe candidate audit only.

---

## 62N - Project index update after 62M build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_62M
- 62M build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- 62L business category save repository wiring completed.
- Changed code files:
  - lib\features\businesses\business_category_required_page.dart
  - lib\features\businesses\data\registered_business_gateway_repository.dart
- business_category_required_page.dart:
  - _save() uses RegisteredBusinessGatewayRepository.updateBusinessCategory().
  - direct cloud_firestore references removed.
  - selected/saving/snackbar/Navigator.pop behavior preserved.
- RegisteredBusinessGatewayRepository:
  - updateBusinessCategory() added.
  - category.toFirestore() + updatedAt FieldValue.serverTimestamp() written with SetOptions(merge: true).
- Target analyze after 62M: 0 error, 0 warning, 2 info for Radio groupValue/onChanged deprecation.
- Production deploy: false.
- Protected domains touched: false.
- Next route: 62O businesses next safe candidate audit-only or Radio deprecation exact audit.

---

## 62S - Project index update after 62R build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_62R
- 62R build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- 62Q / 62Q_REV1 business services list stream repository wiring completed.
- Changed code files:
  - lib\features\businesses\business_services_manage_page.dart
  - lib\features\businesses\data\business_services_repository.dart
- BusinessServicesRepository.watchBusinessServices(businessId) added.
- business_services_manage_page.dart list StreamBuilder uses repository stream.
- _col getter removed.
- Duplicate unused _servicesRepository fields removed; exactly one stream-using repository field remains.
- Service write paths remain direct:
  - toggle active set
  - delete service
  - ServiceFormPage _save add/update
- Target analyze after 62R: 0 error, 0 warning, 2 info.
- Production deploy: false.
- Protected domains touched: false.
- Accelerated rule locked:
  - services/businesses protected-outside: 2-4 method batch allowed after exact audit.
  - appointment/staff/finance/messages/notifications: domain audit first, then same sub-flow small batch only.
- Next route: 63A services toggle + delete exact batch audit.

---

## 63D - Project index update after 63C build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_63C
- 63C build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- 63B_REV1 business services toggle + delete repository batch completed.
- Changed code files:
  - lib\features\businesses\business_services_manage_page.dart
  - lib\features\businesses\data\business_services_repository.dart
- BusinessServicesRepository methods:
  - watchBusinessServices(businessId)
  - setServiceBookingEnabled(serviceId, enabled)
  - deleteBusinessService(serviceId)
- business_services_manage_page.dart:
  - list StreamBuilder is repository-based.
  - _ServiceTile toggle write is repository-based.
  - _ServiceTile delete write is repository-based.
  - _ServiceTile no longer has doc.reference.set/delete.
  - ServiceFormPage _save add/update remains direct and is next migration target.
- Target analyze after 63C: 0 error, 0 warning, 2 info.
- Production deploy: false.
- Protected domains touched: false.
- Next route: 63E ServiceFormPage _save exact audit only.

---

## 63H - Project index update after 63G build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_63G
- 63G build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- Business services repository wiring completed.
- Changed code files:
  - lib\features\businesses\business_services_manage_page.dart
  - lib\features\businesses\data\business_services_repository.dart
- BusinessServicesRepository now owns:
  - watchBusinessServices(businessId)
  - setServiceBookingEnabled(serviceId, enabled)
  - deleteBusinessService(serviceId)
  - saveBusinessService(serviceId, payload)
- business_services_manage_page.dart:
  - list StreamBuilder is repository-based.
  - _ServiceTile toggle is repository-based.
  - _ServiceTile delete is repository-based.
  - ServiceFormPage _save persistence is repository-based.
  - direct FirebaseFirestore.instance/add/doc.set persistence removed.
  - unused firestore_collections import removed.
- Target analyze after 63G: 0 error, 0 warning, 2 info.
- Production deploy: false.
- Protected domains touched: false.
- Next route: 63I services local info cleanup audit or next businesses safe candidate audit.

---

## 63L - Project index update after 63K build lock

- Status: PASS_PROJECT_INDEX_UPDATE_AFTER_63K
- 63K build lock: PASS_BUILD_LOCK
- APK: build\app\outputs\flutter-apk\app-debug.apk
- Business services full repository migration is locked.
- Changed code files:
  - lib\features\businesses\business_services_manage_page.dart
  - lib\features\businesses\data\business_services_repository.dart
- BusinessServicesRepository owns:
  - watchBusinessServices(businessId)
  - setServiceBookingEnabled(serviceId, enabled)
  - deleteBusinessService(serviceId)
  - saveBusinessService(serviceId, payload)
- business_services_manage_page.dart:
  - list stream, toggle, delete, and save persistence are repository-based.
  - direct FirebaseFirestore.instance/add/doc.set/doc.reference.set/delete surface removed.
  - DropdownButtonFormField service type uses initialValue.
- Target analyze after 63K: 0 error, 0 warning, 1 parked info.
- Parked info: business_services_manage_page.dart:645:25 curly_braces_in_flow_control_structures.
- Production deploy: false.
- Protected domains touched: false.
- Next route: 64A businesses next safe candidate audit only.

---

## 64C - Business product movement service wiring

- Status: PASS_STATIC_BOUNDARY_AUDIT / TOOLING_BLOCKED
- Scope: product sale/purchase movement create flow and recent movement stream.
- Changed code files:
  - lib\features\business_analysis\business_product_movement_page.dart
  - lib\features\business_analysis\business_product_movement_models.dart
  - lib\features\business_analysis\data\business_product_movement_repository.dart
  - lib\features\business_analysis\services\business_product_movement_service.dart
- `business_product_movement_page.dart` now calls `BusinessProductMovementService` for create and recent list stream.
- Firestore collection selection, server timestamps, source marker and document mapping live behind `BusinessProductMovementRepository`.
- Existing `BusinessAnalysisRepository` reporting path was not modified.
- Targeted Dart tooling: blocked by Pub cache/AppData access in this sandbox.
- Static boundary check: page no longer contains direct Firebase/Firestore access tokens.
- Production deploy: false.
- Full app build: pending.

---

## 64D - Business profile post create service wiring

- Status: PASS_STATIC_BOUNDARY_AUDIT / TOOLING_BLOCKED
- Scope: business profile intro post create flow.
- Changed code files:
  - lib\features\business\pages\business_profile_post_create_page.dart
  - lib\features\business\data\business_profile_post_create_repository.dart
  - lib\features\business\services\business_profile_post_create_service.dart
- `business_profile_post_create_page.dart` now calls `BusinessProfilePostCreateService` for post creation.
- FirebaseAuth current user ownership and Firestore document creation moved behind service/repository boundaries.
- Existing image pick/upload behavior stays on the page via `AppImageUploadService`.
- `BusinessProfilePostCreateService.ensureSignedIn()` is called before image upload to preserve the previous early-auth-stop behavior.
- Targeted Dart tooling: blocked by Pub cache/AppData access in this sandbox.
- Static boundary check: page no longer contains direct FirebaseAuth/FirebaseFirestore access tokens.
- Production deploy: false.
- Full app build: pending.

---

## 64E - Service wiring verification checkpoint

- Status: PASS_NODE_CHECK / TOOLING_BLOCKED
- Verification:
  - `dart format`: blocked by Pub cache/AppData access in this sandbox
  - `dart analyze`: blocked by Pub cache/AppData access in this sandbox
  - `node --check functions/index.js`: pass
- Git status check: skipped by environment because this workspace is not a Git repository.
- Production deploy: false.
- Full APK build: pending.

---

## 64F - Professional hardening foundation

- Status: PASS_STATIC_PLATFORM_CHECKS
- Changed files:
  - .gitignore
  - android\.gitignore
  - android\app\src\main\AndroidManifest.xml
  - ios\Runner\Info.plist
  - tools\quality_check.ps1
  - docs\project_index\rxpro_professional_hardening_plan.md
- `.gitignore` now blocks Firebase local state, debug logs, local env files and `functions/node_modules`.
- `android/.gitignore` now allows Gradle wrapper files to be tracked.
- Android app label fixed to `RxPro`; production `INTERNET` permission added; manifest formatting normalized.
- iOS display name fixed to `RxPro`; camera/photo/location permission descriptions added.
- XML parse check passed for Android manifest and iOS plist.
- Git repository initialized; commit blocked because sandbox denied `.git/index` and `.git/config` writes after initialization.
- Production deploy: false.

---

## 64G - Business live flow repository wiring

- Status: PASS_STATIC_BOUNDARY_AUDIT / TOOLING_BLOCKED
- Changed files:
  - lib\features\businesses\business_live_flow_page.dart
  - lib\features\businesses\data\business_live_flow_repository.dart
  - test\features\businesses\data\business_live_flow_repository_test.dart
- `business_live_flow_page.dart` now consumes repository-backed view models for appointments, staff and activity logs.
- Direct Cloud Firestore imports and stream construction were removed from the page.
- Added pure model tests for active appointment, busy staff and activity log fallback mapping.
- Targeted Dart tooling: blocked by Pub cache/AppData access in this sandbox.
- Static boundary check: page no longer contains direct Firebase/Firestore access tokens.
- Production deploy: false.

---

## 64H - Test coverage increment

- Status: PASS_STATIC_ADDITION / TOOLING_BLOCKED
- Added files:
  - test\features\business_analysis\business_product_movement_models_test.dart
  - test\features\businesses\data\business_live_flow_repository_test.dart
- Test file count increased from 3 to 6 after duration analytics tests were added.
- Added pure mapping coverage for product movement records, live-flow appointment/staff/activity models and duration analytics appointments.
- Targeted Dart tooling: blocked by Pub cache/AppData access in this sandbox.
- Production deploy: false.

---

## 64I - Business duration analytics repository wiring

- Status: PASS_STATIC_BOUNDARY_AUDIT / TOOLING_BLOCKED
- Changed files:
  - lib\features\businesses\business_duration_analytics_page.dart
  - lib\features\businesses\data\business_duration_analytics_repository.dart
  - test\features\businesses\data\business_duration_analytics_repository_test.dart
- `business_duration_analytics_page.dart` now consumes repository-backed completed appointment models.
- Direct Cloud Firestore imports and stream construction were removed from the page.
- Added pure model tests for completion filtering and duration fallback mapping.
- Targeted Dart tooling: blocked by Pub cache/AppData access in this sandbox.
- Static boundary check: page no longer contains direct Firebase/Firestore access tokens.
- Production deploy: false.

---

## 64J - Remaining gaps inventory

- Status: PASS_INVENTORY
- Added file:
  - docs\project_index\rxpro_remaining_gaps.md
- Direct Firebase surface outside repository/service/domain paths was measured at 29 files before 64K and 28 files after 64K.
- Remaining gaps were classified into direct Firebase surface, product features, platform/release and test debt.
- Production deploy: false.

---

## 64K - Home explore badge/session repository wiring

- Status: PASS_STATIC_BOUNDARY_AUDIT / TOOLING_BLOCKED
- Changed files:
  - lib\features\public_home\home_explore_page.dart
  - lib\features\public_home\data\home_explore_badge_repository.dart
  - lib\features\public_home\data\home_explore_session_repository.dart
  - docs\project_index\rxpro_remaining_gaps.md
- Unread message and notification badge Firestore queries moved behind `HomeExploreBadgeRepository`.
- Current user and auth-state access moved behind `HomeExploreSessionRepository`.
- `home_explore_page.dart` no longer contains direct FirebaseAuth/FirebaseFirestore imports or stream construction.
- Static boundary check passed; direct Firebase surface outside repository/service/domain paths is now 28 files.
- Targeted Dart tooling: blocked by Pub cache/AppData access in this sandbox.
- Production deploy: false.

---

## 64L - Business profile post interaction card session/state wiring

- Status: PASS_STATIC_BOUNDARY_AUDIT / TOOLING_BLOCKED
- Changed files:
  - lib\features\business\widgets\business_profile_post_interactive_card.dart
  - lib\features\business\data\business_profile_post_interaction_repository.dart
  - lib\features\business\data\business_profile_post_session_repository.dart
- Like/save active state now reaches the widget as `bool` streams instead of Firestore document snapshots.
- Current user lookup moved behind `BusinessProfilePostSessionRepository`.
- Static boundary check passed; the widget no longer contains direct FirebaseAuth/FirebaseFirestore imports or stream construction.
- Production deploy: false.

---

## 64M - Session boundary cleanup for small UI surfaces

- Status: PASS_STATIC_BOUNDARY_AUDIT / TOOLING_BLOCKED
- Changed files:
  - lib\features\auth\fix_login_gate_page.dart
  - lib\features\auth\data\fix_login_gate_repository.dart
  - lib\features\accounting\pages\accounting_permissions_page.dart
  - lib\features\business\pages\business_profile_edit_entry_page.dart
  - lib\features\favorites\favorite_feed_page.dart
  - lib\features\notifications\customer_notifications_page.dart
- Fix login corporate business context lookup moved fully behind `FixLoginGateRepository`.
- Small UI surfaces now use existing service/repository boundaries for current-user access.
- Favorite feed removed its unused Firestore document factory and now uses `AuthService` for auth stream/current user.
- Static boundary checks passed for the cleaned screens.
- Production deploy: false.

---

## 64N - Campaign AI service boundary

- Status: PASS_STATIC_BOUNDARY_AUDIT / TOOLING_BLOCKED
- Changed files:
  - lib\features\campaigns\campaign_ai_create_safe_page.dart
  - lib\features\campaigns\campaign_service.dart
- Firebase project id, auth token and HTTP call details moved from the AI campaign page into `CampaignService.generateCampaignAi`.
- Page behavior remains local-template fallback plus publish-through-service.
- Static boundary check passed; `campaign_ai_create_safe_page.dart` no longer imports FirebaseAuth/FirebaseCore/http/json directly.
- Production deploy: false.

---

## 64O - Notification center repository wiring

- Status: PASS_STATIC_BOUNDARY_AUDIT / TOOLING_BLOCKED
- Changed files:
  - lib\features\notifications\notification_center_page.dart
  - lib\features\notifications\data\notification_center_repository.dart
  - docs\project_index\rxpro_remaining_gaps.md
  - docs\project_index\rxpro_professional_hardening_plan.md
- Notification scope resolution, Firestore query selection, visibility filtering and date sorting moved behind `NotificationCenterRepository`.
- `NotificationCenterPage` now renders repository models and delegates read-state mutations through the repository.
- Static boundary check passed; direct Firebase surface outside repository/service/domain paths is now 20 files.
- Targeted Dart tooling: blocked by Pub cache/AppData access in this sandbox.
- Production deploy: false.

---

## 64P - Business role resolver repository facade

- Status: PASS_STATIC_BOUNDARY_AUDIT / TOOLING_BLOCKED
- Changed files:
  - lib\features\business_role\business_role_resolver.dart
  - lib\features\business_role\business_role_result.dart
  - lib\features\business_role\data\business_role_repository.dart
  - docs\project_index\rxpro_remaining_gaps.md
- Existing `BusinessRoleResolver` import path remains valid for legacy entry pages.
- Role lookup, user document read and business fallback lookup moved behind `BusinessRoleRepository`.
- Static boundary check passed; direct Firebase surface outside repository/service/domain paths is now 19 files.
- Targeted Dart tooling: blocked by Pub cache/AppData access in this sandbox.
- Production deploy: false.

---

## 64Q - High-traffic UI service boundary sprint

- Status: PASS_STATIC_BOUNDARY_AUDIT / TOOLING_BLOCKED
- Changed areas:
  - Appointment entry/customer appointment actions.
  - Messages inbox/thread flows.
  - Business appointment management and direct customer message mirror writes.
  - Business staff management and staff task/workspace flows.
  - Account entry/session lookup and main shell auth access.
  - Business profile review, rating summary and follow actions.
- New or expanded boundaries:
  - `BusinessAppointmentDashboardRepository`
  - `CustomerAppointmentActionService`
  - `MessagesRepository`
  - `BusinessAppointmentManagementRepository`
  - `BusinessCustomerMessageRepository`
  - `StaffTasksEntryRepository`
  - `StaffWorkspaceRepository`
  - `AccountEntryRepository`
  - `BusinessProfileRepository`
- Direct Firebase surface outside repository/service/domain paths is now 8 files, down from 19 at 64P and 29 at the first remaining-gaps inventory.
- Remaining direct files are service/core infrastructure surfaces, not high-traffic UI screens.
- `tools/quality_check.ps1 -SkipFlutter` passed.
- Full Dart/Flutter tooling remains blocked in this sandbox; run full format/analyze/test/build in the user environment.
- Production deploy: false.

---

## 64R - Architecture tree and operating algorithm enforcement

- Status: PASS_ARCHITECTURE_CHECK / PASS_SKIP_FLUTTER_QUALITY / TOOLING_BLOCKED
- Changed files:
  - `tools/architecture_check.ps1`
  - `tools/quality_check.ps1`
  - `docs/project_index/rxpro_target_architecture.md`
  - `docs/project_index/rxpro_working_algorithm.md`
  - `docs/project_index/rxpro_architecture_direction.md`
  - `docs/project_index/rxpro_service_repository_map.md`
  - `docs/project_index/rxpro_code_index.md`
- Added executable architecture budget check for direct Firebase access outside approved repository/service/domain boundaries.
- `tools/quality_check.ps1` now runs the architecture check before function syntax and Flutter checks.
- Documented target tree: app/core/shared/features with presentation/application/domain/data/services contracts.
- Documented runtime algorithms for bootstrap, auth/session, appointments, messaging, business profile and development workflow.
- Architecture check passed with 8 approved infrastructure files.
- Full Dart/Flutter tooling remains blocked in this sandbox; `dart format --output=none ...` timed out.
- Production deploy: false.

---

## 64S - Professional product and release audit

- Status: DOCUMENTATION_AUDIT / NO_SOURCE_BEHAVIOR_CHANGE
- Changed files:
  - `docs/project_index/rxpro_professional_audit_20260526.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
  - `docs/project_index/rxpro_professional_hardening_plan.md`
- Added a detailed professional readiness audit for architecture, release, security, tests, backend, feed/media/moderation and UX/store readiness.
- Recorded measured state: 166 Dart files, 6 test files, 17 features, 13 features with data boundaries, 3 features with domain boundaries and 0 features with presentation boundaries.
- Confirmed key release gaps: missing CI, missing iOS plist, starter package ids, debug release signing, missing Crashlytics/global error wiring, missing rules/function tests and mojibake text debt.
- Production deploy: false.

---

## 64T - Staff workspace release build fix

- Status: PASS_USER_RELEASE_BUILD / PASS_TESTS / PASS_ARCHITECTURE_CHECK
- Changed files:
  - `lib/features/businesses/data/staff_workspace_repository.dart`
- Fixed release compile error where nullable `workDurationMinutes` from staff workspace completion was passed into a non-nullable repository parameter.
- `StaffWorkspaceRepository.completeAppointment()` now accepts nullable duration and writes `workDurationMinutes` / `durationSource` only when a valid duration can be calculated.
- User environment verification:
  - `flutter analyze`: completed with 132 warnings/info and no compile error.
  - `flutter test`: PASS, 16 tests.
  - `flutter build apk --release`: PASS.
  - APK output: `build/app/outputs/flutter-apk/app-release.apk`, 61.2 MB.
- Local quick verification:
  - `tools/architecture_check.ps1`: PASS, direct Firebase surface remains 8.
  - `tools/quality_check.ps1 -SkipFlutter`: PASS.
- Production deploy: false.

---

## 64U - Analyze debt cleanup pass

- Status: PASS_STATIC_CHECKS / USER_ANALYZE_RECHECK_NEEDED
- Changed areas:
  - Deprecated Flutter API cleanup: `withOpacity` -> `withValues(alpha:)`.
  - Dropdown form fields moved from deprecated `value` to `initialValue`.
  - Location API moved from deprecated `desiredAccuracy` to `LocationSettings`.
  - Removed unused imports and low-risk unused optional parameters.
  - Added direct `uuid` dependency for `MessagingService`.
  - Cleaned small lint issues: braces, color hex, interpolation and accumulator names.
  - Added targeted ignores for parked legacy UI helpers in high-risk appointment/profile files rather than deleting behavior.
- User analyze before final 64U patch: 8 issues, down from 132.
- Final local pattern scan removed the remaining 8 issue signatures.
- Local quick verification:
  - `tools/architecture_check.ps1`: PASS, direct Firebase surface remains 8.
  - `tools/quality_check.ps1 -SkipFlutter`: PASS.
- User environment recheck: `flutter analyze` PASS, no issues found.
- Production deploy: false.

---

## 64V - CI Quality Gate And Release Readiness Lock

- Status: PASS_USER_ANALYZE / PASS_LOCAL_SKIP_FLUTTER_CI / CI_SCAFFOLD_ADDED
- Changed files:
  - `tools/ci_quality_check.ps1`
  - `.github/workflows/flutter_quality.yml`
  - `docs/project_index/rxpro_release_readiness_checklist.md`
  - `docs/project_index/rxpro_professional_hardening_plan.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
  - `docs/project_index/rxpro_professional_audit_20260526.md`
  - `README.md`
  - `pubspec.yaml`
- User environment verification:
  - `flutter analyze`: PASS, no issues found.
- Local quick verification:
  - `tools/architecture_check.ps1`: PASS, direct Firebase surface remains 8.
  - `tools/quality_check.ps1 -SkipFlutter`: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
- Added CI entrypoint for architecture check, Cloud Functions syntax, Flutter dependency resolution, format, analyze, tests and optional debug APK build.
- Added GitHub Actions workflow for push, pull request and manual quality runs.
- Added release readiness checklist so package ids, signing, iOS plist, rules tests, Crashlytics, Analytics and smoke checks are tracked before production.
- Production deploy: false.

---

## 64W - App Observability Bootstrap

- Status: IMPLEMENTED / LOCAL_FLUTTER_ANALYZE_TIMEOUT / PASS_SKIP_FLUTTER_CI
- Changed files:
  - `lib/core/services/app_observability_service.dart`
  - `lib/main.dart`
  - `docs/project_index/rxpro_professional_hardening_plan.md`
  - `docs/project_index/rxpro_professional_audit_20260526.md`
  - `docs/project_index/rxpro_release_readiness_checklist.md`
- Added an app-level observability service for Crashlytics and Analytics.
- Bootstrap now runs inside a guarded root zone.
- Flutter framework errors and uncaught platform dispatcher errors are forwarded to Crashlytics on supported platforms.
- App open and navigation screen observer hooks are wired through Firebase Analytics on supported platforms.
- Auth user id is synchronized into Crashlytics/Analytics when the session stream changes.
- Local quick verification:
  - `tools/architecture_check.ps1`: PASS, direct Firebase surface remains 8.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
- Local `flutter analyze` timed out in this sandbox; run it in the user environment before treating 64W as Flutter-verified.
- Production deploy: false.

---

## 64X - Visible Text And AI Prompt Encoding Cleanup

- Status: PASS_NODE_CHECK / PASS_SKIP_FLUTTER_CI / FLUTTER_ANALYZE_USER_RECHECK_NEEDED
- Changed files:
  - `functions/index.js`
  - `functions/src/accounting/accountingCallable.ts`
  - `functions/src/accounting/accountingValidators.ts`
  - `lib/features/auth/phone_password_reset_flow_page.dart`
  - `tools/mojibake_scan.ps1`
  - `README.md`
  - `docs/project_index/rxpro_professional_hardening_plan.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
  - `docs/project_index/rxpro_release_readiness_checklist.md`
- Added clean Turkish prompt builders for campaign creative AI and business analysis AI.
- Routed live OpenAI calls to the clean prompt builders.
- Added clean fallback campaign variants and clean business analysis fallback messages.
- Rebuilt the phone password reset flow text with proper Turkish labels, warnings and action labels.
- Cleaned accounting TypeScript callable/validator error messages.
- Added `tools/mojibake_scan.ps1` for controlled encoding debt scans.
- Local quick verification:
  - `node --check functions/index.js`: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/architecture_check.ps1`: PASS, direct Firebase surface remains 8.
  - `tools/mojibake_scan.ps1 -CountOnly`: RUN, remaining signatures found for follow-up cleanup.
  - `rg` over `functions/src/accounting`: no mojibake signatures.
- Remaining mojibake debt still exists in legacy/dead blocks and other feature/docs files; continue feature-by-feature cleanup.
- Production deploy: false.

---

## 64Y - Feature Architecture Report And First Presentation Slice

- Status: PASS_SKIP_FLUTTER_CI / REPORT_ADDED / TARGETED_FLUTTER_TEST_TIMEOUT
- Changed files:
  - `tools/feature_architecture_report.ps1`
  - `lib/features/auth/presentation/pages/phone_password_reset_flow_page.dart`
  - `lib/features/auth/phone_password_reset_flow_page.dart`
  - `test/features/auth/presentation/phone_password_reset_flow_page_test.dart`
  - `README.md`
  - `docs/project_index/rxpro_professional_audit_20260526.md`
  - `docs/project_index/rxpro_professional_hardening_plan.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
  - `docs/project_index/rxpro_release_readiness_checklist.md`
- Added a feature architecture report for data/domain/presentation/test/large-file visibility.
- Moved the phone password reset flow into the auth presentation/pages boundary.
- Kept the old auth import path as a compatibility export.
- Added a widget test for the password reset flow labels and step transitions.
- Current architecture report:
  - Features: 17.
  - Features without presentation: 16.
  - Large Dart files over 30KB: 11.
- Local quick verification:
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/mojibake_scan.ps1 -CountOnly`: PASS/RUN with remaining signatures.
- Targeted Flutter test timed out in this sandbox:
  - `flutter test test/features/auth/presentation/phone_password_reset_flow_page_test.dart --no-pub`
- Production deploy: false.

---

## 64Z - User Quality Run Follow-Up

- Status: PASS_USER_WIDGET_TEST / PASS_USER_TESTS / ANALYZE_WARNING_FIXED / RG_FALLBACK_ADDED
- Changed files:
  - `lib/core/services/app_observability_service.dart`
  - `tools/architecture_check.ps1`
  - `tools/mojibake_scan.ps1`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_locked_lines.md`
  - `docs/rxpro_patch_ledger.md`
  - `docs/rxpro_locked_lines.md`
- User environment verification before this fix:
  - `flutter test test/features/auth/presentation/phone_password_reset_flow_page_test.dart`: PASS.
  - Full `flutter test`: PASS, 17 tests.
  - `flutter analyze`: 1 info, unnecessary `dart:ui` import in `AppObservabilityService`.
  - `tools/ci_quality_check.ps1 -SkipBuild`: reached analyze/test, but architecture check reported missing `rg`.
- Removed the unnecessary `dart:ui` import.
- Added PowerShell fallback scanning to `tools/architecture_check.ps1` when `rg` is unavailable.
- Added PowerShell fallback scanning to `tools/mojibake_scan.ps1` when `rg` is unavailable.
- Local quick verification after this fix:
  - `tools/architecture_check.ps1`: PASS, direct Firebase surface remains 8.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/mojibake_scan.ps1 -CountOnly`: PASS/RUN with remaining signatures.
- Production deploy: false.

---

## 65A - Auth Presentation Page Split

- Status: PASS_SKIP_FLUTTER_CI / PASS_ARCHITECTURE_REPORT / USER_FULL_CI_GREEN_BEFORE_SPLIT
- Changed files:
  - `lib/features/auth/presentation/pages/fix_login_gate_page.dart`
  - `lib/features/auth/fix_login_gate_page.dart`
  - `lib/features/auth/presentation/widgets/fix_login_gate_actions.dart`
  - `lib/features/auth/presentation/widgets/fix_login_brand.dart`
  - `docs/project_index/rxpro_professional_audit_20260526.md`
  - `docs/project_index/rxpro_professional_hardening_plan.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_locked_lines.md`
  - `docs/rxpro_patch_ledger.md`
  - `docs/rxpro_locked_lines.md`
- User environment verification before this split:
  - `flutter analyze`: PASS, no issues found.
  - `flutter test`: PASS, 17 tests.
  - `tools/ci_quality_check.ps1 -SkipBuild`: PASS.
- Moved `FixLoginGatePage` into `lib/features/auth/presentation/pages/`.
- Kept `lib/features/auth/fix_login_gate_page.dart` as a compatibility export.
- Extracted guest/forgot-password actions into `presentation/widgets/fix_login_gate_actions.dart`.
- Extracted brand/logo header into `presentation/widgets/fix_login_brand.dart`.
- Cleaned visible Turkish text in the login/register gate.
- Auth feature now has 0 Dart files above the 30KB budget.
- Overall large Dart files above 30KB dropped from 11 to 10.
- Local quick verification:
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Auth presentation mojibake scan: no signatures.
- Production deploy: false.

---

## 65B - Public Home Account Entry Presentation Split

- Status: PASS_SKIP_FLUTTER_CI / PASS_ARCHITECTURE_REPORT / ANALYZE_TIMEOUT_IN_SANDBOX
- Changed files:
  - `lib/features/public_home/account_entry_page.dart`
  - `lib/features/public_home/presentation/pages/account_entry_page.dart`
  - `lib/features/public_home/presentation/pages/account_entry_lite_pages.dart`
  - `lib/features/public_home/presentation/widgets/account_entry_cards.dart`
  - `lib/features/public_home/presentation/widgets/account_entry_menu.dart`
  - `lib/features/public_home/presentation/models/account_entry_context.dart`
  - `lib/main.dart`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_locked_lines.md`
  - `docs/project_index/rxpro_professional_hardening_plan.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
  - `docs/project_index/rxpro_professional_audit_20260526.md`
  - `docs/rxpro_patch_ledger.md`
  - `docs/rxpro_locked_lines.md`
- Moved the real account entry page into `lib/features/public_home/presentation/pages/`.
- Kept `lib/features/public_home/account_entry_page.dart` as a compatibility export.
- Extracted reusable account cards into `presentation/widgets/account_entry_cards.dart`.
- Extracted the account menu scaffold into `presentation/widgets/account_entry_menu.dart`.
- Extracted lightweight profile/settings pages and account context models into presentation files.
- Preserved the scoped session business id/category behavior inside `AccountEntryContext.fromSession()`.
- Public home now has 0 Dart files above the 30KB budget.
- Overall large Dart files above 30KB dropped from 10 to 9.
- Overall features without presentation dropped from 16 to 15.
- Local quick verification:
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Public home mojibake scan: no signatures.
- Sandbox limitation:
  - `dart format`, `dart analyze lib/features/public_home` and `flutter analyze` timed out in this environment.
  - User environment should run `tools/ci_quality_check.ps1 -SkipBuild` for the full Flutter gate.
- Production deploy: false.

---

## 65C - Business Analysis Presentation And Service Split

- Status: PASS_SKIP_FLUTTER_CI / PASS_ARCHITECTURE_REPORT / ANALYZE_DEFERRED_TO_USER_ENV
- Changed files:
  - `lib/features/business_analysis/business_analysis_page.dart`
  - `lib/features/business_analysis/business_product_movement_page.dart`
  - `lib/features/business_analysis/presentation/pages/business_analysis_page.dart`
  - `lib/features/business_analysis/presentation/pages/business_product_movement_page.dart`
  - `lib/features/business_analysis/presentation/widgets/business_analysis_widgets.dart`
  - `lib/features/business_analysis/presentation/models/business_analysis_view_models.dart`
  - `lib/features/business_analysis/services/business_analysis_ai_service.dart`
  - `lib/features/business_analysis/services/business_analysis_computation_service.dart`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_locked_lines.md`
  - `docs/project_index/rxpro_professional_hardening_plan.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
  - `docs/project_index/rxpro_professional_audit_20260526.md`
  - `docs/rxpro_patch_ledger.md`
  - `docs/rxpro_locked_lines.md`
- Moved the real business analysis page into `lib/features/business_analysis/presentation/pages/`.
- Kept `lib/features/business_analysis/business_analysis_page.dart` as a compatibility export.
- Moved the product movement page into `presentation/pages/` and kept its old path as a compatibility export.
- Extracted report cards, period selector and analysis sections into `presentation/widgets/business_analysis_widgets.dart`.
- Extracted analysis view models into `presentation/models/business_analysis_view_models.dart`.
- Moved Cloud Functions AI report call into `BusinessAnalysisAiService`.
- Moved date parsing, filtering, revenue computation, AI payload and local report algorithm into `BusinessAnalysisComputationService`.
- Cleaned visible Turkish text encoding inside the business analysis feature slice.
- Business analysis now has 0 Dart files above the 30KB budget.
- Overall large Dart files above 30KB dropped from 9 to 8.
- Overall features without presentation dropped from 15 to 14.
- Local quick verification:
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Business analysis mojibake scan: no signatures.
- Full Flutter analyze/test still needs to run in the user environment because Dart/Flutter analysis commands time out in this sandbox.
- Production deploy: false.

---

## 65D - Appointments Presentation Split And Analysis Service Test

- Status: PASS_SKIP_FLUTTER_CI / PASS_ARCHITECTURE_REPORT / TARGETED_TEST_TIMEOUT_IN_SANDBOX
- Changed files:
  - `lib/features/appointments/appointment_entry_page.dart`
  - `lib/features/appointments/customer_appointments_page.dart`
  - `lib/features/appointments/presentation/pages/appointment_entry_page.dart`
  - `lib/features/appointments/presentation/pages/customer_appointments_page.dart`
  - `lib/features/appointments/presentation/widgets/appointment_dashboard_views.dart`
  - `lib/features/appointments/presentation/widgets/customer_appointment_widgets.dart`
  - `lib/features/appointments/presentation/models/appointment_dashboard_models.dart`
  - `lib/main.dart`
  - `lib/core/realtime/rx_push_notification_service.dart`
  - `lib/features/public_home/presentation/widgets/account_entry_menu.dart`
  - `test/features/business_analysis/business_analysis_computation_service_test.dart`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_locked_lines.md`
  - `docs/project_index/rxpro_professional_hardening_plan.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
  - `docs/project_index/rxpro_professional_audit_20260526.md`
  - `docs/rxpro_patch_ledger.md`
  - `docs/rxpro_locked_lines.md`
- Added pure tests for `BusinessAnalysisComputationService` date filtering, cancellation filtering, revenue totals and top-list summaries.
- Moved `AppointmentEntryPage` and `CustomerAppointmentsPage` into `lib/features/appointments/presentation/pages/`.
- Kept both old appointment root page paths as compatibility exports.
- Extracted appointment dashboard daily flow, heatmap, legend and error card into `presentation/widgets/appointment_dashboard_views.dart`.
- Extracted appointment dashboard lightweight view models into `presentation/models/appointment_dashboard_models.dart`.
- Extracted customer appointment tabs, empty state, info line and status line widgets into `presentation/widgets/customer_appointment_widgets.dart`.
- Updated main, push notification and public home imports to use the new presentation page paths.
- Cleaned visible Turkish text encoding inside appointment presentation files.
- Appointments now has 0 Dart files above the 30KB budget.
- Overall large Dart files above 30KB dropped from 8 to 6.
- Overall features without presentation dropped from 14 to 13.
- Business analysis test file count increased from 1 to 2.
- Local quick verification:
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Appointment presentation and business analysis mojibake scan: no signatures.
- Sandbox limitation:
  - `flutter test test/features/business_analysis/business_analysis_computation_service_test.dart --no-pub` timed out after 120s.
  - Full Flutter analyze/test should be run in the user environment.
- Production deploy: false.

---

## 65E - Business Finance Presentation Split And Formatter Test

- Status: PASS_SKIP_FLUTTER_CI / PASS_ARCHITECTURE_REPORT
- Changed files:
  - `lib/features/businesses/business_finance_page.dart`
  - `lib/features/businesses/presentation/pages/business_finance_page.dart`
  - `lib/features/businesses/presentation/models/business_finance_models.dart`
  - `lib/features/businesses/presentation/widgets/business_finance_widgets.dart`
  - `lib/features/businesses/presentation/utils/business_finance_formatters.dart`
  - `lib/features/businesses/business_owner_hub_page.dart`
  - `lib/features/public_home/presentation/pages/account_entry_page.dart`
  - `test/features/businesses/presentation/business_finance_formatters_test.dart`
- Moved the real business finance page into `lib/features/businesses/presentation/pages/`.
- Kept `lib/features/businesses/business_finance_page.dart` as a compatibility export.
- Extracted finance summary/debug/report widgets into `presentation/widgets/business_finance_widgets.dart`.
- Extracted finance display rows into `presentation/models/business_finance_models.dart`.
- Extracted month/file/money formatting into `presentation/utils/business_finance_formatters.dart`.
- Added focused pure tests for finance formatter behavior.
- Businesses now has a `presentation` boundary.
- Overall large Dart files above 30KB dropped from 6 to 5.
- Overall features without presentation dropped from 13 to 12.
- Local quick verification:
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Businesses presentation mojibake scan: no signatures.
- Full Flutter analyze/test should be run in the user environment.
- Production deploy: false.

---

## 65F - Business Staff Management Presentation Split

- Status: PASS_SKIP_FLUTTER_CI / PASS_ARCHITECTURE_REPORT
- Changed files:
  - `lib/features/businesses/business_staff_manage_page.dart`
  - `lib/features/businesses/presentation/pages/business_staff_manage_page.dart`
  - `lib/features/businesses/presentation/pages/business_staff_form_page.dart`
  - `lib/features/businesses/presentation/widgets/business_staff_manage_widgets.dart`
  - `lib/features/businesses/business_owner_hub_page.dart`
  - `lib/features/public_home/presentation/pages/account_entry_page.dart`
- Moved the real staff management page into `lib/features/businesses/presentation/pages/`.
- Kept `lib/features/businesses/business_staff_manage_page.dart` as a compatibility export.
- Split the staff create/edit form into `presentation/pages/business_staff_form_page.dart`.
- Extracted reusable staff group/card UI into `presentation/widgets/business_staff_manage_widgets.dart`.
- Updated business owner hub and public home imports to use the new presentation page path.
- Overall large Dart files above 30KB dropped from 5 to 4.
- Businesses large Dart files above 30KB dropped from 4 to 3.
- Overall features without presentation remains 12.
- Local quick verification:
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Businesses presentation mojibake scan: no signatures.
- Full Flutter analyze/test should be run in the user environment.
- Production deploy: false.

---

## 65G - Accounting Sales Presentation Split

- Status: PASS_SKIP_FLUTTER_CI / PASS_ARCHITECTURE_REPORT
- Changed files:
  - `lib/features/accounting/pages/accounting_sales_page.dart`
  - `lib/features/accounting/presentation/pages/accounting_sales_page.dart`
  - `lib/features/accounting/presentation/widgets/accounting_sales_widgets.dart`
  - `lib/features/accounting/presentation/models/accounting_sales_models.dart`
  - `lib/features/accounting/business_accounting_shell.dart`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_locked_lines.md`
  - `docs/project_index/rxpro_professional_hardening_plan.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
  - `docs/project_index/rxpro_professional_audit_20260526.md`
  - `docs/rxpro_patch_ledger.md`
  - `docs/rxpro_locked_lines.md`
- Moved the real accounting sales page into `lib/features/accounting/presentation/pages/`.
- Kept `lib/features/accounting/pages/accounting_sales_page.dart` as a compatibility export.
- Extracted sales wizard steps, preview rows, header and step cards into `presentation/widgets/accounting_sales_widgets.dart`.
- Extracted sales wizard/catalog lightweight models into `presentation/models/accounting_sales_models.dart`.
- Updated accounting shell import to use the new presentation page path.
- Accounting now has a `presentation` boundary and 0 Dart files above the 30KB budget.
- Overall large Dart files above 30KB dropped from 4 to 3.
- Overall features without presentation dropped from 12 to 11.
- Local quick verification:
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Accounting presentation mojibake scan: no signatures.
- Full Flutter analyze/test should be run in the user environment.
- Production deploy: false.

---

## 65H - Location Discovery And Directions Flow

- Status: PASS_SKIP_FLUTTER_CI / PASS_ARCHITECTURE_REPORT / TARGETED_TEST_TIMEOUT_IN_SANDBOX
- Changed files:
  - `lib/core/businesses/business_location_data.dart`
  - `lib/core/businesses/business_directions_service.dart`
  - `lib/core/businesses/business_directory_cache_service.dart`
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_business_cards.dart`
  - `lib/features/business/data/business_profile_edit_repository.dart`
  - `lib/features/business/pages/business_profile_edit_page.dart`
  - `test/core/businesses/business_location_data_test.dart`
- Added a shared business location parser for Firestore `GeoPoint`, direct `lat/lng`, `latitude/longitude`, nested Google Places `geometry.location`, comma decimal coordinates and formatted address/map fields.
- Added a pure haversine distance helper and tests covering Google Places geometry, comma/whitespace coordinates and nearby distance calculation.
- Added `BusinessDirectionsService` to open Google Maps directions with business destination and optional user origin.
- Extended `BusinessDirectoryItem` with address, phone, place id, map url, source and member/directory-only membership state.
- Added Google Places type-to-category fallback for beauty/spa/hair/barber, health/clinic, sport and education records.
- Updated explore sorting to support smart recommendation, nearest, rating/popularity, category and A-Z modes.
- Added member-aware discovery cards:
  - RxPro member businesses keep profile/photo/rating/profile actions.
  - Directory-only or Google-imported businesses show a compact no-profile-photo card focused on name, distance/location and directions.
- Added directions action to business cards.
- Added business-side location capture in the business profile edit page and persisted `lat`, `lng`, `latitude`, `longitude`, `location` GeoPoint, `locationUpdatedAt` and `locationSource`.
- Kept public_home at 0 Dart files above the 30KB budget by extracting explore cards into presentation widgets.
- Local quick verification:
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - New core/businesses and public_home location slices mojibake scan: no signatures.
- Sandbox limitation:
  - `flutter test test/core/businesses/business_location_data_test.dart --no-pub` timed out after 120s.
  - Full Flutter analyze/test should be run in the user environment.
- Production deploy: false.

---

## 65I - Location Geo Index Query Foundation

- Status: PASS_SKIP_FLUTTER_CI / PASS_ARCHITECTURE_REPORT / TARGETED_TEST_TIMEOUT_IN_SANDBOX
- Changed files:
  - `lib/core/businesses/business_geo_index.dart`
  - `lib/core/businesses/business_directory_cache_service.dart`
  - `lib/core/firestore/firestore_fields.dart`
  - `lib/features/business/data/business_profile_edit_repository.dart`
  - `lib/features/public_home/home_explore_page.dart`
  - `functions/package.json`
  - `functions/scripts/backfillBusinessGeoIndex.js`
  - `test/core/businesses/business_geo_index_test.dart`
  - `docs/project_index/rxpro_deep_analysis_notes_20260526_location_scale.md`
- Added a pure geohash encoder, prefix payload builder and neighboring-prefix helper for Firestore-friendly location indexes.
- Added `geoHash`, `geoHash4`, `geoHash5`, `geoHash6`, `geoHash7`, `locationUpdatedAt` and `locationSource` Firestore field constants.
- Business profile location saves now persist stable geohash prefixes together with scalar coordinates and GeoPoint.
- Discovery now uses indexed nearby business queries when user location is available, with a safe fallback to the existing broad cache for legacy/imported records.
- Explore radius changes now refresh the indexed location query when a user location exists.
- Added a Firebase Admin dry-run-first backfill script for old/imported business records: `npm run backfill:business-geo-index -- --limit=50`, then `-- --write` when reviewed.
- Added pure geohash tests for known coordinates, prefix payloads, radius precision choice and nearby-prefix coverage.
- Current counts after this patch:
  - `lib` Dart files: 194.
  - `test` Dart files: 11.
  - Overall large Dart files above 30KB: 3.
  - Features without presentation: 11.
- Local quick verification:
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - New geo/public_home slices mojibake scan: no signatures.
  - `node --check functions/scripts/backfillBusinessGeoIndex.js`: PASS.
- Sandbox limitation:
  - `dart format ...` timed out after 120s.
  - `flutter test test/core/businesses/business_geo_index_test.dart --no-pub` timed out after 120s.
  - `flutter test test/core/businesses/business_location_data_test.dart --no-pub` timed out after 120s.
  - Full Flutter format/analyze/test should be run in the user environment.
- Production deploy: false.

---

## 65J - Business Appointment Management Presentation Split

- Status: PASS_SKIP_FLUTTER_CI / PASS_ARCHITECTURE_REPORT / FORMAT_ANALYZE_TIMEOUT_IN_SANDBOX
- Changed files:
  - `lib/features/businesses/business_appointment_management_page.dart`
  - `lib/features/businesses/presentation/pages/business_customer_direct_message_page.dart`
  - `lib/features/businesses/presentation/widgets/business_appointment_management_widgets.dart`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_locked_lines.md`
  - `docs/rxpro_locked_lines.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
  - `docs/project_index/rxpro_professional_hardening_plan.md`
  - `docs/project_index/rxpro_professional_audit_20260526.md`
- Extracted the customer direct-message page from the monolithic business appointment management page into `presentation/pages/`.
- Extracted appointment summary card, status pill, customer info row and quick customer profile sheet into `presentation/widgets/`.
- Removed unused legacy appointment summary helper functions from the root page.
- `business_appointment_management_page.dart` dropped below the 30KB large-file budget.
- Current counts after this patch:
  - `lib` Dart files: 196.
  - `test` Dart files: 11.
  - Overall large Dart files above 30KB: 2.
  - Businesses large Dart files above 30KB: 2.
  - Features without presentation: 11.
- Local quick verification:
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - New businesses appointment presentation slices mojibake scan: no signatures.
- Sandbox limitation:
  - `dart format ...` timed out after 120s.
  - `flutter analyze --no-pub` timed out after 120s.
  - Full Flutter format/analyze/test should be run in the user environment.
- Production deploy: false.

---

## 65K - Business Analysis Local AI Compile Fix

- Status: PASS_SKIP_FLUTTER_CI / TARGETED_TEST_TIMEOUT_IN_SANDBOX
- Changed files:
  - `lib/features/business_analysis/services/business_analysis_computation_service.dart`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/rxpro_patch_ledger.md`
- Fixed the `localAiReport` method signature to accept the `periodLabel`, `periodMode` and `anchorDate` values already passed by `BusinessAnalysisPage`.
- This resolves the compile error:
  - `The getter 'periodLabel' isn't defined for the type 'BusinessAnalysisComputationService'.`
- Local quick verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Business analysis computation service mojibake scan: no signatures.
- Sandbox limitation:
  - `flutter test test/features/business_analysis/business_analysis_computation_service_test.dart --no-pub` timed out after 120s.
- Full Flutter test/analyze should be rerun in the user environment.
- Production deploy: false.

---

## 65L - Analyze Account Entry And Widget Key Cleanup

- Status: PASS_SKIP_FLUTTER_CI / PASS_ARCHITECTURE_REPORT / ANALYZE_TIMEOUT_IN_SANDBOX
- Changed files:
  - `lib/features/public_home/presentation/pages/account_entry_page.dart`
  - `lib/features/appointments/presentation/widgets/appointment_dashboard_views.dart`
  - `lib/features/appointments/presentation/widgets/customer_appointment_widgets.dart`
  - `lib/features/business_analysis/presentation/widgets/business_analysis_widgets.dart`
  - `lib/features/public_home/presentation/pages/account_entry_lite_pages.dart`
  - `lib/features/public_home/presentation/widgets/account_entry_cards.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_business_cards.dart`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/rxpro_patch_ledger.md`
- Imported `AccountModeX` into `account_entry_page.dart` so `accountMode.isCorporate` resolves correctly.
- Removed the unused `_displayNameOf` helper from `account_entry_page.dart`.
- Added `super.key` to the public widget constructors flagged by analyze in appointment, business analysis and public home presentation slices.
- Local quick verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
  - Touched slices mojibake scan: no signatures.
- Sandbox limitation:
  - Targeted `flutter analyze ...` timed out after 240s in this sandbox.
  - Full Flutter analyze should be rerun in the user environment.
- Production deploy: false.

---

## 65M - Google Places Live Directory And Seed Index Foundation

- Status: PASS_NODE_SYNTAX / FLUTTER_TOOL_TIMEOUT_IN_SANDBOX
- Changed files:
  - `functions/index.js`
  - `functions/package.json`
  - `functions/scripts/seedGooglePlacesDirectoryIndex.js`
  - `lib/core/businesses/business_directory_cache_service.dart`
  - `lib/core/businesses/google_places_directory_service.dart`
  - `lib/features/public_home/home_explore_page.dart`
  - `test/core/businesses/business_directory_item_test.dart`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
  - `docs/project_index/rxpro_professional_hardening_plan.md`
  - `docs/project_index/rxpro_deep_analysis_notes_20260526_location_scale.md`
- Added callable Cloud Function `searchNearbyDirectoryBusinesses` in `europe-west1`.
- Google Places API key is kept server-side through `GOOGLE_PLACES_API_KEY`; it is not exposed to the mobile app.
- Discovery now merges RxPro member businesses from Firestore with live Google Places directory-only businesses when user location is available.
- Category changes now reload the live nearby search so beauty, clinic and sport/fitness discovery can be narrowed by user intent.
- Added a dry-run-first seed script for large city minimum index creation:
  - collection default: `businessPlaceIndex`
  - stored data: `placeId`, provider/source, category group, types, lat/lng, GeoPoint and geohash prefixes
  - intentionally does not store full Google business profile content
- Added pure parser test coverage for live Google Places directory payloads.
- Local verification:
  - `node --check functions/index.js`: PASS.
  - `node --check functions/scripts/seedGooglePlacesDirectoryIndex.js`: PASS.
- Sandbox limitation:
  - `dart format`, targeted `flutter test` and `flutter analyze` timed out in this environment without returning code errors.
  - Full Flutter format/analyze/test should be rerun in the user environment.
- Production deploy: pending `GOOGLE_PLACES_API_KEY` secret and Firebase Functions deploy.

---

## 65N - Places Runtime Healthcheck And Business Claim Requests

- Status: PASS_NODE_SYNTAX / PASS_SKIP_FLUTTER_CI / PASS_ARCHITECTURE_REPORT / LIVE_ENDPOINT_INTERNAL_ON_OLD_DEPLOY
- Changed files:
  - `functions/index.js`
  - `lib/core/firestore/firestore_collections.dart`
  - `lib/features/public_home/data/home_explore_claim_repository.dart`
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_business_cards.dart`
  - `infra/rules/firestore.rules`
  - `tools/check_places_function.ps1`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/rxpro_patch_ledger.md`
- Live endpoint check reached:
  - `https://europe-west1-rxpro-mobile-202605172210.cloudfunctions.net/searchNearbyDirectoryBusinesses`
  - Current deployed version responded with `500 INTERNAL`, so deployment exists but runtime/config is not healthy yet.
- Added safe `GOOGLE_PLACES_API_KEY` secret reading and a callable `healthCheck` branch.
- Wrapped Places API calls in structured error handling so future runtime failures return safer callable errors instead of anonymous `INTERNAL`.
- Added debug live-sample mode so `tools/check_places_function.ps1 -LiveSample` prints the sanitized Google Places rejection reason after redeploy.
- Added category type fallback groups for 400-level Nearby Search type validation failures.
- Added `tools/check_places_function.ps1` for post-deploy health checks.
- Added `businessClaimRequests` collection constant.
- Added `HomeExploreClaimRepository` to create pending claim requests from Google directory-only business cards.
- Directory-only cards now include `Bu işletme benim` claim CTA next to directions.
- Firestore rules now allow signed-in users to create/read/update only their own pending claim request.
- Local verification:
  - `node --check functions/index.js`: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS/RUN.
- Sandbox limitation:
  - `flutter analyze --no-pub` and targeted Flutter test timed out after 180s.
- Required next deploy:
  - redeploy `searchNearbyDirectoryBusinesses`;
  - run `tools/check_places_function.ps1`;
  - optionally run `tools/check_places_function.ps1 -LiveSample`.

---

## 65O - Places Secret Automation And Live Check Cleanup

- Status: USER_DEPLOY_VERIFIED / PASS_SCRIPT_CLEANUP_PENDING_FULL_FLUTTER
- Changed files:
  - `tools/set_places_secret_from_file.ps1`
  - `tools/check_places_function.ps1`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/rxpro_patch_ledger.md`
- Added `tools/set_places_secret_from_file.ps1` so the Google Places API key can be read from the desktop key file and written into Firebase Secret Manager without printing the key.
- Confirmed the deployed `searchNearbyDirectoryBusinesses` function is now returning live Google Places results from the user-side check:
  - source: `google_places_live`
  - category: `beauty_care`
  - radius: `1500`
  - result included real nearby directory-only businesses.
- Cleaned `tools/check_places_function.ps1` so live checks print a short summary instead of dumping the full Places JSON response into the terminal.
- The accidental `firebase-functions@latestpowershell` command in the terminal was only a paste/typing mistake; the later actual check passed.
- Local verification still required for the mobile app after this operational fix:
  - `flutter analyze`
  - `flutter test`
  - debug APK smoke test.
- Production deploy: completed by user for `searchNearbyDirectoryBusinesses`.

---

## 65P - App Display Name Rebrand To fi

- Status: PASS_LIGHT_VALIDATION / PENDING_FULL_FLUTTER
- Changed files:
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/kotlin/com/example/rxpro_mobile/MainActivity.kt`
  - `ios/Runner/Info.plist`
  - `lib/main.dart`
  - `lib/core/realtime/rx_push_notification_service.dart`
  - `lib/features/campaigns/customer_campaigns_page.dart`
  - `lib/features/businesses/presentation/pages/business_finance_page.dart`
  - `lib/features/public_home/presentation/widgets/account_entry_menu.dart`
  - `web/index.html`
  - `web/manifest.json`
  - `macos/Runner/Configs/AppInfo.xcconfig`
  - `linux/runner/my_application.cc`
  - `windows/runner/main.cpp`
  - `windows/runner/Runner.rc`
  - `lib/features/accounting/ACCOUNTING_CHECKLIST.md`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/rxpro_patch_ledger.md`
- Changed install-visible app labels to `fi` for Android and iOS.
- Updated iOS permission prompts, mobile notification fallback title/channel name, Flutter app title, web/PWA title, desktop window titles and visible leftover brand fallbacks.
- Intentionally did not change:
  - Android `applicationId`
  - iOS bundle identifier
  - Firebase package/config identifiers
  - Dart package name in `pubspec.yaml`
  - existing Firestore field names such as `isRxProMember`
- Reason: changing package/bundle identifiers would create a new app identity and can break Firebase registration, installed update behavior and production continuity.
- Local verification:
  - `web/manifest.json` JSON parse: PASS.
  - `ios/Runner/Info.plist` XML parse: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
- Sandbox limitation:
  - `dart format` timed out in this environment.
- Production deploy: no backend deploy required.

---

## 65Q - Turkish UX Copy And Istanbul Explore Starter

- Status: PASS_TARGETED_MOJIBAKE_SCAN / PASS_SKIP_FLUTTER_CI / FLUTTER_TOOL_TIMEOUT_IN_SANDBOX
- Changed files:
  - `lib/core/businesses/business_category.dart`
  - `lib/core/businesses/business_directory_cache_service.dart`
  - `lib/core/businesses/google_places_directory_service.dart`
  - `lib/features/messages/messages_inbox_page.dart`
  - `lib/features/messages/data/messages_repository.dart`
  - `lib/features/campaigns/business_campaigns_page.dart`
  - `lib/features/campaigns/campaign_ai_create_safe_page.dart`
  - `lib/features/campaigns/bulk_message_create_page.dart`
  - `lib/features/campaigns/customer_campaigns_page.dart`
  - `lib/features/campaigns/campaign_service.dart`
  - `lib/features/guest/guest_required_sheet.dart`
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_business_cards.dart`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/rxpro_patch_ledger.md`
- Fixed Turkish character corruption in the critical user-facing surfaces:
  - Messages inbox, new message, thread, recall dialog and empty states.
  - Business campaign management, AI campaign creation, bulk message draft and customer campaign fallbacks.
  - Guest-required login sheet.
  - Explore business cards and shared category labels.
- Reworked messaging copy by role:
  - Business owner sees an inbox for individual user questions, demands and feedback.
  - Individual user sees a flow for messaging businesses.
  - Business owner no longer sees copy that implies messaging other businesses from the business inbox.
- Added Istanbul starter discovery:
  - When no user location is available, Explore loads a starter Google Places directory around Istanbul center.
  - Category and radius changes now refresh this starter discovery too.
  - Once location permission is available, the flow switches back to user-location ranking.
- Kept data compatibility:
  - Existing fields such as `isRxProMember` remain unchanged.
  - Existing message thread schema and campaign write schema remain unchanged.
- Local verification:
  - Targeted mojibake scan for touched message/campaign/explore/category files: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
- Sandbox limitation:
  - `dart format`, `flutter analyze --no-pub` and targeted `flutter test` timed out in this environment.
- Follow-up inventory:
  - Other feature surfaces still contain legacy mojibake, especially business profile edit, products, notification repository and old accounting docs.
- Production deploy: no backend deploy required for the mobile app changes.

---

## 65R - Test Inventory And Connected UX Cleanup

- Status: PASS_TARGETED_MOJIBAKE_SCAN / PASS_ARCHITECTURE_REPORT / PASS_SKIP_FLUTTER_CI / FLUTTER_TOOL_TIMEOUT_IN_SANDBOX
- Changed files:
  - `lib/core/app_state/current_user_state_service.dart`
  - `lib/core/models/auth_status_model.dart`
  - `lib/features/appointments/service/appointment_booking_service.dart`
  - `lib/features/business/pages/business_profile_edit_page.dart`
  - `lib/features/businesses/business_category_required_page.dart`
  - `lib/features/businesses/business_owner_hub_page.dart`
  - `lib/features/businesses/business_products_page.dart`
  - `lib/features/businesses/business_profile_page.dart`
  - `lib/features/businesses/data/business_staff_repository.dart`
  - `lib/features/notifications/data/notification_center_repository.dart`
  - `lib/features/notifications/notification_center_page.dart`
  - `lib/features/accounting/pages/accounting_reports_page.dart`
  - `lib/features/accounting/pages/accounting_receivables_page.dart`
  - `lib/features/accounting/pages/accounting_expenses_page.dart`
  - `lib/features/campaigns/business_campaigns_page.dart`
  - `lib/features/campaigns/bulk_message_create_page.dart`
  - `lib/features/campaigns/campaign_ai_create_safe_page.dart`
  - `lib/features/campaigns/campaign_models.dart`
  - `lib/features/campaigns/customer_campaigns_page.dart`
  - `test/features/campaigns/campaign_models_test.dart`
- Test inventory:
  - `lib` Dart files: 198.
  - `test` Dart files: 13.
  - Ratio: about 6.6%, still weak for production-grade confidence.
- UX/connectivity fixes:
  - Business campaign cards now open a detail bottom sheet.
  - Bulk message draft status is now `draft_ready` and the copy describes a ready-for-approval flow.
  - Accounting preview sheets no longer show disabled dead buttons.
  - Campaign AI preview CTA now explains that it is a preview control.
  - Empty campaign descriptions now say "Kampanya açıklaması henüz girilmedi" instead of "yakında".
- Quality cleanup:
  - Cleared remaining real mojibake in key business, product, notification and role/session surfaces.
  - Targeted mojibake scan over `lib/**/*.dart`: no bad `Ã/Ä/Å/�` files found.
- Remaining professional gaps:
  - `business_profile_page.dart` and `staff_workspace_page.dart` are still above the 30KB split target.
  - 11 features still lack a presentation directory.
  - Accounting real write/export flows remain intentionally gated until secure Cloud Function write paths are completed.
- Local verification:
  - `tools/feature_architecture_report.ps1`: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
- Sandbox limitation:
  - `dart --version`, `dart format` and targeted `flutter test` timed out in this environment.
- Production deploy: no backend deploy required for this mobile-side cleanup.

---

## 65S - Large Page Split To Professional Feature Slices

- Status: PASS_ARCHITECTURE_REPORT / PASS_SKIP_FLUTTER_CI / PASS_TARGETED_MOJIBAKE_SCAN / FLUTTER_TOOL_TIMEOUT_IN_SANDBOX
- Changed files:
  - `lib/features/businesses/business_profile_page.dart`
  - `lib/features/businesses/presentation/widgets/business_profile_header_part.dart`
  - `lib/features/businesses/presentation/widgets/business_profile_intro_part.dart`
  - `lib/features/businesses/presentation/widgets/business_profile_booking_part.dart`
  - `lib/features/businesses/presentation/widgets/business_profile_reviews_part.dart`
  - `lib/features/businesses/staff_workspace_page.dart`
  - `lib/features/businesses/presentation/widgets/staff_workspace_permissions_part.dart`
  - `lib/features/businesses/presentation/widgets/staff_workspace_actions_part.dart`
  - `lib/features/businesses/presentation/widgets/staff_workspace_widgets_part.dart`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/rxpro_patch_ledger.md`
- Split result:
  - `business_profile_page.dart`: root page shell is now about 6.4KB.
  - `staff_workspace_page.dart`: root page shell is now about 11.2KB.
  - Largest new part file is `business_profile_booking_part.dart` at about 29.1KB.
  - No Dart file remains above the 30KB budget.
- Architecture report:
  - `Large files over 30KB: 0`.
  - `businesses` feature still has data and presentation boundaries.
- Current inventory:
  - `lib` Dart files: 205.
  - `test` Dart files: 13.
  - Test ratio: about 6.3%, still weak.
- Local verification:
  - `tools/feature_architecture_report.ps1`: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Targeted mojibake scan over `lib/**/*.dart`: PASS.
- Sandbox limitation:
  - Full Flutter format/analyze/test should be rerun locally.
- Production deploy: no backend deploy required for this architecture split.

---

## 65T - Category And Session Role Test Coverage

- Status: PASS_ARCHITECTURE_REPORT / PASS_SKIP_FLUTTER_CI / FLUTTER_TOOL_TIMEOUT_IN_SANDBOX
- Changed files:
  - `test/core/businesses/business_category_test.dart`
  - `test/core/session/session_role_policy_test.dart`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/rxpro_patch_ledger.md`
- Added tests:
  - Business category Turkish normalization.
  - Dynamic category fallback by id, label and legacy business category fields.
  - Category matching including the `Tümü` label.
  - Firestore category compatibility payload fields.
  - Session role precedence where modern individual account kind wins over legacy business leftovers.
  - Active linked staff resolves as corporate staff.
  - Inactive linked staff falls back to individual mode.
  - Owner authority accepts owner UID fields from business data.
- Current inventory:
  - `lib` Dart files: 205.
  - `test` Dart files: 14.
  - Test ratio: about 6.8%.
- Local verification:
  - `tools/feature_architecture_report.ps1`: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
- Sandbox limitation:
  - Full Flutter test execution should be rerun locally.
- Production deploy: no backend deploy required.

---

## 65U - Staff Workspace Analyze Cleanup

- Status: PASS_ARCHITECTURE_REPORT / PASS_SKIP_FLUTTER_CI / USER_TESTS_PASS_BEFORE_PATCH / FLUTTER_ANALYZE_TIMEOUT_IN_SANDBOX
- Changed files:
  - `lib/features/businesses/staff_workspace_page.dart`
  - `lib/features/businesses/presentation/widgets/staff_workspace_permissions_part.dart`
  - `lib/features/businesses/presentation/widgets/staff_workspace_actions_part.dart`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/rxpro_patch_ledger.md`
- Fixes:
  - Moved `_toggle` back into `_StaffWorkspacePageState`, removing the analyzer warning about `setState` inside an extension.
  - Changed staff expense guard access to `_StaffWorkspacePageState._staffExpenseLiveWriteEnabled`, removing the analyzer error about unqualified static access from an extension.
- Verification:
  - User reported `flutter test`: `00:04 +42: All tests passed!` before this cleanup.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Large files over 30KB remain `0`.
- Sandbox limitation:
  - `flutter analyze --no-pub` timed out in this environment; rerun `flutter analyze` locally to verify the two reported issues are gone.
- Production deploy: no backend deploy required.

---

## 65V - Business Customer CRM And Segment Bulk Messaging

- Status: PASS_ARCHITECTURE_REPORT / PASS_SKIP_FLUTTER_CI / PASS_TARGETED_MOJIBAKE_SCAN / FLUTTER_TOOL_TIMEOUT_IN_SANDBOX
- Changed files:
  - `lib/core/firestore/firestore_collections.dart`
  - `lib/features/businesses/data/business_customer_repository.dart`
  - `lib/features/businesses/business_customers_page.dart`
  - `lib/features/businesses/business_owner_hub_page.dart`
  - `lib/features/businesses/staff_workspace_page.dart`
  - `lib/features/campaigns/bulk_message_create_page.dart`
  - `lib/features/campaigns/campaign_models.dart`
  - `infra/rules/firestore.rules`
  - `emulator_rules_lab/firestore.rules`
  - `test/features/businesses/data/business_customer_repository_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
- Feature result:
  - Corporate customer history now has a repository/model layer.
  - Appointment records are aggregated into customer history by UID, phone, email or name.
  - Manual customer records can be created and later enriched by appointment history.
  - Customers can be classified as manual, new, active, loyal, inactive or follow-up required.
  - Selected customer segment opens a business-bound bulk message draft with audience metadata and estimated target count.
- Security/rules:
  - `businessCustomers` is allowed only as a business-scoped collection.
  - Emulator draft rules include the same collection for local rules testing.
- Current inventory:
  - `lib` Dart files: 207.
  - `test` Dart files: 15.
  - Large files over 30KB: 0.
- Local verification:
  - `tools/feature_architecture_report.ps1`: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Targeted mojibake scan over touched files: PASS.
- Sandbox limitation:
  - `dart format`, `flutter analyze --no-pub` and targeted `flutter test` timed out in this environment; rerun locally before APK build.
- Production deploy:
  - Firestore rules need deploy for live writes to `businessCustomers`.

---

## 65W - Startup Freeze Guard And APK Launch Diagnostics

- Status: PASS_PS_SCRIPT_PARSE / PASS_SKIP_FLUTTER_CI / PASS_TARGETED_MOJIBAKE_SCAN
- Changed files:
  - `lib/main.dart`
  - `lib/core/realtime/rx_push_notification_service.dart`
  - `lib/core/services/app_observability_service.dart`
  - `tools/apk_test_install.ps1`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fixes:
  - Startup freeze guard was added; the visible app-name value is superseded by 65X and is now `fix`.
  - First app frame is no longer blocked by push notification setup or follow-cache warmup.
  - Push notification permission/token/initial-message startup reads are timeout guarded.
  - Crashlytics setup is started asynchronously so it cannot hold the first screen.
  - The visible login prompt now says `fi hesabınla devam et`.
  - APK test/install script now resolves `adb.exe`, launches with `am start`, and captures `06_runtime_logcat.txt` for freeze/crash diagnosis.
- Verification:
  - PowerShell parser: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Targeted mojibake scan: PASS.
- Sandbox limitation:
  - ADB execution is blocked in this Codex sandbox, so device log verification must be done from the user PowerShell session.

---

## 65X - Published App Name Correction To fix

- Status: PASS_SKIP_FLUTTER_CI / PASS_TARGETED_MOJIBAKE_SCAN / FLUTTER_ANALYZE_TIMEOUT_IN_SANDBOX
- Changed files:
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/kotlin/com/example/rxpro_mobile/MainActivity.kt`
  - `ios/Runner/Info.plist`
  - `web/manifest.json`
  - `web/index.html`
  - `macos/Runner/Configs/AppInfo.xcconfig`
  - `linux/runner/my_application.cc`
  - `windows/runner/Runner.rc`
  - `lib/main.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - The publish/install visible app name is now `fix`, not `fi`.
  - Notification fallback/channel name and platform desktop/web titles also use `fix`.
  - Internal package identifiers remain unchanged.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - Targeted mojibake scan: PASS.
  - Brand spot-check: Android/iOS/web/desktop visible name values are `fix`.
- Sandbox limitation:
  - `flutter analyze --no-pub` timed out in this environment; rerun locally before release build.

---

## 65Y - Explore Freeze Stabilization

- Status: IMPLEMENTED / DEVICE_RETEST_REQUIRED
- Changed files:
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_shell_widgets.dart`
  - `lib/core/businesses/business_directory_cache_service.dart`
  - `lib/core/businesses/google_places_directory_service.dart`
  - `tools/explore_freeze_debug.ps1`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Debug finding:
  - `EXPLORE_FREEZE_DEBUG_20260526_160023.zip` showed a successful cold launch and visible activity, not a crash.
  - Logcat contained main-thread skipped-frame warnings around startup and early interaction, which points to startup/discovery workload rather than an APK install failure.
- Fixes:
  - Explore starter discovery now begins after the first frame.
  - Silent location lookup is delayed and timeout guarded.
  - Category/radius refresh keeps existing results visible and shows a thin progress indicator instead of blocking the screen.
  - Stale directory responses are ignored with a load-ticket guard.
  - Firestore directory reads and Google Places callable reads have timeout fallback.
  - `FIX_EXPLORE_*` log markers were added for precise follow-up diagnosis.
  - `tools/explore_freeze_debug.ps1` now creates a reusable device debug zip for this exact screen.
  - Shared explore shell widgets were split out; architecture report is back to `Large files over 30KB: 0`.
- Sandbox limitation:
  - `dart format` and targeted `flutter test` timed out in this environment; rerun local analyze/test/APK debug flow after this patch.

---

## 65Z - PDF Audit Follow-up: Session And Cache Hardening

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE
- Audit inputs:
  - `C:\Users\Casper\Downloads\RxPro_Performans_Mimari_Eksiklik_Raporu_26_Mayis_2026.pdf`
  - `C:\Users\Casper\Downloads\rxpro_mimari_analiz.pdf`
- Changed files:
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/core/app_cache/app_cache_service.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Findings applied:
  - The reports correctly flagged dual state/session risk. `HomeExplorePage` no longer imports or watches `CurrentUserStateService`; it now uses `AppSessionScope` for the visible user context.
  - The reports correctly flagged repeated `SharedPreferences.getInstance()` usage. `AppCacheService` now caches the preferences future and reuses it across cache operations.
- Current status correction:
  - The older PDF claim that tests are zero is stale. The project currently has 15 Dart test files.
  - The large-file budget remains clean after the explore split: `Large files over 30KB: 0`.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
- Next report-backed priorities:
  - Finish AppSession migration away from remaining legacy current-user consumers.
  - Add cursor pagination for large lists.
  - Modularize `functions/index.js`.
  - Add emulator/rules/functions tests.
  - Add media cache/thumbnail strategy before profile/story media volume grows.

---

## 66A - Explore Algorithm Fallback Repair

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / DEVICE_RETEST_REQUIRED
- Changed files:
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/core/businesses/business_directory_cache_service.dart`
  - `lib/core/businesses/business_category.dart`
  - `lib/core/businesses/business_location_data.dart`
  - `test/core/businesses/business_category_test.dart`
  - `test/core/businesses/business_directory_item_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Finding:
  - The explore startup algorithm had a race between the Istanbul starter load and the delayed silent-location refresh.
  - If the location refresh became the newer request and produced an empty result, the starter result could be discarded as stale and the screen could remain empty.
  - The position-based fallback also returned the raw local business list instead of the starter Google Places directory when nearby search produced no items.
- Fix:
  - Initial explore load now completes the starter directory first, then starts silent location refresh.
  - Empty later refreshes no longer erase a non-empty visible list.
  - Position-based empty results fall back to the same starter directory path used by the no-location state.
  - The screen keeps its filters/header/list shell visible while loading and uses a professional non-blocking empty/loading state.
  - Legacy garbled Turkish labels from Places/directory payloads are normalized before display and category matching.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - Run the APK/debug flow on the phone and capture a fresh `tools/explore_freeze_debug.ps1` package if the screen still freezes.

---

## 66B - Explore Radius And Card Semantics Tightening

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / DEVICE_RETEST_REQUIRED
- Changed files:
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_business_cards.dart`
  - `lib/core/businesses/business_directory_cache_service.dart`
  - `lib/core/businesses/google_places_directory_service.dart`
  - `test/core/businesses/business_directory_item_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Finding:
  - Location-based discovery could still fall back to the Istanbul starter directory when no nearby result was found, which made small-radius searches look misleading.
  - Manual location refresh and radius changes did not force distance sorting strongly enough for a location-first discover experience.
  - Explore cards already existed, but the business name and directions action were not visually explicit enough for the intended marketplace behavior.
- Fix:
  - When location is available, nearby discovery now returns the real nearby result set, including empty results, instead of masking it with the starter directory.
  - Pressing `Konum al` and changing radius while a location exists now moves sorting to nearest-first.
  - Force/location refreshes can replace the visible list with an empty list so stale wider-radius results do not remain on screen.
  - Silent automatic location refresh keeps the starter list when it finds no nearby result, preserving a non-empty first screen until the user explicitly requests location/radius filtering.
  - Cards now show the business name in strong uppercase, a clearer proximity label and `Yol tarifi al`.
  - Live Places calls are explicitly limited to the supported imported categories: beauty/care, health/clinic and sport/fitness. Unsupported marketplace categories stay Firestore/member-driven until their Places mapping is added.
  - The Places Cloud Function now fans out `Tümü` searches by supported category group, reducing the chance that one dense category consumes the whole 20-result Google response.
  - Google type classification now recognizes medical/yoga/pilates-style type strings more reliably.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - Run `flutter analyze`, `flutter test` and a device APK test; compare 5 km vs 50 km after tapping `Konum al`.

---

## 66C - Places Query Expansion And Radius Narrowing

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / FUNCTIONS_DEPLOY_REQUIRED
- Changed files:
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/core/businesses/business_directory_cache_service.dart`
  - `lib/core/businesses/google_places_directory_service.dart`
  - `functions/index.js`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Decision:
  - A single Nearby Search (New) call cannot exceed 20 results, so RxPro now expands discovery through controlled type-level fan-out rather than trying to enlarge one Google call.
- Fix:
  - Default explore radius is now 10 km.
  - Radius slider is capped at 50 km.
  - Client requests up to 80 merged results.
  - Cloud Function accepts a larger overall limit and `maxSearchCalls` budget.
  - Cloud Function queries individual supported place types in parallel, deduplicates by place id, sorts by distance and caps the final response.
  - `Tümü` interleaves beauty/care, health/clinic and sport/fitness type searches so results are more balanced.
  - Places timeout guards are now 12 seconds.
- Policy guard:
  - Google Places content is not treated as a permanent import database. Long-term RxPro records should be owned/claimed business data; Google directory records should use `placeId` as the durable key with short-lived display/query caches.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Next action:
  - Deploy `searchNearbyDirectoryBusinesses`, then run the health check and compare 5 km/10 km/50 km on a real device.

---

## 66D - District Discovery Index And Query Gate

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / FUNCTIONS_AND_RULES_DEPLOY_REQUIRED / LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `functions/index.js`
  - `infra/rules/firestore.rules`
  - `lib/core/businesses/business_directory_cache_service.dart`
  - `lib/core/firestore/firestore_collections.dart`
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/features/public_home/domain/home_explore_location_policy.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_filter_widgets.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_business_cards.dart`
  - `test/core/businesses/business_directory_item_test.dart`
  - `test/features/public_home/domain/home_explore_location_policy_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Decision:
  - RxPro should not call Google as if every discover request is cold. Live Places results now become a server-owned district/category/radius discovery index, while claimed/member businesses remain the authoritative marketplace records.
- Fix:
  - Added `businessPlaceIndex` for cached Google directory cards with `placeId`, name, category, address, city, district, coordinates, geohash prefixes, rating and route URL fields.
  - Added `placeQueryBuckets` query metadata with district/category/radius, center coordinate, result count and place ids.
  - Nearby discovery now merges member businesses, cached directory businesses and fresh Google results, deduplicating by `placeId` and preferring RxPro member records.
  - If the local district/category index already has enough nearby records, the app returns that database result without opening another Google live request.
  - Firestore rules make the directory index and query buckets public-readable but not client-writable.
  - Pressing `Konum al` inside the same 1 km movement window keeps the existing list instead of making another live Places query.
  - The app fetches a wider 50 km live package for a new location, while the slider locally filters the already loaded result set to 1-50 km.
  - Explore search/category controls and location-query policy were split out so the public home page remains below the 30 KB file budget.
  - Directory-only cards now present uppercase name, category/location/proximity text and a prominent `Yol tarifi al` button.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `node --check functions/index.js`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - Deploy `firebase deploy --only functions:searchNearbyDirectoryBusinesses,firestore:rules`.
  - Run `flutter analyze`, `flutter test`, rebuild APK and verify `Konum al`, 5 km/10 km/50 km filtering, category filtering and `Yol tarifi al` on device.

---

## 66E - UI Design System First Pass

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED
- Reviewed input:
  - `RxPro_Modern_Arayuz_Tasarim_Kilavuzu.pdf`
  - `rxpro_ui_tasarim_sistemi.pdf`
  - `RxPro_Modern_Kullanisli_Arayuz_Tasarim_Calismasi_26_Mayis_2026.pdf`
- Shared conclusion:
  - The strongest common recommendation is not a cosmetic redesign; it is a role-based UI system with shared components, semantic status colors, skeleton loading, counted filters and simpler high-traffic screens.
- Changed files:
  - `lib/core/theme/rx_ui.dart`
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/features/public_home/domain/home_explore_category_counts.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_filter_widgets.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_shell_widgets.dart`
  - `test/features/public_home/domain/home_explore_category_counts_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Added semantic UI tones: success, warning, danger and premium.
  - Added shared UI primitives: `RxSectionHeader`, `RxStatusChip`, `RxEmptyState` and `RxSkeletonCard`.
  - Changed Explore empty/error state to use the shared empty-state standard.
  - Added count badges to Explore category chips.
  - Added skeleton cards for first Explore load.
  - Extracted category count computation into a domain helper to keep `HomeExplorePage` below the large-file threshold.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - `flutter analyze` and `flutter test`; targeted `dart analyze` timed out in this environment.

---

## 66F - Explore Category Visual Identity

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `lib/features/public_home/presentation/models/home_explore_category_style.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_business_cards.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_filter_widgets.dart`
  - `test/features/public_home/presentation/home_explore_category_style_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Added stable category visual identities for Explore cards and chips.
  - Beauty/care uses soft pink, health/clinic uses clean white with green medical accents, sport/fitness uses light blue, consulting uses premium purple, organization uses amber and education uses indigo.
  - Member cards now keep richer profile actions while adopting category background, border and accent colors.
  - Directory-only cards inherit category identity but remain route-first with `Yol tarifi al`.
  - Category chips now show matching icons and count badges.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - `flutter analyze` and `flutter test`.

---

## 66G - Corporate Owner Overview Panel

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `lib/features/public_home/domain/account_owner_overview_model.dart`
  - `lib/features/public_home/presentation/widgets/account_owner_overview_panel.dart`
  - `lib/features/public_home/presentation/widgets/account_entry_menu.dart`
  - `test/features/public_home/domain/account_owner_overview_model_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Added a corporate owner summary panel above the legacy accordion-heavy account menu.
  - Added a 2x2 operating grid for appointments, customer messaging, campaigns and profile completion.
  - Added fast actions for appointment management, bulk messaging and finance/operations.
  - Added a testable overview model for profile completion percentage and active/review status.
  - Connected the panel to existing business module routing without changing route contracts.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - `flutter analyze` and `flutter test`.

---

## 66H - Messaging UI Role-Aware Modernization

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `lib/features/messages/domain/message_ui_policy.dart`
  - `lib/features/messages/presentation/widgets/messages_ui_widgets.dart`
  - `lib/features/messages/messages_inbox_page.dart`
  - `test/features/messages/domain/message_ui_policy_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Added a reusable `MessageUiPolicy` for topic/status labels, role-specific hints, empty-state copy and read receipt text.
  - Added shared messaging UI widgets for inbox header, skeleton loading, thread context, closed conversation notice and fixed input bar.
  - Updated the inbox so corporate users and individual users see distinct, role-correct wording and actions.
  - Reworked thread cards with unread indicators, topic/status chips and cleaner text hierarchy.
  - Reworked the conversation screen with a role-aware context panel and modern message bubbles.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
  - Targeted `flutter test test/features/messages/domain/message_ui_policy_test.dart` timed out in this environment.
- Local retest required:
  - `flutter analyze` and `flutter test`.

---

## 66I - Campaign AI UTF-8 Response Hardening

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `lib/features/campaigns/domain/campaign_ai_response_decoder.dart`
  - `lib/features/campaigns/campaign_service.dart`
  - `test/features/campaigns/domain/campaign_ai_response_decoder_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Campaign AI HTTP responses are now decoded from raw UTF-8 bytes before JSON parsing.
  - Campaign AI request bodies are sent as explicit UTF-8 bytes.
  - This protects Turkish campaign copy from charset-related corruption in title/body/CTA fields.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
  - Source scan found no literal mojibake markers.
- Local retest required:
  - `flutter analyze` and `flutter test`.

---

## 66J - Customer Ledger Direct Message Integration

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `lib/features/businesses/domain/business_customer_action_policy.dart`
  - `lib/features/businesses/presentation/widgets/business_customer_widgets.dart`
  - `lib/features/businesses/business_customers_page.dart`
  - `lib/features/businesses/data/business_customer_message_repository.dart`
  - `lib/features/messages/data/messages_repository.dart`
  - `test/features/businesses/domain/business_customer_action_policy_test.dart`
  - `test/features/messages/data/messages_repository_models_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Customer cards now expose a one-to-one `Mesaj` action only for records linked to an individual user account.
  - Manual CRM customers remain available for classification and bulk messaging without presenting an unavailable DM workflow.
  - Bulk message drafts created from customer segments now carry linked-customer count metadata.
  - Business-to-customer message writes now include sender uid/name, unread flags, topic/status and read receipt fields expected by the modern messages inbox.
  - Message model parsing now normalizes Firestore timestamps into sortable ISO text with local ISO fallback support.
  - Customer card metric and segment badge UI was extracted to keep the customer page under the large-file threshold.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
  - Source scan found no literal mojibake markers.
- Local retest required:
  - `flutter analyze` and `flutter test`.

---

## 66K - Bulk Message Draft Visibility

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `lib/features/campaigns/campaign_models.dart`
  - `lib/features/campaigns/campaign_repository.dart`
  - `lib/features/campaigns/business_campaigns_page.dart`
  - `test/features/campaigns/campaign_models_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Business campaign management now reads both business campaigns and bulk message drafts.
  - Customer campaign discovery remains protected from bulk message drafts.
  - Bulk message draft cards are normalized as `Toplu mesaj` with target/channel metadata.
  - Added test coverage for business-only bulk draft visibility.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - `flutter analyze` and `flutter test`.

---

## 66L - Bulk Message Dispatch Foundation

- Status: FUNCTION_SYNTAX_PASS / LOCAL_FLUTTER_RETEST_REQUIRED / DEPLOY_REQUIRED
- Changed files:
  - `functions/index.js`
  - `lib/features/campaigns/campaign_models.dart`
  - `lib/features/campaigns/campaign_service.dart`
  - `lib/features/campaigns/business_campaigns_page.dart`
  - `lib/features/notifications/data/customer_notification_repository.dart`
  - `lib/features/notifications/customer_notifications_page.dart`
  - `lib/features/businesses/data/business_customer_repository.dart`
  - `lib/features/businesses/business_customers_page.dart`
  - `test/features/campaigns/campaign_models_test.dart`
  - `test/features/businesses/data/business_customer_repository_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Bulk message drafts can now be sent through a callable Cloud Function.
  - Delivery is owner-authorized, segment-aware and consent-gated.
  - Eligible linked customers receive `bulkMessage` app notifications.
  - Business campaign detail sheets expose a send action for ready bulk-message drafts.
  - Campaign management refreshes after draft creation and bulk delivery.
  - Customer notification screens no longer hide bulk-message notifications.
  - Manual customer/classification forms now store explicit campaign/bulk-message consent fields.
  - Removed an unreachable mojibake fallback block from the campaign Cloud Function path.
- Verification:
  - `node --check functions/index.js`: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - `flutter analyze` and `flutter test`.
- Deploy required:
  - `firebase deploy --only functions:sendBulkMessageDraft`.

---

## 66M - Bulk Message Production Hardening

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED / DEPLOY_REQUIRED
- Changed files:
  - `functions/index.js`
  - `lib/features/campaigns/campaign_models.dart`
  - `lib/features/campaigns/business_campaigns_page.dart`
  - `test/features/campaigns/campaign_models_test.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Bulk send now uses an atomic claim step to prevent duplicate sending from concurrent taps.
  - Callable responses include `attemptId`, `alreadySent` and `alreadySending`.
  - Notifications use deterministic ids per draft/customer pair, preventing duplicate notifications on retry.
  - Each send attempt writes an audit record to `bulkMessageSendLogs`.
  - Interrupted sends move to `send_failed` and become retryable instead of remaining stuck in `sending`.
  - Business campaign UI treats `send_failed` bulk drafts as retryable and labels them as `Hata`.
  - Bulk-message cards/details show delivery summaries.
  - Campaign item view-model parsing moved into the campaign domain layer to preserve the large-file budget.
- Verification:
  - `node --check functions/index.js`: PASS.
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - `flutter analyze` and `flutter test`.
- Deploy required:
  - `firebase deploy --only functions:sendBulkMessageDraft`.

---

## 66N - Explore Route Distance Clarity

- Status: FUNCTION_SYNTAX_PASS / LOCAL_FLUTTER_RETEST_REQUIRED / DEPLOY_REQUIRED
- Changed files:
  - `functions/index.js`
  - `lib/core/businesses/business_route_distance_service.dart`
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_business_cards.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_route_distance_chip.dart`
  - `test/core/businesses/business_route_distance_service_test.dart`
  - `tools/check_route_function.ps1`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Added `calculateBusinessRouteInfo` to call Google Routes `computeRoutes` for real driving route distance and duration.
  - Added a Flutter route-distance service with short-lived cache.
  - Explore cards now distinguish `Yaklaşık ... yakınında` straight-line proximity from `Araçla ... · ...` route guidance.
  - Route preview is limited to the first visible cards so the app does not run a paid route request for every listed business at once.
  - Radius filtering and nearest sorting continue to use fast coordinate distance; route distance is shown as user guidance.
  - Added a PowerShell check script for route function health-check and live sample validation.
- Verification:
  - `node --check functions/index.js`: PASS.
- Local retest required:
  - `flutter analyze` and `flutter test`.
- Deploy required:
  - `firebase deploy --only functions:calculateBusinessRouteInfo`.
- Cloud requirement:
  - Enable Google Routes API for the same project/key before live route distances can return.

---

## 66O - Login Brand Banner and Explore Header Refresh

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `assets/images/fix_login_hero_banner.png`
  - `lib/features/auth/presentation/widgets/fix_login_brand.dart`
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_shell_widgets.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - The supplied Fix artwork is now used on the login screen as a compact brand banner.
  - Explore no longer receives a large marketing image above the list.
  - Explore header now uses a verified Fix wordmark, user avatar circle, greeting/name and trailing message/notification actions.
  - Header UI pieces were extracted to shared widgets so `home_explore_page.dart` stays below the large-file budget.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - `flutter analyze` and `flutter test`.

---

## 66P - Explore Control Panel Modernization

- Status: LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_filter_widgets.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Replaced the old slider/dropdown form panel with a compact mobile control panel.
  - Location status now has a visual icon block and a tonal `Konum al` action.
  - Radius uses a stable `km` badge plus slider.
  - Sort mode moved to horizontal chips: `Akıllı`, `Yakın`, `Puan`, `Kategori`, `A-Z`.
  - Control UI is extracted into `HomeExploreControlPanel`, keeping `home_explore_page.dart` below the large-file limit.
- Local retest required:
  - `flutter analyze` and `flutter test`.

---

## 66Q - Login Form Componentization

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `lib/features/auth/presentation/pages/fix_login_gate_page.dart`
  - `lib/features/auth/presentation/widgets/fix_login_form_widgets.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Login role/action tabs, remember-password tile, login panel, flow info and inputs were extracted into reusable widgets.
  - Login form controls now use icon-backed segmented buttons and shared modern input styling.
  - Active visible Turkish copy in the login form path was cleaned.
  - `fix_login_gate_page.dart` dropped from roughly 29 KB to roughly 22 KB.
- Local retest required:
  - `flutter analyze` and `flutter test`.

---

## 66R - Test Regression Fixes

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `lib/core/businesses/business_category.dart`
  - `lib/features/messages/data/messages_repository.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Rebuilt business category labels and keywords with clean Turkish strings.
  - Category normalization now handles both clean Turkish text and legacy mojibake payloads.
  - Firestore `Timestamp` and epoch values in message repository models now normalize to UTC ISO strings.
  - Local ISO fallback strings remain local, preserving existing thread fallback behavior.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - `flutter test`.
- Note:
  - Targeted Flutter test execution timed out in this Codex environment before returning test output.

---

## 66S - UI Action System and Corporate Flow Cleanup

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `lib/features/public_home/home_explore_page.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_filter_widgets.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_business_cards.dart`
  - `lib/features/public_home/presentation/widgets/account_entry_cards.dart`
  - `lib/features/public_home/presentation/widgets/account_entry_menu.dart`
  - `lib/features/public_home/presentation/pages/account_entry_page.dart`
  - `lib/features/businesses/business_owner_hub_page.dart`
  - `lib/features/businesses/business_customers_page.dart`
  - `lib/features/businesses/presentation/widgets/business_customer_header_panel.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
- Fix:
  - Explore now keeps location sorting as a primary visible action instead of hiding it inside the horizontal chip rail.
  - Directory-only Explore cards now show approximate distance as a separate chip, so users can see how many km away the business is.
  - Account screen gained a corporate command panel for the main owner tasks: appointments, customers, bulk message, messages, profile and operations.
  - Business owner hub now opens as a modern Fix business center with quick action cards and grouped management sections.
  - Customer ledger header actions were modernized and extracted to keep the page below the large-file threshold.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - `flutter analyze` and `flutter test`.
- Note:
  - `dart format` and Flutter-family commands timed out in this Codex environment, so final formatting/analyze should be verified on the user's PowerShell.

---

## 66T - Remaining Action Wiring and Settings Cleanup

- Status: PASS_SKIP_FLUTTER_CI / PASS_FEATURE_ARCHITECTURE / LOCAL_FLUTTER_RETEST_REQUIRED
- Changed files:
  - `lib/features/public_home/presentation/pages/account_entry_page.dart`
  - `lib/features/public_home/presentation/pages/account_entry_lite_pages.dart`
  - `lib/features/public_home/presentation/widgets/account_entry_menu.dart`
  - `lib/features/public_home/presentation/widgets/home_explore_route_distance_chip.dart`
  - `lib/features/businesses/staff_workspace_page.dart`
  - `lib/features/businesses/business_products_page.dart`
  - `lib/features/businesses/presentation/widgets/business_stock_ledger_list.dart`
  - `docs/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_patch_ledger.md`
  - `docs/project_index/rxpro_remaining_gaps.md`
- Fix:
  - Account `Devamlılık` now opens the live customer ledger instead of a future placeholder.
  - Account `Tanıtım / Paylaşım İçerikleri` now opens story creation through the business module router.
  - Lightweight app settings are now backed by local persisted preferences.
  - Explore route-distance chips respect the user's route-distance setting before calling the route service.
  - Staff quick actions now open campaign/story and finance screens when the staff permission allows them.
  - Product stock overview now includes a real stock ledger from current product records instead of a future-package placeholder.
  - Stock ledger UI is extracted to keep `business_products_page.dart` below the 30 KB large-file threshold.
- Verification:
  - `tools/ci_quality_check.ps1 -SkipFlutter -SkipBuild`: PASS.
  - `tools/feature_architecture_report.ps1`: PASS.
  - `Large files over 30KB`: 0.
- Local retest required:
  - `flutter analyze` and `flutter test`.
