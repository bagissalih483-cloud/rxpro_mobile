import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/realtime/rx_notification_service.dart';
import 'package:rxpro_mobile/core/services/app_observability_service.dart';
import 'package:rxpro_mobile/features/appointments/data/appointment_slot_lock_release.dart';
import 'package:rxpro_mobile/features/appointments/domain/appointment_state_transition_policy.dart';

class BusinessAppointmentManagementRepository {
  BusinessAppointmentManagementRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int _conflictPageSize = 100;
  static const int _conflictPageCap = 1000;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection(FirestoreCollections.appointments);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAppointments({
    required String businessId,
  }) {
    return _appointments
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .limit(300)
        .snapshots(includeMetadataChanges: true);
  }

  Future<bool> slotHasConflict({
    required String businessId,
    required String currentAppointmentId,
    required String dateKey,
    required String visibleDate,
    required String time,
  }) async {
    final docs = await _loadConflictCandidateDocs(businessId);

    for (final doc in docs) {
      if (doc.id == currentAppointmentId) continue;
      final data = doc.data();
      if (!_blocksSlot(data)) continue;
      if (_sameAppointmentSlot(data, dateKey, visibleDate, time)) {
        return true;
      }
    }

    return false;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadConflictCandidateDocs(String businessId) async {
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;

    while (docs.length < _conflictPageCap) {
      Query<Map<String, dynamic>> query = _appointments
          .where(FirestoreFields.businessId, isEqualTo: businessId)
          .orderBy(FieldPath.documentId)
          .limit(_conflictPageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final remaining = _conflictPageCap - docs.length;
      docs.addAll(snapshot.docs.take(remaining));
      lastDoc = snapshot.docs.last;

      if (snapshot.docs.length < _conflictPageSize) break;
    }

    return docs;
  }

  Future<void> cancelAppointment({
    required String appointmentId,
    required Map<String, dynamic> appointment,
    required String businessId,
    required String businessName,
    required String reason,
  }) async {
    if (!AppointmentStateTransitionPolicy.canCancelByBusiness(
      appointment[FirestoreFields.status] ??
          appointment[FirestoreFields.appointmentStatus],
    )) {
      return;
    }

    final ref = _appointments.doc(appointmentId);
    final batch = _firestore.batch();
    batch.set(ref, {
      ...AppointmentStateTransitionPolicy.businessCancellationFields(
        reason: reason,
      ),
      'customerNoticeTitle': 'Randevunuz iptal edildi',
      'customerNoticeBody': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledAtLocalIso': DateTime.now().toIso8601String(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    for (final slotRef in AppointmentSlotLockRelease.refsForAppointment(
      firestore: _firestore,
      appointment: appointment,
    )) {
      batch.delete(slotRef);
    }
    await batch.commit();

    await notifyCustomer(
      appointment: appointment,
      appointmentId: appointmentId,
      businessId: businessId,
      businessName: businessName,
      type: 'appointment_cancelled',
      title: 'Randevunuz iptal edildi',
      body: '$businessName randevunuzu iptal etti. Gerekce: $reason',
    );

    await AppObservabilityService.instance.logEvent(
      AppAnalyticsEvents.appointmentCancelled,
      parameters: <String, Object?>{
        'appointment_id': appointmentId,
        'actor_role': 'business',
        'reason': reason,
      },
    );
  }

  Future<void> requestPostpone({
    required String appointmentId,
    required Map<String, dynamic> appointment,
    required String businessId,
    required String businessName,
    required BusinessAppointmentPostponeRequest request,
  }) async {
    await _appointments.doc(appointmentId).set({
      'status': 'postpone_requested',
      'appointmentStatus': 'postpone_requested',
      'state': 'postpone_requested',
      'isActive': true,
      'isCancelled': false,
      'postponeRequestedBy': 'business',
      'postponeRequestStatus': 'pending',
      'postponeRequestedDateKey': request.dateKey,
      'postponeRequestedDateText': request.dateText,
      'postponeRequestedTimeText': request.timeText,
      'postponeRequestedStartAt': Timestamp.fromDate(request.startAt),
      'postponeRequestedStartAtIso': request.startAt.toIso8601String(),
      'postponeRequestNote': request.note,
      'customerApprovalRequired': true,
      'customerApprovalStatus': 'pending',
      'customerNoticeTitle': 'Randevu erteleme talebi',
      'customerNoticeBody':
          '${request.dateText} ${request.timeText} icin erteleme talebi gonderildi. Not: ${request.note}',
      'postponeRequestedAt': FieldValue.serverTimestamp(),
      'postponeRequestedAtLocalIso': DateTime.now().toIso8601String(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await notifyCustomer(
      appointment: appointment,
      appointmentId: appointmentId,
      businessId: businessId,
      businessName: businessName,
      type: 'appointment_postpone_requested',
      title: 'Randevu erteleme talebi',
      body:
          '$businessName randevunuz icin ${request.dateText} ${request.timeText} saatine erteleme talebi gonderdi. Not: ${request.note}',
    );
  }

  Future<void> notifyCustomer({
    required Map<String, dynamic> appointment,
    required String businessId,
    required String businessName,
    required String title,
    required String body,
    required String type,
    String? appointmentId,
  }) async {
    final customerUid = _field(appointment, [
      'customerUid',
      'customerId',
      'userId',
      'uid',
      'clientUid',
    ], '');

    if (customerUid.isEmpty || customerUid == '-') return;

    await RxNotificationService.createUserNotification(
      recipientUid: customerUid,
      businessId: businessId,
      businessName: businessName,
      type: type,
      title: title,
      body: body,
      route: 'customerAppointments',
      data: {
        'appointmentId': appointmentId ?? '',
        'serviceName': _field(appointment, ['serviceName', 'title'], ''),
        'dateText': _field(appointment, ['dateText', 'appointmentDate'], ''),
        'timeText': _field(appointment, ['timeText', 'appointmentTime'], ''),
      },
    );
  }

  static String _clean(dynamic value) => value?.toString().trim() ?? '';

  static String _statusOf(Map<String, dynamic> data) {
    return _clean(
      data['status'] ??
          data['appointmentStatus'] ??
          data['state'] ??
          data['bookingStatus'],
    ).toLowerCase();
  }

  static String _field(
    Map<String, dynamic> data,
    List<String> keys, [
    String fallback = '-',
  ]) {
    for (final key in keys) {
      final value = _clean(data[key]);
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  static bool _isCancelled(Map<String, dynamic> data) {
    final status = _statusOf(data);
    final approval = _clean(
      data['customerApprovalStatus'] ?? data['postponeRequestStatus'],
    ).toLowerCase();

    return status.contains('cancel') ||
        status.contains('iptal') ||
        status == 'postpone_rejected' ||
        status == 'reschedule_rejected' ||
        approval == 'rejected' ||
        approval == 'declined' ||
        data['isCancelled'] == true;
  }

  static bool _isCompleted(Map<String, dynamic> data) {
    final status = _statusOf(data);

    return status == 'completed' ||
        status == 'done' ||
        status == 'finished' ||
        status == 'tamamlandi' ||
        status == 'tamamlandı' ||
        status == 'sonuclandi' ||
        status == 'sonuçlandı' ||
        status == 'resulted' ||
        data['isCompleted'] == true ||
        data['completed'] == true;
  }

  static bool _sameAppointmentSlot(
    Map<String, dynamic> data,
    String dateKey,
    String visibleDate,
    String time,
  ) {
    final appointmentDate = _clean(data['appointmentDate']);
    final dateText = _clean(data['dateText']);
    final existingDateKey = _clean(data['dateKey']);
    final postponeDateKey = _clean(data['postponeRequestedDateKey']);
    final appointmentTime = _clean(data['appointmentTime']);
    final timeText = _clean(data['timeText']);
    final postponeTimeText = _clean(data['postponeRequestedTimeText']);

    final sameDate =
        appointmentDate == dateKey ||
        appointmentDate == visibleDate ||
        dateText == dateKey ||
        dateText == visibleDate ||
        existingDateKey == dateKey ||
        postponeDateKey == dateKey;

    final sameTime =
        appointmentTime == time || timeText == time || postponeTimeText == time;

    return sameDate && sameTime;
  }

  static bool _blocksSlot(Map<String, dynamic> data) {
    if (_isCancelled(data) || _isCompleted(data)) return false;

    final status = _statusOf(data);
    if (status == 'postpone_requested' ||
        status == 'reschedule_requested' ||
        status == 'cancel_requested') {
      return false;
    }

    return true;
  }
}

class BusinessAppointmentPostponeRequest {
  const BusinessAppointmentPostponeRequest({
    required this.dateKey,
    required this.dateText,
    required this.timeText,
    required this.startAt,
    required this.note,
  });

  final String dateKey;
  final String dateText;
  final String timeText;
  final DateTime startAt;
  final String note;
}
