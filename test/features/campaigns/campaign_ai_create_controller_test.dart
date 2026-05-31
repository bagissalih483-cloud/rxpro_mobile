import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/campaigns/campaign_ai_create_controller.dart';

void main() {
  group('CampaignAiCreateController', () {
    test('owns business context, dates, generation, and publish state', () {
      final controller = CampaignAiCreateController();
      addTearDown(controller.dispose);

      controller.applyBusinessContext(
        businessId: ' business-1 ',
        businessName: ' RxPro ',
      );
      expect(controller.resolvedBusinessId, 'business-1');
      expect(controller.resolvedBusinessName, 'RxPro');

      final start = DateTime(2026, 5, 30);
      final earlierEnd = DateTime(2026, 5, 20);

      controller.setDate(start: true, picked: start);
      controller.setDate(start: false, picked: earlierEnd);

      expect(controller.startDate, start);
      expect(controller.endDate, start);

      expect(
        controller.canGenerate(offer: '20%', audience: 'customers'),
        isTrue,
      );

      controller.beginGenerate();
      expect(
        controller.canGenerate(offer: '20%', audience: 'customers'),
        isFalse,
      );

      controller.applyGenerated(title: 'Title', body: 'Body', cta: 'Book');
      controller.finishGenerate();

      expect(controller.generatedTitle, 'Title');
      expect(controller.canPublish, isTrue);

      final key = controller.publishKey();
      controller.beginPublish();
      expect(controller.canPublish, isFalse);

      controller.markPublished(key);
      controller.finishPublish();

      expect(controller.lastPublishedKey, key);
      expect(controller.publishing, isFalse);
    });
  });
}
