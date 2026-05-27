# RxPro Code Index

Generated: 20260524_224933

## 64Q Current Index Note

Updated: 20260526

- This table is historical and predates the 64Q service boundary sprint.
- The current enforceable architecture check is `tools/architecture_check.ps1`.
- Current direct Firebase surface outside repository/service/domain paths: 8 approved infrastructure files.
- The following former high-risk UI/root surfaces are now repository/service-backed: messages inbox, appointment entry, customer appointments, business appointment management, business staff management, staff tasks entry, staff workspace, account entry, business profile, and `main.dart`.

The legacy generated table below is retained for path discovery until a full code-index regeneration is run locally.

| Path | Type | Firestore Patterns | Risk |
|---|---:|---:|---|
| lib/core/appointments/appointment_status.dart | core | 0 | HIGH |
| lib/core/appointments/appointment_status_mapper.dart | core | 0 | HIGH |
| lib/features/appointments/appointment_entry_page.dart | ui | 11 | HIGH |
| lib/features/appointments/customer_appointments_page.dart | ui | 16 | HIGH |
| lib/features/appointments/data/appointment_repository.dart | repository | 0 | HIGH |
| lib/features/appointments/data/customer_appointment_repository.dart | repository | 11 | HIGH |
| lib/features/appointments/data/firestore_appointment_repository.dart | repository | 13 | HIGH |
| lib/features/appointments/domain/appointment_booking_request.dart | dart | 0 | HIGH |
| lib/features/appointments/domain/appointment_booking_result.dart | dart | 0 | HIGH |
| lib/features/appointments/domain/service_staff_compatibility_policy.dart | service | 0 | HIGH |
| lib/features/appointments/service/appointment_booking_service.dart | service | 0 | HIGH |
| lib/features/auth/data/fix_login_gate_repository.dart | repository | 25 | HIGH |
| lib/features/auth/fix_login_gate_page.dart | ui | 10 | HIGH |
| lib/features/business/data/business_profile_post_interaction_repository.dart | repository | 37 | HIGH |
| lib/features/business/pages/business_profile_edit_entry_page.dart | ui | 18 | HIGH |
| lib/features/business/pages/business_profile_edit_page.dart | ui | 7 | HIGH |
| lib/features/business_analysis/business_analysis_page.dart | ui | 14 | HIGH |
| lib/features/business_analysis/business_product_movement_page.dart | ui | 6 | HIGH |
| lib/features/businesses/business_appointment_management_page.dart | ui | 65 | HIGH |
| lib/features/businesses/business_duration_analytics_page.dart | ui | 6 | HIGH |
| lib/features/businesses/business_finance_page.dart | ui | 3 | HIGH |
| lib/features/businesses/business_live_flow_page.dart | ui | 9 | HIGH |
| lib/features/businesses/business_owner_hub_page.dart | ui | 7 | HIGH |
| lib/features/businesses/business_products_page.dart | ui | 13 | HIGH |
| lib/features/businesses/business_profile_page.dart | ui | 44 | HIGH |
| lib/features/businesses/business_services_manage_page.dart | service | 10 | HIGH |
| lib/features/businesses/business_staff_manage_page.dart | ui | 7 | HIGH |
| lib/features/businesses/data/business_profile_repository.dart | repository | 23 | HIGH |
| lib/features/businesses/data/business_staff_repository.dart | repository | 17 | HIGH |
| lib/features/businesses/data/registered_business_gateway_repository.dart | repository | 17 | HIGH |
| lib/features/businesses/staff_tasks_entry_page.dart | ui | 16 | HIGH |
| lib/features/businesses/staff_workspace_page.dart | ui | 20 | HIGH |
| lib/features/campaigns/bulk_message_create_page.dart | ui | 3 | HIGH |
| lib/features/campaigns/business_campaigns_page.dart | ui | 7 | HIGH |
| lib/features/campaigns/campaign_ai_create_safe_page.dart | ui | 15 | HIGH |
| lib/features/favorites/data/favorite_feed_repository.dart | repository | 30 | HIGH |
| lib/features/favorites/favorite_feed_page.dart | ui | 24 | HIGH |
| lib/features/finance/data/business_finance_repository.dart | repository | 13 | HIGH |
| lib/features/finance/services/finance_record_service.dart | service | 7 | HIGH |
| lib/features/messages/data/chat_repository.dart | repository | 22 | HIGH |
| lib/features/messages/domain/messaging_service.dart | service | 0 | HIGH |
| lib/features/messages/messages_inbox_page.dart | ui | 55 | HIGH |
| lib/features/public_home/account_entry_page.dart | ui | 20 | HIGH |
| lib/features/public_home/home_explore_page.dart | ui | 8 | HIGH |
| lib/features/staff_invites/staff_invite_service.dart | service | 24 | HIGH |
| lib/features/stories/business_story_service.dart | service | 21 | HIGH |
| lib/core/realtime/rx_notification_service.dart | service | 7 | LOCKED/HIGH |
| lib/core/realtime/rx_push_notification_service.dart | service | 28 | LOCKED/HIGH |
| lib/features/notifications/customer_notifications_page.dart | ui | 0 | LOCKED/HIGH |
| lib/features/notifications/data/customer_notification_repository.dart | repository | 11 | LOCKED/HIGH |
| lib/features/notifications/domain/notification_service.dart | service | 9 | LOCKED/HIGH |
| lib/features/notifications/notification_center_page.dart | ui | 8 | LOCKED/HIGH |
| lib/core/account/account_mode.dart | core | 0 | LOW |
| lib/core/account/account_mode_resolver.dart | core | 0 | LOW |
| lib/core/app_state/fix_session_gate.dart | core | 0 | LOW |
| lib/core/app_state/fix_shell_nav_state.dart | core | 0 | LOW |
| lib/core/businesses/business_category.dart | core | 0 | LOW |
| lib/core/firebase/firebase_collection_paths.dart | core | 0 | LOW |
| lib/core/firestore/firestore_collections.dart | core | 0 | LOW |
| lib/core/firestore/firestore_fields.dart | core | 0 | LOW |
| lib/core/firestore/firestore_schema_versions.dart | core | 0 | LOW |
| lib/core/lookup/rxpro_directory_filters.dart | core | 0 | LOW |
| lib/core/models/app_user_model.dart | core | 0 | LOW |
| lib/core/models/auth_status_model.dart | core | 0 | LOW |
| lib/core/models/business_account_model.dart | core | 0 | LOW |
| lib/core/services/auth_service.dart | service | 0 | LOW |
| lib/core/session/app_role.dart | core | 0 | LOW |
| lib/core/session/app_session.dart | core | 0 | LOW |
| lib/core/session/app_session_scope.dart | core | 0 | LOW |
| lib/core/session/role_guard.dart | core | 0 | LOW |
| lib/core/session/session_role_gate.dart | core | 0 | LOW |
| lib/core/session/session_role_policy.dart | policy | 0 | LOW |
| lib/core/tasks/task_status_filter.dart | core | 0 | LOW |
| lib/core/theme/rx_ui.dart | core | 0 | LOW |
| lib/core/uploads/app_image_upload_service.dart | service | 0 | LOW |
| lib/features/accounting/business_accounting_shell.dart | dart | 0 | LOW |
| lib/features/accounting/data/accounting_dto.dart | dart | 0 | LOW |
| lib/features/accounting/data/accounting_firestore_paths.dart | dart | 0 | LOW |
| lib/features/accounting/data/accounting_functions_client.dart | dart | 0 | LOW |
| lib/features/accounting/data/accounting_permission_bridge.dart | dart | 0 | LOW |
| lib/features/accounting/data/accounting_permissions.dart | dart | 0 | LOW |
| lib/features/accounting/data/accounting_repository.dart | repository | 0 | LOW |
| lib/features/accounting/data/accounting_validators.dart | dart | 0 | LOW |
| lib/features/accounting/data/callable_accounting_repository.dart | repository | 0 | LOW |
| lib/features/accounting/models/accounting_models.dart | dart | 0 | LOW |
| lib/features/auth/widgets/fix_session_loading_image.dart | dart | 0 | LOW |
| lib/features/business/widgets/business_profile_edit_button.dart | dart | 0 | LOW |
| lib/features/businesses/FIX_47D_FINANCE_STAFF_NAV_NOTES.dart | dart | 0 | LOW |
| lib/features/guest/guest_required_sheet.dart | dart | 0 | LOW |
| lib/features/public_home/account_bodies/account_bodies.dart | dart | 0 | LOW |
| lib/features/public_home/account_bodies/corporate_owner_account_body.dart | dart | 0 | LOW |
| lib/features/public_home/account_bodies/individual_account_body.dart | dart | 0 | LOW |
| lib/features/public_home/account_bodies/linked_staff_account_body.dart | dart | 0 | LOW |
| lib/features/staff/data/staff_repository.dart | repository | 0 | LOW |
| lib/features/stories/business_story_model.dart | dart | 0 | LOW |
| lib/features/stories/business_story_rail.dart | dart | 0 | LOW |
| lib/firebase_options.dart | dart | 0 | LOW |
| lib/main.dart | dart | 0 | LOW |
| lib/core/app_cache/app_cache_service.dart | service | 1 | MEDIUM |
| lib/core/app_state/current_user_state_service.dart | service | 13 | MEDIUM |
| lib/core/app_state/follow_cache_warmup_service.dart | service | 5 | MEDIUM |
| lib/core/businesses/business_directory_cache_service.dart | service | 3 | MEDIUM |
| lib/core/services/firestore_service.dart | service | 13 | MEDIUM |
| lib/core/session/app_session_controller.dart | core | 10 | MEDIUM |
| lib/features/accounting/data/accounting_installment_plan.dart | dart | 3 | MEDIUM |
| lib/features/accounting/pages/accounting_expenses_page.dart | ui | 1 | MEDIUM |
| lib/features/accounting/pages/accounting_permissions_page.dart | ui | 4 | MEDIUM |
| lib/features/accounting/pages/accounting_receivables_page.dart | ui | 0 | MEDIUM |
| lib/features/accounting/pages/accounting_reports_page.dart | ui | 0 | MEDIUM |
| lib/features/accounting/pages/accounting_sales_page.dart | ui | 1 | MEDIUM |
| lib/features/accounting/pages/accounting_summary_page.dart | ui | 0 | MEDIUM |
| lib/features/auth/business_login_page.dart | ui | 0 | MEDIUM |
| lib/features/auth/customer_login_page.dart | ui | 0 | MEDIUM |
| lib/features/auth/login_choice_page.dart | ui | 0 | MEDIUM |
| lib/features/auth/phone_password_reset_flow_page.dart | ui | 0 | MEDIUM |
| lib/features/business/pages/business_profile_post_create_page.dart | ui | 3 | MEDIUM |
| lib/features/business/widgets/business_profile_post_interactive_card.dart | dart | 4 | MEDIUM |
| lib/features/business_analysis/data/business_analysis_repository.dart | repository | 13 | MEDIUM |
| lib/features/business_role/business_role_resolver.dart | dart | 11 | MEDIUM |
| lib/features/businesses/business_activity_logs_page.dart | ui | 3 | MEDIUM |
| lib/features/businesses/business_category_required_page.dart | ui | 4 | MEDIUM |
| lib/features/businesses/business_pos_page.dart | ui | 0 | MEDIUM |
| lib/features/businesses/registered_businesses_page.dart | ui | 0 | MEDIUM |
| lib/features/campaigns/customer_campaigns_page.dart | ui | 4 | MEDIUM |
| lib/features/favorites/favorite_entry_page.dart | ui | 0 | MEDIUM |
| lib/features/public_home/guest_feature_preview_page.dart | ui | 0 | MEDIUM |
| lib/features/staff/data/firestore_staff_repository.dart | repository | 10 | MEDIUM |
| lib/features/staff_invites/staff_invite_code_page.dart | ui | 0 | MEDIUM |
| lib/features/stories/business_story_create_page.dart | ui | 0 | MEDIUM |
| lib/features/stories/business_story_viewer_page.dart | ui | 0 | MEDIUM |
