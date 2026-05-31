import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class BusinessProfileRepository {
  BusinessProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchBusinessProfile({
    required String businessId,
    bool includeMetadataChanges = true,
  }) {
    return _firestore
        .collection(FirestoreCollections.businesses)
        .doc(businessId)
        .snapshots(includeMetadataChanges: includeMetadataChanges);
  }

  Future<Map<String, dynamic>?> fetchBusinessProfile({
    required String businessId,
  }) async {
    final doc = await _firestore
        .collection(FirestoreCollections.businesses)
        .doc(businessId)
        .get();

    final data = doc.data();
    if (data == null) return null;

    return <String, dynamic>{FirestoreFields.id: doc.id, ...data};
  }

  Stream<List<Map<String, dynamic>>> watchBusinessPosts({
    required String businessId,
    bool onlyActive = true,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreCollections.businessProfilePosts)
        .where(FirestoreFields.businessId, isEqualTo: businessId);

    if (onlyActive) {
      query = query.where(FirestoreFields.isActive, isEqualTo: true);
    }

    return query.snapshots().map(_withDocumentIds);
  }

  Stream<List<Map<String, dynamic>>> watchBusinessServices({
    required String businessId,
  }) {
    return _firestore
        .collection(FirestoreCollections.businessServices)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .snapshots()
        .map(_withDocumentIds);
  }

  Stream<List<Map<String, dynamic>>> watchBusinessStaff({
    required String businessId,
  }) {
    return _firestore
        .collection(FirestoreCollections.businessStaff)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .snapshots()
        .map(_withDocumentIds);
  }

  Stream<List<Map<String, dynamic>>> watchBusinessReviews({
    required String businessId,
  }) {
    return _firestore
        .collection(FirestoreCollections.businessReviews)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          return _withDocumentIds(snapshot)
              .where((data) {
                final status = _clean(data['moderationStatus']).toLowerCase();
                return status != 'hidden' && status != 'removed';
              })
              .toList(growable: false);
        });
  }

  Future<List<Map<String, dynamic>>> fetchBusinessServices({
    required String businessId,
  }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.businessServices)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .get();

    return _withDocumentIds(snapshot);
  }

  Future<List<Map<String, dynamic>>> fetchBusinessStaff({
    required String businessId,
  }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.businessStaff)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .get();

    return _withDocumentIds(snapshot);
  }

  Future<List<Map<String, dynamic>>> fetchBusinessReviews({
    required String businessId,
  }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.businessReviews)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .get();

    return _withDocumentIds(snapshot);
  }

  Future<Map<String, dynamic>> fetchUserData({required String uid}) async {
    if (uid.trim().isEmpty) return <String, dynamic>{};

    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    return doc.data() ?? <String, dynamic>{};
  }

  Future<void> refreshRatingSummary({required String businessId}) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.businessReviews)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .get();

    if (snapshot.docs.isEmpty) {
      await _firestore
          .collection(FirestoreCollections.businesses)
          .doc(businessId)
          .set({
            FirestoreFields.ratingAvg: 0,
            FirestoreFields.ratingCount: 0,
          }, SetOptions(merge: true));
      return;
    }

    var total = 0.0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final raw = data[FirestoreFields.rating];

      if (raw is num) {
        total += raw.toDouble();
      } else {
        total += double.tryParse(raw?.toString() ?? '') ?? 0;
      }
    }

    final count = snapshot.docs.length;
    final avg = total / count;

    await _firestore
        .collection(FirestoreCollections.businesses)
        .doc(businessId)
        .set({
          FirestoreFields.ratingAvg: avg,
          FirestoreFields.ratingCount: count,
          FirestoreFields.updatedAt: DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
  }

  Future<void> createReview({
    required String businessId,
    required String businessName,
    required String customerUid,
    required String customerName,
    required int rating,
    required String comment,
  }) async {
    await _firestore.collection(FirestoreCollections.businessReviews).add({
      FirestoreFields.businessId: businessId,
      FirestoreFields.businessName: businessName,
      FirestoreFields.customerUid: customerUid,
      FirestoreFields.customerName: customerName,
      FirestoreFields.rating: rating,
      FirestoreFields.comment: comment,
      'moderationStatus': 'active',
      FirestoreFields.createdAt: DateTime.now().toIso8601String(),
    });

    await _firestore
        .collection(FirestoreCollections.businessRatings)
        .doc('_')
        .set({
          FirestoreFields.businessId: businessId,
          FirestoreFields.customerUid: customerUid,
          FirestoreFields.customerName: customerName,
          FirestoreFields.rating: rating,
          FirestoreFields.updatedAt: DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
  }

  Future<bool> reportReview({
    required String reviewId,
    required String businessId,
    required String uid,
    String reason = 'user_report',
  }) async {
    if (reviewId.trim().isEmpty || uid.trim().isEmpty) return false;

    final reportId = 'review_${reviewId.trim()}_$uid';
    final reportRef = _firestore
        .collection(FirestoreCollections.businessReviewReports)
        .doc(reportId);

    var created = false;
    await _firestore.runTransaction((transaction) async {
      final current = await transaction.get(reportRef);
      if (current.exists) return;

      transaction.set(reportRef, {
        'reviewId': reviewId.trim(),
        FirestoreFields.businessId: businessId,
        FirestoreFields.uid: uid,
        'reason': reason,
        'status': 'open',
        FirestoreFields.createdAt: DateTime.now().toIso8601String(),
      });
      created = true;
    });

    return created;
  }

  Future<bool> isFollowingBusiness({
    required String businessId,
    required String uid,
  }) async {
    if (businessId.trim().isEmpty || uid.trim().isEmpty) return false;

    final doc = await _firestore
        .collection(FirestoreCollections.businessFollowers)
        .doc(_followId(businessId, uid))
        .get();

    return doc.exists;
  }

  Future<void> setBusinessFollowing({
    required String businessId,
    required String businessName,
    required String uid,
    required bool followed,
  }) async {
    final followRef = _firestore
        .collection(FirestoreCollections.businessFollowers)
        .doc(_followId(businessId, uid));
    final businessRef = _firestore
        .collection(FirestoreCollections.businesses)
        .doc(businessId);

    await _firestore.runTransaction((transaction) async {
      final businessDoc = await transaction.get(businessRef);
      final data = businessDoc.data() ?? {};
      final rawCount = data[FirestoreFields.followerCount];
      final count = rawCount is num
          ? rawCount.toInt()
          : int.tryParse(rawCount?.toString() ?? '') ?? 0;

      if (followed) {
        transaction.set(followRef, {
          FirestoreFields.businessId: businessId,
          FirestoreFields.businessName: businessName,
          FirestoreFields.customerUid: uid,
          FirestoreFields.createdAt: DateTime.now().toIso8601String(),
        });

        transaction.set(businessRef, {
          FirestoreFields.followerCount: count + 1,
        }, SetOptions(merge: true));
      } else {
        transaction.delete(followRef);
        transaction.set(businessRef, {
          FirestoreFields.followerCount: count > 0 ? count - 1 : 0,
        }, SetOptions(merge: true));
      }
    });
  }

  static String _followId(String businessId, String uid) =>
      '${businessId}_$uid';

  List<Map<String, dynamic>> _withDocumentIds(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) {
          return <String, dynamic>{FirestoreFields.id: doc.id, ...doc.data()};
        })
        .toList(growable: false);
  }

  /// Watches the current signed-in user's Firestore document.
  ///
  /// Returns null when there is no signed-in user. This keeps the page helper
  /// signature nullable while keeping Firestore stream values non-nullable.
  Stream<DocumentSnapshot<Map<String, dynamic>>>? watchCurrentUserDocument({
    required String? uid,
  }) {
    final cleanUid = uid?.trim();
    if (cleanUid == null || cleanUid.isEmpty) {
      return null;
    }

    return _firestore
        .collection(FirestoreCollections.users)
        .doc(cleanUid)
        .snapshots();
  }

  static String _clean(Object? value) => value?.toString().trim() ?? '';
}
