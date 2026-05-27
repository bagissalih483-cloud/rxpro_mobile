# RxPro Working Algorithm

This document defines how the app should work as a system and how code changes should move through the project.

## Product Runtime Algorithm

```text
1. App bootstrap
   - Initialize Flutter bindings.
   - Initialize Firebase.
   - Initialize push notification service.
   - Warm local follow/cache data in the background.

2. Auth gate
   - Listen to id token changes through AuthService.
   - If no user, show guest/login flow.
   - If user exists, resolve AppSession.

3. Session resolution
   - Read user role state.
   - Resolve individual, corporate owner or linked staff session.
   - For corporate users, require businessId.
   - Expose the resolved session through AppSessionScope.

4. Shell routing
   - Individual shell opens explore, favorites, appointments, campaigns and account.
   - Corporate shell opens preview, accounting, campaigns, appointments and account.
   - Every protected area passes through SessionRoleGate.

5. Feature execution
   - Page reads UI state and user input.
   - Repository/service performs data access or side effects.
   - Domain policy validates business decisions where needed.
   - Page renders result states only.

6. Realtime updates
   - Repositories own Firestore streams.
   - UI receives normalized models or maps, not raw business queries.
   - Notification and push services own token/notification side effects.
```

## Appointment Algorithm

```text
1. Customer selects business, service, staff, date and time.
2. Compatibility policy checks service/staff match.
3. Booking service creates appointment through repository boundary.
4. Business/staff dashboards consume appointment streams.
5. Staff may start, complete, remind overdue or mark no-show through StaffWorkspaceRepository.
6. Completion creates finance income record and activity log.
7. Customer/business notifications are written through notification services.
```

## Messaging Algorithm

```text
1. User opens inbox.
2. MessagesRepository resolves current user context.
3. Repository chooses customer threads or business threads.
4. Thread page watches normalized thread and message models.
5. Sending a message updates the canonical thread and message stream.
6. Legacy mirror writes stay behind repository/service boundaries until the chat provider decision is finalized.
```

## Business Profile Algorithm

```text
1. Profile page watches business profile through BusinessProfileRepository.
2. Intro posts stream through repository.
3. Booking tab delegates appointment creation to booking service.
4. Reviews tab delegates review write and rating summary update to repository.
5. Follow button delegates follow state and counter transaction to repository.
6. UI only decides visibility, labels and navigation.
```

## Development Algorithm

Every meaningful change follows this order:

```text
1. Audit
   - Find direct Firebase, cross-feature imports and risky state transitions.
   - Classify risk: LOW, MEDIUM, HIGH, LOCKED/HIGH.

2. Foundation
   - Create or extend model, policy, repository or service.
   - Keep old UI behavior unchanged.

3. Wiring
   - Replace page/root direct calls with the boundary.
   - Keep method signatures small and explicit.

4. Verification
   - Run architecture check.
   - Run quality check.
   - Run targeted tests when tooling is available.

5. Lock
   - Update patch ledger, locked lines and remaining gaps.
   - Record what was intentionally not changed.
```

## Refactor Algorithm

```text
1. Never move a whole feature folder before its data/service boundary is stable.
2. Move pure models and policies first.
3. Move repositories second.
4. Move pages/widgets last.
5. After every move, run architecture check and targeted import scan.
6. Stop if the change crosses appointment, messaging, finance, notification or staff workspace without a narrow audit.
```

## Data Safety Algorithm

```text
1. Firestore collection names live in FirestoreCollections.
2. Field names live in FirestoreFields.
3. Timestamp/server mutation values stay inside repositories/services.
4. UI never constructs broad write payloads for sensitive flows.
5. Every user-visible mutation should produce one of:
   - activity log,
   - notification,
   - finance record,
   - audit field,
   depending on the domain.
```
