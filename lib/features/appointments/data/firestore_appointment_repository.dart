import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/appointments/data/appointment_repository.dart';

/// 50C-E1: Appointment repository Firestore collection/field literals use
/// FirestoreCollections/FirestoreFields constants. Query behavior is unchanged.
class FirestoreAppointmentRepository implements AppointmentRepository {
  FirestoreAppointmentRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _db.collection(FirestoreCollections.users).doc(uid).get();
  }

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
  Future<QuerySnapshot<Map<String, dynamic>>> findActiveConflict({
    required String businessId,
    required String businessStaffId,
    required String dateText,
    required String timeText,
  }) {
    return _db
        .collection(FirestoreCollections.appointments)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .where(FirestoreFields.staffId, isEqualTo: businessStaffId)
        .where(FirestoreFields.dateText, isEqualTo: dateText)
        .where(FirestoreFields.status, whereIn: ['active', 'pending'])
        .get();
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> createAppointment(
    Map<String, dynamic> payload,
  ) {
    return _db.collection(FirestoreCollections.appointments).add(payload);
  }
}
