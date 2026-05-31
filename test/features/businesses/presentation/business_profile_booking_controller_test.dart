import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/presentation/business_profile_booking_controller.dart';

void main() {
  group('BusinessProfileBookingController', () {
    test('owns service, staff, date, time, and saving state', () {
      final controller = BusinessProfileBookingController();
      addTearDown(controller.dispose);

      expect(controller.expandedBookingSection, 0);
      expect(controller.hasRequiredSelection, isFalse);

      controller.selectService(
        id: 'svc-1',
        name: 'Sac Kesim',
        durationMinutes: 45,
      );

      expect(controller.selectedServiceId, 'svc-1');
      expect(controller.selectedServiceName, 'Sac Kesim');
      expect(controller.selectedServiceDurationMinutes, 45);
      expect(controller.expandedBookingSection, 1);

      controller.selectStaff(
        id: 'staff-1',
        name: 'Ayse',
        uid: 'uid-1',
        email: 'staff@example.com',
        serviceIds: const <String>['svc-1'],
      );

      expect(controller.selectedStaffId, 'staff-1');
      expect(controller.selectedStaffUid, 'uid-1');
      expect(controller.expandedBookingSection, 2);

      controller.selectDate('30.05.2026');
      expect(controller.selectedDateText, '30.05.2026');
      expect(controller.expandedBookingSection, 3);

      controller.selectTime('10:30');
      expect(controller.selectedTimeText, '10:30');
      expect(controller.expandedBookingSection, -1);
      expect(controller.hasRequiredSelection, isTrue);

      controller.setSaving(true);
      expect(controller.saving, isTrue);
    });

    test('clears incompatible staff when service changes', () {
      final controller = BusinessProfileBookingController();
      addTearDown(controller.dispose);

      controller.selectStaff(
        id: 'staff-1',
        name: 'Ayse',
        uid: '',
        email: '',
        serviceIds: const <String>['svc-a'],
      );

      controller.selectService(
        id: 'svc-b',
        name: 'Manikur',
        durationMinutes: 30,
      );

      expect(controller.selectedServiceId, 'svc-b');
      expect(controller.selectedStaffId, isNull);
      expect(controller.expandedBookingSection, 1);
    });

    test('clears incompatible service when staff changes', () {
      final controller = BusinessProfileBookingController();
      addTearDown(controller.dispose);

      controller.selectService(
        id: 'svc-a',
        name: 'Sac Kesim',
        durationMinutes: 30,
      );

      controller.selectStaff(
        id: 'staff-2',
        name: 'Mehmet',
        uid: '',
        email: '',
        serviceIds: const <String>['svc-b'],
      );

      expect(controller.selectedStaffId, 'staff-2');
      expect(controller.selectedServiceId, isNull);
      expect(controller.expandedBookingSection, 0);
    });

    test('reset returns booking flow to the first section', () {
      final controller = BusinessProfileBookingController();
      addTearDown(controller.dispose);

      controller
        ..selectService(id: 'svc-1', name: 'Sac Kesim', durationMinutes: 30)
        ..selectStaff(
          id: 'staff-1',
          name: 'Ayse',
          uid: '',
          email: '',
          serviceIds: const <String>['svc-1'],
        )
        ..selectDate('30.05.2026')
        ..selectTime('11:00');

      expect(controller.hasRequiredSelection, isTrue);

      controller.resetAfterBooking();

      expect(controller.selectedServiceId, isNull);
      expect(controller.selectedStaffId, isNull);
      expect(controller.selectedDateText, isNull);
      expect(controller.selectedTimeText, isNull);
      expect(controller.hasRequiredSelection, isFalse);
      expect(controller.expandedBookingSection, 0);
    });
  });
}
