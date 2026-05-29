import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

/// 56N: Repository foundation for BusinessProfileEditEntryPage resolver/gateway.
///
/// This repository is intentionally not wired to the UI in 56N.
/// It mirrors the existing resolver behavior in
/// business_profile_edit_entry_page.dart:
/// - resolve possible business ids from users/{uid}
/// - check direct businesses/{id}
/// - query businesses/businessProfiles/registeredBusinesses by uid/email fields
/// - mirror non-canonical profile docs into businesses/{businessId}
/// - fallback scan businesses with cursor pages
class BusinessProfileEditEntryResolverRepository {
  BusinessProfileEditEntryResolverRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int _fallbackPageSize = 100;
  static const int _fallbackPageCap = 1000;

  final FirebaseFirestore _firestore;

  static String clean(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  bool matchesUserData(
    Map<String, dynamic> data, {
    required String uid,
    String? email,
  }) {
    final normalizedEmail = email?.trim().toLowerCase() ?? '';

    final uidFields = <String>[
      FirestoreFields.ownerUid,
      FirestoreFields.ownerId,
      FirestoreFields.userId,
      FirestoreFields.uid,
      FirestoreFields.createdBy,
      FirestoreFields.creatorUid,
      FirestoreFields.businessOwnerUid,
      FirestoreFields.adminUid,
      FirestoreFields.managerUid,
    ];

    for (final field in uidFields) {
      if (clean(data[field]) == uid) return true;
    }

    final listFields = <String>[
      FirestoreFields.ownerUids,
      FirestoreFields.owners,
      FirestoreFields.adminUids,
      FirestoreFields.admins,
      FirestoreFields.managerUids,
      FirestoreFields.authorizedUids,
    ];

    for (final field in listFields) {
      final value = data[field];
      if (value is Iterable && value.map((e) => e.toString()).contains(uid)) {
        return true;
      }
    }

    if (normalizedEmail.isNotEmpty) {
      final emailFields = <String>[
        FirestoreFields.ownerEmail,
        FirestoreFields.email,
        FirestoreFields.createdByEmail,
        FirestoreFields.contactEmail,
        FirestoreFields.businessEmail,
      ];

      for (final field in emailFields) {
        if (clean(data[field]).toLowerCase() == normalizedEmail) {
          return true;
        }
      }
    }

    return false;
  }

  Future<String?> queryBusinessIdByField({
    required String field,
    required String value,
    required String currentUid,
  }) async {
    for (final collection in <String>[
      FirestoreCollections.businesses,
      FirestoreCollections.businessProfiles,
      FirestoreCollections.registeredBusinesses,
    ]) {
      try {
        final snap = await _firestore
            .collection(collection)
            .where(field, isEqualTo: value)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) continue;

        final doc = snap.docs.first;
        final data = Map<String, dynamic>.from(doc.data());
        final businessId =
            (data[FirestoreFields.businessId] ??
                    data[FirestoreFields.id] ??
                    doc.id)
                .toString();

        if (collection != FirestoreCollections.businesses) {
          await _firestore
              .collection(FirestoreCollections.businesses)
              .doc(businessId)
              .set(<String, dynamic>{
                ...data,
                FirestoreFields.businessId: businessId,
                FirestoreFields.ownerUid:
                    data[FirestoreFields.ownerUid] ?? currentUid,
                FirestoreFields.uid: data[FirestoreFields.uid] ?? currentUid,
                FirestoreFields.mirroredFromCollection: collection,
                FirestoreFields.mirroredFromDocId: doc.id,
                FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }

        return businessId;
      } catch (_) {
        // Preserve existing page behavior: resolver continues with next source.
      }
    }

    return null;
  }

  Future<String?> resolveOwnedBusinessId({
    required String uid,
    String? email,
  }) async {
    try {
      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();

      final userData = userDoc.data() ?? <String, dynamic>{};
      final possibleIds = <dynamic>[
        userData[FirestoreFields.businessId],
        userData[FirestoreFields.ownedBusinessId],
        userData[FirestoreFields.activeBusinessId],
        userData[FirestoreFields.businessDocId],
      ].map(clean).where((e) => e.isNotEmpty).toList();

      for (final id in possibleIds) {
        final doc = await _firestore
            .collection(FirestoreCollections.businesses)
            .doc(id)
            .get();

        if (doc.exists) return doc.id;
      }
    } catch (_) {
      // Preserve existing page behavior: continue resolver chain.
    }

    final uidFields = <String>[
      FirestoreFields.ownerUid,
      FirestoreFields.ownerId,
      FirestoreFields.userId,
      FirestoreFields.uid,
      FirestoreFields.createdBy,
      FirestoreFields.creatorUid,
      FirestoreFields.businessOwnerUid,
      FirestoreFields.adminUid,
      FirestoreFields.managerUid,
    ];

    for (final field in uidFields) {
      final foundId = await queryBusinessIdByField(
        field: field,
        value: uid,
        currentUid: uid,
      );
      if (foundId != null) return foundId;
    }

    final normalizedEmail = email?.trim().toLowerCase() ?? '';
    if (normalizedEmail.isNotEmpty) {
      final emailFields = <String>[
        FirestoreFields.ownerEmail,
        FirestoreFields.email,
        FirestoreFields.createdByEmail,
        FirestoreFields.contactEmail,
        FirestoreFields.businessEmail,
      ];

      for (final field in emailFields) {
        final foundId = await queryBusinessIdByField(
          field: field,
          value: normalizedEmail,
          currentUid: uid,
        );
        if (foundId != null) return foundId;
      }
    }

    try {
      final docs = await _loadFallbackBusinessDocs();

      for (final doc in docs) {
        if (matchesUserData(doc.data(), uid: uid, email: normalizedEmail)) {
          return doc.id;
        }
      }
    } catch (_) {
      // Preserve existing page behavior: resolver returns null when not found.
    }

    return null;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadFallbackBusinessDocs() async {
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;

    while (docs.length < _fallbackPageCap) {
      Query<Map<String, dynamic>> query = _firestore
          .collection(FirestoreCollections.businesses)
          .orderBy(FieldPath.documentId)
          .limit(_fallbackPageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final remaining = _fallbackPageCap - docs.length;
      docs.addAll(snapshot.docs.take(remaining));
      lastDoc = snapshot.docs.last;

      if (snapshot.docs.length < _fallbackPageSize) break;
    }

    return docs;
  }
}
