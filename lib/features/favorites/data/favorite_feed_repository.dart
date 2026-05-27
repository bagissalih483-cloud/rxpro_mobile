import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class FavoriteFeedRepository {
  FavoriteFeedRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _businessFollowers =>
      _firestore.collection(FirestoreCollections.businessFollowers);

  CollectionReference<Map<String, dynamic>> get _businesses =>
      _firestore.collection(FirestoreCollections.businesses);

  CollectionReference<Map<String, dynamic>> get _businessProfilePosts =>
      _firestore.collection(FirestoreCollections.businessProfilePosts);

  CollectionReference<Map<String, dynamic>> get _businessProfilePostSaves =>
      _firestore.collection(FirestoreCollections.businessProfilePostSaves);

  Future<Set<String>> fetchFollowedBusinessIds({
    required String uid,
    int limitPerField = 500,
    int fallbackLimit = 1000,
  }) async {
    if (uid.isEmpty) return <String>{};

    final ids = <String>{};

    void addFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final data = doc.data();
      final docId = doc.id;

      final userMatches = <dynamic>[
        data[FirestoreFields.customerUid],
        data[FirestoreFields.customerId],
        data[FirestoreFields.uid],
        data[FirestoreFields.userId],
        data[FirestoreFields.followerUid],
        data[FirestoreFields.followerId],
      ].map(_clean).contains(uid);

      final docMatches = docId.endsWith('_$uid') || docId.startsWith('${uid}_');

      if (!userMatches && !docMatches) return;

      var businessId = _firstNonEmpty(<dynamic>[
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

      if (businessId.isNotEmpty) {
        ids.add(businessId);
      }
    }

    Future<void> readByField(String field) async {
      try {
        final snapshot = await _businessFollowers
            .where(field, isEqualTo: uid)
            .limit(limitPerField)
            .get();

        for (final doc in snapshot.docs) {
          addFromDoc(doc);
        }
      } catch (_) {
        // Keep legacy fallback behavior non-fatal.
      }
    }

    await readByField(FirestoreFields.customerUid);
    await readByField(FirestoreFields.customerId);
    await readByField(FirestoreFields.uid);
    await readByField(FirestoreFields.userId);
    await readByField(FirestoreFields.followerUid);
    await readByField(FirestoreFields.followerId);

    if (ids.isEmpty) {
      try {
        final snapshot = await _businessFollowers.limit(fallbackLimit).get();

        for (final doc in snapshot.docs) {
          addFromDoc(doc);
        }
      } catch (_) {
        // Keep legacy fallback behavior non-fatal.
      }
    }

    if (ids.isEmpty) {
      await _readFollowedBusinessSubcollections(
        uid: uid,
        ids: ids,
        limitPerCollection: limitPerField,
      );
    }

    return ids;
  }

  Future<void> _readFollowedBusinessSubcollections({
    required String uid,
    required Set<String> ids,
    required int limitPerCollection,
  }) async {
    Future<void> readSubcollection(String name) async {
      try {
        final snapshot = await _firestore
            .collection(FirestoreCollections.users)
            .doc(uid)
            .collection(name)
            .limit(limitPerCollection)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          final businessId = _firstNonEmpty(<dynamic>[
            data[FirestoreFields.businessId],
            data[FirestoreFields.targetBusinessId],
            data[FirestoreFields.followedBusinessId],
            data[FirestoreFields.businessDocId],
            data[FirestoreFields.id],
            doc.id,
          ]);

          if (businessId.isNotEmpty) {
            ids.add(businessId);
          }
        }
      } catch (_) {
        // Keep legacy fallback behavior non-fatal.
      }
    }

    await readSubcollection(FirestoreCollections.follows);
    await readSubcollection(FirestoreCollections.followedBusinesses);
    await readSubcollection(FirestoreCollections.followingBusinesses);
    await readSubcollection(FirestoreCollections.favoriteBusinesses);
  }

  Future<List<FavoriteBusinessDocument>> fetchBusinessSummariesByIds({
    required Set<String> businessIds,
  }) async {
    final ids = businessIds.where((id) => id.trim().isNotEmpty).toList();
    final items = <FavoriteBusinessDocument>[];

    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);

      try {
        final snapshot = await _businesses
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          items.add(
            FavoriteBusinessDocument(
              id: doc.id,
              data: <String, dynamic>{...doc.data()},
            ),
          );
        }
      } catch (_) {
        for (final id in chunk) {
          try {
            final doc = await _businesses.doc(id).get();
            final data = doc.data();

            if (data != null) {
              items.add(
                FavoriteBusinessDocument(
                  id: doc.id,
                  data: <String, dynamic>{...data},
                ),
              );
            }
          } catch (_) {
            // Skip broken document reads.
          }
        }
      }
    }

    return items;
  }

  Future<List<FavoritePostDocument>> fetchPostsForBusinesses({
    required Set<String> businessIds,
    int limitPerChunk = 100,
    int fallbackLimit = 300,
  }) async {
    final ids = businessIds.where((id) => id.trim().isNotEmpty).toList();
    final posts = <FavoritePostDocument>[];

    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);

      try {
        final snapshot = await _businessProfilePosts
            .where(FirestoreFields.businessId, whereIn: chunk)
            .limit(limitPerChunk)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data[FirestoreFields.isActive] != false) {
            posts.add(
              FavoritePostDocument(
                id: doc.id,
                data: <String, dynamic>{...data},
              ),
            );
          }
        }
      } catch (_) {
        // whereIn/rules fallback below.
      }
    }

    if (posts.isNotEmpty) return posts;

    try {
      final snapshot = await _businessProfilePosts.limit(fallbackLimit).get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final businessId = _firstNonEmpty(<dynamic>[
          data[FirestoreFields.businessId],
          data[FirestoreFields.businessDocId],
        ]);

        if (data[FirestoreFields.isActive] != false &&
            businessIds.contains(businessId)) {
          posts.add(
            FavoritePostDocument(id: doc.id, data: <String, dynamic>{...data}),
          );
        }
      }
    } catch (_) {
      // Keep legacy fallback behavior non-fatal.
    }

    return posts;
  }

  Future<FavoriteFeedBundle> fetchFavoriteFeedBundle({
    required String uid,
  }) async {
    final followedIds = await fetchFollowedBusinessIds(uid: uid);

    if (followedIds.isEmpty) {
      return const FavoriteFeedBundle(
        followedBusinessIds: <String>{},
        followedBusinesses: <FavoriteBusinessDocument>[],
        posts: <FavoritePostDocument>[],
      );
    }

    final followedBusinesses = await fetchBusinessSummariesByIds(
      businessIds: followedIds,
    );

    final posts = await fetchPostsForBusinesses(businessIds: followedIds);

    return FavoriteFeedBundle(
      followedBusinessIds: followedIds,
      followedBusinesses: followedBusinesses,
      posts: posts,
    );
  }

  Future<List<FavoritePostDocument>> fetchSavedPosts({
    required String uid,
    int limit = 500,
  }) async {
    if (uid.isEmpty) return <FavoritePostDocument>[];

    final saveDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    Future<void> readSavesByField(String field) async {
      try {
        final snapshot = await _businessProfilePostSaves
            .where(field, isEqualTo: uid)
            .limit(limit)
            .get();

        saveDocs.addAll(snapshot.docs);
      } catch (_) {
        // Keep legacy fallback behavior non-fatal.
      }
    }

    await readSavesByField(FirestoreFields.uid);
    await readSavesByField(FirestoreFields.userId);
    await readSavesByField(FirestoreFields.customerUid);
    await readSavesByField(FirestoreFields.customerId);
    await readSavesByField(FirestoreFields.followerUid);

    if (saveDocs.isEmpty) {
      try {
        final snapshot = await _businessProfilePostSaves.limit(1000).get();

        saveDocs.addAll(
          snapshot.docs.where((doc) {
            final data = doc.data();
            final docId = doc.id;

            final userMatches = <dynamic>[
              data[FirestoreFields.uid],
              data[FirestoreFields.userId],
              data[FirestoreFields.customerUid],
              data[FirestoreFields.customerId],
              data[FirestoreFields.followerUid],
            ].map(_clean).contains(uid);

            final docMatches =
                docId.endsWith('_$uid') || docId.startsWith('${uid}_');

            return userMatches || docMatches;
          }),
        );
      } catch (_) {
        // Keep legacy fallback behavior non-fatal.
      }
    }

    final postIds = <String>{};

    for (final doc in saveDocs) {
      final data = doc.data();
      final docId = doc.id;

      var postId = _firstNonEmpty(<dynamic>[
        data[FirestoreFields.postId],
        data[FirestoreFields.businessProfilePostId],
        data[FirestoreFields.businessPostId],
        data[FirestoreFields.targetPostId],
        data[FirestoreFields.id],
      ]);

      if (postId.isEmpty && docId.endsWith('_$uid')) {
        postId = docId.substring(0, docId.length - uid.length - 1);
      }

      if (postId.isEmpty && docId.startsWith('${uid}_')) {
        postId = docId.substring(uid.length + 1);
      }

      if (postId.isNotEmpty) {
        postIds.add(postId);
      }
    }

    final posts = <FavoritePostDocument>[];

    for (final postId in postIds) {
      try {
        final doc = await _businessProfilePosts.doc(postId).get();
        final data = doc.data();

        if (data != null && data[FirestoreFields.isActive] != false) {
          posts.add(
            FavoritePostDocument(id: doc.id, data: <String, dynamic>{...data}),
          );
        }
      } catch (_) {
        // Skip broken saved post reads.
      }
    }

    return posts;
  }

  static String _clean(dynamic value) => value?.toString().trim() ?? '';

  static String _firstNonEmpty(List<dynamic> values, [String fallback = '']) {
    for (final value in values) {
      final text = _clean(value);
      if (text.isNotEmpty) return text;
    }

    return fallback;
  }
}

class FavoriteFeedBundle {
  const FavoriteFeedBundle({
    required this.followedBusinessIds,
    required this.followedBusinesses,
    required this.posts,
  });

  final Set<String> followedBusinessIds;
  final List<FavoriteBusinessDocument> followedBusinesses;
  final List<FavoritePostDocument> posts;
}

class FavoriteBusinessDocument {
  const FavoriteBusinessDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

class FavoritePostDocument {
  const FavoritePostDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}
