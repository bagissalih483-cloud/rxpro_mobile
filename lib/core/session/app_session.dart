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
    return permissions[key] == true;
  }
}
