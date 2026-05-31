import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxpro_mobile/core/businesses/business_category.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_cache_service.dart';
import 'package:rxpro_mobile/features/public_home/domain/home_explore_filter_policy.dart';

void main() {
  group('HomeExploreFilterPolicy', () {
    test(
      'keeps nearest visible businesses first after location is available',
      () {
        final origin = _position(37.1901, 38.7937);
        final items = <BusinessDirectoryItem>[
          _item(
            id: 'far_member',
            name: 'Far Member',
            category: BusinessCategories.values.first.label,
            lat: 37.2600,
            lng: 38.8800,
            membership: BusinessDirectoryMembership.member,
          ),
          _item(
            id: 'near_directory',
            name: 'Near Directory',
            category: BusinessCategories.values.first.label,
            lat: 37.1910,
            lng: 38.7940,
          ),
          _item(
            id: 'hidden',
            name: 'Hidden',
            category: BusinessCategories.values.first.label,
            lat: 37.1902,
            lng: 38.7938,
            visible: false,
          ),
        ];

        final filtered = HomeExploreFilterPolicy.filterAndSort(
          items: items,
          queryText: '',
          selectedCategory: BusinessCategories.allLabel,
          currentPosition: origin,
          radiusKm: 20,
          sortMode: HomeExploreSortMode.recommended,
        );

        expect(filtered.map((item) => item.id), [
          'near_directory',
          'far_member',
        ]);
      },
    );

    test('applies category, search, and radius filters together', () {
      final origin = _position(37.1901, 38.7937);
      final health = BusinessCategories.values[1].label;
      final items = <BusinessDirectoryItem>[
        _item(
          id: 'health_near',
          name: 'Karakopru Dental',
          category: health,
          district: 'Karakopru',
          lat: 37.1910,
          lng: 38.7940,
        ),
        _item(
          id: 'health_far',
          name: 'Remote Dental',
          category: health,
          district: 'Remote',
          lat: 37.5000,
          lng: 39.1000,
        ),
        _item(
          id: 'beauty_near',
          name: 'Karakopru Beauty',
          category: BusinessCategories.values.first.label,
          district: 'Karakopru',
          lat: 37.1910,
          lng: 38.7940,
        ),
      ];

      final filtered = HomeExploreFilterPolicy.filterAndSort(
        items: items,
        queryText: 'dental',
        selectedCategory: health,
        currentPosition: origin,
        radiusKm: 5,
        sortMode: HomeExploreSortMode.recommended,
      );

      expect(filtered.map((item) => item.id), ['health_near']);
    });

    test('detects nearest city and district from listed businesses', () {
      final origin = _position(37.1901, 38.7937);
      final area = HomeExploreFilterPolicy.detectNearestArea(
        items: <BusinessDirectoryItem>[
          _item(
            id: 'mardin',
            name: 'Mardin Clinic',
            category: BusinessCategories.values[1].label,
            city: 'Mardin',
            district: 'Artuklu',
            lat: 37.3100,
            lng: 40.7300,
          ),
          _item(
            id: 'karakopru',
            name: 'Karakopru Clinic',
            category: BusinessCategories.values[1].label,
            city: 'Sanliurfa',
            district: 'Karakopru',
            lat: 37.1910,
            lng: 38.7940,
          ),
        ],
        position: origin,
      );

      expect(area?.city, 'Sanliurfa');
      expect(area?.district, 'Karakopru');
    });
  });
}

Position _position(double latitude, double longitude) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime(2026, 5, 29),
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
  required String category,
  double? lat,
  double? lng,
  String city = '',
  String district = '',
  bool visible = true,
  BusinessDirectoryMembership membership =
      BusinessDirectoryMembership.directoryOnly,
}) {
  return BusinessDirectoryItem(
    id: id,
    name: name,
    category: category,
    description: '',
    address: '',
    phone: '',
    city: city,
    district: district,
    neighborhood: '',
    logoUrl: '',
    mapsUrl: '',
    placeId: id,
    membership: membership,
    source: 'test',
    lat: lat,
    lng: lng,
    visible: visible,
  );
}
