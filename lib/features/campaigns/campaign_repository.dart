import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'campaign_models.dart';

class CampaignRepository {
  CampaignRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Future<CampaignBusinessContext?> resolveOwnedBusinessForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};

    final directBusinessId = CampaignFieldReaders.firstString(
      userData,
      const <String>[
        'businessId',
        'ownedBusinessId',
        'businessDocId',
        'companyId',
      ],
    );

    if (directBusinessId.isNotEmpty) {
      final direct = await _readBusinessById(directBusinessId);
      if (direct != null) {
        return direct;
      }
    }

    return _findBusinessByOwnerUid(user.uid);
  }

  Future<List<CampaignRecord>> listBusinessCampaigns({
    required String businessId,
    int limit = 300,
    Iterable<String> collections =
        CampaignCollections.businessReadableCampaignCollections,
  }) async {
    final normalizedBusinessId = businessId.trim();
    final deduped = <String, CampaignRecord>{};

    for (final collection in collections) {
      Query<Map<String, dynamic>> query = _firestore.collection(collection);
      if (normalizedBusinessId.isNotEmpty) {
        query = query.where('businessId', isEqualTo: normalizedBusinessId);
      }

      final snap = await query.limit(limit).get();
      for (final doc in snap.docs) {
        final record = CampaignRecord.fromDoc(
          doc,
          sourceCollection: collection,
        );
        deduped['$collection/${record.id}'] = record;
      }
    }

    final list = deduped.values.toList();
    list.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return list;
  }

  Future<List<CampaignRecord>> listCustomerCampaigns({
    int limit = 300,
    Iterable<String> collections =
        CampaignCollections.customerReadableCampaignCollections,
  }) async {
    final deduped = <String, CampaignRecord>{};

    for (final collection in collections) {
      final snap = await _firestore.collection(collection).limit(limit).get();
      for (final doc in snap.docs) {
        final record = CampaignRecord.fromDoc(
          doc,
          sourceCollection: collection,
        );
        if (record.visible) {
          deduped['$collection/${record.id}'] = record;
        }
      }
    }

    final list = deduped.values.toList();
    list.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return list;
  }

  Future<DocumentReference<Map<String, dynamic>>> createBusinessCampaignDraft(
    CampaignDraftInput input,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Campaign publish requires an authenticated user.');
    }

    final doc = _firestore
        .collection(CampaignCollections.businessCampaigns)
        .doc();
    final timestamp = FieldValue.serverTimestamp();

    await doc.set(
      input.toFirestoreMap(ownerUid: user.uid, serverTimestamp: timestamp),
    );

    return doc;
  }

  Future<CampaignRecord?> findBusinessCampaignByClientRequestKey(
    String clientRequestKey,
  ) async {
    final key = clientRequestKey.trim();
    if (key.isEmpty) return null;

    final snapshot = await _firestore
        .collection(CampaignCollections.businessCampaigns)
        .where('clientRequestKey', isEqualTo: key)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return CampaignRecord.fromDoc(
      snapshot.docs.first,
      sourceCollection: CampaignCollections.businessCampaigns,
    );
  }

  Future<DocumentReference<Map<String, dynamic>>> createBulkMessageDraft(
    BulkMessageDraftInput input,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Bulk message draft requires an authenticated user.');
    }

    final doc = await _firestore
        .collection(CampaignCollections.bulkMessageDrafts)
        .add(
          input.toFirestoreMap(
            ownerUid: user.uid,
            serverTimestamp: FieldValue.serverTimestamp(),
          ),
        );

    return doc;
  }

  Future<void> markCampaignPassive(CampaignRecord campaign) async {
    await _firestore.collection(campaign.sourceCollection).doc(campaign.id).set(
      <String, dynamic>{
        'status': 'passive',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<CampaignBusinessContext?> _readBusinessById(String businessId) async {
    const collections = <String>[
      'businesses',
      'registeredBusinesses',
      'businessProfiles',
    ];

    for (final collection in collections) {
      final doc = await _firestore.collection(collection).doc(businessId).get();
      if (doc.exists) {
        return CampaignBusinessContext.fromDoc(
          doc,
          sourceCollection: collection,
        );
      }
    }

    return null;
  }

  Future<CampaignBusinessContext?> _findBusinessByOwnerUid(String uid) async {
    const collections = <String>[
      'businesses',
      'registeredBusinesses',
      'businessProfiles',
    ];

    const ownerFields = <String>['ownerUid', 'ownerId', 'uid', 'userId'];

    for (final collection in collections) {
      for (final field in ownerFields) {
        final snap = await _firestore
            .collection(collection)
            .where(field, isEqualTo: uid)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          return CampaignBusinessContext.fromDoc(
            snap.docs.first,
            sourceCollection: collection,
          );
        }
      }
    }

    return null;
  }
}
