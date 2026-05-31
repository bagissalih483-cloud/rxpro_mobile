import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/legal/account_deletion_request_controller.dart';

void main() {
  group('AccountDeletionRequestController', () {
    test('owns confirmation and submitting state', () {
      final controller = AccountDeletionRequestController();

      expect(controller.confirmed, isFalse);
      expect(controller.submitting, isFalse);
      expect(controller.canSubmit, isFalse);

      controller.setConfirmed(true);
      expect(controller.canSubmit, isTrue);

      controller.setSubmitting(true);
      expect(controller.canSubmit, isFalse);

      controller.dispose();
    });
  });
}
