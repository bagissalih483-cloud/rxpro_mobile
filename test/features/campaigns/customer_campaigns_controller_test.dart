import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/campaigns/customer_campaigns_controller.dart';

void main() {
  group('CustomerCampaignsController', () {
    test('refreshes the campaign future through its loader', () async {
      var loadCount = 0;
      final controller = CustomerCampaignsController<int>(
        load: () async {
          loadCount += 1;
          return <int>[loadCount];
        },
      );

      expect(await controller.future, <int>[1]);

      var notifications = 0;
      controller.addListener(() => notifications += 1);

      await controller.refresh();

      expect(await controller.future, <int>[2]);
      expect(loadCount, 2);
      expect(notifications, 1);

      controller.dispose();
    });

    test('owns selected tab and category state', () {
      final controller = CustomerCampaignsController<String>(
        load: () async => const <String>[],
      );

      expect(controller.selectedTab, 0);
      expect(controller.selectedCategory, 'Tümü');

      controller
        ..selectTab(2)
        ..selectCategory('Sağlık');

      expect(controller.selectedTab, 2);
      expect(controller.selectedCategory, 'Sağlık');

      controller.dispose();
    });
  });
}
