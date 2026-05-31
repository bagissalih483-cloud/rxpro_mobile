import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/campaigns/business_campaigns_controller.dart';
import 'package:rxpro_mobile/features/campaigns/domain/business_campaign_item_view_model.dart';

void main() {
  group('BusinessCampaignsController', () {
    test('refreshes campaign future through its loader', () async {
      var loadCount = 0;
      final controller = BusinessCampaignsController(
        load: () async {
          loadCount += 1;
          return const <BusinessCampaignItemViewModel>[];
        },
      );

      expect(await controller.future, isEmpty);

      var notifications = 0;
      controller.addListener(() => notifications += 1);

      await controller.refresh();

      expect(await controller.future, isEmpty);
      expect(loadCount, 2);
      expect(notifications, 1);

      controller.dispose();
    });

    test('owns selected tab and bulk send busy state', () {
      final controller = BusinessCampaignsController(
        load: () async => const <BusinessCampaignItemViewModel>[],
      );

      expect(controller.selectedTab, 0);
      expect(controller.sendingBulkDraft, isFalse);

      controller
        ..selectTab(2)
        ..setSendingBulkDraft(true);

      expect(controller.selectedTab, 2);
      expect(controller.sendingBulkDraft, isTrue);

      controller.dispose();
    });
  });
}
