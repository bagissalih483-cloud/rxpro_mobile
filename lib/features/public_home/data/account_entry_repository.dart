import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

class AccountEntryRepository {
  AccountEntryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>> fetchUserData(String uid) async {
    if (uid.trim().isEmpty) return <String, dynamic>{};

    final userDoc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    return Map<String, dynamic>.from(userDoc.data() ?? {});
  }

  Future<AccountEntryBusinessData?> tryBusinessById(String id) async {
    if (id.trim().isEmpty) return null;

    for (final collection in const [
      'businesses',
      'businessProfiles',
      'registeredBusinesses',
    ]) {
      try {
        final doc = await _firestore.collection(collection).doc(id).get();
        if (!doc.exists) continue;

        final data = Map<String, dynamic>.from(doc.data() ?? {});
        final businessId = (data[FirestoreFields.businessId] ?? doc.id)
            .toString();
        data[FirestoreFields.businessId] = businessId;
        data[FirestoreFields.sourceCollection] = collection;
        data[FirestoreFields.sourceDocId] = doc.id;

        return AccountEntryBusinessData(
          id: businessId,
          name: businessName(data),
          category: businessCategory(data),
          data: data,
          source: collection,
        );
      } catch (_) {}
    }

    return null;
  }

  Future<AccountEntryBusinessData?> tryBusinessByOwner(String uid) async {
    if (uid.trim().isEmpty) return null;

    for (final collection in const [
      'businesses',
      'businessProfiles',
      'registeredBusinesses',
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
          final businessId = (data[FirestoreFields.businessId] ?? doc.id)
              .toString();
          data[FirestoreFields.businessId] = businessId;
          data[FirestoreFields.sourceCollection] = collection;
          data[FirestoreFields.sourceDocId] = doc.id;

          return AccountEntryBusinessData(
            id: businessId,
            name: businessName(data),
            category: businessCategory(data),
            data: data,
            source: collection,
          );
        } catch (_) {}
      }
    }

    return null;
  }

  static String businessName(Map<String, dynamic> data) {
    return (data[FirestoreFields.businessName] ??
            data[FirestoreFields.name] ??
            data[FirestoreFields.title] ??
            data[FirestoreFields.displayName] ??
            'Kurumsal Kullanıcı')
        .toString();
  }

  static String businessCategory(Map<String, dynamic> data) {
    return (data[FirestoreFields.categoryLabel] ??
            data[FirestoreFields.category] ??
            data[FirestoreFields.businessCategory] ??
            '')
        .toString();
  }
}

class AccountEntryBusinessData {
  const AccountEntryBusinessData({
    required this.id,
    required this.name,
    required this.category,
    required this.data,
    required this.source,
  });

  final String id;
  final String name;
  final String category;
  final Map<String, dynamic> data;
  final String source;
}
