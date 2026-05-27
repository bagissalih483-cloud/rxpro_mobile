import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class HomeExploreBadgeRepository {
  HomeExploreBadgeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<int> watchUnreadMessagesCount({
    required String uid,
    required bool previewMode,
    required String businessId,
  }) {
    final col = _firestore.collection(FirestoreCollections.messageThreads);

    if (previewMode && businessId.isNotEmpty) {
      return col
          .where(FirestoreFields.businessId, isEqualTo: businessId)
          .where(FirestoreFields.unreadForBusiness, isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    }

    return col
        .where(FirestoreFields.customerUid, isEqualTo: uid)
        .where(FirestoreFields.unreadForCustomer, isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> watchUnreadNotificationsCount({
    required String uid,
    required bool previewMode,
    required String businessId,
  }) {
    final col = _firestore.collection(FirestoreCollections.notifications);

    if (previewMode && businessId.isNotEmpty) {
      return col
          .where(FirestoreFields.targetScope, isEqualTo: 'business')
          .where(FirestoreFields.businessId, isEqualTo: businessId)
          .snapshots()
          .map((snapshot) => _unreadCount(snapshot));
    }

    return col
        .where(FirestoreFields.targetScope, whereIn: _userTargetScopes)
        .where(FirestoreFields.recipientUid, isEqualTo: uid)
        .snapshots()
        .map((snapshot) => _unreadCount(snapshot));
  }

  int _unreadCount(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .where((doc) => doc.data()[FirestoreFields.isRead] != true)
        .length;
  }

  static const _userTargetScopes = <String>['user', 'customer'];
}
