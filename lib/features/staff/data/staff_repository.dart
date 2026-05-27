import 'package:cloud_firestore/cloud_firestore.dart';

abstract class StaffRepository {
  Future<DocumentSnapshot<Map<String, dynamic>>> getBusinessStaff(
    String businessStaffId,
  );

  Stream<QuerySnapshot<Map<String, dynamic>>> watchBusinessStaff(
    String businessId,
  );

  Future<QuerySnapshot<Map<String, dynamic>>> getBusinessStaffForBusiness(
    String businessId,
  );
}
