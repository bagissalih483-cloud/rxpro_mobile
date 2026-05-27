# RxPro Service / Repository Map

Generated: 20260524_224933

## 64Q Current Architecture Summary

Updated: 20260526

- Direct Firebase surface outside repository/service/domain paths: 8 approved infrastructure files.
- `tools/architecture_check.ps1` is the executable source of truth for the current boundary budget.
- New high-traffic boundaries added after this map was first generated:
  - `lib/features/appointments/data/business_appointment_dashboard_repository.dart`
  - `lib/features/appointments/services/customer_appointment_action_service.dart`
  - `lib/features/messages/data/messages_repository.dart`
  - `lib/features/businesses/data/business_appointment_management_repository.dart`
  - `lib/features/businesses/data/business_customer_message_repository.dart`
  - `lib/features/businesses/data/staff_tasks_entry_repository.dart`
  - `lib/features/businesses/data/staff_workspace_repository.dart`
  - `lib/features/public_home/data/account_entry_repository.dart`
- Feature folders with active `data` boundaries: accounting, appointments, auth, business, businesses, business_analysis, business_role, favorites, finance, messages, notifications, public_home, staff.
- Remaining feature folders without a dedicated `data` boundary are lightweight UI shells or service-only surfaces: campaigns, guest, staff_invites, stories.

The legacy generated table below is retained as historical context until a full index regeneration is available in the local user environment.

| Path | Kind | Firestore Patterns | Risk |
|---|---:|---:|---|
| lib/core/session/app_session_controller.dart | controller | 10 | MEDIUM |
| lib/core/session/session_role_policy.dart | policy | 0 | LOW |
| lib/features/accounting/data/accounting_repository.dart | repository | 0 | LOW |
| lib/features/accounting/data/callable_accounting_repository.dart | repository | 0 | LOW |
| lib/features/appointments/data/appointment_repository.dart | repository | 0 | HIGH |
| lib/features/appointments/data/customer_appointment_repository.dart | repository | 11 | HIGH |
| lib/features/appointments/data/firestore_appointment_repository.dart | repository | 13 | HIGH |
| lib/features/auth/data/fix_login_gate_repository.dart | repository | 25 | HIGH |
| lib/features/business/data/business_profile_post_interaction_repository.dart | repository | 37 | HIGH |
| lib/features/business_analysis/data/business_analysis_repository.dart | repository | 13 | MEDIUM |
| lib/features/businesses/data/business_profile_repository.dart | repository | 23 | HIGH |
| lib/features/businesses/data/business_staff_repository.dart | repository | 17 | HIGH |
| lib/features/businesses/data/registered_business_gateway_repository.dart | repository | 17 | HIGH |
| lib/features/favorites/data/favorite_feed_repository.dart | repository | 30 | HIGH |
| lib/features/finance/data/business_finance_repository.dart | repository | 13 | HIGH |
| lib/features/messages/data/chat_repository.dart | repository | 22 | HIGH |
| lib/features/notifications/data/customer_notification_repository.dart | repository | 11 | LOCKED/HIGH |
| lib/features/staff/data/firestore_staff_repository.dart | repository | 10 | MEDIUM |
| lib/features/staff/data/staff_repository.dart | repository | 0 | LOW |
| lib/core/account/account_mode_resolver.dart | resolver | 0 | LOW |
| lib/features/business_role/business_role_resolver.dart | resolver | 11 | MEDIUM |
| lib/core/app_cache/app_cache_service.dart | service | 1 | MEDIUM |
| lib/core/app_state/current_user_state_service.dart | service | 13 | MEDIUM |
| lib/core/app_state/follow_cache_warmup_service.dart | service | 5 | MEDIUM |
| lib/core/businesses/business_directory_cache_service.dart | service | 3 | MEDIUM |
| lib/core/realtime/rx_notification_service.dart | service | 7 | LOCKED/HIGH |
| lib/core/realtime/rx_push_notification_service.dart | service | 28 | LOCKED/HIGH |
| lib/core/services/auth_service.dart | service | 0 | LOW |
| lib/core/services/firestore_service.dart | service | 13 | MEDIUM |
| lib/core/uploads/app_image_upload_service.dart | service | 0 | LOW |
| lib/features/appointments/domain/service_staff_compatibility_policy.dart | service | 0 | HIGH |
| lib/features/appointments/service/appointment_booking_service.dart | service | 0 | HIGH |
| lib/features/businesses/business_services_manage_page.dart | service | 10 | HIGH |
| lib/features/finance/services/finance_record_service.dart | service | 7 | HIGH |
| lib/features/messages/domain/messaging_service.dart | service | 0 | HIGH |
| lib/features/notifications/domain/notification_service.dart | service | 9 | LOCKED/HIGH |
| lib/features/staff_invites/staff_invite_service.dart | service | 24 | HIGH |
| lib/features/stories/business_story_service.dart | service | 21 | HIGH |

## BusinessProfileEditEntry Resolver

- Page: `lib/.../business_profile_edit_entry_page.dart`
- Repository: `lib/features/business/data/business_profile_edit_entry_resolver_repository.dart`
- Current wiring: `_loadOwnedBusiness` delegates owned business id resolution to `BusinessProfileEditEntryResolverRepository`.
- Repository signature: `resolveOwnedBusinessId({ required String uid, String? email })`.
