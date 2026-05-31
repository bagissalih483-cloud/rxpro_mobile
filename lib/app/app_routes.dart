import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/legal/legal_document.dart';
import '../features/stories/business_story_model.dart';

abstract final class AppRoutes {
  static const String accountDeletionRequest = '/legal/account-deletion';
  static const String adminModeration = '/admin/moderation';
  static const String businessOwnerHub = '/business/owner-hub';
  static const String businessProductMovement = '/business/analysis/products';
  static const String businessPos = '/business/pos';
  static const String businessProducts = '/business/products';
  static const String businessProductForm = '/business/products/form';
  static const String businessProfile = '/business/profile';
  static const String businessProfileEdit = '/business/profile/edit';
  static const String businessProfileEditEntry = '/business/profile/edit-entry';
  static const String businessProfilePostCreate =
      '/business/profile/post-create';
  static const String businessServiceForm = '/business/services/form';
  static const String businessExpenseForm = '/business/finance/expense-form';
  static const String businessStaffForm = '/business/staff/form';
  static const String bulkMessageCreate = '/campaigns/bulk-message';
  static const String campaignAiCreate = '/campaigns/ai-create';
  static const String customerAppointments = '/customer/appointments';
  static const String explore = '/explore';
  static const String legalDocuments = '/legal/documents';
  static const String legalDocumentDetail = '/legal/documents/detail';
  static const String login = '/auth/login';
  static const String messageThread = '/messages/thread';
  static const String messagesInbox = '/messages';
  static const String messagesNewCustomer = '/messages/new-customer';
  static const String businessCustomerDirectMessage =
      '/business/customers/direct-message';
  static const String businessCustomers = '/business/customers';
  static const String businessCampaigns = '/business/campaigns';
  static const String businessFinance = '/business/finance';
  static const String businessLiveFlow = '/business/live-flow';
  static const String businessStoryCreate = '/business/stories/create';
  static const String notificationCenter = '/notifications';
  static const String notificationPreferences = '/notifications/preferences';
  static const String phonePasswordReset = '/auth/phone-password-reset';
  static const String registeredBusinesses = '/business/registered';
  static const String staffInviteCode = '/staff/invite-code';
  static const String staffTasks = '/staff/tasks';
  static const String staffWorkspace = '/staff/workspace';
  static const String storyViewer = '/stories/viewer';
}

class NotificationCenterRouteArgs {
  const NotificationCenterRouteArgs({this.businessId, this.businessName});

  final String? businessId;
  final String? businessName;
}

class BusinessOwnerHubRouteArgs {
  const BusinessOwnerHubRouteArgs({
    this.businessId,
    this.initialData,
    this.openSection,
  });

  final String? businessId;
  final Map<String, dynamic>? initialData;
  final String? openSection;
}

class BusinessProfileRouteArgs {
  const BusinessProfileRouteArgs({
    required this.businessId,
    required this.businessName,
    required this.category,
  });

  final String businessId;
  final String businessName;
  final String category;
}

class BusinessProfileEditRouteArgs {
  const BusinessProfileEditRouteArgs({required this.businessId});

  final String businessId;
}

class BusinessProfilePostCreateRouteArgs {
  const BusinessProfilePostCreateRouteArgs({
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;
}

class BusinessCampaignToolRouteArgs {
  const BusinessCampaignToolRouteArgs({
    this.businessId,
    this.businessName,
    this.initialAudience,
    this.initialEstimatedTargetCount,
    this.audienceMetadata,
  });

  final String? businessId;
  final String? businessName;
  final String? initialAudience;
  final int? initialEstimatedTargetCount;
  final Map<String, dynamic>? audienceMetadata;
}

class BusinessProductMovementRouteArgs {
  const BusinessProductMovementRouteArgs({
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;
}

class BusinessProductFormRouteArgs {
  const BusinessProductFormRouteArgs({
    required this.businessId,
    required this.businessName,
    this.doc,
  });

  final String businessId;
  final String businessName;
  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;
}

class BusinessCustomerDirectMessageRouteArgs {
  const BusinessCustomerDirectMessageRouteArgs({
    required this.businessId,
    required this.businessName,
    required this.customerUid,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  });

  final String businessId;
  final String businessName;
  final String customerUid;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
}

class BusinessServiceFormRouteArgs {
  const BusinessServiceFormRouteArgs({
    required this.businessId,
    this.businessData = const <String, dynamic>{},
    this.serviceId,
    this.initialData,
  });

  final String businessId;
  final Map<String, dynamic> businessData;
  final String? serviceId;
  final Map<String, dynamic>? initialData;
}

class BusinessExpenseFormRouteArgs {
  const BusinessExpenseFormRouteArgs({
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;
}

class BusinessPageRouteArgs {
  const BusinessPageRouteArgs({
    required this.businessId,
    required this.businessName,
    this.businessLogoUrl,
    this.category,
  });

  final String businessId;
  final String businessName;
  final String? businessLogoUrl;
  final String? category;
}

class BusinessStaffFormRouteArgs {
  const BusinessStaffFormRouteArgs({
    required this.businessId,
    required this.businessAccessCode,
    this.staffId,
    this.initialData,
  });

  final String businessId;
  final String businessAccessCode;
  final String? staffId;
  final Map<String, dynamic>? initialData;
}

class LegalDocumentDetailRouteArgs {
  const LegalDocumentDetailRouteArgs({required this.document});

  final LegalDocument document;
}

class BusinessStoryViewerRouteArgs {
  const BusinessStoryViewerRouteArgs({
    required this.stories,
    required this.initialIndex,
  });

  final List<BusinessStoryModel> stories;
  final int initialIndex;
}

class StaffWorkspaceRouteArgs {
  const StaffWorkspaceRouteArgs({
    required this.memberData,
    this.title = 'Görevlerim',
    this.tasksOnly = false,
  });

  final Map<String, dynamic> memberData;
  final String title;
  final bool tasksOnly;
}

class NewCustomerMessageRouteArgs {
  const NewCustomerMessageRouteArgs({
    this.initialBusinessId,
    this.initialBusinessName,
    this.initialBusinessCategory,
  });

  final String? initialBusinessId;
  final String? initialBusinessName;
  final String? initialBusinessCategory;
}

class MessageThreadRouteArgs {
  const MessageThreadRouteArgs({
    required this.threadId,
    required this.isBusinessOwner,
    required this.currentUid,
    required this.currentName,
  });

  final String threadId;
  final bool isBusinessOwner;
  final String currentUid;
  final String currentName;
}
