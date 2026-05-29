import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RxPushNotificationSessionRepository {
  RxPushNotificationSessionRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<String?> watchUserIds() {
    return _auth.authStateChanges().map((user) => user?.uid);
  }

  String get currentUid => _auth.currentUser?.uid.trim() ?? '';

  Future<void> upsertActiveToken({
    required String uid,
    required String token,
    required String tokenDocId,
    required String platform,
    required String tokenTail,
  }) async {
    final cleanUid = uid.trim();
    final cleanToken = token.trim();
    if (cleanUid.isEmpty || cleanToken.isEmpty) return;

    final userRef = _firestore.collection('users').doc(cleanUid);

    await userRef.set({
      'fcmToken': cleanToken,
      'fcmTokenOwnerUid': cleanUid,
      'fcmPlatform': platform,
      'fcmTokenActive': true,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      'fcmTokenUpdatedAtIso': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await userRef.collection('fcmTokens').doc(tokenDocId).set({
      'token': cleanToken,
      'ownerUid': cleanUid,
      'platform': platform,
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtIso': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    await _deactivateOtherActiveTokensForUid(
      uid: cleanUid,
      currentToken: cleanToken,
      currentTokenDocId: tokenDocId,
    );

    debugPrint('RX_41I_B_AFTER_TOKEN_WRITE_UNIQUE uid=$cleanUid');
    debugPrint('RX_41I_TOKEN_SYNC_SUCCESS uid=$cleanUid tokenTail=$tokenTail');
  }

  Future<void> deactivateTokenForUid({
    required String uid,
    required String token,
    required String tokenDocId,
    required String tokenTail,
  }) async {
    final cleanUid = uid.trim();
    final cleanToken = token.trim();
    if (cleanUid.isEmpty) return;

    final userRef = _firestore.collection('users').doc(cleanUid);

    await userRef.set({
      'fcmTokenActive': false,
      'fcmTokenDeactivatedAt': FieldValue.serverTimestamp(),
      'fcmTokenDeactivatedAtIso': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (cleanToken.isEmpty) {
      debugPrint('RX_41I_TOKEN_DEACTIVATE_NO_TOKEN uid=$cleanUid');
      return;
    }

    final rawTokenDocRef = userRef.collection('fcmTokens').doc(cleanToken);
    final safeTokenDocRef = userRef.collection('fcmTokens').doc(tokenDocId);

    final inactiveData = {
      'token': cleanToken,
      'ownerUid': cleanUid,
      'active': false,
      'deactivatedAt': FieldValue.serverTimestamp(),
      'deactivatedAtIso': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await rawTokenDocRef.set(inactiveData, SetOptions(merge: true));
    await safeTokenDocRef.set(inactiveData, SetOptions(merge: true));

    final sameTokenSnap = await userRef
        .collection('fcmTokens')
        .where('token', isEqualTo: cleanToken)
        .limit(20)
        .get();

    final batch = _firestore.batch();
    var count = 0;

    for (final doc in sameTokenSnap.docs) {
      batch.set(doc.reference, inactiveData, SetOptions(merge: true));
      count++;
    }

    if (count > 0) {
      await batch.commit();
    }

    debugPrint(
      'RX_41I_TOKEN_DEACTIVATED uid=$cleanUid tokenTail=$tokenTail count=$count',
    );
  }

  Future<bool> businessNotificationBelongsToCurrentUser(
    String businessId,
  ) async {
    final uid = currentUid;
    final rawBusinessId = businessId.trim();
    if (uid.isEmpty || rawBusinessId.isEmpty) return false;

    final businessCandidates = <String>{
      rawBusinessId,
      if (rawBusinessId.startsWith('business_'))
        rawBusinessId.replaceFirst(RegExp(r'^business_'), '').trim(),
    }.where((value) => value.isNotEmpty).toSet();

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 3));
      final userData = userDoc.data() ?? <String, dynamic>{};
      final userBusinessIds =
          <String>[
                'businessId',
                'ownedBusinessId',
                'activeBusinessId',
                'selectedBusinessId',
                'staffBusinessId',
                'linkedBusinessId',
              ]
              .map((field) => (userData[field] ?? '').toString().trim())
              .where((value) => value.isNotEmpty)
              .toSet();

      if (userBusinessIds.any(businessCandidates.contains)) return true;
    } catch (e) {
      debugPrint('RX_PUSH_BUSINESS_USER_SCOPE_CHECK_SKIPPED $e');
    }

    for (final candidate in businessCandidates) {
      try {
        final businessDoc = await _firestore
            .collection('businesses')
            .doc(candidate)
            .get()
            .timeout(const Duration(seconds: 3));
        final data = businessDoc.data() ?? <String, dynamic>{};

        final directOwners = <String>[
          'ownerUid',
          'ownerId',
          'businessOwnerUid',
          'userId',
          'uid',
          'createdBy',
          'createdByUid',
          'adminUid',
          'managerUid',
        ].map((field) => (data[field] ?? '').toString().trim());

        if (directOwners.any((ownerUid) => ownerUid == uid)) return true;
        if (_ownerContainerContainsUid(data['ownerUids'], uid)) return true;
        if (_ownerContainerContainsUid(data['owners'], uid)) return true;
      } catch (e) {
        debugPrint('RX_PUSH_BUSINESS_DOC_SCOPE_CHECK_SKIPPED $e');
      }
    }

    return false;
  }

  Future<void> _deactivateOtherActiveTokensForUid({
    required String uid,
    required String currentToken,
    required String currentTokenDocId,
  }) async {
    final cleanUid = uid.trim();
    final cleanToken = currentToken.trim();

    if (cleanUid.isEmpty || cleanToken.isEmpty) return;

    try {
      final userRef = _firestore.collection('users').doc(cleanUid);

      final activeSnap = await userRef
          .collection('fcmTokens')
          .where('active', isEqualTo: true)
          .limit(100)
          .get();

      if (activeSnap.docs.isEmpty) return;

      final batch = _firestore.batch();
      var closedCount = 0;

      for (final doc in activeSnap.docs) {
        final data = doc.data();
        final docToken = (data['token'] ?? '').toString().trim();

        final isCurrent =
            doc.id == currentTokenDocId ||
            doc.id == cleanToken ||
            docToken == cleanToken;

        if (isCurrent) continue;

        batch.set(doc.reference, {
          'active': false,
          'deactivatedReason': 'replaced_by_latest_login_token',
          'deactivatedAt': FieldValue.serverTimestamp(),
          'deactivatedAtIso': DateTime.now().toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        closedCount++;
      }

      if (closedCount > 0) {
        await batch.commit();
      }

      debugPrint(
        'RX_41I_B_OTHER_TOKENS_DEACTIVATED uid=$cleanUid count=$closedCount',
      );
    } catch (e) {
      debugPrint(
        'RX_41I_B_OTHER_TOKENS_DEACTIVATE_ERROR uid=$cleanUid error=$e',
      );
    }
  }

  bool _ownerContainerContainsUid(Object? value, String uid) {
    if (value == null || uid.trim().isEmpty) return false;
    if (value is String) return value.trim() == uid;
    if (value is Iterable) {
      return value.any((item) => _ownerContainerContainsUid(item, uid));
    }
    if (value is Map) {
      return value.entries.any((entry) {
        if (entry.value == true) {
          return entry.key.toString().trim() == uid;
        }
        return _ownerContainerContainsUid(entry.value, uid);
      });
    }
    return value.toString().trim() == uid;
  }
}
