import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_query_budget_policy.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';

class BusinessDirectoryRawDoc {
  const BusinessDirectoryRawDoc({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

class BusinessDirectoryFirestoreRepository {
  BusinessDirectoryFirestoreRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<BusinessDirectoryRawDoc>> loadBusinessDocs({
    required int pageSize,
    required int pageCap,
    required Duration timeout,
  }) async {
    final safePageSize = BusinessDirectoryQueryBudgetPolicy.pageSize(pageSize);
    final safePageCap = BusinessDirectoryQueryBudgetPolicy.pageCap(pageCap);
    final docs = <BusinessDirectoryRawDoc>[];
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;

    while (docs.length < safePageCap) {
      Query<Map<String, dynamic>> query = _firestore
          .collection(FirestoreCollections.businesses)
          .orderBy(FieldPath.documentId)
          .limit(safePageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout);

      if (snapshot.docs.isEmpty) break;

      final remaining = safePageCap - docs.length;
      docs.addAll(
        snapshot.docs
            .take(remaining)
            .map(
              (doc) => BusinessDirectoryRawDoc(id: doc.id, data: doc.data()),
            ),
      );
      lastDoc = snapshot.docs.last;

      if (snapshot.docs.length < safePageSize) break;
    }

    return docs;
  }

  Future<List<BusinessDirectoryRawDoc>> loadNearbyDocs({
    required String collection,
    required String prefixField,
    required List<String> prefixes,
    required int limit,
    required Duration timeout,
  }) async {
    final safePrefixes = BusinessDirectoryQueryBudgetPolicy.whereInPrefixes(
      prefixes,
    );
    if (safePrefixes.isEmpty) return const <BusinessDirectoryRawDoc>[];

    final snapshot = await _firestore
        .collection(collection)
        .where(prefixField, whereIn: safePrefixes)
        .limit(BusinessDirectoryQueryBudgetPolicy.nearbyLimit(limit))
        .get(const GetOptions(source: Source.serverAndCache))
        .timeout(timeout);

    return snapshot.docs
        .map((doc) => BusinessDirectoryRawDoc(id: doc.id, data: doc.data()))
        .toList(growable: false);
  }
}
