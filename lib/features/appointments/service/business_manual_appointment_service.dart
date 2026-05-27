import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class BusinessManualAppointmentService {
  BusinessManualAppointmentService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection(FirestoreCollections.appointments);

  Future<List<BusinessManualAppointmentServiceOption>> loadServices(
    String businessId,
  ) async {
    final cleanBusinessId = businessId.trim();
    if (cleanBusinessId.isEmpty) {
      return const <BusinessManualAppointmentServiceOption>[];
    }

    final snapshot = await _firestore
        .collection(FirestoreCollections.businessServices)
        .where(FirestoreFields.businessId, isEqualTo: cleanBusinessId)
        .limit(100)
        .get();

    final items = snapshot.docs
        .map((doc) {
          final data = doc.data();
          return BusinessManualAppointmentServiceOption(
            id: doc.id,
            name: _firstNonEmpty([
              data[FirestoreFields.serviceName],
              data[FirestoreFields.name],
              data[FirestoreFields.title],
              data[FirestoreFields.service],
              'Hizmet',
            ]),
            durationMinutes: _intOf(
              data[FirestoreFields.durationMinutes] ??
                  data[FirestoreFields.duration],
              fallback: 30,
            ),
          );
        })
        .where((item) => item.name.trim().isNotEmpty)
        .toList();

    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  Future<BusinessManualAppointmentResult> createManualAppointment(
    BusinessManualAppointmentDraft draft,
  ) async {
    final validation = draft.validate();
    if (validation != null) {
      return BusinessManualAppointmentResult.failure(validation);
    }

    final endAt = draft.startAt.add(Duration(minutes: draft.durationMinutes));
    final conflict = await _hasConflict(draft, endAt);
    if (conflict) {
      return BusinessManualAppointmentResult.failure(
        'Seçilen tarih, saat ve personel için mevcut bir randevu var.',
      );
    }

    final currentUser = _auth.currentUser;
    final createdByUid = currentUser?.uid ?? '';
    final createdByName = _firstNonEmpty([
      currentUser?.displayName,
      currentUser?.email,
      'Kurumsal kullanıcı',
    ]);

    final payload = <String, dynamic>{
      FirestoreFields.businessId: draft.businessId,
      FirestoreFields.businessName: draft.businessName,
      FirestoreFields.customerUid: '',
      FirestoreFields.customerId: '',
      FirestoreFields.userId: '',
      'clientUid': '',
      FirestoreFields.customerName: draft.customerName,
      FirestoreFields.clientName: draft.customerName,
      FirestoreFields.customerPhone: draft.customerPhone,
      FirestoreFields.phone: draft.customerPhone,
      'customerEmail': draft.customerEmail,
      FirestoreFields.serviceId: draft.serviceId,
      FirestoreFields.serviceName: draft.serviceName,
      FirestoreFields.service: draft.serviceName,
      FirestoreFields.businessStaffId: draft.staffId,
      FirestoreFields.staffId: draft.staffId,
      FirestoreFields.assignedStaffId: draft.staffId,
      'staffDocId': draft.staffId,
      FirestoreFields.staffName: draft.staffName,
      FirestoreFields.employeeName: draft.staffName,
      'assignedStaffName': draft.staffName,
      FirestoreFields.appointmentDate: draft.dateText,
      FirestoreFields.dateText: draft.dateText,
      FirestoreFields.appointmentDateIso: draft.dateKey,
      'dateKey': draft.dateKey,
      FirestoreFields.appointmentTime: draft.timeText,
      FirestoreFields.timeText: draft.timeText,
      FirestoreFields.startAt: Timestamp.fromDate(draft.startAt),
      FirestoreFields.startAtIso: draft.startAt.toIso8601String(),
      FirestoreFields.endAt: Timestamp.fromDate(endAt),
      'endAtIso': endAt.toIso8601String(),
      FirestoreFields.durationMinutes: draft.durationMinutes,
      FirestoreFields.status: 'active',
      FirestoreFields.appointmentStatus: 'active',
      FirestoreFields.state: 'active',
      FirestoreFields.bookingStatus: 'manual_confirmed',
      FirestoreFields.isActive: true,
      FirestoreFields.isCancelled: false,
      FirestoreFields.note: draft.note,
      'manualEntry': true,
      'createdByRole': 'business',
      FirestoreFields.createdBy: createdByUid,
      FirestoreFields.createdByUid: createdByUid,
      FirestoreFields.createdByName: createdByName,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdAtIso: DateTime.now().toIso8601String(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.sourceModule: 'business_manual_appointment_service',
    };

    final ref = await _appointments.add(payload);

    return BusinessManualAppointmentResult.success(ref.id);
  }

  Future<bool> _hasConflict(
    BusinessManualAppointmentDraft draft,
    DateTime draftEndAt,
  ) async {
    final snapshot = await _appointments
        .where(FirestoreFields.businessId, isEqualTo: draft.businessId)
        .where(FirestoreFields.dateText, isEqualTo: draft.dateText)
        .limit(240)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!_blocksSlot(data)) continue;

      final existingStaff = _firstNonEmpty([
        data[FirestoreFields.businessStaffId],
        data[FirestoreFields.staffId],
        data[FirestoreFields.assignedStaffId],
        data['staffDocId'],
      ]);

      final sameResource =
          draft.staffId.isEmpty ||
          existingStaff.isEmpty ||
          existingStaff == draft.staffId;

      if (!sameResource) continue;

      if (_appointmentConflicts(data, draft, draftEndAt)) {
        return true;
      }
    }

    return false;
  }

  static bool _appointmentConflicts(
    Map<String, dynamic> data,
    BusinessManualAppointmentDraft draft,
    DateTime draftEndAt,
  ) {
    final existingRange = _appointmentRangeOf(data, draft.dateText);
    if (existingRange != null) {
      return _rangesOverlap(
        draft.startAt,
        draftEndAt,
        existingRange.start,
        existingRange.end,
      );
    }

    final existingTime = _firstNonEmpty([
      data[FirestoreFields.timeText],
      data[FirestoreFields.appointmentTime],
    ]);

    return existingTime == draft.timeText;
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

    final date = _trDateOf(fallbackDateText);
    final time = _timePartsOf(fallbackTimeText);
    if (date == null || time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static DateTime? _trDateOf(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    final iso = DateTime.tryParse(clean);
    if (iso != null) return iso;

    final match = RegExp(
      r'(\d{1,2})[./-](\d{1,2})[./-](\d{4})',
    ).firstMatch(clean);
    if (match == null) return null;

    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) return null;

    return DateTime(year, month, day);
  }

  static _TimeParts? _timePartsOf(String text) {
    final parts = text.trim().split(':');
    if (parts.isEmpty) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0');
    if (hour == null || minute == null) return null;

    return _TimeParts(hour, minute);
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
    if (status == 'postpone_requested' || status == 'reschedule_requested') {
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

class BusinessManualAppointmentDraft {
  const BusinessManualAppointmentDraft({
    required this.businessId,
    required this.businessName,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.serviceId,
    required this.serviceName,
    required this.staffId,
    required this.staffName,
    required this.dateKey,
    required this.dateText,
    required this.timeText,
    required this.startAt,
    required this.durationMinutes,
    required this.note,
  });

  final String businessId;
  final String businessName;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String serviceId;
  final String serviceName;
  final String staffId;
  final String staffName;
  final String dateKey;
  final String dateText;
  final String timeText;
  final DateTime startAt;
  final int durationMinutes;
  final String note;

  String? validate() {
    if (businessId.trim().isEmpty) return 'İşletme bağlantısı bulunamadı.';
    if (customerName.trim().length < 2) {
      return 'Müşteri adı en az 2 karakter olmalıdır.';
    }
    if (serviceName.trim().isEmpty) return 'Hizmet adı girilmelidir.';
    if (dateKey.trim().isEmpty || dateText.trim().isEmpty) {
      return 'Randevu tarihi seçilmelidir.';
    }
    if (timeText.trim().isEmpty) return 'Randevu saati seçilmelidir.';
    if (durationMinutes < 5) return 'Süre geçerli olmalıdır.';

    return null;
  }
}

class BusinessManualAppointmentServiceOption {
  const BusinessManualAppointmentServiceOption({
    required this.id,
    required this.name,
    required this.durationMinutes,
  });

  final String id;
  final String name;
  final int durationMinutes;
}

class BusinessManualAppointmentResult {
  const BusinessManualAppointmentResult._({
    required this.ok,
    required this.message,
    required this.appointmentId,
  });

  factory BusinessManualAppointmentResult.success(String appointmentId) {
    return BusinessManualAppointmentResult._(
      ok: true,
      message: 'Randevu oluşturuldu.',
      appointmentId: appointmentId,
    );
  }

  factory BusinessManualAppointmentResult.failure(String message) {
    return BusinessManualAppointmentResult._(
      ok: false,
      message: message,
      appointmentId: '',
    );
  }

  final bool ok;
  final String message;
  final String appointmentId;
}
