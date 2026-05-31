import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/app/role_gate_controller.dart';

void main() {
  group('RoleGateController', () {
    test('owns timeout and delayed role repair state', () {
      final controller = RoleGateController();
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      controller.setStartupTimedOut(true);
      controller.setAllowRoleRepair(true);

      expect(controller.startupTimedOut, isTrue);
      expect(controller.allowRoleRepair, isTrue);
      expect(notifications, 2);

      controller.setStartupTimedOut(false, notify: false);
      controller.setAllowRoleRepair(false, notify: false);

      expect(controller.startupTimedOut, isFalse);
      expect(controller.allowRoleRepair, isFalse);
      expect(notifications, 2);

      controller.requestRefresh();
      expect(notifications, 3);

      controller.dispose();
    });
  });
}
