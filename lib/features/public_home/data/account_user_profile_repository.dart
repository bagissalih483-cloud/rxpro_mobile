import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class AccountUserProfileRepository {
  AccountUserProfileRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<AccountUserProfileData> fetchProfile(User user) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .get();

    return AccountUserProfileData.fromFirebase(
      user: user,
      data: Map<String, dynamic>.from(doc.data() ?? const <String, dynamic>{}),
    );
  }

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String phone,
    required String city,
    required String district,
    String? photoUrl,
  }) async {
    final currentUser = _auth.currentUser;
    final cleanName = displayName.trim();
    final cleanPhone = phone.trim();
    final cleanCity = city.trim();
    final cleanDistrict = district.trim();
    final cleanPhotoUrl = photoUrl?.trim();

    if (currentUser != null && currentUser.uid == uid) {
      if (cleanName.isNotEmpty && currentUser.displayName != cleanName) {
        await currentUser.updateDisplayName(cleanName);
      }

      if (cleanPhotoUrl != null &&
          cleanPhotoUrl.isNotEmpty &&
          currentUser.photoURL != cleanPhotoUrl) {
        await currentUser.updatePhotoURL(cleanPhotoUrl);
      }
    }

    final payload = <String, dynamic>{
      FirestoreFields.uid: uid,
      FirestoreFields.displayName: cleanName,
      FirestoreFields.fullName: cleanName,
      FirestoreFields.phone: cleanPhone,
      FirestoreFields.phoneNumber: cleanPhone,
      FirestoreFields.city: cleanCity,
      FirestoreFields.district: cleanDistrict,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.sourceModule: 'account_user_profile',
    };

    if (cleanPhotoUrl != null && cleanPhotoUrl.isNotEmpty) {
      payload[FirestoreFields.photoUrl] = cleanPhotoUrl;
      payload[FirestoreFields.imageUrl] = cleanPhotoUrl;
    }

    final email = currentUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      payload[FirestoreFields.email] = email;
      payload[FirestoreFields.emailLower] = email.toLowerCase();
    }

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .set(payload, SetOptions(merge: true));
  }
}

class AccountUserProfileData {
  const AccountUserProfileData({
    required this.displayName,
    required this.email,
    required this.phone,
    required this.city,
    required this.district,
    required this.photoUrl,
  });

  factory AccountUserProfileData.fromFirebase({
    required User user,
    required Map<String, dynamic> data,
  }) {
    return AccountUserProfileData(
      displayName: _firstNonEmpty([
        data[FirestoreFields.displayName],
        data[FirestoreFields.fullName],
        user.displayName,
      ]),
      email: _firstNonEmpty([data[FirestoreFields.email], user.email]),
      phone: _firstNonEmpty([
        data[FirestoreFields.phone],
        data[FirestoreFields.phoneNumber],
        user.phoneNumber,
      ]),
      city: (data[FirestoreFields.city] ?? '').toString().trim(),
      district: (data[FirestoreFields.district] ?? '').toString().trim(),
      photoUrl: _firstNonEmpty([
        data[FirestoreFields.photoUrl],
        data[FirestoreFields.imageUrl],
        user.photoURL,
      ]),
    );
  }

  final String displayName;
  final String email;
  final String phone;
  final String city;
  final String district;
  final String photoUrl;

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return '';
  }
}
