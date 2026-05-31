import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/business/presentation/business_profile_post_interaction_controller.dart';

void main() {
  group('BusinessProfilePostInteractionController', () {
    test('allows only one post action at a time', () {
      final controller = BusinessProfilePostInteractionController();

      expect(controller.beginAction(), isTrue);
      expect(controller.busy, isTrue);
      expect(controller.beginAction(), isFalse);

      controller.finishAction();

      expect(controller.busy, isFalse);
      expect(controller.beginAction(), isTrue);

      controller.dispose();
    });

    test('notifies on busy state transitions only', () {
      final controller = BusinessProfilePostInteractionController();
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      controller
        ..beginAction()
        ..beginAction()
        ..finishAction()
        ..finishAction();

      expect(notifications, 2);

      controller.dispose();
    });
  });
}
