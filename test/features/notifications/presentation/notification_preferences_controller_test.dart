import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/notifications/presentation/notification_preferences_controller.dart';

void main() {
  group('NotificationPreferencesController', () {
    test('owns saving preference key', () {
      final controller = NotificationPreferencesController();

      expect(controller.savingKey, isEmpty);

      controller.setSavingKey('messages');
      expect(controller.savingKey, 'messages');

      controller.setSavingKey('');
      expect(controller.savingKey, isEmpty);

      controller.dispose();
    });
  });
}
