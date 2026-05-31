import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/presentation/business_customer_direct_message_controller.dart';

void main() {
  group('BusinessCustomerDirectMessageController', () {
    test('owns message sending state', () {
      final controller = BusinessCustomerDirectMessageController();
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      expect(controller.sending, isFalse);

      controller.setSending(true);
      expect(controller.sending, isTrue);
      expect(notifications, 1);

      controller.setSending(true);
      expect(notifications, 1);

      controller.setSending(false);
      expect(controller.sending, isFalse);
      expect(notifications, 2);

      controller.dispose();
    });
  });
}
