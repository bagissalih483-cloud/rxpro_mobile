import 'package:geolocator/geolocator.dart';

import '../../../core/businesses/business_category.dart';
import '../../../core/businesses/business_directory_cache_service.dart';

class HomeExploreCategoryCounts {
  const HomeExploreCategoryCounts._();

  static Map<String, int> build({
    required List<BusinessDirectoryItem> items,
    required List<String> categories,
    required String queryText,
    required Position? currentPosition,
    required double radiusKm,
  }) {
    final counts = <String, int>{
      for (final category in categories) category: 0,
    };
    final query = queryText.trim().toLowerCase();

    for (final item in items) {
      if (!item.visible) continue;
      if (!_matchesQuery(item, query)) continue;
      if (!_matchesRadius(item, currentPosition, radiusKm)) continue;

      counts[BusinessCategories.allLabel] =
          (counts[BusinessCategories.allLabel] ?? 0) + 1;

      for (final category in BusinessCategories.labels) {
        if (BusinessCategories.matches(
          selectedLabel: category,
          businessCategory: item.category,
        )) {
          counts[category] = (counts[category] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  static bool _matchesQuery(BusinessDirectoryItem item, String query) {
    if (query.isEmpty) return true;

    final searchable = [
      item.name,
      item.category,
      item.description,
      item.city,
      item.district,
      item.neighborhood,
    ].join(' ').toLowerCase();

    return searchable.contains(query);
  }

  static bool _matchesRadius(
    BusinessDirectoryItem item,
    Position? position,
    double radiusKm,
  ) {
    if (position == null) return true;
    if (!item.hasCoordinate) return false;

    final distance = item.distanceKmFrom(position);
    return !distance.isFinite || distance <= radiusKm;
  }
}
