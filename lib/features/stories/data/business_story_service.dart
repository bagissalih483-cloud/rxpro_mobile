import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firestore/firestore_fields.dart';
import '../../../core/firestore/firestore_collections.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/uploads/app_image_upload_service.dart';
import '../business_story_model.dart';

class BusinessStoryService {
  BusinessStoryService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int _followPageSize = 100;
  static const int _followPageCap = 1000;

  static Stream<List<BusinessStoryModel>> watchActiveStories({
    int limit = 100,
  }) {
    return _db
        .collection(FirestoreCollections.businessStories)
        .where(FirestoreFields.active, isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final stories = snapshot.docs
              .map(BusinessStoryModel.fromDoc)
              .where((story) => story.visibleNow)
              .toList();

          stories.sort((a, b) {
            final ac = a.createdAt ?? DateTime(1970);
            final bc = b.createdAt ?? DateTime(1970);
            return bc.compareTo(ac);
          });

          return stories;
        });
  }

  static Future<Set<String>> loadFollowedBusinessIds() async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return <String>{};

    final ids = <String>{};

    void addFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final data = doc.data();
      final docId = doc.id;

      final userMatches = [
        data[FirestoreFields.customerUid],
        data[FirestoreFields.customerId],
        data[FirestoreFields.uid],
        data[FirestoreFields.userId],
        data[FirestoreFields.followerUid],
        data[FirestoreFields.followerId],
      ].map(_clean).contains(uid);

      final docMatches = docId.endsWith('_$uid') || docId.startsWith('${uid}_');

      if (!userMatches && !docMatches) return;

      var businessId = _first([
        data[FirestoreFields.businessId],
        data[FirestoreFields.targetBusinessId],
        data[FirestoreFields.followedBusinessId],
        data[FirestoreFields.businessDocId],
        data[FirestoreFields.id],
      ]);

      if (businessId.isEmpty && docId.endsWith('_$uid')) {
        businessId = docId.substring(0, docId.length - uid.length - 1);
      }

      if (businessId.isEmpty && docId.startsWith('${uid}_')) {
        businessId = docId.substring(uid.length + 1);
      }

      if (businessId.isNotEmpty) ids.add(businessId);
    }

    Future<void> readByField(String field) async {
      try {
        final docs = await _getPagedDocs(
          _db
              .collection(FirestoreCollections.businessFollowers)
              .where(field, isEqualTo: uid),
        );

        for (final doc in docs) {
          addFromDoc(doc);
        }
      } catch (_) {}
    }

    for (final field in const [
      'customerUid',
      'customerId',
      'uid',
      'userId',
      'followerUid',
      'followerId',
    ]) {
      await readByField(field);
    }

    if (ids.isEmpty) {
      Future<void> readSub(String name) async {
        try {
          final docs = await _getPagedDocs(
            _db
                .collection(FirestoreCollections.users)
                .doc(uid)
                .collection(name),
          );

          for (final doc in docs) {
            final data = doc.data();

            final businessId = _first([
              data[FirestoreFields.businessId],
              data[FirestoreFields.targetBusinessId],
              data[FirestoreFields.followedBusinessId],
              data[FirestoreFields.businessDocId],
              data[FirestoreFields.id],
              doc.id,
            ]);

            if (businessId.isNotEmpty) ids.add(businessId);
          }
        } catch (_) {}
      }

      await readSub('follows');
      await readSub('followedBusinesses');
      await readSub('followingBusinesses');
      await readSub('favoriteBusinesses');
    }

    return ids;
  }

  static Future<List<BusinessStoryModel>> prioritizeForCurrentUser(
    List<BusinessStoryModel> stories,
  ) async {
    final followedIds = await loadFollowedBusinessIds();

    final followed = <BusinessStoryModel>[];
    final others = <BusinessStoryModel>[];

    for (final story in stories) {
      if (followedIds.contains(story.businessId)) {
        followed.add(story);
      } else {
        others.add(story);
      }
    }

    return [...followed, ...others];
  }

  static Future<String> createImageStory({
    required String businessId,
    required String businessName,
    required String businessLogoUrl,
    required String category,
    required XFile file,
    required String caption,
    String storyType = 'normal',
    String campaignId = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Hikâye paylaşmak için giriş yapmalısınız.');
    }

    final upload = await AppImageUploadService.uploadBusinessStoryImageSet(
      businessId: businessId,
      ownerUid: user.uid,
      file: file,
    );
    final mediaUrl = upload.url;

    final now = DateTime.now();
    final expires = now.add(const Duration(hours: 24));

    final doc = _db.collection(FirestoreCollections.businessStories).doc();

    await doc.set({
      'businessId': businessId,
      'businessOwnerUid': user.uid,
      'businessName': businessName,
      'businessLogoUrl': businessLogoUrl,
      'category': category,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': upload.thumbnailUrl ?? '',
      'mediaType': 'image',
      'caption': caption.trim(),
      'storyType': storyType,
      'campaignId': campaignId,
      'active': true,
      'viewCount': 0,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtIso': now.toIso8601String(),
      'expiresAt': Timestamp.fromDate(expires),
      'expiresAtIso': expires.toIso8601String(),
      'source': 'business_story_create_page_41J_B1',
    });

    return doc.id;
  }

  static Future<void> markViewed(String storyId) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (storyId.trim().isEmpty) return;

    try {
      await _db
          .collection(FirestoreCollections.businessStories)
          .doc(storyId)
          .set({
            'viewCount': FieldValue.increment(1),
            if (uid.isNotEmpty) 'lastViewerUid': uid,
            'lastViewedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}
  }

  static String _clean(dynamic value) => value?.toString().trim() ?? '';

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _getPagedDocs(Query<Map<String, dynamic>> baseQuery) async {
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;

    while (docs.length < _followPageCap) {
      Query<Map<String, dynamic>> query = baseQuery
          .orderBy(FieldPath.documentId)
          .limit(_followPageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final remaining = _followPageCap - docs.length;
      docs.addAll(snapshot.docs.take(remaining));
      lastDoc = snapshot.docs.last;

      if (snapshot.docs.length < _followPageSize) break;
    }

    return docs;
  }

  static String _first(List<dynamic> values, [String fallback = '']) {
    for (final value in values) {
      final text = _clean(value);
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }
}
