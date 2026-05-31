import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/staff_invites/presentation/staff_invite_code_controller.dart';
import 'package:rxpro_mobile/features/staff_invites/staff_invite_service.dart';

void main() {
  group('StaffInviteCodeController', () {
    test('owns invite submit and linked status state', () {
      final controller = StaffInviteCodeController();
      addTearDown(controller.dispose);

      expect(controller.statusLoading, isTrue);
      expect(controller.initialStatusLoaded, isFalse);

      controller.applyLinkedStatus(null);
      controller.finishStatusLoad();

      expect(controller.statusLoading, isFalse);
      expect(controller.initialStatusLoaded, isTrue);
      expect(controller.linked, isNull);

      controller.beginSubmit();
      expect(controller.loading, isTrue);
      expect(controller.result, isNull);

      controller.applyResult(
        const StaffInviteAcceptResult(success: true, message: 'ok'),
      );
      controller.finishSubmit();

      expect(controller.loading, isFalse);
      expect(controller.result?.success, isTrue);

      controller.beginWorkStatusMutation();
      expect(controller.statusLoading, isTrue);
      expect(controller.result, isNull);

      controller.applyLinkedStatus(
        const StaffLinkedAccountSummary(
          linked: true,
          businessName: 'RxPro',
          staffName: 'User',
          staffWorkStatus: 'active',
        ),
      );
      controller.finishStatusLoad();

      expect(controller.linked?.isWorkActive, isTrue);
      expect(controller.statusLoading, isFalse);

      controller.applyError('failed');

      expect(controller.result?.success, isFalse);
      expect(controller.result?.message, 'failed');
      expect(controller.initialStatusLoaded, isTrue);
    });
  });
}
