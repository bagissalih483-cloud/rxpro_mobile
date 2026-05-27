import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

/// Tamamlanan randevulardan muhasebe kaydı üreten çekirdek servis.
///
/// appointment.completed -> financeRecords/appointment_{appointmentId}
/// Idempotent yazım: aynı randevu ikinci kez bitirilirse yeni kayıt açmaz,
/// aynı dokümanı merge ederek günceller.
///
/// 51B-Q:
/// - Deterministic document id korunur: appointment_{appointmentId}.
/// - createdAt sadece ilk kayıt oluşturulurken yazılır.
/// - updatedAt her çağrıda güncellenir.
/// - businessStaffId / linkedStaffId / assignedStaffUid payload standardına eklenir.
/// - sourceModule eklenir.
/// - Payload key'leri mümkün olduğunca FirestoreFields constants üzerinden yazılır.
class FinanceRecordService {
  FinanceRecordService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> createIncomeFromCompletedAppointment({
    required String appointmentId,
    required Map<String, dynamic> appointmentData,
    required String businessId,
    required String actorUid,
    required String actorName,
    String? staffId,
    String? staffName,
  }) async {
    final cleanAppointmentId = appointmentId.trim();
    final cleanBusinessId = businessId.trim();

    if (cleanBusinessId.isEmpty || cleanAppointmentId.isEmpty) {
      return;
    }

    final amount = _amountOf(appointmentData);
    if (amount <= 0) {
      return;
    }

    final paymentStatus = _paymentStatusOf(appointmentData);
    final recordId = 'appointment_$cleanAppointmentId';
    final now = FieldValue.serverTimestamp();

    final businessStaffId = _firstNonEmpty([
      staffId,
      appointmentData[FirestoreFields.businessStaffId],
      appointmentData[FirestoreFields.staffId],
      appointmentData[FirestoreFields.linkedStaffId],
    ]);

    final cleanStaffUid = _firstNonEmpty([
      appointmentData[FirestoreFields.staffUid],
      appointmentData[FirestoreFields.assignedStaffUid],
      actorUid,
    ]);

    final cleanStaffName = _firstNonEmpty([
      staffName,
      appointmentData[FirestoreFields.staffName],
      actorName,
    ]);

    final recordRef = _db
        .collection(FirestoreCollections.financeRecords)
        .doc(recordId);

    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(recordRef);
      final payload = <String, dynamic>{
        FirestoreFields.id: recordId,
        FirestoreFields.recordId: recordId,
        FirestoreFields.source: 'appointment_completed',
        FirestoreFields.sourceModule: 'finance_record_service_51B_Q',
        FirestoreFields.sourceCollection: FirestoreCollections.appointments,
        FirestoreFields.sourceAppointmentId: cleanAppointmentId,
        FirestoreFields.appointmentId: cleanAppointmentId,
        FirestoreFields.businessId: cleanBusinessId,
        FirestoreFields.businessName: _firstNonEmpty([
          appointmentData[FirestoreFields.businessName],
        ]),
        FirestoreFields.customerId: _firstNonEmpty([
          appointmentData[FirestoreFields.customerId],
          appointmentData[FirestoreFields.userId],
          appointmentData['clientId'],
        ]),
        FirestoreFields.customerName: _firstNonEmpty([
          appointmentData[FirestoreFields.customerName],
          appointmentData[FirestoreFields.clientName],
        ]),
        FirestoreFields.serviceId: _firstNonEmpty([
          appointmentData[FirestoreFields.serviceId],
        ]),
        FirestoreFields.serviceName: _firstNonEmpty([
          appointmentData[FirestoreFields.serviceName],
          appointmentData[FirestoreFields.title],
          'Hizmet',
        ]),
        FirestoreFields.businessStaffId: businessStaffId,
        FirestoreFields.staffId: businessStaffId,
        FirestoreFields.linkedStaffId: businessStaffId,
        FirestoreFields.staffUid: cleanStaffUid,
        FirestoreFields.assignedStaffUid: cleanStaffUid,
        FirestoreFields.staffName: cleanStaffName,
        FirestoreFields.amount: amount,
        FirestoreFields.recordType: 'income',
        FirestoreFields.paymentStatus: paymentStatus,
        FirestoreFields.paymentMethod: _firstNonEmpty([
          appointmentData[FirestoreFields.paymentMethod],
          appointmentData['payMethod'],
        ]),
        FirestoreFields.dueDate: appointmentData[FirestoreFields.dueDate],
        FirestoreFields.appointmentDate:
            appointmentData[FirestoreFields.appointmentDate],
        FirestoreFields.appointmentTime:
            appointmentData[FirestoreFields.appointmentTime],
        FirestoreFields.createdBy: actorUid,
        FirestoreFields.createdByName: actorName,
        FirestoreFields.updatedBy: actorUid,
        FirestoreFields.updatedByName: actorName,
        FirestoreFields.updatedAt: now,
        FirestoreFields.monthKey: _monthKeyOf(appointmentData),
        FirestoreFields.isDeleted: false,
      };

      if (!existing.exists) {
        payload[FirestoreFields.createdAt] = now;
      }

      transaction.set(recordRef, payload, SetOptions(merge: true));
    });
  }

  static double _amountOf(Map<String, dynamic> data) {
    final raw =
        data[FirestoreFields.paidAmount] ??
        data[FirestoreFields.amount] ??
        data[FirestoreFields.price] ??
        data[FirestoreFields.servicePrice] ??
        data['totalPrice'] ??
        data['finalPrice'];

    if (raw is num) return raw.toDouble();

    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return 0;

    final normalized = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  static String _paymentStatusOf(Map<String, dynamic> data) {
    final existing = _firstNonEmpty([data[FirestoreFields.paymentStatus]]);
    if (existing.isNotEmpty) return existing;

    final paidAmount = _toDouble(data[FirestoreFields.paidAmount]);
    final amount = _amountOf(data);

    if (paidAmount > 0 && paidAmount >= amount) return 'paid';
    if (amount > 0) return 'paymentPending';

    return 'receivable';
  }

  static double _toDouble(Object? raw) {
    if (raw is num) return raw.toDouble();

    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return 0;

    final normalized = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  static String _monthKeyOf(Map<String, dynamic> data) {
    final existing = _firstNonEmpty([data[FirestoreFields.monthKey]]);
    if (existing.isNotEmpty) return existing;

    final raw =
        data[FirestoreFields.completedAt] ??
        data[FirestoreFields.workCompletedAtLocalIso] ??
        data[FirestoreFields.appointmentDate] ??
        data[FirestoreFields.startAtIso] ??
        data[FirestoreFields.createdAtLocalIso] ??
        data[FirestoreFields.createdAt];

    DateTime? date;
    if (raw is Timestamp) {
      date = raw.toDate();
    } else if (raw is DateTime) {
      date = raw;
    } else {
      date = DateTime.tryParse((raw ?? '').toString());
    }

    date ??= DateTime.now();

    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  static String _firstNonEmpty(Iterable<Object?> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
