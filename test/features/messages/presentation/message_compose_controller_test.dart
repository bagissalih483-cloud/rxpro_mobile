import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/messages/presentation/message_compose_controller.dart';

void main() {
  group('MessageComposeController', () {
    test('normalizes initial text and send readiness', () {
      final controller = MessageComposeController(
        initialText: '  Merhaba  ',
        initialTopic: 'request',
      );
      addTearDown(controller.dispose);

      expect(controller.trimmedText, 'Merhaba');
      expect(controller.topic, 'request');
      expect(controller.canSend, isTrue);
    });

    test('blocks send readiness while sending', () {
      final controller = MessageComposeController(initialText: 'Mesaj');
      addTearDown(controller.dispose);

      controller.setSending(true);

      expect(controller.sending, isTrue);
      expect(controller.canSend, isFalse);
    });

    test('notifies when topic and sending state changes', () {
      final controller = MessageComposeController(initialTopic: 'request');
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      controller.setTopic('complaint');
      controller.setTopic('complaint');
      controller.setSending(true);
      controller.setSending(true);

      expect(controller.topic, 'complaint');
      expect(controller.sending, isTrue);
      expect(notifications, 2);
    });

    test('clears text and disables send readiness', () {
      final controller = MessageComposeController(initialText: 'Mesaj');
      addTearDown(controller.dispose);

      controller.clearText();

      expect(controller.trimmedText, isEmpty);
      expect(controller.canSend, isFalse);
    });
  });
}
