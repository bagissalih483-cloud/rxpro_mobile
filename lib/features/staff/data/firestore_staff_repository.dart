import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/staff/data/staff_repository.dart';

/// 50C-E1: Staff repository Firestore collection/field literals use
/// FirestoreCollections/FirestoreFields constants. Query behavior is unchanged.
class FirestoreStaffRepository implements StaffRepository {
  FirestoreStaffRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getBusinessStaff(
    String businessStaffId,
  ) {
    return _db
        .collection(FirestoreCollections.businessStaff)
        .doc(businessStaffId)
        .get();
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchBusinessStaff(
    String businessId,
  ) {
    return _db
        .collection(FirestoreCollections.businessStaff)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .snapshots();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getBusinessStaffForBusiness(
    String businessId,
  ) {
    return _db
        .collection(FirestoreCollections.businessStaff)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .get();
  }
}
