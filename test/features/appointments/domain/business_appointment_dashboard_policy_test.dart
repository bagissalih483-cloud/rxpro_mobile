import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/appointments/domain/business_appointment_dashboard_policy.dart';

void main() {
  group('BusinessAppointmentDashboardPolicy', () {
    test('parses appointment date from modern and legacy fields', () {
      expect(
        BusinessAppointmentDashboardPolicy.dateOf({
          FirestoreFields.startAtIso: '2026-05-30T14:45:00.000',
        }),
        DateTime(2026, 5, 30, 14, 45),
      );

      expect(
        BusinessAppointmentDashboardPolicy.dateOf({
          FirestoreFields.appointmentDate: '30.05.2026',
          FirestoreFields.appointmentTime: '09:30',
        }),
        DateTime(2026, 5, 30, 9, 30),
      );

      expect(
        BusinessAppointmentDashboardPolicy.dateOf({
          FirestoreFields.appointmentDate: 'not-a-date',
        }),
        isNull,
      );
    });

    test('classifies cancelled and passive appointment rows', () {
      expect(
        BusinessAppointmentDashboardPolicy.isCancelledOrPassive({
          FirestoreFields.isCancelled: true,
        }),
        isTrue,
      );
      expect(
        BusinessAppointmentDashboardPolicy.isCancelledOrPassive({
          FirestoreFields.status: 'pasif',
        }),
        isTrue,
      );
      expect(
        BusinessAppointmentDashboardPolicy.isCancelledOrPassive({
          FirestoreFields.bookingStatus: 'active',
        }),
        isFalse,
      );
    });

    test('normalizes staff, customer, service, time, and capacity values', () {
      final row = {
        FirestoreFields.staffUid: ' staff_1 ',
        FirestoreFields.staffName: '  Aylin  ',
        FirestoreFields.customerName: '  Mehmet  ',
        FirestoreFields.serviceName: '  Muayene  ',
      };

      expect(BusinessAppointmentDashboardPolicy.staffIdOf(row), 'staff_1');
      expect(BusinessAppointmentDashboardPolicy.staffNameOf(row), 'Aylin');
      expect(BusinessAppointmentDashboardPolicy.customerNameOf(row), 'Mehmet');
      expect(BusinessAppointmentDashboardPolicy.serviceNameOf(row), 'Muayene');
      expect(BusinessAppointmentDashboardPolicy.customerNameOf({}), 'Müşteri');
      expect(
        BusinessAppointmentDashboardPolicy.timeText(DateTime(2026, 5, 30, 8, 5)),
        '08:05',
      );
      expect(
        BusinessAppointmentDashboardPolicy.dateTitle(DateTime(2026, 2, 3)),
        '3 Şubat 2026',
      );
      expect(
        BusinessAppointmentDashboardPolicy.capacityForDay(
          openingHour: 9,
          closingHour: 17,
          slotMinutes: 30,
          staffCount: 2,
        ),
        32,
      );
    });

    test('normalizes business schedule settings with safe bounds', () {
      expect(
        BusinessAppointmentDashboardPolicy.openingHour({
          FirestoreFields.openingHour: -2,
        }),
        0,
      );
      expect(
        BusinessAppointmentDashboardPolicy.closingHour({
          FirestoreFields.closingHour: 30,
        }),
        24,
      );
      expect(
        BusinessAppointmentDashboardPolicy.slotMinutes({
          FirestoreFields.slotMinutes: 5,
        }),
        15,
      );
      expect(BusinessAppointmentDashboardPolicy.openingHour({}), 9);
      expect(BusinessAppointmentDashboardPolicy.closingHour({}), 20);
      expect(BusinessAppointmentDashboardPolicy.slotMinutes({}), 30);
    });

    test('filters active appointments for the visible month only', () {
      final items = BusinessAppointmentDashboardPolicy.activeAppointmentsForMonth(
        appointments: [
          {FirestoreFields.startAtIso: '2026-05-01T09:00:00.000'},
          {
            FirestoreFields.startAtIso: '2026-05-02T09:00:00.000',
            FirestoreFields.status: 'cancelled',
          },
          {FirestoreFields.startAtIso: '2026-06-01T09:00:00.000'},
          {FirestoreFields.appointmentDate: '03.05.2026'},
        ],
        visibleMonth: DateTime(2026, 5),
      );

      expect(items.length, 2);
    });

    test('builds staff options from staff rows, appointments, or default', () {
      final staffRows = BusinessAppointmentDashboardPolicy.staffOptions(
        staffRows: const [
          {
            FirestoreFields.staffName: ' Aylin ',
            FirestoreFields.staffUid: ' staff_1 ',
          },
          {
            FirestoreFields.staffName: ' Duplicate ',
            FirestoreFields.staffUid: ' staff_1 ',
          },
          {
            FirestoreFields.name: ' Mehmet ',
            '__docId': ' staff_2 ',
          },
        ],
        appointments: const [],
      );

      expect(staffRows.length, 2);
      expect(staffRows.first.id, 'staff_1');
      expect(staffRows.first.name, 'Aylin');
      expect(staffRows.last.id, 'staff_2');

      final fromAppointments = BusinessAppointmentDashboardPolicy.staffOptions(
        staffRows: const [],
        appointments: const [
          {
            FirestoreFields.staffId: 'appointment_staff',
            FirestoreFields.staffName: 'Appointment Staff',
          },
        ],
      );
      expect(fromAppointments.single.id, 'appointment_staff');

      final fallback = BusinessAppointmentDashboardPolicy.staffOptions(
        staffRows: const [],
        appointments: const [],
      );
      expect(fallback.single.name, 'Genel');
    });
  });
}
