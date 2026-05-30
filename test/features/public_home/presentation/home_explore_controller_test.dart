import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxpro_mobile/core/businesses/business_category.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_cache_service.dart';
import 'package:rxpro_mobile/features/public_home/domain/home_explore_filter_policy.dart';
import 'package:rxpro_mobile/features/public_home/presentation/home_explore_controller.dart';

void main() {
  group('HomeExploreController', () {
    test('loads businesses and detects nearest area', () async {
      final origin = _position(37.1901, 38.7937);
      final source = _FakeHomeExploreDataSource([
        [
          _item(
            id: 'mardin',
            name: 'Mardin Clinic',
            city: 'Mardin',
            district: 'Artuklu',
            lat: 37.3100,
            lng: 40.7300,
          ),
          _item(
            id: 'karakopru',
            name: 'Karakopru Clinic',
            city: 'Sanliurfa',
            district: 'Karakopru',
            lat: 37.1910,
            lng: 38.7940,
          ),
        ],
      ]);
      final controller = HomeExploreController(dataSource: source);
      addTearDown(controller.dispose);

      final applied = await controller.reloadBusinesses(
        position: origin,
        radiusKm: 10,
        categoryLabel: BusinessCategories.allLabel,
        forceRefresh: true,
        replaceWithEmpty: true,
      );

      expect(applied, isTrue);
      expect(controller.loadingBusinesses, isFalse);
      expect(controller.hasCompletedInitialBusinessLoad, isTrue);
      expect(controller.businesses.map((item) => item.id), [
        'mardin',
        'karakopru',
      ]);
      expect(controller.detectedCity, 'Sanliurfa');
      expect(controller.detectedDistrict, 'Karakopru');
      expect(source.forceRefreshValues, [true]);
    });

    test('preserves existing list on empty reload unless replacement is forced', () async {
      final source = _FakeHomeExploreDataSource([
        [_item(id: 'first', name: 'First')],
        const <BusinessDirectoryItem>[],
        const <BusinessDirectoryItem>[],
      ]);
      final controller = HomeExploreController(dataSource: source);
      addTearDown(controller.dispose);

      await controller.reloadBusinesses(
        position: null,
        radiusKm: 10,
        categoryLabel: BusinessCategories.allLabel,
        replaceWithEmpty: true,
      );
      await controller.reloadBusinesses(
        position: null,
        radiusKm: 10,
        categoryLabel: BusinessCategories.allLabel,
      );

      expect(controller.businesses.map((item) => item.id), ['first']);

      await controller.reloadBusinesses(
        position: null,
        radiusKm: 10,
        categoryLabel: BusinessCategories.allLabel,
        replaceWithEmpty: true,
      );

      expect(controller.businesses, isEmpty);
    });

    test('filters list and suppresses repeated nearby location queries', () async {
      final origin = _position(37.1901, 38.7937);
      final nearAgain = _position(37.1905, 38.7941);
      final source = _FakeHomeExploreDataSource([
        [
          _item(
            id: 'near',
            name: 'Karakopru Dental',
            category: BusinessCategories.values[1].label,
            lat: 37.1910,
            lng: 38.7940,
          ),
          _item(
            id: 'far',
            name: 'Remote Dental',
            category: BusinessCategories.values[1].label,
            lat: 37.5000,
            lng: 39.1000,
          ),
        ],
      ]);
      final controller = HomeExploreController(dataSource: source);
      addTearDown(controller.dispose);

      await controller.reloadBusinesses(
        position: origin,
        radiusKm: 5,
        categoryLabel: BusinessCategories.values[1].label,
        replaceWithEmpty: true,
      );
      controller.markLocationQueryApplied(origin);

      final filtered = controller.filteredBusinesses(
        queryText: 'dental',
        selectedCategory: BusinessCategories.values[1].label,
        currentPosition: origin,
        radiusKm: 5,
        sortMode: HomeExploreSortMode.recommended,
      );

      expect(filtered.map((item) => item.id), ['near']);
      expect(controller.shouldRunLocationQuery(nearAgain), isFalse);
    });
  });
}

class _FakeHomeExploreDataSource implements HomeExploreDataSource {
  _FakeHomeExploreDataSource(this._responses);

  final List<List<BusinessDirectoryItem>> _responses;
  final forceRefreshValues = <bool>[];
  int _next = 0;

  @override
  Future<List<BusinessDirectoryItem>> loadBusinesses({
    required Position? position,
    required double radiusKm,
    required String categoryLabel,
    required bool forceRefresh,
  }) async {
    forceRefreshValues.add(forceRefresh);
    final index = _next < _responses.length ? _next : _responses.length - 1;
    _next += 1;
    return _responses[index];
  }
}

Position _position(double latitude, double longitude) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime(2026, 5, 30),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

BusinessDirectoryItem _item({
  required String id,
  required String name,
  String? category,
  double? lat,
  double? lng,
  String city = '',
  String district = '',
}) {
  return BusinessDirectoryItem(
    id: id,
    name: name,
    category: category ?? BusinessCategories.values.first.label,
    description: '',
    address: '',
    phone: '',
    city: city,
    district: district,
    neighborhood: '',
    logoUrl: '',
    mapsUrl: '',
    placeId: id,
    membership: BusinessDirectoryMembership.directoryOnly,
    source: 'test',
    lat: lat,
    lng: lng,
    visible: true,
  );
}
