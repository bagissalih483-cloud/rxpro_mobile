import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

class StaffWorkspaceRepository {
  StaffWorkspaceRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get currentUid => _auth.currentUser?.uid ?? '';
  String get currentEmail => _auth.currentUser?.email ?? '';

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  watchBusinessAppointments({required String businessId, int limit = 250}) {
    if (businessId.trim().isEmpty) {
      return Stream.value(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);
    }

    return _firestore
        .collection(FirestoreCollections.appointments)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> writeActivityLog({
    required String businessId,
    required String staffId,
    required String staffName,
    required String type,
    required String title,
    required String description,
    String? appointmentId,
    String? expenseId,
    Map<String, dynamic>? extra,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty || businessId.trim().isEmpty) return;

    await _firestore.collection(FirestoreCollections.businessActivityLogs).add({
      FirestoreFields.businessId: businessId,
      FirestoreFields.staffId: staffId,
      FirestoreFields.staffUid: uid,
      FirestoreFields.staffName: staffName,
      FirestoreFields.type: type,
      FirestoreFields.title: title,
      FirestoreFields.description: description,
      FirestoreFields.appointmentId: appointmentId,
      FirestoreFields.expenseId: expenseId,
      FirestoreFields.extra: extra ?? <String, dynamic>{},
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdByUid: uid,
      FirestoreFields.source: 'staff_workspace',
    });
  }

  Future<void> completeAppointment({
    required String appointmentId,
    required String staffId,
    required String staffName,
    required bool hasStarted,
    required DateTime completedAtLocal,
    required int? workDurationMinutes,
  }) {
    final uid = currentUid;
    if (uid.isEmpty || appointmentId.trim().isEmpty) return Future.value();

    final payload = <String, dynamic>{
      FirestoreFields.status: 'completed',
      FirestoreFields.appointmentStatus: 'completed',
      FirestoreFields.state: 'completed',
      FirestoreFields.isCompleted: true,
      FirestoreFields.isActive: false,
      FirestoreFields.completedAt: FieldValue.serverTimestamp(),
      FirestoreFields.workCompletedAtLocalIso: completedAtLocal
          .toIso8601String(),
      FirestoreFields.completedByUid: uid,
      FirestoreFields.completedByName: staffName,
      FirestoreFields.staffUid: uid,
      FirestoreFields.linkedStaffId: staffId,
      FirestoreFields.lastStaffActionByUid: uid,
      FirestoreFields.lastStaffActionByName: staffName,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };

    if (workDurationMinutes != null && workDurationMinutes >= 0) {
      payload[FirestoreFields.workDurationMinutes] = workDurationMinutes;
      payload[FirestoreFields.durationSource] = hasStarted
          ? 'staff_start_to_complete'
          : 'appointment_start_to_complete';
    }

    return _firestore
        .collection(FirestoreCollections.appointments)
        .doc(appointmentId)
        .set(payload, SetOptions(merge: true));
  }

  Future<void> startAppointment({
    required String appointmentId,
    required String staffId,
    required String staffName,
  }) {
    final uid = currentUid;
    if (uid.isEmpty || appointmentId.trim().isEmpty) return Future.value();

    return _firestore
        .collection(FirestoreCollections.appointments)
        .doc(appointmentId)
        .set({
          FirestoreFields.status: 'inProgress',
          FirestoreFields.appointmentStatus: 'inProgress',
          FirestoreFields.state: 'inProgress',
          FirestoreFields.startedAt: FieldValue.serverTimestamp(),
          FirestoreFields.startedByUid: uid,
          FirestoreFields.staffUid: uid,
          FirestoreFields.linkedStaffId: staffId,
          FirestoreFields.lastStaffActionByUid: uid,
          FirestoreFields.lastStaffActionByName: staffName,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> createOverdueReminder({
    required String appointmentId,
    required String businessId,
    required String staffName,
    required String appointmentTitle,
    required String status,
    required String time,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty || appointmentId.trim().isEmpty) return;

    await _firestore
        .collection(FirestoreCollections.appointments)
        .doc(appointmentId)
        .set({
          FirestoreFields.overdueReminderAt: FieldValue.serverTimestamp(),
          FirestoreFields.overdueReminderByUid: uid,
          FirestoreFields.overdueReminderByName: staffName,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await _firestore.collection(FirestoreCollections.notifications).add({
      FirestoreFields.targetScope: 'business',
      FirestoreFields.businessId: businessId,
      FirestoreFields.recipientUid: '',
      FirestoreFields.actorUid: uid,
      'type': 'appointment_overdue_staff_warning',
      'title': 'Sonuclanmamis randevu uyarisi',
      FirestoreFields.body:
          '$appointmentTitle icin randevu saati gecti, kayit hala acik.',
      FirestoreFields.route: 'staff_tasks',
      FirestoreFields.data: {
        FirestoreFields.appointmentId: appointmentId,
        FirestoreFields.status: status,
        FirestoreFields.time: time,
      },
      FirestoreFields.isRead: false,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdAtIso: DateTime.now().toIso8601String(),
      FirestoreFields.source: 'staff_workspace_tasks_rev2',
    });
  }

  Future<void> cancelAppointmentNoShow({
    required String appointmentId,
    required String businessId,
    required String staffId,
    required String staffName,
    required String appointmentTitle,
    required String time,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty || appointmentId.trim().isEmpty) return;

    await _firestore
        .collection(FirestoreCollections.appointments)
        .doc(appointmentId)
        .set({
          FirestoreFields.status: 'noShow',
          FirestoreFields.appointmentStatus: 'noShow',
          FirestoreFields.state: 'noShow',
          FirestoreFields.isCancelled: true,
          FirestoreFields.isActive: false,
          FirestoreFields.noShow: true,
          'cancelReason': 'no_show_or_late_cancel_after_appointment_time',
          FirestoreFields.cancelledAt: FieldValue.serverTimestamp(),
          FirestoreFields.cancelledByUid: uid,
          FirestoreFields.cancelledByName: staffName,
          FirestoreFields.staffUid: uid,
          FirestoreFields.linkedStaffId: staffId,
          FirestoreFields.lastStaffActionByUid: uid,
          FirestoreFields.lastStaffActionByName: staffName,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await _firestore.collection(FirestoreCollections.notifications).add({
      FirestoreFields.targetScope: 'business',
      FirestoreFields.businessId: businessId,
      FirestoreFields.recipientUid: '',
      FirestoreFields.actorUid: uid,
      'type': 'appointment_cancelled_no_show_by_staff',
      'title': 'Randevu iptal / gelmedi',
      FirestoreFields.body:
          '$appointmentTitle iptal/gelmedi olarak isaretlendi.',
      FirestoreFields.route: 'staff_tasks',
      FirestoreFields.data: {
        FirestoreFields.appointmentId: appointmentId,
        FirestoreFields.status: 'noShow',
        'reason': 'no_show_or_late_cancel_after_appointment_time',
        FirestoreFields.time: time,
      },
      FirestoreFields.isRead: false,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdAtIso: DateTime.now().toIso8601String(),
      FirestoreFields.source: 'staff_workspace_tasks_rev2',
    });
  }

  Future<String> createExpense({
    required String businessId,
    required String staffId,
    required String createdByName,
    required String title,
    required String category,
    required double amount,
    required String note,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) return '';

    final expenseRef = await _firestore
        .collection(FirestoreCollections.businessExpenses)
        .add({
          FirestoreFields.businessId: businessId,
          FirestoreFields.staffId: staffId,
          FirestoreFields.createdByUid: uid,
          FirestoreFields.createdByName: createdByName,
          FirestoreFields.title: title,
          FirestoreFields.category: category,
          FirestoreFields.amount: amount,
          FirestoreFields.note: note,
          FirestoreFields.expenseDate: FieldValue.serverTimestamp(),
          FirestoreFields.createdAt: FieldValue.serverTimestamp(),
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
          FirestoreFields.source: 'staff_workspace',
        });

    return expenseRef.id;
  }
}
