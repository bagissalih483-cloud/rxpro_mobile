import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../firestore/firestore_collections.dart';

class CurrentUserAuthSnapshot {
  const CurrentUserAuthSnapshot({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  factory CurrentUserAuthSnapshot.fromFirebaseUser(User user) {
    return CurrentUserAuthSnapshot(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
    );
  }

  final String uid;
  final String email;
  final String displayName;
}

class CurrentUserDocumentSnapshot {
  const CurrentUserDocumentSnapshot({
    required this.exists,
    required this.data,
  });

  factory CurrentUserDocumentSnapshot.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return CurrentUserDocumentSnapshot(
      exists: snapshot.exists,
      data: Map<String, dynamic>.from(snapshot.data() ?? {}),
    );
  }

  final bool exists;
  final Map<String, dynamic> data;
}

class CurrentUserStateRepository {
  CurrentUserStateRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CurrentUserAuthSnapshot? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return CurrentUserAuthSnapshot.fromFirebaseUser(user);
  }

  Stream<CurrentUserAuthSnapshot?> watchAuthState() {
    return _auth
        .authStateChanges()
        .map(
          (user) => user == null
              ? null
              : CurrentUserAuthSnapshot.fromFirebaseUser(user),
        );
  }

  Stream<CurrentUserDocumentSnapshot> watchUserDocument(String uid) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots()
        .map(CurrentUserDocumentSnapshot.fromFirestore);
  }

  Future<CurrentUserDocumentSnapshot> loadUserDocument(String uid) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    return CurrentUserDocumentSnapshot.fromFirestore(snapshot);
  }
}
