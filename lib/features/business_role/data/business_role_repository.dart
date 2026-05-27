import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/session/app_role.dart';
import 'package:rxpro_mobile/core/session/session_role_policy.dart';
import 'package:rxpro_mobile/features/business_role/business_role_result.dart';

class BusinessRoleRepository {
  BusinessRoleRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<BusinessRoleResult> resolveCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return const BusinessRoleResult.customer();

    return resolveByUid(user.uid);
  }

  Future<BusinessRoleResult> resolveByUid(String uid) async {
    var userData = <String, dynamic>{};

    try {
      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();
      userData = Map<String, dynamic>.from(userDoc.data() ?? {});
    } catch (_) {}

    final canonicalRole = SessionRolePolicy.resolveCanonicalRole(userData);
    final explicitCorporate =
        canonicalRole == AppRole.corporateOwner ||
        canonicalRole == AppRole.corporateStaff;

    final candidateIds = <String>[
      (userData[FirestoreFields.activeBusinessId] ?? '').toString(),
      (userData[FirestoreFields.ownedBusinessId] ?? '').toString(),
      (userData[FirestoreFields.businessId] ?? '').toString(),
      (userData[FirestoreFields.selectedBusinessId] ?? '').toString(),
      (userData[FirestoreFields.staffBusinessId] ?? '').toString(),
      (userData[FirestoreFields.linkedBusinessId] ?? '').toString(),
    ].where((e) => e.trim().isNotEmpty).toSet().toList();

    if (explicitCorporate) {
      for (final id in candidateIds) {
        final business = await _tryBusinessById(id);
        if (business != null) return business;
      }

      final owned = await _tryBusinessByOwner(uid);
      if (owned != null) return owned;

      return BusinessRoleResult.business(
        businessId: candidateIds.isNotEmpty
            ? candidateIds.first
            : 'business_$uid',
        businessName: _businessName(userData),
        businessData: userData,
      );
    }

    return const BusinessRoleResult.customer();
  }

  Future<BusinessRoleResult?> _tryBusinessById(String id) async {
    for (final collection in const [
      FirestoreCollections.businesses,
      FirestoreCollections.businessProfiles,
      FirestoreCollections.registeredBusinesses,
    ]) {
      try {
        final doc = await _firestore.collection(collection).doc(id).get();
        if (!doc.exists) continue;

        final data = Map<String, dynamic>.from(doc.data() ?? {});
        return BusinessRoleResult.business(
          businessId: (data[FirestoreFields.businessId] ?? doc.id).toString(),
          businessName: _businessName(data),
          businessData: data,
        );
      } catch (_) {}
    }

    return null;
  }

  Future<BusinessRoleResult?> _tryBusinessByOwner(String uid) async {
    for (final collection in const [
      FirestoreCollections.businesses,
      FirestoreCollections.businessProfiles,
      FirestoreCollections.registeredBusinesses,
    ]) {
      for (final field in const [
        FirestoreFields.ownerUid,
        FirestoreFields.ownerId,
        FirestoreFields.businessOwnerUid,
      ]) {
        try {
          final snap = await _firestore
              .collection(collection)
              .where(field, isEqualTo: uid)
              .limit(1)
              .get();

          if (snap.docs.isEmpty) continue;

          final doc = snap.docs.first;
          final data = Map<String, dynamic>.from(doc.data());

          return BusinessRoleResult.business(
            businessId: (data[FirestoreFields.businessId] ?? doc.id).toString(),
            businessName: _businessName(data),
            businessData: data,
          );
        } catch (_) {}
      }
    }

    return null;
  }

  static String _businessName(Map<String, dynamic> data) {
    return (data[FirestoreFields.businessName] ??
            data[FirestoreFields.name] ??
            data[FirestoreFields.title] ??
            data[FirestoreFields.displayName] ??
            'İşletme')
        .toString();
  }
}
