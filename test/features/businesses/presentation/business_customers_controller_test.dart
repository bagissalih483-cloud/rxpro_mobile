import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/data/business_customer_repository.dart';
import 'package:rxpro_mobile/features/businesses/presentation/business_customers_controller.dart';

void main() {
  group('BusinessCustomersController', () {
    test('filters customers by segment and search query', () {
      final controller = BusinessCustomersController();
      addTearDown(controller.dispose);

      final records = <BusinessCustomerRecord>[
        const BusinessCustomerRecord(
          id: 'customer-1',
          businessId: 'business-1',
          name: 'Ayse Yilmaz',
          phone: '555',
          segmentId: 'active',
          lastServiceName: 'Sac Kesim',
        ),
        const BusinessCustomerRecord(
          id: 'customer-2',
          businessId: 'business-1',
          name: 'Mehmet Demir',
          segmentId: 'inactive',
          note: 'VIP',
        ),
      ];

      expect(controller.visibleRecords(records).length, 2);

      controller.selectSegment(BusinessCustomerSegments.active.id);
      expect(controller.visibleRecords(records).map((record) => record.id), [
        'customer-1',
      ]);

      controller.setQuery('sac');
      expect(controller.visibleRecords(records).map((record) => record.id), [
        'customer-1',
      ]);

      controller.setQuery('vip');
      expect(controller.visibleRecords(records), isEmpty);
    });
  });

  group('ManualCustomerFormController', () {
    test('owns segment, consent, and saving state', () {
      final controller = ManualCustomerFormController();
      addTearDown(controller.dispose);

      expect(controller.segmentId, BusinessCustomerSegments.manual.id);
      expect(controller.campaignConsent, isFalse);
      expect(controller.saving, isFalse);

      controller.selectSegment(BusinessCustomerSegments.loyal.id);
      controller.setCampaignConsent(true);
      controller.setSaving(true);

      expect(controller.segmentId, BusinessCustomerSegments.loyal.id);
      expect(controller.campaignConsent, isTrue);
      expect(controller.saving, isTrue);
    });
  });

  group('CustomerClassificationController', () {
    test('keeps classification edits outside the widget', () {
      final controller = CustomerClassificationController(
        initialSegmentId: BusinessCustomerSegments.active.id,
        initialCampaignConsent: true,
      );
      addTearDown(controller.dispose);

      expect(controller.segmentId, BusinessCustomerSegments.active.id);
      expect(controller.campaignConsent, isTrue);

      controller.selectSegment(BusinessCustomerSegments.needsFollowUp.id);
      controller.setCampaignConsent(false);
      controller.setSaving(true);

      expect(controller.segmentId, BusinessCustomerSegments.needsFollowUp.id);
      expect(controller.campaignConsent, isFalse);
      expect(controller.saving, isTrue);
    });
  });
}
