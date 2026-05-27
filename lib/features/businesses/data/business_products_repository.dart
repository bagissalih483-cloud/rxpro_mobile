import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class BusinessProductsRepository {
  BusinessProductsRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.businessProducts);

  Future<BusinessProductContext> resolveBusinessContext() async {
    final user = _auth.currentUser;
    final uid = user?.uid ?? '';

    if (uid.isEmpty) {
      return const BusinessProductContext(
        businessId: '',
        businessName: 'Kurumsal Kullanici',
      );
    }

    Future<BusinessProductContext?> tryCollection(String collection) async {
      try {
        final snap = await _firestore
            .collection(collection)
            .where(FirestoreFields.ownerUid, isEqualTo: uid)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) return null;

        final doc = snap.docs.first;
        final data = doc.data();

        return BusinessProductContext(
          businessId: doc.id,
          businessName: _clean(
            data[FirestoreFields.businessName] ??
                data[FirestoreFields.name] ??
                data[FirestoreFields.title] ??
                data[FirestoreFields.companyName] ??
                'Kurumsal Kullanici',
          ),
        );
      } catch (_) {
        return null;
      }
    }

    final fromBusinesses = await tryCollection(FirestoreCollections.businesses);
    if (fromBusinesses != null) return fromBusinesses;

    final fromProfiles = await tryCollection(
      FirestoreCollections.businessProfiles,
    );
    if (fromProfiles != null) return fromProfiles;

    final fromRegistered = await tryCollection(
      FirestoreCollections.registeredBusinesses,
    );
    if (fromRegistered != null) return fromRegistered;

    return BusinessProductContext(
      businessId: uid,
      businessName: user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName!.trim()
          : 'Kurumsal Kullanici',
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProducts(String businessId) {
    return _products
        .where(FirestoreFields.businessId, isEqualTo: businessId.trim())
        .snapshots();
  }

  Future<void> setProductActive({
    required DocumentReference<Map<String, dynamic>> productRef,
    required bool active,
  }) {
    return productRef.set(<String, dynamic>{
      FirestoreFields.isActive: active,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAtLocalIso: DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> setProductPublic({
    required DocumentReference<Map<String, dynamic>> productRef,
    required bool isPublic,
  }) {
    return productRef.set(<String, dynamic>{
      FirestoreFields.isPublic: isPublic,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAtLocalIso: DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteProduct(
    DocumentReference<Map<String, dynamic>> productRef,
  ) {
    return productRef.delete();
  }

  Future<void> upsertProduct({
    DocumentReference<Map<String, dynamic>>? productRef,
    required Map<String, dynamic> data,
  }) {
    if (productRef == null) {
      return _products
          .add(<String, dynamic>{
            ...data,
            FirestoreFields.createdAt: FieldValue.serverTimestamp(),
            FirestoreFields.createdAtLocalIso: DateTime.now().toIso8601String(),
          })
          .then((_) {});
    }

    return productRef.set(data, SetOptions(merge: true));
  }

  static String _clean(Object? value) => value?.toString().trim() ?? '';
}

class BusinessProductContext {
  const BusinessProductContext({
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;
}
