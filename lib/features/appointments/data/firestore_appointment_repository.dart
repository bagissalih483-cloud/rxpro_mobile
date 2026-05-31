import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/appointments/data/appointment_repository.dart';
import 'package:rxpro_mobile/features/appointments/domain/appointment_slot_lock_policy.dart';

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

  @override
  Future<DocumentReference<Map<String, dynamic>>>
  createAppointmentWithSlotLock({
    required Map<String, dynamic> payload,
    required DateTime startAt,
    required DateTime endAt,
    required String businessId,
    required String businessStaffId,
  }) async {
    final appointmentRef = _db
        .collection(FirestoreCollections.appointments)
        .doc();
    final slotRefs = _slotRefsForRange(
      businessId: businessId,
      businessStaffId: businessStaffId,
      startAt: startAt,
      endAt: endAt,
    );

    await _db.runTransaction((transaction) async {
      for (final slotRef in slotRefs) {
        final slot = await transaction.get(slotRef);
        if (slot.exists) {
          throw const AppointmentSlotConflictException();
        }
      }

      transaction.set(appointmentRef, {
        ...payload,
        'appointmentId': appointmentRef.id,
        'slotLockVersion': 'appointment_slot_v1',
      });

      for (final slotRef in slotRefs) {
        transaction.set(slotRef, {
          FirestoreFields.businessId: businessId,
          FirestoreFields.businessStaffId: businessStaffId,
          FirestoreFields.appointmentId: appointmentRef.id,
          FirestoreFields.customerUid: payload[FirestoreFields.customerUid],
          FirestoreFields.dateText: payload[FirestoreFields.dateText],
          FirestoreFields.startAt: Timestamp.fromDate(startAt),
          FirestoreFields.endAt: Timestamp.fromDate(endAt),
          FirestoreFields.status: 'active',
          FirestoreFields.createdAt: FieldValue.serverTimestamp(),
        });
      }
    });

    return appointmentRef;
  }

  List<DocumentReference<Map<String, dynamic>>> _slotRefsForRange({
    required String businessId,
    required String businessStaffId,
    required DateTime startAt,
    required DateTime endAt,
  }) {
    return AppointmentSlotLockPolicy.slotIdsForRange(
          businessId: businessId,
          businessStaffId: businessStaffId,
          startAt: startAt,
          endAt: endAt,
        )
        .map(
          (slotId) =>
              _db.collection(FirestoreCollections.appointmentSlots).doc(slotId),
        )
        .toList();
  }
}
