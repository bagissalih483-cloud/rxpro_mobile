import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firestore/firestore_collections.dart';

class AccountDeletionRepository {
  AccountDeletionRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> requestDeletion() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Oturum bulunamadı.');
    }

    await _firestore
        .collection(FirestoreCollections.accountDeletionRequests)
        .doc(user.uid)
        .set({
          'uid': user.uid,
          'email': user.email ?? '',
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
          'source': 'account_deletion_request_page',
        }, SetOptions(merge: true));
  }
}

