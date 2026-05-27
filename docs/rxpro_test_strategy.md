# RxPro Test Strategy Backlog

## 57Y purpose
This document adds the automatic test infrastructure plan to the project index/work area after 57R/57X service-repository migration locks.

## Current decision
The project should not wait until the absolute final release to think about tests. The safer order is:

1. Keep current manual real-device testing for visible flows.
2. Add a lightweight test foundation before the next high-risk migrations.
3. Add unit tests first for pure policy/service/repository boundaries.
4. Add widget tests for isolated screens after dependencies are mockable.
5. Add integration tests later for login, appointment, notification, messaging and finance smoke flows.

## Priority 1 - unit test candidates
- SessionRolePolicy canonical role resolution.
- ServiceStaffCompatibilityPolicy service/staff matching.
- AppointmentBookingService payload compatibility boundaries, without touching appointment core.
- FinanceRecordService idempotency and deterministic document id rules.
- BusinessStaffRepository stream/access-code/delete/upsert helper boundaries.
- BusinessProfileEditEntryResolverRepository owned business resolver.
- BusinessProfilePostInteractionRepository like/save/report method contracts.
- NotificationService helper contracts, without changing FCM/push triggers.

## Priority 2 - widget test candidates
- Account role body selection.
- Staff tasks tabs: work queue, completed, cancelled.
- Business profile edit entry navigation states.
- Business profile post interactive card button states.
- Business staff manage read-only list state.

## Priority 3 - integration test candidates
- Customer login -> appointment booking -> assigned staff sees task.
- Staff start/finish appointment -> finance record created once.
- Owner expense add -> finance summary refresh.
- Message send/read smoke flow.
- Notification center mark-read and mark-all-read smoke flow.

## Rules
- Tests must not trigger production deploy.
- Tests must not patch notification/push/FCM, messages/chat, appointment core, finance core or staff_workspace blindly.
- Test foundation patches must be small and separate from domain migrations.
- Firestore-dependent tests should use fake/mocked repositories first; emulator-based tests can come later.

## 58B - Pure Policy Unit Test Foundation Lock
- Date: 20260525_094812
- Scope: SessionRolePolicy and ServiceStaffCompatibilityPolicy targeted unit tests.
- Source app behavior changed: NO.
- Targeted test decision: PASS.
- Build run: True.
- Policy: run targeted unit tests during sensitive service/repository locks; keep integration tests for later final readiness.
