import 'package:geolocator/geolocator.dart';
import 'package:rxpro_mobile/core/businesses/business_category.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_cache_service.dart';

enum HomeExploreSortMode { recommended, distance, rating, category, name }

class HomeExploreDetectedArea {
  const HomeExploreDetectedArea({required this.city, required this.district});

  final String city;
  final String district;
}

class HomeExploreFilterPolicy {
  const HomeExploreFilterPolicy._();

  static List<BusinessDirectoryItem> filterAndSort({
    required List<BusinessDirectoryItem> items,
    required String queryText,
    required String selectedCategory,
    required Position? currentPosition,
    required double radiusKm,
    required HomeExploreSortMode sortMode,
  }) {
    final query = queryText.trim().toLowerCase();

    final filtered = items.where((item) {
      if (!item.visible) return false;

      if (!BusinessCategories.matches(
        selectedLabel: selectedCategory,
        businessCategory: item.category,
      )) {
        return false;
      }

      if (query.isNotEmpty && !_matchesSearch(item, query)) return false;

      if (currentPosition != null) {
        if (!item.hasCoordinate) return false;
        final distance = item.distanceKmFrom(currentPosition);
        if (distance.isFinite && distance > radiusKm) return false;
      }

      return true;
    }).toList();

    filtered.sort(
      (a, b) => compareBusinesses(
        a,
        b,
        currentPosition: currentPosition,
        sortMode: sortMode,
      ),
    );

    return filtered;
  }

  static HomeExploreDetectedArea? detectNearestArea({
    required List<BusinessDirectoryItem> items,
    required Position? position,
  }) {
    if (position == null) return null;

    BusinessDirectoryItem? nearest;
    var nearestDistance = double.infinity;
    for (final item in items) {
      if (!item.visible || !item.hasCoordinate) continue;
      if (item.district.trim().isEmpty && item.city.trim().isEmpty) continue;

      final distance = item.distanceKmFrom(position);
      if (!distance.isFinite || distance >= nearestDistance) continue;

      nearest = item;
      nearestDistance = distance;
    }

    if (nearest == null) return null;

    return HomeExploreDetectedArea(
      city: nearest.city.trim(),
      district: nearest.district.trim(),
    );
  }

  static int compareBusinesses(
    BusinessDirectoryItem a,
    BusinessDirectoryItem b, {
    required Position? currentPosition,
    required HomeExploreSortMode sortMode,
  }) {
    switch (sortMode) {
      case HomeExploreSortMode.distance:
        return _compareDistance(a, b, currentPosition);
      case HomeExploreSortMode.rating:
        return _compareRating(a, b);
      case HomeExploreSortMode.category:
        final category = a.category.compareTo(b.category);
        if (category != 0) return category;
        return _compareDistance(a, b, currentPosition);
      case HomeExploreSortMode.name:
        return a.name.compareTo(b.name);
      case HomeExploreSortMode.recommended:
        if (currentPosition != null) {
          return _compareDistance(a, b, currentPosition);
        }

        final score = _businessScore(
          b,
          currentPosition,
        ).compareTo(_businessScore(a, currentPosition));
        if (score != 0) return score;
        return _compareDistance(a, b, currentPosition);
    }
  }

  static bool _matchesSearch(BusinessDirectoryItem item, String query) {
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

  static int _compareDistance(
    BusinessDirectoryItem a,
    BusinessDirectoryItem b,
    Position? currentPosition,
  ) {
    final distance = a
        .distanceKmFrom(currentPosition)
        .compareTo(b.distanceKmFrom(currentPosition));
    if (distance != 0) return distance;

    if (a.isMember != b.isMember) return a.isMember ? -1 : 1;

    return _compareRating(a, b);
  }

  static int _compareRating(BusinessDirectoryItem a, BusinessDirectoryItem b) {
    final ratingCompare = b.ratingAvg.compareTo(a.ratingAvg);
    if (ratingCompare != 0) return ratingCompare;

    final followerCompare = b.followerCount.compareTo(a.followerCount);
    if (followerCompare != 0) return followerCompare;

    return a.name.compareTo(b.name);
  }

  static double _businessScore(
    BusinessDirectoryItem item,
    Position? currentPosition,
  ) {
    final distance = item.distanceKmFrom(currentPosition);
    final distanceScore = distance.isFinite
        ? 60 - (distance > 60 ? 60 : distance)
        : 0;
    final memberBoost = item.isMember ? 35 : 0;
    final ratingScore = item.ratingAvg * 8;
    final popularityScore = item.followerCount > 500
        ? 20
        : item.followerCount / 25;
    final coordinateBoost = item.hasCoordinate ? 5 : 0;

    return distanceScore +
        memberBoost +
        ratingScore +
        popularityScore +
        coordinateBoost;
  }
}
