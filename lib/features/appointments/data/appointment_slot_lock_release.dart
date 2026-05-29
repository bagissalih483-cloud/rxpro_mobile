import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/appointments/domain/appointment_slot_lock_policy.dart';

class AppointmentSlotLockRelease {
  const AppointmentSlotLockRelease._();

  static List<DocumentReference<Map<String, dynamic>>> refsForAppointment({
    required FirebaseFirestore firestore,
    required Map<String, dynamic> appointment,
  }) {
    final businessId = _firstNonEmpty([
      appointment[FirestoreFields.businessId],
      appointment['businessId'],
    ]);
    final staffId = _firstNonEmpty([
      appointment[FirestoreFields.businessStaffId],
      appointment[FirestoreFields.staffId],
      appointment['staffDocId'],
      appointment['assignedStaffId'],
    ]);
    final startAt = _dateOf(appointment[FirestoreFields.startAt]) ??
        DateTime.tryParse(_clean(appointment[FirestoreFields.startAtIso]));
    final endAt = _dateOf(appointment[FirestoreFields.endAt]) ??
        DateTime.tryParse(_clean(appointment['endAtIso'])) ??
        startAt?.add(
          Duration(
            minutes: _intOf(appointment[FirestoreFields.durationMinutes], 30),
          ),
        );

    if (businessId.isEmpty || staffId.isEmpty || startAt == null || endAt == null) {
      return const <DocumentReference<Map<String, dynamic>>>[];
    }

    return AppointmentSlotLockPolicy.slotIdsForRange(
      businessId: businessId,
      businessStaffId: staffId,
      startAt: startAt,
      endAt: endAt,
    )
        .map(
          (slotId) => firestore
              .collection(FirestoreCollections.appointmentSlots)
              .doc(slotId),
        )
        .toList();
  }

  static DateTime? _dateOf(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static int _intOf(Object? value, int fallback) {
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.round();
    return int.tryParse(_clean(value)) ?? fallback;
  }

  static String _firstNonEmpty(Iterable<Object?> values) {
    for (final value in values) {
      final text = _clean(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _clean(Object? value) => value?.toString().trim() ?? '';
}
