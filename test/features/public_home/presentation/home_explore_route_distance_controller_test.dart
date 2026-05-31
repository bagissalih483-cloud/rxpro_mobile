import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/businesses/business_route_distance_service.dart';
import 'package:rxpro_mobile/features/public_home/presentation/widgets/home_explore_route_distance_controller.dart';

void main() {
  group('HomeExploreRouteDistanceController', () {
    test('owns route attempt lifecycle', () {
      final controller = HomeExploreRouteDistanceController();

      expect(controller.beginAttempt('a'), isTrue);
      expect(controller.activeKey, 'a');
      expect(controller.loading, isTrue);
      expect(controller.attempted, isTrue);

      controller.complete(
        const BusinessRouteInfo(distanceMeters: 1200, durationSeconds: 300),
      );
      expect(controller.loading, isFalse);
      expect(controller.info?.distanceMeters, 1200);

      controller.resetForKey('b');
      expect(controller.info, isNull);
      expect(controller.attempted, isFalse);

      controller.dispose();
    });
  });
}
