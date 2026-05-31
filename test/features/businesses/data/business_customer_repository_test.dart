import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/data/business_customer_repository.dart';

void main() {
  group('BusinessCustomerSegmentation', () {
    final now = DateTime.utc(2026, 5, 26, 12);

    test('classifies recent first appointment as new customer', () {
      final segment = BusinessCustomerSegmentation.classify(
        appointmentCount: 1,
        completedAppointmentCount: 0,
        noShowCount: 0,
        lastAppointmentAt: now.subtract(const Duration(days: 3)),
        now: now,
      );

      expect(segment, BusinessCustomerSegments.newCustomer.id);
    });

    test('classifies repeated completed appointments as loyal', () {
      final segment = BusinessCustomerSegmentation.classify(
        appointmentCount: 3,
        completedAppointmentCount: 3,
        noShowCount: 0,
        lastAppointmentAt: now.subtract(const Duration(days: 20)),
        now: now,
      );

      expect(segment, BusinessCustomerSegments.loyal.id);
    });

    test('classifies no-show only customers as follow-up required', () {
      final segment = BusinessCustomerSegmentation.classify(
        appointmentCount: 1,
        completedAppointmentCount: 0,
        noShowCount: 1,
        lastAppointmentAt: now.subtract(const Duration(days: 1)),
        now: now,
      );

      expect(segment, BusinessCustomerSegments.needsFollowUp.id);
    });

    test('classifies old appointment history as inactive', () {
      final segment = BusinessCustomerSegmentation.classify(
        appointmentCount: 2,
        completedAppointmentCount: 1,
        noShowCount: 0,
        lastAppointmentAt: now.subtract(const Duration(days: 120)),
        now: now,
      );

      expect(segment, BusinessCustomerSegments.inactive.id);
    });
  });

  group('BusinessCustomerRecord merge', () {
    test(
      'manual classification wins while appointment history enriches record',
      () {
        final manual = BusinessCustomerRecord(
          id: 'manual-1',
          businessId: 'business-1',
          customerUid: 'customer-1',
          name: 'Ayşe Yılmaz',
          phone: '0555 111 22 33',
          segmentId: BusinessCustomerSegments.loyal.id,
          note: 'VIP bakım paketiyle ilgileniyor.',
          isManual: true,
          matchKey: 'uid:customer-1',
          campaignConsent: true,
        );

        final appointment = BusinessCustomerRecord(
          id: 'appointment:customer-1',
          businessId: 'business-1',
          customerUid: 'customer-1',
          name: 'Ayşe Yılmaz',
          segmentId: BusinessCustomerSegments.active.id,
          source: 'appointments',
          appointmentCount: 4,
          completedAppointmentCount: 2,
          lastServiceName: 'Cilt bakımı',
          matchKey: 'uid:customer-1',
        );

        final merged = BusinessCustomerRecord.mergeManualAndAppointmentRecords(
          <BusinessCustomerRecord>[manual],
          <BusinessCustomerRecord>[appointment],
        );

        expect(merged, hasLength(1));
        expect(merged.first.segmentId, BusinessCustomerSegments.loyal.id);
        expect(merged.first.appointmentCount, 4);
        expect(merged.first.lastServiceName, 'Cilt bakımı');
        expect(merged.first.note, contains('VIP'));
        expect(merged.first.canReceiveBulkMessage, isTrue);
      },
    );
  });
}
