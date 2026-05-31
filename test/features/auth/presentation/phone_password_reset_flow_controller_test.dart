import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/auth/presentation/controllers/phone_password_reset_flow_controller.dart';

void main() {
  group('PhonePasswordResetFlowController', () {
    test('owns reset step and password visibility state', () {
      final controller = PhonePasswordResetFlowController();

      expect(controller.step, 0);
      expect(controller.obscure, isTrue);

      controller.goToCodeStep();
      expect(controller.step, 1);

      controller.goToPasswordStep();
      expect(controller.step, 2);

      controller.toggleObscure();
      expect(controller.obscure, isFalse);

      controller.dispose();
    });
  });
}
