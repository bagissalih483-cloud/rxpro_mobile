import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';
import '../data/appointment_repository.dart';
import '../data/firestore_appointment_repository.dart';

class BusinessManualAppointmentService {
  BusinessManualAppointmentService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    AppointmentRepository? appointmentRepository,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _appointmentRepository =
           appointmentRepository ??
           FirestoreAppointmentRepository(firestore: firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AppointmentRepository _appointmentRepository;

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

    try {
      final ref = await _appointmentRepository.createAppointmentWithSlotLock(
        payload: payload,
        startAt: draft.startAt,
        endAt: endAt,
        businessId: draft.businessId,
        businessStaffId: draft.staffId,
      );
      return BusinessManualAppointmentResult.success(ref.id);
    } on AppointmentSlotConflictException {
      return BusinessManualAppointmentResult.failure(
        'Seçilen tarih, saat ve personel için mevcut bir randevu var.',
      );
    }
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
