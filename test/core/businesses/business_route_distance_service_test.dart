import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/businesses/business_route_distance_service.dart';

void main() {
  group('BusinessRouteInfo', () {
    test('formats route distance and duration for explore cards', () {
      final info = BusinessRouteInfo.fromMap(<String, dynamic>{
        'distanceMeters': 8200,
        'durationSeconds': 840,
        'source': 'google_routes',
      });

      expect(info.isUsable, isTrue);
      expect(info.distanceLabel, '8.2 km');
      expect(info.durationLabel, '14 dk');
      expect(info.summaryLabel, 'Araçla 8.2 km · 14 dk');
      expect(info.source, 'google_routes');
    });

    test('keeps route label readable without duration', () {
      final info = BusinessRouteInfo(distanceMeters: 540, durationSeconds: 0);

      expect(info.distanceLabel, '540 m');
      expect(info.durationLabel, '');
      expect(info.summaryLabel, 'Araçla 540 m');
    });
  });
}
