import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_cache_service.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

class HomeExploreClaimRepository {
  HomeExploreClaimRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> submitClaimRequest(BusinessDirectoryItem item) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const HomeExploreClaimException('loginRequired');
    }

    final placeId = item.placeId.trim();
    if (placeId.isEmpty) {
      throw const HomeExploreClaimException('missingPlaceId');
    }

    final docId = '${user.uid}_${_safeDocId(placeId)}';
    final payload = <String, dynamic>{
      FirestoreFields.uid: user.uid,
      FirestoreFields.userId: user.uid,
      FirestoreFields.email: user.email ?? '',
      FirestoreFields.displayName: user.displayName ?? '',
      FirestoreFields.businessName: item.name,
      FirestoreFields.category: item.category,
      FirestoreFields.categoryLabel: item.category,
      FirestoreFields.businessCategory: item.category,
      FirestoreFields.address: item.address,
      FirestoreFields.phone: item.phone,
      'placeId': placeId,
      'googlePlaceId': placeId,
      'mapsUrl': item.mapsUrl,
      'sourceBusinessId': item.id,
      'sourceProvider': item.source,
      'claimSource': 'home_explore_directory_card',
      FirestoreFields.status: 'pending',
      'reviewStatus': 'pending',
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };

    if (item.lat != null && item.lng != null) {
      payload.addAll(<String, dynamic>{
        FirestoreFields.lat: item.lat,
        FirestoreFields.lng: item.lng,
        FirestoreFields.latitude: item.lat,
        FirestoreFields.longitude: item.lng,
        FirestoreFields.location: GeoPoint(item.lat!, item.lng!),
      });
    }

    await _firestore
        .collection(FirestoreCollections.businessClaimRequests)
        .doc(docId)
        .set(payload, SetOptions(merge: true));
  }

  static String _safeDocId(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}

class HomeExploreClaimException implements Exception {
  const HomeExploreClaimException(this.code);

  final String code;

  @override
  String toString() => 'HomeExploreClaimException($code)';
}
