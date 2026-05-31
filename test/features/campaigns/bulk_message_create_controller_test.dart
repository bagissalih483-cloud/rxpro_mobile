import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/campaigns/bulk_message_create_controller.dart';

void main() {
  group('BulkMessageCreateController', () {
    test('owns selected target, channel, consent and saving state', () {
      final controller = BulkMessageCreateController(
        targets: const ['all', 'recent'],
        initialTarget: 'all',
        initialChannel: 'push',
      );

      expect(controller.target, 'all');
      expect(controller.channel, 'push');
      expect(controller.consentOnly, isTrue);
      expect(controller.saving, isFalse);

      controller
        ..selectTarget('recent')
        ..selectChannel('push_and_message')
        ..setConsentOnly(false)
        ..setSaving(true);

      expect(controller.target, 'recent');
      expect(controller.channel, 'push_and_message');
      expect(controller.consentOnly, isFalse);
      expect(controller.saving, isTrue);

      controller.dispose();
    });

    test('notifies when text inputs need button state refresh', () {
      final controller = BulkMessageCreateController(
        targets: const ['all'],
        initialTarget: 'all',
        initialChannel: 'push',
      );
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      controller.refreshTextInputs();

      expect(controller.textVersion, 1);
      expect(notifications, 1);

      controller.dispose();
    });
  });
}
