import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';
import '../../../core/firestore/firestore_schema_versions.dart';

class FixLoginGateRepository {
  FixLoginGateRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> get _publicProfiles =>
      _firestore.collection(FirestoreCollections.publicProfiles);

  CollectionReference<Map<String, dynamic>> get _businesses =>
      _firestore.collection(FirestoreCollections.businesses);

  Future<void> ensureIndividualUserDocument({
    required User user,
    required String email,
    required String phone,
    required String displayName,
    String city = '',
    String district = '',
    required bool phoneVerified,
    bool recordLegalAcceptance = false,
  }) async {
    final batch = _firestore.batch();
    final userRef = _users.doc(user.uid);
    final publicProfileRef = _publicProfiles.doc(user.uid);

    batch.set(userRef, <String, dynamic>{
      FirestoreFields.uid: user.uid,
      FirestoreFields.email: email,
      FixLoginGateFieldNames.phone: phone,
      FirestoreFields.displayName: displayName,
      FirestoreFields.city: city.trim(),
      FirestoreFields.district: district.trim(),
      FirestoreFields.role: FixLoginGateRoleValues.individual,
      FirestoreFields.legacyRole: FixLoginGateRoleValues.customer,
      FirestoreFields.accountKind: FixLoginGateRoleValues.individual,
      FirestoreFields.userType: FixLoginGateRoleValues.individual,
      FirestoreFields.accountType: FixLoginGateRoleValues.individual,
      FirestoreFields.activeRole: FixLoginGateRoleValues.individual,
      FirestoreFields.isBusiness: false,
      FirestoreFields.businessAccount: false,
      FirestoreFields.isBusinessOwner: false,
      FirestoreFields.roleSchemaVersion: FirestoreSchemaVersions.role49dC,
      FirestoreFields.roleUpdatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.businessId: FieldValue.delete(),
      FirestoreFields.ownedBusinessId: FieldValue.delete(),
      FirestoreFields.activeBusinessId: FieldValue.delete(),
      FixLoginGateFieldNames.selectedBusinessId: FieldValue.delete(),
      FixLoginGateFieldNames.staffBusinessId: FieldValue.delete(),
      FirestoreFields.businessName: FieldValue.delete(),
      FixLoginGateFieldNames.permissions: FieldValue.delete(),
      FixLoginGateFieldNames.phoneVerified: phoneVerified,
      FirestoreFields.sourceModule:
          FixLoginGateFieldNames.sourceModule53uIndividual,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      if (recordLegalAcceptance) ...FixLoginGateLegalAcceptanceFields.accepted(),
    }, SetOptions(merge: true));

    batch.set(publicProfileRef, <String, dynamic>{
      FirestoreFields.uid: user.uid,
      FirestoreFields.displayName: displayName,
      FirestoreFields.city: city.trim(),
      FirestoreFields.district: district.trim(),
      FirestoreFields.accountKind: FixLoginGateRoleValues.individual,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> ensureCorporateBusinessDocument({
    required User user,
    required String businessId,
    required String businessName,
    String city = '',
    String district = '',
    Map<String, dynamic> categoryData = const <String, dynamic>{},
  }) async {
    final safeBusinessName = businessName.trim().isEmpty
        ? 'Kurumsal Kullanıcı'
        : businessName.trim();

    await _businesses.doc(businessId).set(<String, dynamic>{
      ...categoryData,
      FirestoreFields.ownerUid: user.uid,
      FirestoreFields.businessName: safeBusinessName,
      FirestoreFields.city: city.trim(),
      FirestoreFields.district: district.trim(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> ensureCorporateOwnerUserDocument({
    required User user,
    required String email,
    required String phone,
    required String businessId,
    required String businessName,
    required String ownerName,
    String city = '',
    String district = '',
    required bool phoneVerified,
    bool recordLegalAcceptance = false,
  }) async {
    final safeBusinessName = businessName.trim().isEmpty
        ? 'Kurumsal Kullanıcı'
        : businessName.trim();

    final safeOwnerName = ownerName.trim().isEmpty
        ? 'Kurumsal Yetkili'
        : ownerName.trim();

    final batch = _firestore.batch();
    final userRef = _users.doc(user.uid);
    final publicProfileRef = _publicProfiles.doc(user.uid);

    batch.set(userRef, <String, dynamic>{
      FirestoreFields.uid: user.uid,
      FirestoreFields.email: email,
      FixLoginGateFieldNames.phone: phone,
      FirestoreFields.displayName: safeOwnerName,
      FirestoreFields.city: city.trim(),
      FirestoreFields.district: district.trim(),
      FirestoreFields.role: FixLoginGateRoleValues.corporateOwner,
      FirestoreFields.legacyRole: FixLoginGateRoleValues.businessOwner,
      FirestoreFields.accountKind: FixLoginGateRoleValues.corporate,
      FirestoreFields.userType: FixLoginGateRoleValues.corporate,
      FirestoreFields.accountType: FixLoginGateRoleValues.corporateOwner,
      FirestoreFields.activeRole: FixLoginGateRoleValues.owner,
      FirestoreFields.isBusiness: true,
      FirestoreFields.businessAccount: true,
      FirestoreFields.isBusinessOwner: true,
      FirestoreFields.roleSchemaVersion: FirestoreSchemaVersions.role49dC,
      FirestoreFields.roleUpdatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.businessId: businessId,
      FirestoreFields.ownedBusinessId: businessId,
      FirestoreFields.activeBusinessId: businessId,
      FixLoginGateFieldNames.selectedBusinessId: businessId,
      FixLoginGateFieldNames.staffBusinessId: FieldValue.delete(),
      FirestoreFields.businessName: safeBusinessName,
      FixLoginGateFieldNames.permissions: FieldValue.delete(),
      FixLoginGateFieldNames.phoneVerified: phoneVerified,
      FirestoreFields.sourceModule:
          FixLoginGateFieldNames.sourceModule53uCorporate,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      if (recordLegalAcceptance) ...FixLoginGateLegalAcceptanceFields.accepted(),
    }, SetOptions(merge: true));

    batch.set(publicProfileRef, <String, dynamic>{
      FirestoreFields.uid: user.uid,
      FirestoreFields.displayName: safeOwnerName,
      FirestoreFields.city: city.trim(),
      FirestoreFields.district: district.trim(),
      FirestoreFields.accountKind: FixLoginGateRoleValues.corporate,
      FirestoreFields.businessId: businessId,
      FirestoreFields.businessName: safeBusinessName,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<FixLoginGateBusinessContext> resolveCorporateBusinessContext({
    required User user,
    String fallbackBusinessName = 'Kurumsal Kullanici',
  }) async {
    final fallbackId = 'business_${user.uid}';
    var userData = const <String, dynamic>{};

    try {
      final userDoc = await _users.doc(user.uid).get();
      userData = Map<String, dynamic>.from(userDoc.data() ?? {});

      final candidateIds = <String>[
        userData[FirestoreFields.activeBusinessId]?.toString() ?? '',
        userData[FirestoreFields.ownedBusinessId]?.toString() ?? '',
        userData[FirestoreFields.businessId]?.toString() ?? '',
        userData[FixLoginGateFieldNames.selectedBusinessId]?.toString() ?? '',
        userData[FixLoginGateFieldNames.businessDocId]?.toString() ?? '',
      ].where((value) => value.trim().isNotEmpty).toSet().toList();

      for (final businessId in candidateIds) {
        final businessDoc = await _businesses.doc(businessId).get();
        final businessData = businessDoc.data();

        if (businessDoc.exists && businessData != null) {
          return FixLoginGateBusinessContext(
            businessId: businessDoc.id,
            businessName: _resolvedBusinessName(
              businessData,
              userData,
              fallbackBusinessName,
            ),
          );
        }
      }
    } catch (_) {
      // Fall through to ownerUid lookup.
    }

    try {
      final snapshot = await _businesses
          .where(FirestoreFields.ownerUid, isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return FixLoginGateBusinessContext(
          businessId: doc.id,
          businessName: _resolvedBusinessName(
            doc.data(),
            userData,
            fallbackBusinessName,
          ),
        );
      }
    } catch (_) {
      // Fall through to deterministic fallback.
    }

    return FixLoginGateBusinessContext(
      businessId: fallbackId,
      businessName: _resolvedBusinessName(
        userData,
        const <String, dynamic>{},
        fallbackBusinessName,
      ),
    );
  }

  static String _resolvedBusinessName(
    Map<String, dynamic> primary, [
    Map<String, dynamic> secondary = const <String, dynamic>{},
    String fallback = 'Kurumsal Kullanici',
  ]) {
    return _firstNonEmpty(<dynamic>[
      primary[FirestoreFields.businessName],
      primary[FirestoreFields.name],
      primary[FixLoginGateFieldNames.title],
      secondary[FirestoreFields.businessName],
      secondary[FirestoreFields.displayName],
      fallback,
    ], fallback);
  }

  static String _firstNonEmpty(List<dynamic> values, [String fallback = '']) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return fallback;
  }
}

class FixLoginGateBusinessContext {
  const FixLoginGateBusinessContext({
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;
}

class FixLoginGateRoleValues {
  const FixLoginGateRoleValues._();

  static const individual = 'individual';
  static const customer = 'customer';
  static const corporate = 'corporate';
  static const corporateOwner = 'corporateOwner';
  static const businessOwner = 'businessOwner';
  static const owner = 'owner';
}

class FixLoginGateFieldNames {
  const FixLoginGateFieldNames._();

  static const phone = 'phone';
  static const displayName = 'displayName';
  static const phoneVerified = 'phoneVerified';
  static const ownerEmail = 'ownerEmail';
  static const ownerPhone = 'ownerPhone';
  static const adminApproved = 'adminApproved';
  static const businessDocId = 'businessDocId';
  static const title = 'title';
  static const selectedBusinessId = 'selectedBusinessId';
  static const staffBusinessId = 'staffBusinessId';
  static const permissions = 'permissions';
  static const sourceModule53uIndividual =
      'fix_login_gate_repository_53U_individual';
  static const sourceModule53uCorporate =
      'fix_login_gate_repository_53U_corporate';
}

class FixLoginGateLegalAcceptanceFields {
  const FixLoginGateLegalAcceptanceFields._();

  static const legalVersion = '2026-05-29-draft-v1';

  static Map<String, dynamic> accepted() {
    return <String, dynamic>{
      'legalAccepted': true,
      'legalAcceptedAt': FieldValue.serverTimestamp(),
      'legalVersion': legalVersion,
      'kvkkNoticeAccepted': true,
      'termsAccepted': true,
      'privacyPolicyAccepted': true,
      'explicitConsentAccepted': true,
      'legalAcceptanceSource': 'fix_login_gate',
    };
  }
}
