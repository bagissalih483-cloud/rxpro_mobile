import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/presentation/staff_workspace_controller.dart';

void main() {
  group('StaffWorkspaceController', () {
    test('owns accordion expansion state', () {
      final controller = StaffWorkspaceController(initialExpanded: {0});
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      expect(controller.isExpanded(0), isTrue);

      controller.toggle(0);
      expect(controller.isExpanded(0), isFalse);

      controller.toggle(2);
      expect(controller.isExpanded(2), isTrue);
      expect(notifications, 2);

      controller.dispose();
    });
  });
}
