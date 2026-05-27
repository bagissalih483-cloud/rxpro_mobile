import '../firestore/firestore_fields.dart';

import 'app_role.dart';

/// 49D-B:
/// Rol/mod kararını tek noktaya toplar.
/// Bu policy UI shell, AppSession ve AccountModeResolver arasında
/// farklılaşan legacy alan yorumlarını merkezileştirir.
///
/// Hedef standart:
/// - accountKind: individual / corporate
/// - activeRole: individual / owner / linkedStaff
/// - businessStaffId: businessStaff doküman ID'si
/// - linkedUid: businessStaff tarafında bağlı kullanıcı UID'si
/// - staffWorkStatus veya activeWorkSession pasifse linked staff bireysel modda kalır.
class SessionRolePolicy {
  const SessionRolePolicy._();

  static AppRole resolveCanonicalRole(Map<String, dynamic> data) {
    final accountKind = norm(data[FirestoreFields.accountKind]);
    final userType = norm(data[FirestoreFields.userType]);
    final accountType = norm(data[FirestoreFields.accountType]);
    final role = norm(data[FirestoreFields.role]);
    final legacyRole = norm(data[FirestoreFields.legacyRole]);
    final activeRole = norm(data[FirestoreFields.activeRole]);
    final staffWorkStatus = norm(data[FirestoreFields.staffWorkStatus]);

    final linkedStaffSignal =
        role == 'linkedstaff' ||
        role == 'businessstaff' ||
        role == 'corporatestaff' ||
        accountType == 'linkedstaff' ||
        accountType == 'businessstaff' ||
        accountType == 'corporatestaff' ||
        legacyRole == 'linkedstaff' ||
        legacyRole == 'businessstaff' ||
        activeRole == 'linkedstaff' ||
        text(data[FirestoreFields.businessStaffId]).isNotEmpty ||
        text(data[FirestoreFields.staffBusinessId]).isNotEmpty ||
        text(data[FirestoreFields.linkedBusinessId]).isNotEmpty;

    final inactiveLinkedStaffSession =
        linkedStaffSignal &&
        (data[FirestoreFields.activeWorkSession] == false ||
            staffWorkStatus == 'inactive' ||
            activeRole == 'individual');

    if (inactiveLinkedStaffSession) {
      return AppRole.individual;
    }

    // 1) En güçlü modern kaynak: accountKind.
    // accountKind varsa eski businessId/boolean kalıntıları tek başına shell değiştirmemeli.
    if (accountKind == 'individual') return AppRole.individual;

    if (accountKind == 'corporate') {
      if (isStaffSignal(
        role: role,
        accountType: accountType,
        legacyRole: legacyRole,
        activeRole: activeRole,
      )) {
        return AppRole.corporateStaff;
      }

      return AppRole.corporateOwner;
    }

    // 2) İkinci kaynak: userType.
    if (userType == 'individual') return AppRole.individual;

    if (userType == 'corporate') {
      if (isStaffSignal(
        role: role,
        accountType: accountType,
        legacyRole: legacyRole,
        activeRole: activeRole,
      )) {
        return AppRole.corporateStaff;
      }

      return AppRole.corporateOwner;
    }

    // 3) Modern role / accountType / activeRole.
    if (role == 'individual' ||
        activeRole == 'individual' ||
        accountType == 'individual') {
      return AppRole.individual;
    }

    if (role == 'corporateowner' ||
        role == 'businessowner' ||
        activeRole == 'owner' ||
        activeRole == 'corporateowner' ||
        accountType == 'corporateowner' ||
        accountType == 'businessowner') {
      return AppRole.corporateOwner;
    }

    if (isStaffSignal(
      role: role,
      accountType: accountType,
      legacyRole: legacyRole,
      activeRole: activeRole,
    )) {
      return AppRole.corporateStaff;
    }

    // 4) Geriye uyumluluk.
    if (role == 'customer' ||
        legacyRole == 'customer' ||
        role == 'musteri' ||
        role == 'müşteri') {
      return AppRole.individual;
    }

    if (role == 'businessowner' ||
        legacyRole == 'businessowner' ||
        truthy(data[FirestoreFields.isBusinessOwner]) ||
        truthy(data[FirestoreFields.businessAccount]) ||
        truthy(data[FirestoreFields.isBusiness])) {
      return AppRole.corporateOwner;
    }

    return AppRole.invalid;
  }

  static bool hasOwnerAuthority({
    required String uid,
    required Map<String, dynamic> userData,
    Map<String, dynamic> businessData = const <String, dynamic>{},
  }) {
    if (truthy(userData['isBusinessOwner']) ||
        truthy(userData['isOwner']) ||
        truthy(userData['owner']) ||
        truthy(userData['ownerAuthority']) ||
        truthy(userData['businessOwner']) ||
        truthy(userData['businessAccountOwner'])) {
      return true;
    }

    for (final value in <Object?>[
      userData['role'],
      userData['legacyRole'],
      userData['accountType'],
      userData['userType'],
      userData['accountKind'],
      userData['staffRole'],
      userData['roleLabel'],
      userData['activeRole'],
      businessData['role'],
      businessData['ownerRole'],
    ]) {
      final role = norm(value);
      if (role == 'businessowner' ||
          role == 'corporateowner' ||
          role == 'owner' ||
          role == 'admin' ||
          role == 'kurumsalyetkili' ||
          role == 'işletmesahibi' ||
          role == 'isletmesahibi') {
        return true;
      }
    }

    for (final value in <Object?>[
      userData['ownerUid'],
      userData['ownerId'],
      userData['businessOwnerUid'],
      userData['createdByUid'],
      userData['createdBy'],
      businessData['ownerUid'],
      businessData['ownerId'],
      businessData['businessOwnerUid'],
      businessData['createdByUid'],
      businessData['createdBy'],
      businessData['uid'],
    ]) {
      if (uidMatches(uid, value)) return true;
    }

    return false;
  }

  static bool isStaffSignal({
    required String role,
    required String accountType,
    required String legacyRole,
    required String activeRole,
  }) {
    return role == 'corporatestaff' ||
        role == 'linkedstaff' ||
        role == 'businessstaff' ||
        role == 'staff' ||
        legacyRole == 'staff' ||
        legacyRole == 'linkedstaff' ||
        legacyRole == 'businessstaff' ||
        accountType == 'corporatestaff' ||
        accountType == 'linkedstaff' ||
        accountType == 'businessstaff' ||
        accountType == 'staff' ||
        activeRole == 'linkedstaff';
  }

  static bool truthy(Object? value) {
    if (value == true) return true;
    final valueText = norm(value);
    return valueText == 'true' ||
        valueText == '1' ||
        valueText == 'yes' ||
        valueText == 'owner' ||
        valueText == 'admin' ||
        valueText == 'businessowner' ||
        valueText == 'corporateowner' ||
        valueText == 'kurumsalyetkili' ||
        valueText == 'kurumsalkullanıcı' ||
        valueText == 'kurumsalkullanici' ||
        valueText == 'işletmesahibi' ||
        valueText == 'isletmesahibi';
  }

  static bool uidMatches(String uid, Object? value) {
    final left = norm(uid);
    final right = norm(value);
    return left.isNotEmpty && left == right;
  }

  static String text(Object? value) {
    return (value ?? '').toString().trim();
  }

  static String norm(Object? value) {
    return text(value)
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .trim();
  }
}
