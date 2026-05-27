import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firebase_collection_paths.dart';
import '../models/app_user_model.dart';
import '../models/business_account_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get users {
    return _db.collection(FirebaseCollectionPaths.users);
  }

  CollectionReference<Map<String, dynamic>> get businesses {
    return _db.collection(FirebaseCollectionPaths.businesses);
  }

  Future<void> saveUser(AppUserModel user) {
    return users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<AppUserModel?> getUser(String uid) async {
    final doc = await users.doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return AppUserModel.fromMap(doc.data()!);
  }

  Future<void> saveBusiness(BusinessAccountModel business) {
    return businesses
        .doc(business.id)
        .set(business.toMap(), SetOptions(merge: true));
  }

  Future<BusinessAccountModel?> getBusiness(String businessId) async {
    final doc = await businesses.doc(businessId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return BusinessAccountModel.fromMap(doc.data()!);
  }
}
