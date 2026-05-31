import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/appointments/domain/business_manual_appointment_policy.dart';

void main() {
  group('BusinessManualAppointmentPolicy', () {
    test('formats appointment date keys and labels', () {
      final startAt = BusinessManualAppointmentPolicy.startAt(
        date: DateTime(2026, 5, 7, 22, 15),
        hour: 9,
        minute: 5,
      );

      expect(startAt, DateTime(2026, 5, 7, 9, 5));
      expect(BusinessManualAppointmentPolicy.dateKey(startAt), '2026-05-07');
      expect(BusinessManualAppointmentPolicy.dateText(startAt), '07.05.2026');
      expect(BusinessManualAppointmentPolicy.timeText(startAt), '09:05');
    });

    test('normalizes selected day without carrying time', () {
      expect(
        BusinessManualAppointmentPolicy.dayOnly(DateTime(2026, 5, 7, 22, 15)),
        DateTime(2026, 5, 7),
      );
    });

    test('clamps duration while keeping a default fallback', () {
      expect(BusinessManualAppointmentPolicy.durationMinutes(''), 30);
      expect(BusinessManualAppointmentPolicy.durationMinutes('3'), 5);
      expect(BusinessManualAppointmentPolicy.durationMinutes('45'), 45);
      expect(BusinessManualAppointmentPolicy.durationMinutes('900'), 480);
    });

    test('normalizes staff options and removes duplicate ids', () {
      final options = BusinessManualAppointmentPolicy.staffOptions(const [
        BusinessManualAppointmentStaffOption(id: ' s1 ', name: ' Ayse '),
        BusinessManualAppointmentStaffOption(id: 's1', name: 'Duplicate'),
        BusinessManualAppointmentStaffOption(id: '', name: ' Mehmet '),
        BusinessManualAppointmentStaffOption(id: '', name: '   '),
      ]);

      expect(options.length, 2);
      expect(options.first.id, 's1');
      expect(options.first.name, 'Ayse');
      expect(options.last.id, 'Mehmet');
      expect(options.last.name, 'Mehmet');
    });

    test('selects initial and active staff with safe fallback', () {
      const staff = [
        BusinessManualAppointmentStaffOption(id: 's1', name: 'Ayse'),
        BusinessManualAppointmentStaffOption(id: 's2', name: 'Mehmet'),
      ];

      expect(
        BusinessManualAppointmentPolicy.initialStaffId(
          initialStaff: null,
          staffOptions: staff,
        ),
        's1',
      );
      expect(
        BusinessManualAppointmentPolicy.selectedStaff(
          staffOptions: staff,
          selectedStaffId: 's2',
        ).name,
        'Mehmet',
      );
      expect(
        BusinessManualAppointmentPolicy.selectedStaff(
          staffOptions: const [],
          selectedStaffId: 'missing',
        ).name,
        'Genel',
      );
    });

    test('validates required manual appointment fields', () {
      expect(
        BusinessManualAppointmentPolicy.validateCustomerName(' A '),
        isNotNull,
      );
      expect(
        BusinessManualAppointmentPolicy.validateCustomerName(' Ayse '),
        isNull,
      );
      expect(
        BusinessManualAppointmentPolicy.validateServiceName(' '),
        isNotNull,
      );
      expect(
        BusinessManualAppointmentPolicy.validateServiceName(' Cilt bakimi '),
        isNull,
      );
      expect(BusinessManualAppointmentPolicy.validateDuration('4'), isNotNull);
      expect(BusinessManualAppointmentPolicy.validateDuration('30'), isNull);
    });
  });
}
