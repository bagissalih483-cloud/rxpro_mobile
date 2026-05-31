import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/presentation/business_profile_controller.dart';

void main() {
  group('BusinessProfileController', () {
    test('owns selected profile tab state', () {
      final controller = BusinessProfileController();
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      expect(controller.selectedTab, 0);

      controller.selectTab(2);
      expect(controller.selectedTab, 2);
      expect(notifications, 1);

      controller.selectTab(2);
      expect(notifications, 1);

      controller.dispose();
    });
  });
}
