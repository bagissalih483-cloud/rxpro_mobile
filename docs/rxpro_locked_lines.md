

## 57Y_TEST_BACKLOG_NOTE

- This is not a locked source-code line.
- It is a process lock: future high-risk migrations should be protected by small unit tests where practical.
- No production rules/index/functions deploy is included.
- Notification/push/FCM, messages/chat, appointment core, finance core and staff_workspace remain high-risk and must not be blindly patched.


## 58B - Test Process Lock
- Pure policy unit test foundation is locked if targeted tests PASS.
- Do not change production behavior to satisfy tests without an exact audit.
- Unit tests may be run between repository/service migrations; integration tests are reserved for later release readiness.

## 58G - Messaging/Chat Strategy Process Lock
- Messages/chat remains high-risk and must not be blindly patched.
- Any future messaging provider migration requires exact audit first.
- UI should remain insulated behind ChatRepository/MessagingService/provider boundary.
- Firestore chat cost must be evaluated by active chat usage, listener design, unread counters, mirror writes, and notification coupling.

## 58I Lock - BusinessProfile current-user stream
- Locked line: BusinessProfilePage _currentUserDocStream() must stay repository-backed.
- Do not reintroduce direct FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(uid).snapshots() in the page helper.
- Reviews/rating, follow, appointment core and messaging/chat remain separate high-risk subflows.

## 58I REV1 lock - BusinessProfile current-user stream
- Locked: BusinessProfilePage _currentUserDocStream() repository wiring.
- Do not combine reviews/rating/follow/appointment/messaging changes with this line.

## 58I REV8 Lock - BusinessProfile current-user stream
- Locked: _currentUserDocStream uses BusinessProfileRepository.watchCurrentUserDocument.
- Do not combine this line with reviews/rating/follow/appointment/messaging migrations.

## 64Q - High-Traffic UI Service Boundary Lock
- High-traffic UI/root Firebase access for appointments, messages, staff, account, main shell and business profile review/follow flows moved behind repositories/services.
- Direct Firebase surface outside repository/service/domain paths is now 8 files.
- Remaining direct files are service/core infrastructure surfaces.

## 64R - Architecture Check Lock
- `tools/architecture_check.ps1` is the executable architecture budget.
- `tools/quality_check.ps1` must keep running it.
- Target architecture and working algorithm docs are locked under `docs/project_index/`.

## 64S - Professional Audit Lock
- Current professional audit is `docs/project_index/rxpro_professional_audit_20260526.md`.
- Do not do a mass folder rewrite before quality/build, rules tests, release identifiers and backend safety gates are stable.

## 64T - Staff Workspace Completion Build Lock
- `StaffWorkspaceRepository.completeAppointment()` keeps `workDurationMinutes` nullable.
- Duration fields are written only when a valid duration is calculated.

## 64U - Analyze Cleanup Lock
- Keep deprecated Flutter API cleanup intact: `withValues(alpha:)`, `initialValue`, `LocationSettings`, and `activeThumbColor`.
- Legacy high-risk helper blocks are not deleted until covered by focused tests.

## 64V - CI Quality Gate Lock
- The clean analyze baseline is locked.
- Keep `tools/ci_quality_check.ps1` as the shared local/CI quality gate.
- Keep `.github/workflows/flutter_quality.yml` wired to the quality gate.
- Do not treat the app as production-ready until a committed checkout passes CI and release identifiers/signing/Firebase/rules items are complete.

## 64W - App Observability Lock
- Keep root-zone and Flutter/platform error capture wired before `runApp`.
- Route new Crashlytics/Analytics work through `AppObservabilityService`.
- Validate Crashlytics on a real release build before production.

## 64X - Text Encoding Cleanup Lock
- Keep campaign/business analysis AI calls on clean prompt builders.
- Keep password reset visible text clean.
- Keep accounting callable/validator errors clean.
- Continue mojibake cleanup in narrow feature slices.

## 64Y - Feature Architecture Slice Lock
- Track feature boundaries with `tools/feature_architecture_report.ps1`.
- Keep password reset page under auth presentation/pages.
- Keep compatibility export until imports are migrated safely.

## 64Z - Local Tooling Compatibility Lock
- Architecture and mojibake scan tools must support Windows environments without `rg`.
- Keep observability import list clean so analyze remains at zero issues.

## 65A - Auth Presentation Split Lock
- Keep login gate page under auth presentation/pages.
- Keep old auth login gate path as a compatibility export.
- Keep auth large-file count at 0 above 30KB.

## 65B - Public Home Account Entry Split Lock
- Keep account entry page under public_home presentation/pages.
- Keep old public_home account entry path as a compatibility export.
- Keep account entry cards/menu/context split across presentation widgets/models.
- Preserve scoped session business id/category resolution.
- Keep public_home large-file count at 0 above 30KB.

## 65C - Business Analysis Presentation Split Lock
- Keep business analysis page under presentation/pages.
- Keep product movement page under business_analysis presentation/pages.
- Keep old business analysis page path as a compatibility export.
- Keep analysis widgets/models under presentation.
- Keep Cloud Functions AI access in `BusinessAnalysisAiService`.
- Keep period filtering and analysis computation in `BusinessAnalysisComputationService`.
- Keep business_analysis large-file count at 0 above 30KB.

## 65D - Appointments Presentation Split Lock
- Keep appointment entry and customer appointments pages under appointments presentation/pages.
- Keep old appointment root page paths as compatibility exports.
- Keep dashboard views/models and customer appointment UI widgets under appointments presentation.
- Keep appointments large-file count at 0 above 30KB.
- Keep business analysis computation behavior covered by pure tests.

## 65E - Business Finance Presentation Split Lock
- Keep business finance page under businesses presentation/pages.
- Keep old business finance root path as a compatibility export.
- Keep finance widgets/models/formatters under businesses presentation.
- Keep finance formatter behavior covered by pure tests.

## 65F - Business Staff Management Split Lock
- Keep staff management page under businesses presentation/pages.
- Keep staff form page separate from the staff list page.
- Keep old staff management root path as a compatibility export.
- Keep staff group/card UI widgets under businesses presentation.
- Do not change staff permission payload, service matching or invite code generation during presentation-only splits.

## 65G - Accounting Sales Presentation Split Lock
- Keep accounting sales page under accounting presentation/pages.
- Keep old accounting sales page path as a compatibility export.
- Keep sales wizard widgets and lightweight models under accounting presentation.
- Keep accounting sales draft validation behind `AccountingDraftValidator`.

## 65H - Location Discovery Lock
- Keep business location parsing in `lib/core/businesses/business_location_data.dart`.
- Keep directions launching in `lib/core/businesses/business_directions_service.dart`.
- Keep explore business cards under public_home presentation widgets.
- Treat Google/imported directory records as directory-only unless member/claimed/owner signals exist.
- Keep directory-only cards compact and directions-focused.
- Persist both scalar coordinates and `location` GeoPoint from business profile edit.

## 65I - Location Geo Index Lock
- Keep geohash encoding and nearby-prefix logic in `lib/core/businesses/business_geo_index.dart`.
- Persist `geoHash`, `geoHash4`, `geoHash5`, `geoHash6` and `geoHash7` on business location writes.
- Explore discovery should use the geohash-indexed nearby query when user location exists.
- Keep the broad cache fallback until old/imported records are backfilled.
- Radius changes should refresh the indexed query when current user location exists.
- Keep `functions/scripts/backfillBusinessGeoIndex.js` dry-run-first; production writes require explicit `--write`.
- Add Firestore index configuration and emulator coverage before marking geo discovery production complete.

## 65J - Business Appointment Management Split Lock
- Keep `business_appointment_management_page.dart` below the 30KB large-file budget.
- Keep customer direct-message UI under businesses presentation/pages.
- Keep appointment summary, status pill, customer info row and quick customer profile sheet under businesses presentation/widgets.
- Do not change cancel/postpone/conflict/repository behavior during presentation-only splits unless tests are added first.
