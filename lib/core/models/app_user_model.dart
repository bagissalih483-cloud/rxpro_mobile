import '../firestore/firestore_fields.dart';
import '../session/app_role.dart';
import '../session/session_role_policy.dart';

import 'auth_status_model.dart';

/// 49D-F1: AppUserModel legacy UserRole DTO olarak korunur.
/// Yeni rol kararları AppRole/SessionRolePolicy üzerinden çözülür; fromMap
/// yeni canonical role değerlerini legacy UserRole'a güvenli şekilde map eder.
class AppUserModel {
  final String uid;
  final String email;
  final String phone;
  final String displayName;
  final UserRole role;
  final AccountStatus accountStatus;
  final bool emailVerified;
  final bool phoneVerified;

  const AppUserModel({
    required this.uid,
    required this.email,
    required this.phone,
    required this.displayName,
    required this.role,
    required this.accountStatus,
    required this.emailVerified,
    required this.phoneVerified,
  });

  bool get canUseProtectedActions {
    return phoneVerified && accountStatus == AccountStatus.active;
  }

  AppUserModel copyWith({
    String? uid,
    String? email,
    String? phone,
    String? displayName,
    UserRole? role,
    AccountStatus? accountStatus,
    bool? emailVerified,
    bool? phoneVerified,
  }) {
    return AppUserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreFields.uid: uid,
      FirestoreFields.email: email,
      FirestoreFields.phone: phone,
      FirestoreFields.displayName: displayName,
      FirestoreFields.role: role.name,
      FirestoreFields.accountStatus: accountStatus.name,
      FirestoreFields.emailVerified: emailVerified,
      FirestoreFields.phoneVerified: phoneVerified,
      FirestoreFields.createdAt: DateTime.now().toIso8601String(),
      FirestoreFields.updatedAt: DateTime.now().toIso8601String(),
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      uid: map[FirestoreFields.uid]?.toString() ?? '',
      email: map[FirestoreFields.email]?.toString() ?? '',
      phone: map[FirestoreFields.phone]?.toString() ?? '',
      displayName: map[FirestoreFields.displayName]?.toString() ?? '',
      role: _userRoleFromMap(map),
      accountStatus: AccountStatus.values.firstWhere(
        (item) => item.name == map[FirestoreFields.accountStatus],
        orElse: () => AccountStatus.pendingVerification,
      ),
      emailVerified: map[FirestoreFields.emailVerified] == true,
      phoneVerified: map[FirestoreFields.phoneVerified] == true,
    );
  }

  static UserRole _userRoleFromMap(Map<String, dynamic> map) {
    final canonicalRole = SessionRolePolicy.resolveCanonicalRole(map);

    switch (canonicalRole) {
      case AppRole.guest:
        return UserRole.guest;
      case AppRole.individual:
        return UserRole.customer;
      case AppRole.corporateOwner:
        return UserRole.businessOwner;
      case AppRole.corporateStaff:
        return UserRole.staff;
      case AppRole.admin:
        return UserRole.admin;
      case AppRole.invalid:
        break;
    }

    return _userRoleFromLegacyString(
      _firstNonEmpty([
        map[FirestoreFields.role],
        map[FirestoreFields.legacyRole],
        map[FirestoreFields.userRole],
        map[FirestoreFields.activeRole],
        map[FirestoreFields.accountType],
        map[FirestoreFields.userType],
        map[FirestoreFields.accountKind],
      ]),
    );
  }

  static UserRole _userRoleFromLegacyString(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('_', '');

    if (normalized == 'guest' || normalized == 'misafir') {
      return UserRole.guest;
    }

    if (normalized == 'individual' ||
        normalized == 'customer' ||
        normalized == 'client' ||
        normalized == 'user' ||
        normalized == 'bireysel' ||
        normalized == 'bireyselkullanici' ||
        normalized == 'bireyselkullanıcı' ||
        normalized == 'musteri' ||
        normalized == 'müşteri') {
      return UserRole.customer;
    }

    if (normalized == 'corporateowner' ||
        normalized == 'businessowner' ||
        normalized == 'owner' ||
        normalized == 'business' ||
        normalized == 'kurumsal' ||
        normalized == 'kurumsalkullanici' ||
        normalized == 'kurumsalkullanıcı' ||
        normalized == 'isletmesahibi' ||
        normalized == 'işletmesahibi') {
      return UserRole.businessOwner;
    }

    if (normalized == 'corporatestaff' ||
        normalized == 'linkedstaff' ||
        normalized == 'businessstaff' ||
        normalized == 'staff' ||
        normalized == 'personel') {
      return UserRole.staff;
    }

    if (normalized == 'admin') {
      return UserRole.admin;
    }

    return UserRole.customer;
  }

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return '';
  }
}
