import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';

class AdminModerationRepository {
  AdminModerationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchClaimRequests() {
    return _firestore
        .collection(FirestoreCollections.businessClaimRequests)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAbuseLogs() {
    return _firestore
        .collection(FirestoreCollections.functionAbuseLogs)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAdminAuditLogs() {
    return _firestore
        .collection(FirestoreCollections.adminAuditLogs)
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPostReports() {
    return _firestore
        .collection(FirestoreCollections.businessProfilePostReports)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchModerationBlocks() {
    return _firestore
        .collection(FirestoreCollections.moderationBlocks)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchReviewReports() {
    return _firestore
        .collection(FirestoreCollections.businessReviewReports)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCampaignReports() {
    return _firestore
        .collection(FirestoreCollections.campaignReports)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> updateClaimStatus({
    required String claimId,
    required String status,
  }) async {
    await _firestore
        .collection(FirestoreCollections.businessClaimRequests)
        .doc(claimId)
        .set(<String, dynamic>{
          'status': status,
          'reviewStatus': status,
          'reviewedBy': _auth.currentUser?.uid ?? '',
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    await _writeAuditLog(
      action: 'claim_$status',
      targetCollection: FirestoreCollections.businessClaimRequests,
      targetId: claimId,
    );
  }

  Future<void> updatePostReportStatus({
    required String reportId,
    required String status,
    required Map<String, dynamic> currentData,
  }) async {
    await _firestore
        .collection(FirestoreCollections.businessProfilePostReports)
        .doc(reportId)
        .set(<String, dynamic>{
          'uid': currentData['uid'],
          'postId': currentData['postId'],
          'status': status,
          'reviewedBy': _auth.currentUser?.uid ?? '',
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    await _writeAuditLog(
      action: 'post_report_$status',
      targetCollection: FirestoreCollections.businessProfilePostReports,
      targetId: reportId,
      metadata: <String, dynamic>{
        'postId': currentData['postId'],
        'reportedUid': currentData['uid'],
      },
    );
  }

  Future<void> blockUser({
    required String uid,
    required String reason,
  }) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty || cleanUid == '-') return;

    final adminUid = _auth.currentUser?.uid ?? '';
    final blockId = 'user_$cleanUid';
    final batch = _firestore.batch();

    batch.set(
      _firestore.collection(FirestoreCollections.moderationBlocks).doc(blockId),
      <String, dynamic>{
        'targetType': 'user',
        'targetId': cleanUid,
        'uid': cleanUid,
        'status': 'active',
        'reason': reason.trim().isEmpty ? 'moderation' : reason.trim(),
        'createdBy': adminUid,
        'updatedBy': adminUid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _firestore.collection(FirestoreCollections.users).doc(cleanUid),
      <String, dynamic>{
        'accountStatus': 'blocked',
        'status': 'blocked',
        'blocked': true,
        'blockedAt': FieldValue.serverTimestamp(),
        'blockedBy': adminUid,
        'blockReason': reason.trim().isEmpty ? 'moderation' : reason.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    await _writeAuditLog(
      action: 'user_blocked',
      targetCollection: FirestoreCollections.users,
      targetId: cleanUid,
      metadata: <String, dynamic>{'reason': reason},
    );
  }

  Future<void> unblockUser({required String uid}) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty || cleanUid == '-') return;

    final adminUid = _auth.currentUser?.uid ?? '';
    final blockId = 'user_$cleanUid';
    final batch = _firestore.batch();

    batch.set(
      _firestore.collection(FirestoreCollections.moderationBlocks).doc(blockId),
      <String, dynamic>{
        'status': 'inactive',
        'updatedBy': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _firestore.collection(FirestoreCollections.users).doc(cleanUid),
      <String, dynamic>{
        'accountStatus': 'active',
        'status': 'active',
        'blocked': false,
        'unblockedAt': FieldValue.serverTimestamp(),
        'unblockedBy': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    await _writeAuditLog(
      action: 'user_unblocked',
      targetCollection: FirestoreCollections.users,
      targetId: cleanUid,
    );
  }

  Future<void> updateReviewReportStatus({
    required String reportId,
    required String status,
    required Map<String, dynamic> currentData,
  }) async {
    await _firestore
        .collection(FirestoreCollections.businessReviewReports)
        .doc(reportId)
        .set(<String, dynamic>{
          'uid': currentData['uid'],
          'reviewId': currentData['reviewId'],
          'businessId': currentData['businessId'],
          'status': status,
          'reviewedBy': _auth.currentUser?.uid ?? '',
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    await _writeAuditLog(
      action: 'review_report_$status',
      targetCollection: FirestoreCollections.businessReviewReports,
      targetId: reportId,
      metadata: <String, dynamic>{
        'reviewId': currentData['reviewId'],
        'reportedUid': currentData['uid'],
      },
    );
  }

  Future<void> setReviewHidden({
    required String reviewId,
    required bool hidden,
    String reason = 'moderation',
  }) async {
    final cleanReviewId = reviewId.trim();
    if (cleanReviewId.isEmpty || cleanReviewId == '-') return;

    await _firestore
        .collection(FirestoreCollections.businessReviews)
        .doc(cleanReviewId)
        .set(<String, dynamic>{
          'moderationStatus': hidden ? 'hidden' : 'active',
          'moderationReason': reason.trim().isEmpty ? 'moderation' : reason,
          'moderatedBy': _auth.currentUser?.uid ?? '',
          'moderatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await _writeAuditLog(
      action: hidden ? 'review_hidden' : 'review_restored',
      targetCollection: FirestoreCollections.businessReviews,
      targetId: cleanReviewId,
      metadata: <String, dynamic>{'reason': reason},
    );
  }

  Future<void> updateCampaignReportStatus({
    required String reportId,
    required String status,
    required Map<String, dynamic> currentData,
  }) async {
    await _firestore
        .collection(FirestoreCollections.campaignReports)
        .doc(reportId)
        .set(<String, dynamic>{
          'uid': currentData['uid'],
          'campaignId': currentData['campaignId'],
          'sourceCollection': currentData['sourceCollection'],
          'businessId': currentData['businessId'],
          'status': status,
          'reviewedBy': _auth.currentUser?.uid ?? '',
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    await _writeAuditLog(
      action: 'campaign_report_$status',
      targetCollection: FirestoreCollections.campaignReports,
      targetId: reportId,
      metadata: <String, dynamic>{
        'campaignId': currentData['campaignId'],
        'sourceCollection': currentData['sourceCollection'],
        'reportedUid': currentData['uid'],
      },
    );
  }

  Future<void> setCampaignHidden({
    required String campaignId,
    required String sourceCollection,
    required bool hidden,
    String reason = 'campaign_report',
  }) async {
    final cleanCampaignId = campaignId.trim();
    final requestedCollection = sourceCollection.trim();
    final cleanCollection = requestedCollection == FirestoreCollections.campaigns
        ? FirestoreCollections.campaigns
        : FirestoreCollections.businessCampaigns;
    if (cleanCampaignId.isEmpty || cleanCampaignId == '-') return;

    await _firestore.collection(cleanCollection).doc(cleanCampaignId).set(
      <String, dynamic>{
        'moderationStatus': hidden ? 'hidden' : 'active',
        'moderationReason': reason.trim().isEmpty ? 'moderation' : reason,
        'hidden': hidden,
        'isHidden': hidden,
        'moderatedBy': _auth.currentUser?.uid ?? '',
        'moderatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _writeAuditLog(
      action: hidden ? 'campaign_hidden' : 'campaign_restored',
      targetCollection: cleanCollection,
      targetId: cleanCampaignId,
      metadata: <String, dynamic>{'reason': reason},
    );
  }

  Future<void> addSupportNote({
    required String targetCollection,
    required String targetId,
    required String note,
    Map<String, dynamic>? metadata,
  }) {
    final cleanNote = note.trim();
    if (cleanNote.isEmpty || targetId.trim().isEmpty || targetId == '-') {
      return Future<void>.value();
    }

    return _writeAuditLog(
      action: 'support_note',
      targetCollection: targetCollection,
      targetId: targetId.trim(),
      metadata: <String, dynamic>{
        ...?metadata,
        'note': cleanNote.length > 1200
            ? cleanNote.substring(0, 1200)
            : cleanNote,
      },
    );
  }

  Future<void> _writeAuditLog({
    required String action,
    required String targetCollection,
    required String targetId,
    Map<String, dynamic>? metadata,
  }) {
    return _firestore.collection(FirestoreCollections.adminAuditLogs).add({
      'action': action,
      'actorUid': _auth.currentUser?.uid ?? '',
      'targetCollection': targetCollection,
      'targetId': targetId,
      'metadata': metadata ?? const <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
