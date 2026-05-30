import 'package:cloud_firestore/cloud_firestore.dart';

import '../../firestore/firestore_collections.dart';
import '../../firestore/firestore_fields.dart';

class AppSessionUserDocument {
  const AppSessionUserDocument({
    required this.exists,
    required this.data,
  });

  factory AppSessionUserDocument.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return AppSessionUserDocument(
      exists: snapshot.exists,
      data: Map<String, dynamic>.from(snapshot.data() ?? {}),
    );
  }

  final bool exists;
  final Map<String, dynamic> data;
}

class AppSessionBusinessDocument {
  const AppSessionBusinessDocument({
    required this.id,
    required this.data,
  });

  factory AppSessionBusinessDocument.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return AppSessionBusinessDocument(
      id: snapshot.id,
      data: Map<String, dynamic>.from(snapshot.data()),
    );
  }

  factory AppSessionBusinessDocument.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return AppSessionBusinessDocument(
      id: snapshot.id,
      data: Map<String, dynamic>.from(snapshot.data() ?? {}),
    );
  }

  final String id;
  final Map<String, dynamic> data;
}

class AppSessionRepository {
  AppSessionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<AppSessionUserDocument> watchUserDocument(String uid) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots()
        .map(AppSessionUserDocument.fromFirestore);
  }

  Future<AppSessionBusinessDocument?> loadBusinessById(
    String id, {
    required Duration timeout,
  }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.businesses)
        .doc(id)
        .get()
        .timeout(timeout);

    if (!snapshot.exists) return null;
    return AppSessionBusinessDocument.fromDocument(snapshot);
  }

  Future<AppSessionBusinessDocument?> loadFirstOwnedBusiness(
    String uid, {
    required Duration timeout,
  }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.businesses)
        .where(FirestoreFields.ownerUid, isEqualTo: uid)
        .limit(1)
        .get()
        .timeout(timeout);

    if (snapshot.docs.isEmpty) return null;
    return AppSessionBusinessDocument.fromFirestore(snapshot.docs.first);
  }
}
