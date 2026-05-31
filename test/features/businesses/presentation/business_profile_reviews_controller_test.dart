import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/presentation/business_profile_reviews_controller.dart';

void main() {
  group('BusinessProfileReviewsController', () {
    test('clamps rating and tracks sending state', () {
      final controller = BusinessProfileReviewsController();

      controller.selectRating(7);
      controller.setSending(true);

      expect(controller.selectedRating, 5);
      expect(controller.sending, isTrue);

      controller.selectRating(0);
      controller.setSending(false);

      expect(controller.selectedRating, 1);
      expect(controller.sending, isFalse);
    });
  });

  group('BusinessProfileFollowController', () {
    test('tracks cached follow state and optimistic toggle state', () {
      final controller = BusinessProfileFollowController();

      controller.applyFollowing(true);
      controller.startToggle(false);

      expect(controller.following, isFalse);
      expect(controller.busy, isTrue);

      controller.applyFollowing(true);
      controller.setBusy(false);

      expect(controller.following, isTrue);
      expect(controller.busy, isFalse);
    });
  });
}
