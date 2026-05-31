import 'app_role.dart';
import 'session_role_policy.dart';

class AppSession {
  const AppSession({
    required this.role,
    required this.isAuthenticated,
    required this.uid,
    required this.email,
    required this.displayName,
    required this.businessId,
    required this.businessName,
    required this.userData,
    required this.businessData,
    required this.permissions,
    required this.message,
  });

  const AppSession.unauthenticated()
    : role = AppRole.guest,
      isAuthenticated = false,
      uid = '',
      email = '',
      displayName = 'Misafir',
      businessId = '',
      businessName = '',
      userData = const {},
      businessData = const {},
      permissions = const {},
      message = '';

  const AppSession.guest()
    : role = AppRole.guest,
      isAuthenticated = false,
      uid = '',
      email = '',
      displayName = 'Misafir',
      businessId = '',
      businessName = '',
      userData = const {},
      businessData = const {},
      permissions = const {},
      message = '';

  const AppSession.invalid({
    required this.uid,
    required this.email,
    required this.message,
    this.userData = const {},
  }) : role = AppRole.invalid,
       isAuthenticated = true,
       displayName = 'Rol Hatası',
       businessId = '',
       businessName = '',
       businessData = const {},
       permissions = const {};

  final AppRole role;
  final bool isAuthenticated;
  final String uid;
  final String email;
  final String displayName;
  final String businessId;
  final String businessName;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> businessData;
  final Map<String, dynamic> permissions;
  final String message;

  bool get isGuest => role == AppRole.guest;
  bool get isIndividual => role == AppRole.individual;
  bool get isCorporate {
    return role == AppRole.corporateOwner || role == AppRole.corporateStaff;
  }

  bool get isCorporateOwner => role == AppRole.corporateOwner;
  bool get isCorporateStaff => role == AppRole.corporateStaff;
  bool get isInvalid => role == AppRole.invalid;

  bool get hasOwnerAuthority {
    if (role == AppRole.corporateOwner || role == AppRole.admin) return true;

    return SessionRolePolicy.hasOwnerAuthority(
      uid: uid,
      userData: userData,
      businessData: businessData,
    );
  }

  bool hasPermission(String key) {
    if (hasOwnerAuthority) return true;
    if (permissions[key] == true) return true;

    final aliases = _permissionAliases[key] ?? const <String>[];
    for (final alias in aliases) {
      if (permissions[alias] == true || userData[alias] == true) return true;
    }

    return false;
  }

  static const Map<String, List<String>> _permissionAliases = {
    'managementRead': [
      'customersRead',
      'customersManage',
      'customerManage',
      'staffManage',
      'manageStaff',
      'servicesManage',
      'manageServices',
      'productsManage',
      'manageProducts',
      'durationRead',
      'activityRead',
    ],
    'customersRead': [
      'customersManage',
      'customerManage',
      'viewCustomers',
      'canViewCustomers',
      'manageCustomers',
      'customerRead',
    ],
    'customersWrite': [
      'customersManage',
      'customerManage',
      'manageCustomers',
      'createCustomers',
      'updateCustomers',
      'canManageCustomers',
    ],
    'appointmentsRead': [
      'viewAppointments',
      'canViewAppointments',
      'workAssignedAppointments',
      'completeAssignedAppointments',
      'appointmentWork',
      'appointmentStartFinish',
    ],
    'appointmentsWrite': [
      'createAppointments',
      'updateAppointments',
      'cancelAppointments',
      'canManageAppointments',
      'canManageAppointmentChanges',
      'manageAppointmentChanges',
      'appointmentManage',
    ],
    'financeRead': [
      'viewFinance',
      'canViewFinance',
      'analysisRead',
      'canViewAnalysis',
      'adisyon.view',
      'adisyon.report',
    ],
    'financeWrite': [
      'enterFinance',
      'canManageFinance',
      'canManageSales',
      'saleProcess',
      'paymentCollect',
      'adisyon.create',
      'adisyon.edit',
      'adisyon.collectPayment',
    ],
    'adisyon.view': [
      'financeRead',
      'viewFinance',
      'canViewFinance',
    ],
    'adisyon.create': [
      'financeWrite',
      'canManageFinance',
      'canManageSales',
    ],
    'adisyon.edit': [
      'financeWrite',
      'canManageFinance',
      'canManageSales',
      'saleProcess',
    ],
    'adisyon.cancel': [
      'financeWrite',
      'saleCancel',
      'canManageFinance',
      'canCancelSales',
    ],
    'adisyon.collectPayment': [
      'financeWrite',
      'paymentCollect',
      'receivableManage',
    ],
    'adisyon.refund': [
      'financeWrite',
      'paymentRefund',
      'canRefundPayments',
      'refundPayments',
    ],
    'adisyon.report': [
      'financeRead',
      'reportsRead',
      'reportExport',
      'canViewFinance',
    ],
    'saleProcess': [
      'financeWrite',
      'adisyon.edit',
      'canManageFinance',
    ],
    'saleCancel': [
      'financeWrite',
      'adisyon.cancel',
      'canCancelSales',
    ],
    'paymentCollect': [
      'financeWrite',
      'adisyon.collectPayment',
      'receivableManage',
    ],
    'paymentRefund': [
      'financeWrite',
      'adisyon.refund',
      'canRefundPayments',
    ],
    'reportsRead': [
      'financeRead',
      'adisyon.report',
      'reportExport',
    ],
    'campaignRead': [
      'canManageCampaigns',
      'manageCampaigns',
      'campaignManage',
      'createPosts',
    ],
    'campaignWrite': [
      'canManageCampaigns',
      'manageCampaigns',
      'campaignManage',
      'createPosts',
    ],
    'bulkMessage': [
      'canManageCampaigns',
      'manageCampaigns',
      'campaignManage',
      'bulkMessageWrite',
      'bulkMessages',
    ],
    'staffManage': [
      'manageStaff',
      'canManageStaff',
      'managePermissions',
    ],
    'servicesManage': [
      'manageServices',
      'canManageServices',
    ],
    'productsManage': [
      'manageProducts',
      'canManageProducts',
      'inventoryManage',
      'stockManage',
    ],
  };
}
