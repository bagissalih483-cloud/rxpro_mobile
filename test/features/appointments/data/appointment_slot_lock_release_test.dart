import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/appointments/data/appointment_slot_lock_release.dart';

void main() {
  group('AppointmentSlotLockRelease', () {
    test('returns slot ids that should be released after cancellation', () {
      final ids = AppointmentSlotLockRelease.slotIdsForAppointment(
        appointment: {
          FirestoreFields.businessId: 'business-1',
          FirestoreFields.businessStaffId: 'staff-1',
          FirestoreFields.startAt: Timestamp.fromDate(
            DateTime(2026, 5, 29, 14, 0),
          ),
          FirestoreFields.endAt: Timestamp.fromDate(
            DateTime(2026, 5, 29, 14, 15),
          ),
        },
      );

      expect(ids, [
        'business-1_staff-1_20260529_1400',
        'business-1_staff-1_20260529_1405',
        'business-1_staff-1_20260529_1410',
      ]);
    });

    test('falls back to iso start and duration when end is missing', () {
      final ids = AppointmentSlotLockRelease.slotIdsForAppointment(
        appointment: {
          FirestoreFields.businessId: 'business-1',
          FirestoreFields.staffId: 'staff-1',
          FirestoreFields.startAtIso: '2026-05-29T14:02:00',
          FirestoreFields.durationMinutes: 10,
        },
      );

      expect(ids, [
        'business-1_staff-1_20260529_1400',
        'business-1_staff-1_20260529_1405',
        'business-1_staff-1_20260529_1410',
      ]);
    });

    test('returns empty when appointment scope is incomplete', () {
      final ids = AppointmentSlotLockRelease.slotIdsForAppointment(
        appointment: {
          FirestoreFields.businessId: 'business-1',
          FirestoreFields.startAtIso: '2026-05-29T14:00:00',
        },
      );

      expect(ids, isEmpty);
    });
  });
}
