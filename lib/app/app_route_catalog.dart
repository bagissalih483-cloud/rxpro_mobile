import 'package:flutter/material.dart';

import 'app_routes.dart';
import '../core/theme/rx_ui.dart';
import '../core/session/app_role.dart';
import '../core/session/session_role_gate.dart';
import '../features/admin/presentation/admin_moderation_page.dart';
import '../features/appointments/presentation/pages/customer_appointments_page.dart';
import '../features/auth/fix_login_gate_page.dart';
import '../features/auth/presentation/pages/phone_password_reset_flow_page.dart';
import '../features/business/pages/business_profile_edit_entry_page.dart';
import '../features/business/pages/business_profile_edit_page.dart';
import '../features/business/pages/business_profile_post_create_page.dart';
import '../features/business_analysis/presentation/pages/business_product_movement_page.dart';
import '../features/businesses/business_owner_hub_page.dart';
import '../features/businesses/business_customers_page.dart';
import '../features/businesses/business_live_flow_page.dart';
import '../features/businesses/business_pos_page.dart';
import '../features/businesses/business_profile_page.dart';
import '../features/businesses/business_products_page.dart';
import '../features/businesses/business_services_manage_page.dart';
import '../features/businesses/presentation/pages/business_finance_page.dart';
import '../features/businesses/presentation/pages/business_customer_direct_message_page.dart';
import '../features/businesses/presentation/pages/business_staff_form_page.dart';
import '../features/businesses/registered_businesses_page.dart';
import '../features/businesses/staff_tasks_entry_page.dart';
import '../features/businesses/staff_workspace_page.dart';
import '../features/campaigns/bulk_message_create_page.dart';
import '../features/campaigns/business_campaigns_page.dart';
import '../features/campaigns/campaign_ai_create_safe_page.dart';
import '../features/legal/account_deletion_request_page.dart';
import '../features/legal/legal_documents_page.dart';
import '../features/messages/messages_inbox_page.dart';
import '../features/notifications/notification_center_page.dart';
import '../features/notifications/presentation/notification_preferences_page.dart';
import '../features/public_home/home_explore_page.dart';
import '../features/staff_invites/staff_invite_code_page.dart';
import '../features/stories/business_story_create_page.dart';
import '../features/stories/business_story_viewer_page.dart';

export 'app_routes.dart';

abstract final class AppRouteCatalog {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.accountDeletionRequest:
        return _page(settings, const AccountDeletionRequestPage());
      case AppRoutes.adminModeration:
        return _page(settings, AdminModerationPage());
      case AppRoutes.businessOwnerHub:
        final args = settings.arguments;
        if (args is BusinessOwnerHubRouteArgs) {
          return _corporatePage(
            settings,
            BusinessOwnerHubPage(
              businessId: args.businessId,
              initialData: args.initialData,
              openSection: args.openSection,
            ),
            permissionKey: _businessOwnerHubPermission(args.openSection),
          );
        }
        return _corporatePage(settings, const BusinessOwnerHubPage());
      case AppRoutes.businessProductMovement:
        final args = settings.arguments;
        if (args is! BusinessProductMovementRouteArgs ||
            args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _page(
          settings,
          BusinessProductMovementPage(
            businessId: args.businessId,
            businessName: args.businessName,
          ),
        );
      case AppRoutes.businessPos:
        return _corporatePage(
          settings,
          const BusinessPosPage(),
          permissionKey: 'financeRead',
        );
      case AppRoutes.businessCampaigns:
        final args = settings.arguments;
        if (args is! BusinessPageRouteArgs || args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _corporatePage(
          settings,
          BusinessCampaignsPage(
            businessId: args.businessId,
            businessName: args.businessName,
          ),
          permissionKey: 'campaignRead',
        );
      case AppRoutes.businessCustomers:
        final args = settings.arguments;
        if (args is! BusinessPageRouteArgs || args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _corporatePage(
          settings,
          BusinessCustomersPage(
            businessId: args.businessId,
            businessName: args.businessName,
          ),
          permissionKey: 'customersRead',
        );
      case AppRoutes.businessFinance:
        final args = settings.arguments;
        if (args is! BusinessPageRouteArgs || args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _corporatePage(
          settings,
          BusinessFinancePage(
            businessId: args.businessId,
            businessName: args.businessName,
          ),
          permissionKey: 'financeRead',
        );
      case AppRoutes.businessLiveFlow:
        final args = settings.arguments;
        if (args is! BusinessPageRouteArgs || args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _corporatePage(
          settings,
          BusinessLiveFlowPage(
            businessId: args.businessId,
            businessName: args.businessName,
          ),
          permissionKey: 'appointmentsRead',
        );
      case AppRoutes.businessProducts:
        return _corporatePage(
          settings,
          const BusinessProductsPage(),
          permissionKey: 'productsManage',
        );
      case AppRoutes.businessProductForm:
        final args = settings.arguments;
        if (args is! BusinessProductFormRouteArgs ||
            args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _corporatePage(
          settings,
          BusinessProductFormPage(
            businessId: args.businessId,
            businessName: args.businessName,
            doc: args.doc,
          ),
          permissionKey: 'productsManage',
        );
      case AppRoutes.businessProfile:
        final args = settings.arguments;
        if (args is! BusinessProfileRouteArgs ||
            args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _page(
          settings,
          BusinessProfilePage(
            businessId: args.businessId,
            businessName: args.businessName,
            category: args.category,
          ),
        );
      case AppRoutes.businessProfileEdit:
        final args = settings.arguments;
        if (args is! BusinessProfileEditRouteArgs ||
            args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _page(
          settings,
          BusinessProfileEditPage(businessId: args.businessId),
        );
      case AppRoutes.businessProfileEditEntry:
        return _page(settings, const BusinessProfileEditEntryPage());
      case AppRoutes.businessProfilePostCreate:
        final args = settings.arguments;
        if (args is! BusinessProfilePostCreateRouteArgs ||
            args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _corporatePage(
          settings,
          BusinessProfilePostCreatePage(
            businessId: args.businessId,
            businessName: args.businessName,
          ),
          permissionKey: 'campaignWrite',
        );
      case AppRoutes.businessServiceForm:
        final args = settings.arguments;
        if (args is! BusinessServiceFormRouteArgs ||
            args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _corporatePage(
          settings,
          ServiceFormPage(
            businessId: args.businessId,
            businessData: args.businessData,
            serviceId: args.serviceId,
            initialData: args.initialData,
          ),
          permissionKey: 'servicesManage',
        );
      case AppRoutes.businessExpenseForm:
        final args = settings.arguments;
        if (args is! BusinessExpenseFormRouteArgs ||
            args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _corporatePage(
          settings,
          ExpenseFormPage(
            businessId: args.businessId,
            businessName: args.businessName,
          ),
          permissionKey: 'financeWrite',
        );
      case AppRoutes.businessStaffForm:
        final args = settings.arguments;
        if (args is! BusinessStaffFormRouteArgs ||
            args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _corporatePage(
          settings,
          StaffFormPage(
            businessId: args.businessId,
            businessAccessCode: args.businessAccessCode,
            staffId: args.staffId,
            initialData: args.initialData,
          ),
          permissionKey: 'staffManage',
        );
      case AppRoutes.businessStoryCreate:
        final args = settings.arguments;
        if (args is! BusinessPageRouteArgs || args.businessId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _corporatePage(
          settings,
          BusinessStoryCreatePage(
            businessId: args.businessId,
            businessName: args.businessName,
            businessLogoUrl: args.businessLogoUrl ?? '',
            category: args.category ?? 'Genel',
          ),
          permissionKey: 'campaignWrite',
        );
      case AppRoutes.bulkMessageCreate:
        final args = settings.arguments;
        if (args is BusinessCampaignToolRouteArgs) {
          return _corporatePage(
            settings,
            BulkMessageCreatePage(
              businessId: args.businessId,
              businessName: args.businessName ?? 'İşletme',
              initialAudience: args.initialAudience,
              initialEstimatedTargetCount: args.initialEstimatedTargetCount,
              audienceMetadata: args.audienceMetadata,
            ),
            permissionKey: 'bulkMessage',
          );
        }
        return _corporatePage(
          settings,
          const BulkMessageCreatePage(),
          permissionKey: 'bulkMessage',
        );
      case AppRoutes.campaignAiCreate:
        final args = settings.arguments;
        if (args is BusinessCampaignToolRouteArgs) {
          return _corporatePage(
            settings,
            CampaignAiCreateSafePage(
              businessId: args.businessId,
              businessName: args.businessName ?? 'İşletme',
            ),
            permissionKey: 'campaignWrite',
          );
        }
        return _corporatePage(
          settings,
          const CampaignAiCreateSafePage(),
          permissionKey: 'campaignWrite',
        );
      case AppRoutes.customerAppointments:
        return _page(settings, const CustomerAppointmentsPage());
      case AppRoutes.explore:
        return _page(settings, const _ExploreRouteHost());
      case AppRoutes.legalDocuments:
        return _page(settings, const LegalDocumentsPage());
      case AppRoutes.legalDocumentDetail:
        final args = settings.arguments;
        if (args is! LegalDocumentDetailRouteArgs) {
          return _badArgs(settings);
        }
        return _page(
          settings,
          LegalDocumentDetailPage(document: args.document),
        );
      case AppRoutes.login:
        return _page(settings, const FixLoginGatePage());
      case AppRoutes.messageThread:
        final args = settings.arguments;
        if (args is! MessageThreadRouteArgs || args.threadId.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _page(
          settings,
          MessageThreadPage(
            threadId: args.threadId,
            isBusinessOwner: args.isBusinessOwner,
            currentUid: args.currentUid,
            currentName: args.currentName,
          ),
        );
      case AppRoutes.messagesInbox:
        return _page(settings, const MessagesInboxPage());
      case AppRoutes.messagesNewCustomer:
        final args = settings.arguments;
        if (args is NewCustomerMessageRouteArgs) {
          return _page(
            settings,
            NewCustomerMessagePage(
              initialBusinessId: args.initialBusinessId,
              initialBusinessName: args.initialBusinessName,
              initialBusinessCategory: args.initialBusinessCategory,
            ),
          );
        }
        return _page(settings, const NewCustomerMessagePage());
      case AppRoutes.businessCustomerDirectMessage:
        final args = settings.arguments;
        if (args is! BusinessCustomerDirectMessageRouteArgs ||
            args.businessId.trim().isEmpty ||
            args.customerUid.trim().isEmpty) {
          return _badArgs(settings);
        }
        return _corporatePage(
          settings,
          BusinessCustomerDirectMessagePage(
            businessId: args.businessId,
            businessName: args.businessName,
            customerUid: args.customerUid,
            customerName: args.customerName,
            customerEmail: args.customerEmail,
            customerPhone: args.customerPhone,
          ),
          permissionKey: 'customersRead',
        );
      case AppRoutes.notificationCenter:
        final args = _notificationArgs(settings.arguments);
        return _page(
          settings,
          NotificationCenterPage(
            businessId: args.businessId,
            businessName: args.businessName,
          ),
        );
      case AppRoutes.notificationPreferences:
        return _page(settings, const NotificationPreferencesPage());
      case AppRoutes.phonePasswordReset:
        return _page(settings, const PhonePasswordResetFlowPage());
      case AppRoutes.registeredBusinesses:
        return _page(settings, const RegisteredBusinessesPage());
      case AppRoutes.staffInviteCode:
        return _page(settings, const StaffInviteCodePage());
      case AppRoutes.staffTasks:
        return _page(settings, const StaffTasksEntryPage());
      case AppRoutes.staffWorkspace:
        final args = settings.arguments;
        if (args is! StaffWorkspaceRouteArgs) {
          return _badArgs(settings);
        }
        return _page(
          settings,
          StaffWorkspacePage(
            memberData: args.memberData,
            title: args.title,
            tasksOnly: args.tasksOnly,
          ),
        );
      case AppRoutes.storyViewer:
        final args = settings.arguments;
        if (args is! BusinessStoryViewerRouteArgs || args.stories.isEmpty) {
          return _badArgs(settings);
        }
        final safeInitialIndex = args.initialIndex
            .clamp(0, args.stories.length - 1)
            .toInt();
        return _page(
          settings,
          BusinessStoryViewerPage(
            stories: args.stories,
            initialIndex: safeInitialIndex,
          ),
        );
    }

    return null;
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return _page(settings, _UnknownRoutePage(routeName: settings.name));
  }

  static MaterialPageRoute<dynamic> _page(
    RouteSettings settings,
    Widget child,
  ) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }

  static MaterialPageRoute<dynamic> _corporatePage(
    RouteSettings settings,
    Widget child, {
    String? permissionKey,
  }) {
    return _page(
      settings,
      SessionRoleGate(
        allowedRoles: const {AppRole.corporateOwner, AppRole.corporateStaff},
        permissionKey: permissionKey,
        title: 'Yetki gerekli',
        description:
            'Bu kurumsal alana eriŞmek iÇin hesabınızda ilgili yetki tanımlı olmalı.',
        child: child,
      ),
    );
  }

  static String? _businessOwnerHubPermission(String? openSection) {
    switch (openSection) {
      case 'customers':
        return 'customersRead';
      case 'staff':
        return 'staffManage';
      case 'services':
        return 'servicesManage';
      case 'products':
        return 'productsManage';
      case 'finance':
      case 'pos':
        return 'financeRead';
      case 'campaigns':
      case 'bulkMessage':
      case 'bulkMessages':
      case 'stories':
        return 'campaignRead';
      case 'appointmentManagement':
      case 'live':
        return 'appointmentsRead';
      case 'duration':
      case 'logs':
        return 'managementRead';
    }
    return 'managementRead';
  }

  static MaterialPageRoute<dynamic> _badArgs(RouteSettings settings) {
    return _page(settings, _RouteArgumentErrorPage(routeName: settings.name));
  }

  static NotificationCenterRouteArgs _notificationArgs(Object? rawArgs) {
    if (rawArgs is NotificationCenterRouteArgs) {
      return rawArgs;
    }

    if (rawArgs is Map) {
      return NotificationCenterRouteArgs(
        businessId: _nonEmpty(rawArgs['businessId']),
        businessName: _nonEmpty(rawArgs['businessName']),
      );
    }

    return const NotificationCenterRouteArgs();
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class _RouteArgumentErrorPage extends StatelessWidget {
  const _RouteArgumentErrorPage({required this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RxColors.background,
      appBar: AppBar(title: const Text('Sayfa acilamadi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 44,
                color: RxColors.warning,
              ),
              const SizedBox(height: 14),
              const Text(
                'Bu sayfa icin gerekli bilgi eksik.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: RxColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                routeName ?? 'bilinmeyen rota',
                textAlign: TextAlign.center,
                style: const TextStyle(color: RxColors.muted),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Geri don'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreRouteHost extends StatelessWidget {
  const _ExploreRouteHost();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7FBFC),
      body: HomeExplorePage(),
    );
  }
}

class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage({required this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final label = routeName?.trim().isNotEmpty == true
        ? routeName!.trim()
        : 'bilinmeyen rota';

    return Scaffold(
      backgroundColor: RxColors.background,
      appBar: AppBar(title: const Text('Sayfa bulunamadi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.route_outlined,
                size: 44,
                color: RxColors.primary,
              ),
              const SizedBox(height: 14),
              const Text(
                'Bu baglanti acilamadi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: RxColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: RxColors.muted),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Geri don'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
