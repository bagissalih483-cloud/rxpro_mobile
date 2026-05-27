import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/businesses/business_category.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_cache_service.dart';
import 'package:rxpro_mobile/features/public_home/domain/home_explore_category_counts.dart';

void main() {
  group('HomeExploreCategoryCounts', () {
    test('counts visible businesses by category for explore chips', () {
      final categories = <String>[
        BusinessCategories.allLabel,
        ...BusinessCategories.labels,
      ];

      final counts = HomeExploreCategoryCounts.build(
        items: <BusinessDirectoryItem>[
          _item('1', 'Fix Beauty', 'Güzellik & Bakım', true),
          _item('2', 'Fix Dental', 'Sağlık & Klinik', true),
          _item('3', 'Hidden Gym', 'Spor & Fitness', false),
        ],
        categories: categories,
        queryText: '',
        currentPosition: null,
        radiusKm: 10,
      );

      expect(counts[BusinessCategories.allLabel], 2);
      expect(counts['Güzellik & Bakım'], 1);
      expect(counts['Sağlık & Klinik'], 1);
      expect(counts['Spor & Fitness'], 0);
    });
  });
}

BusinessDirectoryItem _item(
  String id,
  String name,
  String category,
  bool visible,
) {
  return BusinessDirectoryItem(
    id: id,
    name: name,
    category: category,
    description: '',
    address: '',
    phone: '',
    city: '',
    district: '',
    neighborhood: '',
    logoUrl: '',
    mapsUrl: '',
    placeId: id,
    membership: BusinessDirectoryMembership.directoryOnly,
    source: 'test',
    lat: null,
    lng: null,
    visible: visible,
  );
}
