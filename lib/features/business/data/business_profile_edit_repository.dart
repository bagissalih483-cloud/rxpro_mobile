import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/businesses/business_geo_index.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

/// 56X: BusinessProfileEditPage repository foundation.
/// UI wiring is intentionally not changed in this stage.
class BusinessProfileEditRepository {
  BusinessProfileEditRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _businessRef(String businessId) {
    return _firestore
        .collection(FirestoreCollections.businesses)
        .doc(businessId);
  }

  Future<Map<String, dynamic>> fetchBusinessProfile(String businessId) async {
    final snap = await _businessRef(businessId).get();
    return snap.data() ?? <String, dynamic>{};
  }

  Future<void> updateBusinessProfileInfo({
    required String businessId,
    required String businessName,
    required String categoryId,
    required String categoryLabel,
    required List<String> categoryKeywords,
    required String phone,
    required String businessEmail,
    required String websiteUrl,
    required String instagramUrl,
    required String whatsappPhone,
    required String description,
    required String city,
    required String district,
    required String address,
    required String workingHours,
    double? latitude,
    double? longitude,
  }) {
    final payload = <String, dynamic>{
      FirestoreFields.businessName: businessName,
      FirestoreFields.name: businessName,
      FirestoreFields.companyName: businessName,
      FirestoreFields.displayName: businessName,
      'categoryId': categoryId,
      FirestoreFields.category: categoryLabel,
      FirestoreFields.categoryLabel: categoryLabel,
      FirestoreFields.businessCategory: categoryLabel,
      'categoryKeywords': categoryKeywords,
      FirestoreFields.phone: phone,
      FirestoreFields.phoneNumber: phone,
      FirestoreFields.nationalPhoneNumber: phone,
      FirestoreFields.businessEmail: businessEmail,
      FirestoreFields.contactEmail: businessEmail,
      FirestoreFields.email: businessEmail,
      FirestoreFields.websiteUrl: websiteUrl,
      FirestoreFields.websiteUri: websiteUrl,
      FirestoreFields.instagramUrl: instagramUrl,
      FirestoreFields.whatsappPhone: whatsappPhone,
      FirestoreFields.description: description,
      FirestoreFields.city: city,
      FirestoreFields.district: district,
      FirestoreFields.address: address,
      FirestoreFields.workingHours: workingHours,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };

    if (latitude != null && longitude != null) {
      final geoPayload = BusinessGeoIndex.payload(
        latitude: latitude,
        longitude: longitude,
      );

      payload.addAll(<String, dynamic>{
        FirestoreFields.lat: latitude,
        FirestoreFields.lng: longitude,
        FirestoreFields.latitude: latitude,
        FirestoreFields.longitude: longitude,
        FirestoreFields.location: GeoPoint(latitude, longitude),
        FirestoreFields.geoHash: geoPayload[FirestoreFields.geoHash]!,
        FirestoreFields.geoHash4: geoPayload[FirestoreFields.geoHash4]!,
        FirestoreFields.geoHash5: geoPayload[FirestoreFields.geoHash5]!,
        FirestoreFields.geoHash6: geoPayload[FirestoreFields.geoHash6]!,
        FirestoreFields.geoHash7: geoPayload[FirestoreFields.geoHash7]!,
        FirestoreFields.locationUpdatedAt: FieldValue.serverTimestamp(),
        FirestoreFields.locationSource: 'business_profile_edit',
      });
    }

    return _businessRef(businessId).set(payload, SetOptions(merge: true));
  }

  Future<void> updateBusinessLocation({
    required String businessId,
    required double latitude,
    required double longitude,
  }) {
    final geoPayload = BusinessGeoIndex.payload(
      latitude: latitude,
      longitude: longitude,
    );

    return _businessRef(businessId).set(<String, dynamic>{
      FirestoreFields.lat: latitude,
      FirestoreFields.lng: longitude,
      FirestoreFields.latitude: latitude,
      FirestoreFields.longitude: longitude,
      FirestoreFields.location: GeoPoint(latitude, longitude),
      FirestoreFields.geoHash: geoPayload[FirestoreFields.geoHash]!,
      FirestoreFields.geoHash4: geoPayload[FirestoreFields.geoHash4]!,
      FirestoreFields.geoHash5: geoPayload[FirestoreFields.geoHash5]!,
      FirestoreFields.geoHash6: geoPayload[FirestoreFields.geoHash6]!,
      FirestoreFields.geoHash7: geoPayload[FirestoreFields.geoHash7]!,
      FirestoreFields.locationUpdatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.locationSource: 'business_profile_location_button',
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateBusinessLogoUrl({
    required String businessId,
    required String logoUrl,
  }) {
    return _businessRef(businessId).set(<String, dynamic>{
      FirestoreFields.logoUrl: logoUrl,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateBusinessCoverUrl({
    required String businessId,
    required String coverUrl,
  }) {
    return _businessRef(businessId).set(<String, dynamic>{
      FirestoreFields.coverUrl: coverUrl,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
