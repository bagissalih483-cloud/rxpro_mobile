import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/app/main_shell_controller.dart';

void main() {
  group('MainShellController', () {
    test('owns selected shell index', () {
      final controller = MainShellController(1);

      expect(controller.selectedIndex, 1);

      var notifications = 0;
      controller.addListener(() => notifications += 1);

      controller.selectIndex(1);
      expect(notifications, 0);

      controller.selectIndex(3);
      expect(controller.selectedIndex, 3);
      expect(notifications, 1);

      controller.dispose();
    });
  });
}
