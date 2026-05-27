# RxPro Risk Map

Generated: 20260524_224933

| Path | Risk | Reason | Firestore Patterns |
|---|---|---|---:|
| lib/core/appointments/appointment_status.dart | HIGH | UI/sensitive module | 0 |
| lib/core/appointments/appointment_status_mapper.dart | HIGH | UI/sensitive module | 0 |
| lib/features/appointments/appointment_entry_page.dart | HIGH | Firestore/direct data access or sensitive module | 11 |
| lib/features/appointments/customer_appointments_page.dart | HIGH | Firestore/direct data access or sensitive module | 16 |
| lib/features/appointments/data/appointment_repository.dart | HIGH | UI/sensitive module | 0 |
| lib/features/appointments/data/customer_appointment_repository.dart | HIGH | Firestore/direct data access or sensitive module | 11 |
| lib/features/appointments/data/firestore_appointment_repository.dart | HIGH | Firestore/direct data access or sensitive module | 13 |
| lib/features/appointments/domain/appointment_booking_request.dart | HIGH | UI/sensitive module | 0 |
| lib/features/appointments/domain/appointment_booking_result.dart | HIGH | UI/sensitive module | 0 |
| lib/features/appointments/domain/service_staff_compatibility_policy.dart | HIGH | UI/sensitive module | 0 |
| lib/features/appointments/service/appointment_booking_service.dart | HIGH | UI/sensitive module | 0 |
| lib/features/auth/data/fix_login_gate_repository.dart | HIGH | Firestore/direct data access or sensitive module | 25 |
| lib/features/auth/fix_login_gate_page.dart | HIGH | Firestore/direct data access or sensitive module | 10 |
| lib/features/business/data/business_profile_post_interaction_repository.dart | HIGH | Firestore/direct data access or sensitive module | 37 |
| lib/features/business/pages/business_profile_edit_entry_page.dart | HIGH | Firestore/direct data access or sensitive module | 18 |
| lib/features/business/pages/business_profile_edit_page.dart | HIGH | Firestore/direct data access or sensitive module | 7 |
| lib/features/business_analysis/business_analysis_page.dart | HIGH | Firestore/direct data access or sensitive module | 14 |
| lib/features/business_analysis/business_product_movement_page.dart | HIGH | Firestore/direct data access or sensitive module | 6 |
| lib/features/businesses/business_appointment_management_page.dart | HIGH | Firestore/direct data access or sensitive module | 65 |
| lib/features/businesses/business_duration_analytics_page.dart | HIGH | Firestore/direct data access or sensitive module | 6 |
| lib/features/businesses/business_finance_page.dart | HIGH | Firestore/direct data access or sensitive module | 3 |
| lib/features/businesses/business_live_flow_page.dart | HIGH | Firestore/direct data access or sensitive module | 9 |
| lib/features/businesses/business_owner_hub_page.dart | HIGH | Firestore/direct data access or sensitive module | 7 |
| lib/features/businesses/business_products_page.dart | HIGH | Firestore/direct data access or sensitive module | 13 |
| lib/features/businesses/business_profile_page.dart | HIGH | Firestore/direct data access or sensitive module | 44 |
| lib/features/businesses/business_services_manage_page.dart | HIGH | Firestore/direct data access or sensitive module | 10 |
| lib/features/businesses/business_staff_manage_page.dart | HIGH | Firestore/direct data access or sensitive module | 7 |
| lib/features/businesses/data/business_profile_repository.dart | HIGH | Firestore/direct data access or sensitive module | 23 |
| lib/features/businesses/data/business_staff_repository.dart | HIGH | Firestore/direct data access or sensitive module | 17 |
| lib/features/businesses/data/registered_business_gateway_repository.dart | HIGH | Firestore/direct data access or sensitive module | 17 |
| lib/features/businesses/staff_tasks_entry_page.dart | HIGH | Firestore/direct data access or sensitive module | 16 |
| lib/features/businesses/staff_workspace_page.dart | HIGH | Firestore/direct data access or sensitive module | 20 |
| lib/features/campaigns/bulk_message_create_page.dart | HIGH | Firestore/direct data access or sensitive module | 3 |
| lib/features/campaigns/business_campaigns_page.dart | HIGH | Firestore/direct data access or sensitive module | 7 |
| lib/features/campaigns/campaign_ai_create_safe_page.dart | HIGH | Firestore/direct data access or sensitive module | 15 |
| lib/features/favorites/data/favorite_feed_repository.dart | HIGH | Firestore/direct data access or sensitive module | 30 |
| lib/features/favorites/favorite_feed_page.dart | HIGH | Firestore/direct data access or sensitive module | 24 |
| lib/features/finance/data/business_finance_repository.dart | HIGH | Firestore/direct data access or sensitive module | 13 |
| lib/features/finance/services/finance_record_service.dart | HIGH | Firestore/direct data access or sensitive module | 7 |
| lib/features/messages/data/chat_repository.dart | HIGH | Firestore/direct data access or sensitive module | 22 |
| lib/features/messages/domain/messaging_service.dart | HIGH | UI/sensitive module | 0 |
| lib/features/messages/messages_inbox_page.dart | HIGH | Firestore/direct data access or sensitive module | 55 |
| lib/features/public_home/account_entry_page.dart | HIGH | Firestore/direct data access or sensitive module | 20 |
| lib/features/public_home/home_explore_page.dart | HIGH | Firestore/direct data access or sensitive module | 8 |
| lib/features/staff_invites/staff_invite_service.dart | HIGH | Firestore/direct data access or sensitive module | 24 |
| lib/features/stories/business_story_service.dart | HIGH | Firestore/direct data access or sensitive module | 21 |
| lib/core/realtime/rx_notification_service.dart | LOCKED/HIGH | Firestore/direct data access or sensitive module | 7 |
| lib/core/realtime/rx_push_notification_service.dart | LOCKED/HIGH | Firestore/direct data access or sensitive module | 28 |
| lib/features/notifications/customer_notifications_page.dart | LOCKED/HIGH | UI/sensitive module | 0 |
| lib/features/notifications/data/customer_notification_repository.dart | LOCKED/HIGH | Firestore/direct data access or sensitive module | 11 |
| lib/features/notifications/domain/notification_service.dart | LOCKED/HIGH | Firestore/direct data access or sensitive module | 9 |
| lib/features/notifications/notification_center_page.dart | LOCKED/HIGH | Firestore/direct data access or sensitive module | 8 |
| lib/core/app_cache/app_cache_service.dart | MEDIUM | Firestore/direct data access or sensitive module | 1 |
| lib/core/app_state/current_user_state_service.dart | MEDIUM | Firestore/direct data access or sensitive module | 13 |
| lib/core/app_state/follow_cache_warmup_service.dart | MEDIUM | Firestore/direct data access or sensitive module | 5 |
| lib/core/businesses/business_directory_cache_service.dart | MEDIUM | Firestore/direct data access or sensitive module | 3 |
| lib/core/services/firestore_service.dart | MEDIUM | Firestore/direct data access or sensitive module | 13 |
| lib/core/session/app_session_controller.dart | MEDIUM | Firestore/direct data access or sensitive module | 10 |
| lib/features/accounting/data/accounting_installment_plan.dart | MEDIUM | Firestore/direct data access or sensitive module | 3 |
| lib/features/accounting/pages/accounting_expenses_page.dart | MEDIUM | Firestore/direct data access or sensitive module | 1 |
| lib/features/accounting/pages/accounting_permissions_page.dart | MEDIUM | Firestore/direct data access or sensitive module | 4 |
| lib/features/accounting/pages/accounting_receivables_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/accounting/pages/accounting_reports_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/accounting/pages/accounting_sales_page.dart | MEDIUM | Firestore/direct data access or sensitive module | 1 |
| lib/features/accounting/pages/accounting_summary_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/auth/business_login_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/auth/customer_login_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/auth/login_choice_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/auth/phone_password_reset_flow_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/business/pages/business_profile_post_create_page.dart | MEDIUM | Firestore/direct data access or sensitive module | 3 |
| lib/features/business/widgets/business_profile_post_interactive_card.dart | MEDIUM | Firestore/direct data access or sensitive module | 4 |
| lib/features/business_analysis/data/business_analysis_repository.dart | MEDIUM | Firestore/direct data access or sensitive module | 13 |
| lib/features/business_role/business_role_resolver.dart | MEDIUM | Firestore/direct data access or sensitive module | 11 |
| lib/features/businesses/business_activity_logs_page.dart | MEDIUM | Firestore/direct data access or sensitive module | 3 |
| lib/features/businesses/business_category_required_page.dart | MEDIUM | Firestore/direct data access or sensitive module | 4 |
| lib/features/businesses/business_pos_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/businesses/registered_businesses_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/campaigns/customer_campaigns_page.dart | MEDIUM | Firestore/direct data access or sensitive module | 4 |
| lib/features/favorites/favorite_entry_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/public_home/guest_feature_preview_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/staff/data/firestore_staff_repository.dart | MEDIUM | Firestore/direct data access or sensitive module | 10 |
| lib/features/staff_invites/staff_invite_code_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/stories/business_story_create_page.dart | MEDIUM | UI/sensitive module | 0 |
| lib/features/stories/business_story_viewer_page.dart | MEDIUM | UI/sensitive module | 0 |

## BusinessProfile Reviews Lock Note - 56G

- usiness_profile_page.dart iÃ§indeki _ReviewsTabState._reviewsStream() artÄ±k BusinessProfileRepository.watchBusinessReviews(...) hattÄ±ndadÄ±r.
- _currentUserDocStream, _sendReview, _refreshRatingSummary, appointment, messaging, favorite/rating write, edit/write/delete, notification/push akÄ±ÅŸlarÄ±na dokunulmadÄ±.
- Kalan BusinessProfile Firestore izleri ayrÄ± exact audit ile ele alÄ±nmalÄ±dÄ±r.

## BusinessProfileEditEntry Resolver Risk Note - 56P/56Q

- Risk level: medium-low after wiring; page still owns UI state/navigation.
- Cleanup helpers intentionally remain to avoid combining resolver migration with deletion cleanup.
- Future cleanup requires exact audit and separate small patch.

## 56T/56U note - BusinessProfileEditEntry resolver cleanup
- Direct Firestore resolver logic was removed from the entry page after repository wiring was smoke-verified.
- Remaining risk: full compile/build not taken in this intermediate no-build step; include this module in the next batch build.

## 57D_BUSINESS_PROFILE_EDIT_PAGE_RISK_NOTE

BusinessProfileEditPage repository migration is no-build smoke locked. Remaining risk: full APK build and manual profile edit smoke test are pending for the next batch/final build checkpoint. Do not combine future changes in this file with Storage upload refactor, notification/push, rules/index/functions, or unrelated business profile write flows.


- BusinessActivityLogs read-stream repository wiring locked at 57J no-build smoke; keep write-free/read-stream-only scope.

## 57O Risk Note - AccountingPermissionsPage
- Risk level after migration: low read-stream page.
- Remaining caution: page displays session permission metadata; future changes must preserve role, activeBusinessId, and permissions together.
- Do not combine this page with finance write/permission mutation flows in one patch.

### BusinessActivityLogsPage risk note - 57Q
- Low-risk read-stream page after migration.
- Remaining Firestore import is allowed only for Timestamp handling.
- Direct usinessActivityLogs collection query should remain in repository.
