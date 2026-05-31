import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AppointmentRepository {
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid);

  Future<DocumentSnapshot<Map<String, dynamic>>> getBusinessStaff(
    String businessStaffId,
  );

  Future<QuerySnapshot<Map<String, dynamic>>> findActiveConflict({
    required String businessId,
    required String businessStaffId,
    required String dateText,
    required String timeText,
  });

  Future<DocumentReference<Map<String, dynamic>>> createAppointment(
    Map<String, dynamic> payload,
  );

  Future<DocumentReference<Map<String, dynamic>>>
  createAppointmentWithSlotLock({
    required Map<String, dynamic> payload,
    required DateTime startAt,
    required DateTime endAt,
    required String businessId,
    required String businessStaffId,
  });
}

class AppointmentSlotConflictException implements Exception {
  const AppointmentSlotConflictException();
}
