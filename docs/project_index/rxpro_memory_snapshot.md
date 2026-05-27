# RxPro Memory Snapshot

Generated: 20260525_000624

## Project Paths

- Active project: C:\Users\Casper\Desktop\rxpro_mobile
- Heavy audit/log/zip outputs: C:\Users\Casper\Desktop\RxPro_Audit_Packages
- Lightweight project memory/index: docs/project_index

## Operating Rule

- No blind patches.
- First read/check docs/project_index.
- Exact audit â†’ small patch â†’ build â†’ final lock audit â†’ update project index.
- Patch files should be downloadable .ps1.
- Scripts should use dart format, non-blocking lutter analyze, and lutter build apk --release.
- Analyze issues must not stop build unless they are actual build errors.
- Successful build marker: === APK OLUSTU - KURMAYA HAZIR ===.
- APK install/open command must remain separate.
- Do not deploy production Firestore rules/index/functions unless explicitly requested.

## Do Not Blindly Patch

- notification / push / FCM
- messages / chat
- appointment core
- finance core
- staff_workspace
- BusinessAppointmentManagementPage
- MessagesInboxPage
- locked lines in xpro_locked_lines.md

## Current Locked Lines Summary

- 54U RegisteredBusinesses repository migration.
- 55A BusinessStaffManage read-stream repository wiring.
- 55D BusinessStaffManage access-code repository wiring.
- 55G BusinessStaffManage delete-flow repository wiring.
- 55M/55N StaffFormPage save-flow repository wiring.
- 56G BusinessProfile reviews read-stream repository wiring.
- 56H Project Index update for BusinessProfile reviews lock.

## Project Index Foundation

56A created the permanent project index system under docs/project_index:

- xpro_architecture_direction.md
- xpro_code_index.md
- xpro_service_repository_map.md
- xpro_firestore_dictionary.md
- xpro_locked_lines.md
- xpro_patch_ledger.md
- xpro_risk_map.md
- xpro_project_index.json
- xpro_memory_snapshot.md

Heavy audit packages and before/after source snapshots stay outside the project in RxPro_Audit_Packages.

## Latest Confirmed State

### 56O BusinessProfileEditEntry Resolver Wiring Anchor Audit

Status: build successful.

- Repository foundation recheck: PASS.
- BusinessProfileEditEntryResolverRepository exists.
- Repository helper present: esolveOwnedBusinessId.
- Page still not wired yet.
- _loadOwnedBusiness method boundary found.
- _queryBusinessIdByField method boundary found.
- _matchesUser and _clean boundaries found.
- _loadOwnedBusiness contains Auth/state/navigation decisions.
- Recommendation: 56P resolver wiring patch.

56O recommended next step:

56P BusinessProfileEditEntry resolver wiring patch

Scope for 56P:

- Wire _loadOwnedBusiness to BusinessProfileEditEntryResolverRepository.resolveOwnedBusinessId.
- Keep UI state and navigation in the page.
- Do not remove old helper methods in the same patch.
- Do not touch BusinessProfileEditPage save/storage.
- Do not touch PostInteraction, FavoriteFeed, BusinessProfile reviews locked lines.
- Do not touch notification/push, rules/index/functions.

## New Chat Continuation Rule

In a new chat, upload or paste this file plus the docs/project_index zip if available. Start by reading this snapshot and then checking xpro_locked_lines.md, xpro_patch_ledger.md, and xpro_project_index.json.

## Suggested New Chat Starter

Fix/RxPro projesine kaldÄ±ÄŸÄ±mÄ±z yerden devam ediyoruz.

Aktif proje:
C:\Users\Casper\Desktop\rxpro_mobile

AÄŸÄ±r audit/log/zip Ã§Ä±ktÄ±larÄ±:
C:\Users\Casper\Desktop\RxPro_Audit_Packages

Proje hafÄ±zasÄ±:
docs/project_index. Bu sohbete project_index zipini veya xpro_memory_snapshot.md dosyasÄ±nÄ± ekledim. Ã–nce bunu oku, sonra xpro_locked_lines.md, xpro_patch_ledger.md ve xpro_project_index.json ile kontrol et.

Ã‡alÄ±ÅŸma prensibi:
KÃ¶r patch yok. Exact audit â†’ kÃ¼Ã§Ã¼k patch â†’ build â†’ final lock audit â†’ project_index update. Patchler indirilebilir .ps1 olacak. Analyze build'i durdurmayacak. Production rules/index/functions deploy yok. Notification/push/FCM, messages/chat, appointment core, finance core, staff_workspace ve locked lines kÃ¶r patchlenmeyecek.

Son aktif durum:
56O build baÅŸarÄ±lÄ±. SÄ±radaki gÃ¼venli adÄ±m 56P BusinessProfileEditEntry resolver wiring patch: _loadOwnedBusiness repository resolver hattÄ±na baÄŸlanacak; UI state/navigation sayfada kalacak; helper cleanup aynÄ± patch iÃ§inde yapÄ±lmayacak.

Devam etmeden Ã¶nce snapshot ve project_index dosyalarÄ±nÄ± Ã¶zetle, sonra 56P iÃ§in gÃ¼venli patch hazÄ±rla.

## Latest lock: 59K REV1 / 59L documentation update (20260525_165418)

59A-59K analyze cleanup block is locked by a passing debug APK build. Current known analyzer baseline after 59K REV1: error=0, warning=51, info=107, total=158. 59J batch cleanup removed 9 unused imports; 59K REV1 produced APK at $ApkPath. Continue with controlled low-risk analyze debt cleanup, preferably batched, while avoiding protected domains: notification/push/FCM, messages/chat, appointment core, finance core, staff_workspace, Firestore rules/index/functions.


## 59O Project Index Update After 59N Build Lock (2026-05-25 16:59:49)
- Baseline locked after 59M batch unused import cleanup and 59N build lock.
- 59M removed 8 analyzer-confirmed unused imports outside protected domains.
- 59N build lock passed: lutter build apk --debug exit code 0; APK found at uild\app\outputs\flutter-apk\app-debug.apk.
- Current analyze baseline after 59N: 0 error / 43 warning / 107 info / 150 total.
- Source code was not changed in 59N or 59O; 59O updates only docs/project_index records.
- Production Firestore rules/index/functions deploy: not performed.
- Protected domains remain locked unless exact audit is performed first: Notification/push/FCM, messages/chat, appointment core, finance core, staff_workspace, Firestore rules/index/functions.
- Recommended next step: 59P classify remaining 43 warnings and select only non-protected safe cleanup targets; avoid appointment/notification/messages/finance/staff_workspace unless separately audited.
### 59R lock note - after 59Q build lock (2026-05-25 17:06:32)

Current stable baseline after analyze cleanup block:
- Last successful build lock: 59Q_BUILD_LOCK_AFTER_59P
- Build: PASS
- APK: build\app\outputs\flutter-apk\app-debug.apk
- Analyze: 0 error / 38 warning / 107 info / 145 total
- Total issue reduction from 59A: 179 -> 145 (-34)
- Production deploy: NO
- Source code changed by 59R: NO

Continuation:
- Prefer a classification audit for the remaining 38 warnings before broad cleanup.
- Keep protected domains locked unless exact file/function audit is performed first.

## Latest lock baseline

- Last updated: 20260525_171742
- Current stage: 59V after 59U build lock
- Last passing build lock: 59U_BUILD_LOCK_AFTER_59T
- Analyze baseline: 0 error / 35 warning / 107 info / 142 total
- APK build passed; app-debug.apk was produced.
- 59A to 59U cleanup reduced analyze total from 179 to 142.
- Continue with exact audit -> small controlled patch -> build lock -> project_index update.
- Do not blind-patch protected domains: Notification/push/FCM, messages/chat, appointment core, finance core, staff_workspace, Firestore rules/index/functions.

### 59Z Snapshot - after 59Y build lock
- Current locked analyze baseline: 0 error / 32 warning / 107 info / 139 total.
- 59Y build lock passed; debug APK was produced.
- 59A -> 59Y reduced analyze issues from 179 to 139 while keeping build green.
- Continue with exact audit before touching protected domains: appointment(s), notifications, messages/chat, finance core, staff_workspace, Firestore rules/index/functions.
- Recommended next step: classify remaining 32 warnings and only patch non-protected, behavior-neutral unused/dead-code candidates; keep deprecated/info cleanup staged separately.

### 60D lock snapshot - 20260525_174728

Current safe baseline:
- Last build lock: 60C_BUILD_LOCK_AFTER_60B_REV5
- Build status: PASS
- Analyze: 0 error / 30 warning / 107 info / 137 total
- Total reduction since 59A: 42 issues
- Source code changed in 60D: NO
- Production deploy: NO

Important continuation rule:
- Do not blindly edit protected domains.
- Remaining warnings include protected-domain candidates; use exact audit first for appointment/notification/staff_workspace items.
- Info/deprecated cleanup should be handled after warnings, file by file, because UI behavior can be affected.


---

## Current lock snapshot after 60I / 60J

- 60I build lock after 60H_REV6 passed.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- Current analyze baseline is 0 error / 24 warning / 107 info / 131 total.
- 60H_REV6 cleaned 9 protected-outside unused private declarations.
- Analyze cleanup should be parked if it slows the main product checklist.
- Continue with exact audit -> controlled patch -> build lock -> project_index update.

---

## Current lock snapshot after 61D / 61E

- 61D build lock after 61C CampaignRepository foundation passed.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- Current analyze baseline remains 0 error / 24 warning / 107 info / 131 total.
- Campaign architecture foundation exists:
  - lib\features\campaigns\campaign_models.dart
  - lib\features\campaigns\campaign_repository.dart
- UI pages are not wired yet.
- Next safe step: 61F exact audit for the lowest-risk campaigns page to wire into CampaignRepository.

---

## Current lock snapshot after 61H / 61I

- 61H build lock after 61G customer campaign repository wiring passed.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- Campaigns repository foundation exists:
  - lib\features\campaigns\campaign_models.dart
  - lib\features\campaigns\campaign_repository.dart
- customer_campaigns_page.dart read/list path is wired to CampaignRepository.
- Direct FirebaseFirestore/cloud_firestore was removed from customer_campaigns_page.dart.
- 61G repair required exact excerpt audit; future patches must avoid guessed anchors.
- Recommended next: 61J exact audit of business campaign page/composer before any further wiring.

---

## Current lock snapshot after 61L / 61M

- 61L build lock after 61K business campaign read/list repository wiring passed.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- business_campaigns_page.dart _load() now uses CampaignRepository.listBusinessCampaigns().
- _unpublish() direct Firestore path remains intentionally untouched.
- _BusinessCampaignItem.fromDoc is now unused and should not be removed blindly until _unpublish/legacy parse path is audited.
- Recommended next: 61N exact audit of business_campaigns_page _unpublish()/legacy parser before any further patch.

---

## Current lock snapshot after 61P / 61Q

- 61P build lock after 61O business campaigns unpublish repository wiring passed.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- Campaigns repository foundation exists:
  - lib\features\campaigns\campaign_models.dart
  - lib\features\campaigns\campaign_repository.dart
- customer_campaigns_page.dart read/list path is wired to CampaignRepository.
- business_campaigns_page.dart _load() and _unpublish() are wired to CampaignRepository.
- Direct FirebaseFirestore/cloud_firestore was removed from customer_campaigns_page.dart and business_campaigns_page.dart.
- Recommended next: 61R exact audit of campaign_ai_create_safe_page.dart, or 62A broader checklist audit.

---

## Current lock snapshot after 61T / 61U

- 61T build lock after 61S campaign AI business-context repository wiring passed.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- campaign_ai_create_safe_page.dart _resolveBusinessContext() now uses CampaignRepository.
- _publishCampaign() and AI HTTP/FirebaseAuth token flow remain intentionally untouched.
- Campaigns repository migration has covered customer read, business read, business unpublish, and AI page business-context resolve.
- Recommended next: 62A broader checklist next safe candidate audit, unless campaign publish exact audit is explicitly desired.

---

## Current lock snapshot after 62E / 62F

- 62E build lock after 62D business owner hub resolve repository wiring passed.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- business_owner_hub_page.dart _resolveBusiness() now uses RegisteredBusinessGatewayRepository.
- Direct cloud_firestore/firebase_auth references were removed from business_owner_hub_page.dart.
- RegisteredBusinessGatewayRepository now owns owner-hub business resolution.
- Remaining isolated warning: unused _nameOf in business_owner_hub_page.dart.
- Recommended next: 62G tiny cleanup of unused _nameOf, then build lock or continue businesses exact audit.

---

## Current lock snapshot after 62H / 62I

- 62H build lock after 62G_REV4 owner hub State.build restore passed.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- business_owner_hub_page.dart _resolveBusiness() is repository-based.
- State.build is restored inside _BusinessOwnerHubPageState.
- _nameOf is removed.
- direct cloud_firestore/firebase_auth references are removed from business_owner_hub_page.dart.
- RegisteredBusinessGatewayRepository now owns owner-hub resolve and current-user guard.
- Target analyze for owner hub/repository is clean.
- Recommended next: 62J businesses next safe candidate exact audit only.

---

## Current lock snapshot after 62M / 62N

- 62M build lock after 62L business category save repository wiring passed.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- business_category_required_page.dart _save() now uses RegisteredBusinessGatewayRepository.updateBusinessCategory().
- direct cloud_firestore references were removed from business_category_required_page.dart.
- RegisteredBusinessGatewayRepository now owns category update writes.
- Target analyze for category page/repository has 0 error, 0 warning, 2 info for Radio deprecation.
- Recommended next: 62O businesses next safe candidate exact audit only, or category Radio deprecation exact audit.

---

## Current lock snapshot after 62R / 62S

- 62R build lock after 62Q_REV1 business services list stream repository wiring passed.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- BusinessServicesRepository now exists and owns watchBusinessServices(businessId).
- business_services_manage_page.dart list stream is repository-based.
- Service write paths remain direct and will be migrated in staged batches.
- Target analyze for business services has 0 error, 0 warning, 2 info.
- New tempo accepted:
  - services/businesses: controlled 2-4 method batches after exact audit.
  - protected domains: domain audit first, then same sub-flow small batches only.
- Recommended next: 63A services toggle + delete exact batch audit.

---

## Current lock snapshot after 63C / 63D

- 63C build lock after 63B_REV1 business services toggle/delete repository batch passed.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- BusinessServicesRepository now owns list stream, toggle active/bookingEnabled, and delete service.
- business_services_manage_page.dart _ServiceTile no longer directly uses doc.reference.set/delete.
- ServiceFormPage _save add/update remains direct and is the next exact audit target.
- Target analyze for business services has 0 error, 0 warning, 2 info.
- Recommended next: 63E ServiceFormPage _save exact audit only.

---

## Current lock snapshot after 63G / 63H

- 63G build lock after full business services repository wiring passed.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- BusinessServicesRepository now owns service list stream, toggle, delete, and save persistence.
- business_services_manage_page.dart direct Firebase persistence surface is removed.
- Target analyze for business services has 0 error, 0 warning, 2 info.
- Recommended next: 63I services local info cleanup audit only or next businesses safe candidate audit.

---

## Current lock snapshot after 63K / 63L

- 63K build lock passed after business services full repository migration and partial local info cleanup.
- APK exists at build\app\outputs\flutter-apk\app-debug.apk.
- BusinessServicesRepository owns service list stream, toggle, delete, and save persistence.
- business_services_manage_page.dart no longer has direct FirebaseFirestore.instance/add/doc.set/doc.reference.set/delete persistence surface.
- Service type dropdown uses initialValue.
- One curly-braces style info remains parked.
- Recommended next: 64A businesses next safe candidate audit only.