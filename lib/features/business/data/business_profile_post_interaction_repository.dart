import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class BusinessProfilePostInteractionRepository {
  BusinessProfilePostInteractionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String interactionDocumentId({
    required String prefix,
    required String postId,
    required String uid,
  }) {
    return '${prefix}_${postId}_$uid';
  }

  Future<bool> interactionExists({
    required String collectionPath,
    required String prefix,
    required String postId,
    required String uid,
  }) async {
    if (uid.isEmpty) return false;

    final doc = await _firestore
        .collection(collectionPath)
        .doc(interactionDocumentId(prefix: prefix, postId: postId, uid: uid))
        .get();

    return doc.exists;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchLikeState({
    required String postId,
    required String uid,
  }) {
    if (uid.isEmpty) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }

    return _firestore
        .collection(FirestoreCollections.businessProfilePostLikes)
        .doc(
          interactionDocumentId(
            prefix: BusinessProfilePostInteractionPrefixes.like,
            postId: postId,
            uid: uid,
          ),
        )
        .snapshots();
  }

  Stream<bool> watchLikeActive({required String postId, required String uid}) {
    return watchLikeState(postId: postId, uid: uid).map((doc) => doc.exists);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSaveState({
    required String postId,
    required String uid,
  }) {
    if (uid.isEmpty) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }

    return _firestore
        .collection(FirestoreCollections.businessProfilePostSaves)
        .doc(
          interactionDocumentId(
            prefix: BusinessProfilePostInteractionPrefixes.save,
            postId: postId,
            uid: uid,
          ),
        )
        .snapshots();
  }

  Stream<bool> watchSaveActive({required String postId, required String uid}) {
    return watchSaveState(postId: postId, uid: uid).map((doc) => doc.exists);
  }

  Future<PostInteractionToggleResult> toggleLike({
    required String postId,
    required String uid,
  }) async {
    if (uid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'uid cannot be empty');
    }

    final likeRef = _firestore
        .collection(FirestoreCollections.businessProfilePostLikes)
        .doc(
          interactionDocumentId(
            prefix: BusinessProfilePostInteractionPrefixes.like,
            postId: postId,
            uid: uid,
          ),
        );

    final postRef = _firestore
        .collection(FirestoreCollections.businessProfilePosts)
        .doc(postId);

    var wasActive = false;
    var isActive = false;

    await _firestore.runTransaction((tx) async {
      final current = await tx.get(likeRef);
      wasActive = current.exists;

      if (current.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {
          FirestoreFields.likeCount: FieldValue.increment(-1),
          FirestoreFields.updatedAt: DateTime.now().toIso8601String(),
        });
        isActive = false;
      } else {
        tx.set(likeRef, {
          FirestoreFields.postId: postId,
          FirestoreFields.uid: uid,
          FirestoreFields.createdAt: DateTime.now().toIso8601String(),
        });
        tx.update(postRef, {
          FirestoreFields.likeCount: FieldValue.increment(1),
          FirestoreFields.updatedAt: DateTime.now().toIso8601String(),
        });
        isActive = true;
      }
    });

    return PostInteractionToggleResult(
      wasActive: wasActive,
      isActive: isActive,
    );
  }

  Future<PostInteractionToggleResult> toggleSave({
    required String postId,
    required String uid,
  }) async {
    if (uid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'uid cannot be empty');
    }

    final saveRef = _firestore
        .collection(FirestoreCollections.businessProfilePostSaves)
        .doc(
          interactionDocumentId(
            prefix: BusinessProfilePostInteractionPrefixes.save,
            postId: postId,
            uid: uid,
          ),
        );

    final postRef = _firestore
        .collection(FirestoreCollections.businessProfilePosts)
        .doc(postId);

    var wasActive = false;
    var isActive = false;

    await _firestore.runTransaction((tx) async {
      final current = await tx.get(saveRef);
      wasActive = current.exists;

      if (current.exists) {
        tx.delete(saveRef);
        tx.update(postRef, {
          FirestoreFields.saveCount: FieldValue.increment(-1),
          FirestoreFields.updatedAt: DateTime.now().toIso8601String(),
        });
        isActive = false;
      } else {
        tx.set(saveRef, {
          FirestoreFields.postId: postId,
          FirestoreFields.uid: uid,
          FirestoreFields.createdAt: DateTime.now().toIso8601String(),
        });
        tx.update(postRef, {
          FirestoreFields.saveCount: FieldValue.increment(1),
          FirestoreFields.updatedAt: DateTime.now().toIso8601String(),
        });
        isActive = true;
      }
    });

    return PostInteractionToggleResult(
      wasActive: wasActive,
      isActive: isActive,
    );
  }

  Future<bool> reportPost({
    required String postId,
    required String uid,
    String reason = 'user_report',
  }) async {
    if (uid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'uid cannot be empty');
    }

    final reportRef = _firestore
        .collection(FirestoreCollections.businessProfilePostReports)
        .doc(
          interactionDocumentId(
            prefix: BusinessProfilePostInteractionPrefixes.report,
            postId: postId,
            uid: uid,
          ),
        );

    final postRef = _firestore
        .collection(FirestoreCollections.businessProfilePosts)
        .doc(postId);

    var created = false;

    await _firestore.runTransaction((tx) async {
      final current = await tx.get(reportRef);

      if (!current.exists) {
        tx.set(reportRef, {
          FirestoreFields.postId: postId,
          FirestoreFields.uid: uid,
          FirestoreFields.reason: reason,
          FirestoreFields.status: 'open',
          FirestoreFields.createdAt: DateTime.now().toIso8601String(),
        });
        tx.update(postRef, {
          FirestoreFields.reportCount: FieldValue.increment(1),
          FirestoreFields.updatedAt: DateTime.now().toIso8601String(),
        });
        created = true;
      }
    });

    return created;
  }
}

class PostInteractionToggleResult {
  const PostInteractionToggleResult({
    required this.wasActive,
    required this.isActive,
  });

  final bool wasActive;
  final bool isActive;
}

class BusinessProfilePostInteractionPrefixes {
  const BusinessProfilePostInteractionPrefixes._();

  static const like = 'like';
  static const save = 'save';
  static const report = 'report';
}
