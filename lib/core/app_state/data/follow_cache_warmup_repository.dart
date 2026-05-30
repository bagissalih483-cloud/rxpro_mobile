import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowCacheWarmupRepository {
  FollowCacheWarmupRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? get currentUid => _auth.currentUser?.uid;

  Future<List<String>> loadFollowedBusinessIds(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return const <String>[];

    final snapshot = await _firestore
        .collection('businessFollowers')
        .where('customerUid', isEqualTo: cleanUid)
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['businessId']?.toString() ?? '')
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
