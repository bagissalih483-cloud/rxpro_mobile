import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class BusinessProfilePostCreateRepository {
  BusinessProfilePostCreateRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createPost({
    required String businessId,
    required String businessName,
    required String ownerUid,
    required String text,
    required String imageUrl,
    String thumbnailUrl = '',
  }) {
    final now = DateTime.now().toIso8601String();
    final hasImage = imageUrl.isNotEmpty;
    final cleanThumbnailUrl = thumbnailUrl.trim();

    return _firestore
        .collection(FirestoreCollections.businessProfilePosts)
        .add({
          FirestoreFields.businessId: businessId,
          FirestoreFields.businessName: businessName,
          FirestoreFields.ownerUid: ownerUid,
          FirestoreFields.type: hasImage ? 'image' : 'text',
          FirestoreFields.text: text,
          FirestoreFields.imageUrl: imageUrl,
          FirestoreFields.mediaUrl: imageUrl,
          FirestoreFields.thumbnailUrl: cleanThumbnailUrl,
          FirestoreFields.mediaType: hasImage ? 'image' : 'text',
          FirestoreFields.isActive: true,
          FirestoreFields.likeCount: 0,
          FirestoreFields.saveCount: 0,
          FirestoreFields.reportCount: 0,
          FirestoreFields.createdAt: now,
          FirestoreFields.updatedAt: now,
        });
  }
}
