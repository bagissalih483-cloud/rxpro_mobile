# RxPro Target Architecture

This document defines the target project tree, dependency direction and operating algorithm for RxPro.

## Target Tree

```text
lib/
  app/
    bootstrap/
    routing/
    shell/
  core/
    account/
    app_cache/
    app_state/
    appointments/
    businesses/
    firebase/
    firestore/
    lookup/
    models/
    realtime/
    services/
    session/
    tasks/
    theme/
    uploads/
  shared/
    widgets/
    formatters/
    validators/
    ui_state/
  features/
    <feature>/
      presentation/
        pages/
        widgets/
      application/
        controllers/
        use_cases/
      domain/
        models/
        policies/
      data/
        repositories/
        dto/
        mappers/
      services/
        side_effects/
functions/
  index.js
  src/
    modules/
    shared/
infra/
  firebase/
  rules/
  indexes/
docs/
  project_index/
tools/
  quality_check.ps1
  architecture_check.ps1
test/
  core/
  features/
  functions/
  rules/
```

## Current Practical Tree

The current codebase already uses the most important split:

```text
lib/
  core/
  features/
```

The migration should stay incremental. Do not move every file at once. A file is moved only when the owning feature is already behind repository/service boundaries and the import blast radius is small.

## Layer Contract

| Layer | Owns | Must not own |
|---|---|---|
| `presentation` / page files | UI, form state, navigation, empty/loading/error states | Firestore queries, auth token logic, push writes, business rules |
| `application` | use-case orchestration, screen controller state | raw collection names, widget layout |
| `domain` | pure models, policies, validators, state transitions | Firebase, Flutter widgets, HTTP |
| `data` / repositories | Firestore/Functions/Storage reads and writes, DTO mapping | widget UI, navigation |
| `services` | side effects, push, cache warmup, upload, external calls | page layout, broad cross-feature orchestration |
| `core` | shared infrastructure, session, constants, app-wide policies | feature-specific screen logic |

## Dependency Direction

Allowed:

```text
presentation -> application -> domain
presentation -> data repository interfaces or local repositories when application layer does not exist yet
data -> core firestore/auth/constants
services -> data/core/external SDKs
core -> core only, unless a boundary is explicitly documented
```

Avoid:

```text
page/widget -> FirebaseFirestore.instance
page/widget -> FirebaseAuth.instance
page/widget -> FieldValue / SetOptions
feature A data -> feature B presentation
domain -> Flutter / Firebase / HTTP
```

## Direct Firebase Budget

Direct Firebase access outside `data`, `domain`, `service`, `services` and repository files is an architecture budget, not a convenience.

Current approved budget: 8 files.

Approved infrastructure surfaces:

- `lib/core/app_state/current_user_state_service.dart`
- `lib/core/app_state/follow_cache_warmup_service.dart`
- `lib/core/businesses/business_directory_cache_service.dart`
- `lib/core/realtime/rx_notification_service.dart`
- `lib/core/realtime/rx_push_notification_service.dart`
- `lib/core/session/app_session_controller.dart`
- `lib/features/staff_invites/staff_invite_service.dart`
- `lib/features/stories/business_story_service.dart`

`tools/architecture_check.ps1` fails when a new non-approved UI/root file opens direct Firebase access.

## Feature Migration Shape

For every feature, prefer this end state:

```text
features/<feature>/
  presentation/
    <feature>_page.dart
    widgets/
  application/
    <feature>_controller.dart
  domain/
    <feature>_policy.dart
    <feature>_models.dart
  data/
    <feature>_repository.dart
  services/
    <feature>_side_effect_service.dart
```

If a feature is small, `presentation` can be skipped temporarily and existing page paths can remain, but Firebase access must still stay out of page files.

## Release Readiness Gate

A professional release candidate needs:

- `tools/quality_check.ps1` passes.
- `tools/architecture_check.ps1` passes.
- Flutter format/analyze/test passes in the user environment.
- Firebase rules emulator tests pass.
- High-risk flows have smoke coverage: login, role gate, appointment, message, staff task, notification, finance.
- Platform config is complete: Android google services, iOS `GoogleService-Info.plist`, production Firebase project.
