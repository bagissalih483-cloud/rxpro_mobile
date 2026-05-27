import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/public_home/domain/home_explore_location_policy.dart';

void main() {
  group('HomeExploreLocationPolicy', () {
    test('allows the first location query', () {
      expect(
        HomeExploreLocationPolicy.shouldRunLocationQuery(
          latitude: 37.1901,
          longitude: 38.7937,
        ),
        isTrue,
      );
    });

    test(
      'keeps cached results when location changed less than one kilometer',
      () {
        expect(
          HomeExploreLocationPolicy.shouldRunLocationQuery(
            latitude: 37.1901,
            longitude: 38.7937,
            previousLatitude: 37.1940,
            previousLongitude: 38.7937,
          ),
          isFalse,
        );
      },
    );

    test('allows a fresh query after one kilometer movement', () {
      expect(
        HomeExploreLocationPolicy.shouldRunLocationQuery(
          latitude: 37.1901,
          longitude: 38.7937,
          previousLatitude: 37.2020,
          previousLongitude: 38.7937,
        ),
        isTrue,
      );
    });
  });
}
