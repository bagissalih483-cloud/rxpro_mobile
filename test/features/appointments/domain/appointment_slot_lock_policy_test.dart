import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/appointments/domain/appointment_slot_lock_policy.dart';

void main() {
  group('AppointmentSlotLockPolicy', () {
    test('creates deterministic ids for the same business staff and time', () {
      final first = AppointmentSlotLockPolicy.slotId(
        businessId: 'business-1',
        businessStaffId: 'staff-1',
        time: DateTime(2026, 5, 29, 14, 0),
      );
      final second = AppointmentSlotLockPolicy.slotId(
        businessId: 'business-1',
        businessStaffId: 'staff-1',
        time: DateTime(2026, 5, 29, 14, 0),
      );

      expect(first, second);
      expect(first, 'business-1_staff-1_20260529_1400');
    });

    test('locks every 5 minute bucket in the appointment range', () {
      final ids = AppointmentSlotLockPolicy.slotIdsForRange(
        businessId: 'business-1',
        businessStaffId: 'staff-1',
        startAt: DateTime(2026, 5, 29, 14, 0),
        endAt: DateTime(2026, 5, 29, 14, 30),
      );

      expect(ids, [
        'business-1_staff-1_20260529_1400',
        'business-1_staff-1_20260529_1405',
        'business-1_staff-1_20260529_1410',
        'business-1_staff-1_20260529_1415',
        'business-1_staff-1_20260529_1420',
        'business-1_staff-1_20260529_1425',
      ]);
    });

    test('normalizes non safe document characters', () {
      final id = AppointmentSlotLockPolicy.slotId(
        businessId: 'business/1',
        businessStaffId: 'staff 1',
        time: DateTime(2026, 5, 29, 14, 0),
      );

      expect(id, 'business_1_staff_1_20260529_1400');
    });

    test('rounds a start minute down to the current 5 minute bucket', () {
      final ids = AppointmentSlotLockPolicy.slotIdsForRange(
        businessId: 'business-1',
        businessStaffId: 'staff-1',
        startAt: DateTime(2026, 5, 29, 14, 2),
        endAt: DateTime(2026, 5, 29, 14, 12),
      );

      expect(ids, [
        'business-1_staff-1_20260529_1400',
        'business-1_staff-1_20260529_1405',
        'business-1_staff-1_20260529_1410',
      ]);
    });
  });
}
