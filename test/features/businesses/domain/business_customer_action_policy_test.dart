import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/data/business_customer_repository.dart';
import 'package:rxpro_mobile/features/businesses/domain/business_customer_action_policy.dart';

void main() {
  group('BusinessCustomerActionPolicy', () {
    test('allows direct message only when a linked customer uid exists', () {
      expect(BusinessCustomerActionPolicy.canDirectMessage('user_1'), isTrue);
      expect(
        BusinessCustomerActionPolicy.canDirectMessage('  user_1  '),
        isTrue,
      );
      expect(BusinessCustomerActionPolicy.canDirectMessage(''), isFalse);
      expect(BusinessCustomerActionPolicy.canDirectMessage('-'), isFalse);
      expect(BusinessCustomerActionPolicy.canDirectMessage(null), isFalse);
    });

    test('builds bulk audience labels from selected segment', () {
      expect(
        BusinessCustomerActionPolicy.bulkAudienceLabel(
          selectedSegmentId: BusinessCustomerSegments.all.id,
          segmentLabel: BusinessCustomerSegments.all.label,
        ),
        'Müşteri defteri: tüm müşteriler',
      );

      expect(
        BusinessCustomerActionPolicy.bulkAudienceLabel(
          selectedSegmentId: BusinessCustomerSegments.loyal.id,
          segmentLabel: BusinessCustomerSegments.loyal.label,
        ),
        'Müşteri defteri: Sadık müşteri',
      );
    });
  });
}
