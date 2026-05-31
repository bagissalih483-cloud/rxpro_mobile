import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/app/fix_bootstrap_controller.dart';

void main() {
  group('FixBootstrapController', () {
    test('owns bootstrap future and loading message', () async {
      final controller = FixBootstrapController();
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      final future = Future<void>.value();
      controller.setBootstrapFuture(future);
      controller.setBootstrapMessage('ready');

      expect(controller.bootstrapFuture, same(future));
      expect(controller.bootstrapMessage, 'ready');
      expect(notifications, 2);

      controller.setBootstrapMessage('ready');
      expect(notifications, 2);

      controller.dispose();
    });
  });
}
