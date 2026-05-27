import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/firestore/firestore_schema_versions.dart';
import 'package:rxpro_mobile/core/realtime/rx_notification_service.dart';
import 'package:rxpro_mobile/core/session/app_role.dart';
import 'package:rxpro_mobile/core/session/session_role_policy.dart';
import 'package:rxpro_mobile/features/appointments/data/appointment_repository.dart';
import 'package:rxpro_mobile/features/appointments/data/firestore_appointment_repository.dart';
import 'package:rxpro_mobile/features/appointments/domain/appointment_booking_request.dart';
import 'package:rxpro_mobile/features/appointments/domain/appointment_booking_result.dart';
import 'package:rxpro_mobile/features/appointments/domain/service_staff_compatibility_policy.dart';

class AppointmentBookingService {
  AppointmentBookingService({
    FirebaseAuth? auth,
    AppointmentRepository? repository,
    ServiceStaffCompatibilityPolicy? compatibilityPolicy,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _repository = repository ?? FirestoreAppointmentRepository(),
       _compatibilityPolicy =
           compatibilityPolicy ?? const ServiceStaffCompatibilityPolicy();

  final FirebaseAuth _auth;
  final AppointmentRepository _repository;
  final ServiceStaffCompatibilityPolicy _compatibilityPolicy;

  Future<AppointmentBookingResult> createCustomerAppointment(
    AppointmentBookingRequest request,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return AppointmentBookingResult.failure('Randevu almak için giriş yapın.');
    }

    if (!request.hasRequiredSelection) {
      return AppointmentBookingResult.failure(
        'Hizmet, personel, tarih ve saat seçin.',
      );
    }

    final bookingUserDoc = await _repository.getUser(user.uid);
    final bookingUserData = bookingUserDoc.data() ?? <String, dynamic>{};

    if (_isCorporateSession(bookingUserData)) {
      return AppointmentBookingResult.failure(
        'Kurumsal hesap açıkken randevu talebi oluşturulamaz. Randevu almak için bireysel kullanıcı hesabıyla giriş yapın.',
      );
    }

    final staffDoc = await _repository.getBusinessStaff(
      request.businessStaffId,
    );
    final staffData = staffDoc.data();

    if (!staffDoc.exists) {
      return AppointmentBookingResult.failure('Seçilen personel bulunamadı.');
    }

    final compatibility = _compatibilityPolicy.validate(
      staffData: staffData,
      expectedBusinessId: request.businessId,
      selectedServiceId: request.serviceId,
    );

    if (!compatibility.valid) {
      return AppointmentBookingResult.failure(compatibility.message);
    }

    final startAt = _parseAppointmentStart(request.dateText, request.timeText);
    final endAt = startAt?.add(
      Duration(minutes: request.normalizedDurationMinutes),
    );

    final conflict = await _repository.findActiveConflict(
      businessId: request.businessId,
      businessStaffId: request.businessStaffId,
      dateText: request.dateText,
      timeText: request.timeText,
    );

    if (_hasActiveConflict(conflict.docs, request, startAt, endAt)) {
      return AppointmentBookingResult.failure('Bu saat için randevu alınmış.');
    }

    final userDoc = await _repository.getUser(user.uid);
    final userData = userDoc.data() ?? <String, dynamic>{};
    final customerName =
        userData['displayName']?.toString() ??
        user.email ??
        'Bireysel Kullanıcı';

    final staffServiceIdsAtBooking = request.staffServiceIdsAtBooking.isNotEmpty
        ? request.staffServiceIdsAtBooking
        : compatibility.staffServiceIds;

    final appointmentRef = await _repository.createAppointment({
      FirestoreFields.businessId: request.businessId,
      FirestoreFields.businessName: request.businessName,
      FirestoreFields.category: request.category,
      FirestoreFields.customerUid: user.uid,
      FirestoreFields.customerId: user.uid,
      FirestoreFields.userId: user.uid,
      'uid': user.uid,
      'clientUid': user.uid,
      FirestoreFields.customerName: customerName,
      'customerEmail': user.email ?? '',
      FirestoreFields.serviceId: request.serviceId,
      FirestoreFields.serviceName: request.serviceName,
      FirestoreFields.businessStaffId: request.businessStaffId,
      FirestoreFields.assignedStaffId: request.businessStaffId,
      'staffDocId': request.businessStaffId,
      FirestoreFields.staffId: request.businessStaffId,
      if (request.staffUid.trim().isNotEmpty)
        FirestoreFields.staffUid: request.staffUid,
      if (request.staffUid.trim().isNotEmpty)
        FirestoreFields.assignedStaffUid: request.staffUid,
      FirestoreFields.staffName: request.staffName,
      'assignedStaffName': request.staffName,
      if (request.staffEmail.trim().isNotEmpty)
        'staffEmail': request.staffEmail,
      'staffServiceIdsAtBooking': staffServiceIdsAtBooking,
      FirestoreFields.serviceStaffRelationVersion:
          FirestoreSchemaVersions.serviceStaffRelation49bC,
      'serviceStaffRelationValidated': true,
      FirestoreFields.dateText: request.dateText,
      FirestoreFields.appointmentDate: request.dateText,
      FirestoreFields.timeText: request.timeText,
      FirestoreFields.appointmentTime: request.timeText,
      FirestoreFields.startAt: startAt == null
          ? null
          : Timestamp.fromDate(startAt),
      FirestoreFields.startAtIso: startAt?.toIso8601String(),
      FirestoreFields.endAt: endAt == null ? null : Timestamp.fromDate(endAt),
      'endAtIso': endAt?.toIso8601String(),
      FirestoreFields.durationMinutes: request.normalizedDurationMinutes,
      FirestoreFields.status: 'active',
      FirestoreFields.appointmentStatus: 'active',
      FirestoreFields.state: 'active',
      FirestoreFields.isActive: true,
      FirestoreFields.isCancelled: false,
      FirestoreFields.createdAt: DateTime.now().toIso8601String(),
      'createdAtTs': FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: DateTime.now().toIso8601String(),
    });

    await RxNotificationService.createBusinessNotification(
      businessId: request.businessId,
      businessName: request.businessName,
      recipientUid: '',
      actorUid: user.uid,
      type: 'appointment_created_business',
      title: 'Yeni randevu alındı',
      body:
          '$customerName, ${request.serviceName} için ${request.dateText} ${request.timeText} saatine randevu aldı.',
      route: 'businessAppointments',
      data: {
        'appointmentId': appointmentRef.id,
        FirestoreFields.customerUid: user.uid,
        FirestoreFields.customerName: customerName,
        FirestoreFields.serviceName: request.serviceName,
        FirestoreFields.staffName: request.staffName,
        FirestoreFields.businessStaffId: request.businessStaffId,
        FirestoreFields.assignedStaffId: request.businessStaffId,
        FirestoreFields.staffUid: request.staffUid,
        FirestoreFields.dateText: request.dateText,
        FirestoreFields.timeText: request.timeText,
      },
    );

    return AppointmentBookingResult.success(
      appointmentId: appointmentRef.id,
      serviceName: request.serviceName,
      staffName: request.staffName,
      dateText: request.dateText,
      timeText: request.timeText,
    );
  }

  static DateTime? _parseAppointmentStart(String dateText, String timeText) {
    final date = _parseAppointmentDate(dateText);
    final time = _parseAppointmentTime(timeText);
    if (date == null || time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static bool _hasActiveConflict(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    AppointmentBookingRequest request,
    DateTime? requestedStart,
    DateTime? requestedEnd,
  ) {
    for (final doc in docs) {
      final data = doc.data();
      if (!_blocksSlot(data)) continue;

      final range = _appointmentRangeOf(data, request.dateText);
      if (range == null || requestedStart == null || requestedEnd == null) {
        final existingTime = _firstNonEmpty([
          data[FirestoreFields.timeText],
          data[FirestoreFields.appointmentTime],
        ]);
        if (existingTime == request.timeText) return true;
        continue;
      }

      if (_rangesOverlap(requestedStart, requestedEnd, range.start, range.end)) {
        return true;
      }
    }

    return false;
  }

  static _AppointmentRange? _appointmentRangeOf(
    Map<String, dynamic> data,
    String fallbackDateText,
  ) {
    final start = _dateTimeOf(
      data[FirestoreFields.startAt] ?? data[FirestoreFields.startAtIso],
      fallbackDateText,
      _firstNonEmpty([
        data[FirestoreFields.timeText],
        data[FirestoreFields.appointmentTime],
      ]),
    );
    if (start == null) return null;

    final explicitEnd = _dateTimeOf(
      data[FirestoreFields.endAt] ?? data['endAtIso'],
      fallbackDateText,
      '',
    );
    final end =
        explicitEnd ??
        start.add(
          Duration(
            minutes: _intOf(
              data[FirestoreFields.durationMinutes] ??
                  data[FirestoreFields.duration],
              fallback: 30,
            ),
          ),
        );

    return _AppointmentRange(start, end);
  }

  static DateTime? _dateTimeOf(
    Object? value,
    String fallbackDateText,
    String fallbackTimeText,
  ) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) {
      final parsed = DateTime.tryParse(text);
      if (parsed != null) return parsed;
    }

    final date = _parseAppointmentDate(fallbackDateText);
    final time = _parseAppointmentTime(fallbackTimeText);
    if (date == null || time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static DateTime? _parseAppointmentDate(String dateText) {
    final clean = dateText.trim();
    if (clean.isEmpty) return null;

    final iso = DateTime.tryParse(clean);
    if (iso != null) return iso;

    try {
      final dateParts = clean.split('.');
      if (dateParts.length == 3) {
        return DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
        );
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static _TimeParts? _parseAppointmentTime(String timeText) {
    try {
      final timeParts = timeText.trim().split(':');
      if (timeParts.length >= 2) {
        return _TimeParts(int.parse(timeParts[0]), int.parse(timeParts[1]));
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static bool _rangesOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
  }

  static bool _blocksSlot(Map<String, dynamic> data) {
    final status = _firstNonEmpty([
      data[FirestoreFields.status],
      data[FirestoreFields.appointmentStatus],
      data[FirestoreFields.state],
      data[FirestoreFields.bookingStatus],
    ]).toLowerCase();

    if (data[FirestoreFields.isCancelled] == true) return false;
    if (status.contains('cancel') || status.contains('iptal')) return false;
    if (status == 'completed' || status == 'done' || status == 'finished') {
      return false;
    }

    return true;
  }

  static int _intOf(Object? value, {required int fallback}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return '';
  }

  static bool _isCorporateSession(Map<String, dynamic>? data) {
    if (data == null) return false;

    final canonicalRole = SessionRolePolicy.resolveCanonicalRole(data);

    return canonicalRole == AppRole.corporateOwner ||
        canonicalRole == AppRole.corporateStaff;
  }
}

class _AppointmentRange {
  const _AppointmentRange(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

class _TimeParts {
  const _TimeParts(this.hour, this.minute);

  final int hour;
  final int minute;
}
