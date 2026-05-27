import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_cache/app_cache_service.dart';

class FollowCacheWarmupService {
  FollowCacheWarmupService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    AppCacheService? cache,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _cache = cache ?? AppCacheService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AppCacheService _cache;

  Future<void> syncCurrentUserFollows() async {
    final user = _auth.currentUser;

    if (user == null) {
      await _cache.saveFollowedBusinessIds(const []);
      return;
    }

    final snapshot = await _firestore
        .collection('businessFollowers')
        .where('customerUid', isEqualTo: user.uid)
        .get();

    final ids = snapshot.docs
        .map((doc) => doc.data()['businessId']?.toString() ?? '')
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();

    await _cache.saveFollowedBusinessIds(ids);
  }
}
