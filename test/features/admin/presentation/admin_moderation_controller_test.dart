import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/admin/presentation/admin_moderation_controller.dart';

void main() {
  group('AdminModerationController', () {
    test('owns moderation query and status filter state', () {
      final controller = AdminModerationController();
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      expect(controller.query, isEmpty);
      expect(controller.statusFilter, 'all');

      controller.setQuery('spam');
      controller.setStatusFilter('needs_review');

      expect(controller.query, 'spam');
      expect(controller.statusFilter, 'needs_review');
      expect(notifications, 2);

      controller.setQuery('spam');
      controller.setStatusFilter('needs_review');
      expect(notifications, 2);

      controller.dispose();
    });
  });
}
