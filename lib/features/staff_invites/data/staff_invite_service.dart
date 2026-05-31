import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffLinkedAccountSummary {
  const StaffLinkedAccountSummary({
    required this.linked,
    this.businessId = '',
    this.businessName = '',
    this.staffDocId = '',
    this.staffName = '',
    this.staffWorkStatus = 'inactive',
  });

  final bool linked;
  final String businessId;
  final String businessName;
  final String staffDocId;
  final String staffName;
  final String staffWorkStatus;

  bool get isWorkActive => staffWorkStatus == 'active';
}

class StaffInviteAcceptResult {
  const StaffInviteAcceptResult({
    required this.success,
    required this.message,
    this.businessId = '',
    this.businessName = '',
    this.staffDocId = '',
  });

  final bool success;
  final String message;
  final String businessId;
  final String businessName;
  final String staffDocId;
}

/// Staff invite service Firestore collection/field literals use
/// FirestoreCollections/FirestoreFields constants.
class StaffInviteService {
  StaffInviteService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<StaffLinkedAccountSummary?> currentLinkedAccount() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snap = await _db
        .collection(FirestoreCollections.businessStaff)
        .where(FirestoreFields.linkedUid, isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    final data = Map<String, dynamic>.from(doc.data());
    final businessId = (data[FirestoreFields.businessId] ?? '')
        .toString()
        .trim();
    final businessName = await _businessNameOf(businessId, data);

    return StaffLinkedAccountSummary(
      linked: true,
      businessId: businessId,
      businessName: businessName,
      staffDocId: doc.id,
      staffName: (data[FirestoreFields.staffName] ?? data['name'] ?? '')
          .toString(),
      staffWorkStatus: (data[FirestoreFields.staffWorkStatus] ?? 'inactive')
          .toString(),
    );
  }

  Future<void> setCurrentLinkedWorkActive(bool active) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snap = await _db
        .collection(FirestoreCollections.businessStaff)
        .where(FirestoreFields.linkedUid, isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;

    final doc = snap.docs.first;
    final data = Map<String, dynamic>.from(doc.data());
    final businessId = (data[FirestoreFields.businessId] ?? '')
        .toString()
        .trim();
    final businessName = await _businessNameOf(businessId, data);
    final now = FieldValue.serverTimestamp();

    await doc.reference.set({
      FirestoreFields.staffWorkStatus: active ? 'active' : 'inactive',
      FirestoreFields.activeWorkSession: active,
      'lastSeenAt': now,
      if (active) 'lastRoleActivatedAt': now,
      if (!active) 'lastRoleDeactivatedAt': now,
      FirestoreFields.updatedAt: now,
    }, SetOptions(merge: true));

    await _db.collection(FirestoreCollections.users).doc(user.uid).set({
      'uid': user.uid,
      FirestoreFields.businessStaffId: doc.id,
      'staffId': doc.id,
      FirestoreFields.linkedBusinessId: businessId,
      'activeBusinessId': businessId,
      FirestoreFields.businessId: businessId,
      'businessName': businessName,
      FirestoreFields.staffName:
          (data[FirestoreFields.staffName] ?? data['name'] ?? '').toString(),
      FirestoreFields.staffWorkStatus: active ? 'active' : 'inactive',
      FirestoreFields.activeWorkSession: active,
      FirestoreFields.activeRole: active ? 'linkedStaff' : 'individual',
      FirestoreFields.accountKind: active ? 'corporate' : 'individual',
      'userType': active ? 'corporate' : 'individual',
      'accountType': active ? 'linkedStaff' : 'individual',
      FirestoreFields.role: active ? 'linkedStaff' : 'individual',
      FirestoreFields.legacyRole: active ? 'staff' : 'customer',
      'isBusiness': active,
      'businessAccount': active,
      'isBusinessOwner': false,
      FirestoreFields.updatedAt: now,
    }, SetOptions(merge: true));
  }

  Future<StaffInviteAcceptResult> acceptInviteCode(String rawCode) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const StaffInviteAcceptResult(
        success: false,
        message:
            'Kurumsal giriş kodunu kullanmak için önce bireysel hesaba giriş yap.',
      );
    }

    final code = rawCode.trim().toUpperCase();
    if (code.length < 4) {
      return const StaffInviteAcceptResult(
        success: false,
        message: 'Geçerli bir kurumsal giriş kodu gir.',
      );
    }

    final snap = await _db
        .collection(FirestoreCollections.businessStaff)
        .where(FirestoreFields.inviteCode, isEqualTo: code)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      return const StaffInviteAcceptResult(
        success: false,
        message:
            'Bu kurumsal giriş koduna ait aktif personel kaydı bulunamadı.',
      );
    }

    final doc = snap.docs.first;
    final data = Map<String, dynamic>.from(doc.data());

    final active = data['isActive'] != false && data['active'] != false;
    if (!active) {
      return const StaffInviteAcceptResult(
        success: false,
        message: 'Bu kurumsal giriş koduna ait personel kaydı pasif durumda.',
      );
    }

    final existingLinkedUid =
        (data[FirestoreFields.linkedUid] ??
                data[FirestoreFields.staffUid] ??
                '')
            .toString()
            .trim();

    if (existingLinkedUid.isNotEmpty && existingLinkedUid != user.uid) {
      return const StaffInviteAcceptResult(
        success: false,
        message:
            'Bu kurumsal giriş kodu başka bir kullanıcı hesabına bağlanmış.',
      );
    }

    final businessId = (data[FirestoreFields.businessId] ?? '')
        .toString()
        .trim();
    if (businessId.isEmpty) {
      return const StaffInviteAcceptResult(
        success: false,
        message: 'Personel kaydında kurumsal kullanıcı bağlantısı eksik.',
      );
    }

    final targetEmail = _firstNonEmpty([
      data[FirestoreFields.staffEmailLower],
      data[FirestoreFields.targetEmail],
      data[FirestoreFields.staffEmail],
      data[FirestoreFields.emailLower],
      data[FirestoreFields.email],
    ]).toLowerCase();

    final currentEmail = (user.email ?? '').trim().toLowerCase();

    if (targetEmail.isNotEmpty) {
      if (currentEmail.isEmpty) {
        return const StaffInviteAcceptResult(
          success: false,
          message:
              'Bu kurumsal giriş kodu e-posta ile doğrulanmalı. Lütfen e-posta hesabıyla giriş yap.',
        );
      }

      if (currentEmail != targetEmail) {
        return const StaffInviteAcceptResult(
          success: false,
          message:
              'Personel kaydındaki e-posta ile giriş yaptığın hesap e-postası eşleşmiyor.',
        );
      }
    }

    final requireVerifiedEmail =
        data['requireVerifiedEmailForInvite'] == true ||
        data['emailVerificationRequired'] == true;

    if (requireVerifiedEmail && user.emailVerified != true) {
      return const StaffInviteAcceptResult(
        success: false,
        message:
            'Bu kurumsal giriş kodu için e-posta doğrulaması gerekli. E-postanı doğrulayıp tekrar dene.',
      );
    }

    final staffName = (data[FirestoreFields.staffName] ?? data['name'] ?? '')
        .toString();
    final businessName = await _businessNameOf(businessId, data);
    final permissions = _permissionsOf(data);
    final now = FieldValue.serverTimestamp();

    await _db.collection(FirestoreCollections.businessStaff).doc(doc.id).set({
      FirestoreFields.linkedUid: user.uid,
      FirestoreFields.staffUid: user.uid,
      FirestoreFields.userUid: user.uid,
      FirestoreFields.linkedAt: now,
      'linkedEmail': user.email,
      FirestoreFields.linkedEmailLower: (user.email ?? '').trim().toLowerCase(),
      FirestoreFields.linkedEmailVerified: user.emailVerified,
      'linkedPhone': user.phoneNumber,
      FirestoreFields.staffLinkStatus: 'linked',
      FirestoreFields.staffWorkStatus: 'inactive',
      FirestoreFields.activeWorkSession: false,
      'lastSeenAt': now,
      'lastRoleDeactivatedAt': now,
      FirestoreFields.updatedAt: now,
    }, SetOptions(merge: true));

    await _db.collection(FirestoreCollections.users).doc(user.uid).set({
      'uid': user.uid,

      // Kurumsal giriş kodu bağlantıyı kurar ama görev akışını otomatik açmaz.
      // Kullanıcı "Aktif Et" butonuna basınca linkedStaff shell aktif olur.
      FirestoreFields.accountKind: 'individual',
      'userType': 'individual',
      'accountType': 'individual',
      FirestoreFields.activeRole: 'individual',
      FirestoreFields.role: 'individual',
      FirestoreFields.legacyRole: 'customer',
      'isBusiness': false,
      'isBusinessOwner': false,
      'businessAccount': false,
      FirestoreFields.staffWorkStatus: 'inactive',
      FirestoreFields.activeWorkSession: false,
      FirestoreFields.businessStaffId: doc.id,
      'staffId': doc.id,
      'staffBusinessId': businessId,
      FirestoreFields.linkedBusinessId: businessId,
      'activeBusinessId': businessId,
      FirestoreFields.businessId: businessId,
      'businessName': businessName,
      FirestoreFields.staffName: staffName,
      FirestoreFields.permissions: permissions,
      'linkedBusinesses': FieldValue.arrayUnion([
        {
          FirestoreFields.businessId: businessId,
          'businessName': businessName,
          FirestoreFields.businessStaffId: doc.id,
          FirestoreFields.role: (data[FirestoreFields.role] ?? 'staff')
              .toString(),
          FirestoreFields.linkedAt: DateTime.now().toIso8601String(),
        },
      ]),
      FirestoreFields.updatedAt: now,
    }, SetOptions(merge: true));

    await _db.collection('businessActivityLogs').add({
      FirestoreFields.businessId: businessId,
      'type': 'staff_invite_accepted',
      'title': 'Kurumsal giriş kodu kabul edildi',
      FirestoreFields.staffName: staffName,
      'staffDocId': doc.id,
      FirestoreFields.linkedUid: user.uid,
      FirestoreFields.createdAt: now,
    });

    return StaffInviteAcceptResult(
      success: true,
      message: 'Kurumsal giriş bağlantısı tamamlandı.',
      businessId: businessId,
      businessName: businessName,
      staffDocId: doc.id,
    );
  }

  String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Future<String> _businessNameOf(
    String businessId,
    Map<String, dynamic> staffData,
  ) async {
    final direct = (staffData['businessName'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;

    for (final collection in const [
      'businesses',
      'registeredBusinesses',
      'businessProfiles',
    ]) {
      final doc = await _db.collection(collection).doc(businessId).get();
      final data = doc.data();
      if (data == null) continue;

      final name =
          (data['businessName'] ??
                  data['name'] ??
                  data['title'] ??
                  data['displayName'] ??
                  '')
              .toString()
              .trim();

      if (name.isNotEmpty) return name;
    }

    return 'Kurumsal kullanıcı';
  }

  Map<String, dynamic> _permissionsOf(Map<String, dynamic> staffData) {
    final raw = staffData['permissions'];
    final permissions = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    for (final entry in staffData.entries) {
      if (entry.value is bool && !permissions.containsKey(entry.key)) {
        permissions[entry.key] = entry.value;
      }
    }

    return permissions;
  }
}
