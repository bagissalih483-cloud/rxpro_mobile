import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'business_category.dart';

class GooglePlacesDirectoryService {
  GooglePlacesDirectoryService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  static const _functionName = 'searchNearbyDirectoryBusinesses';
  static const Duration _cacheTtl = Duration(minutes: 10);
  static const Duration _callTimeout = Duration(seconds: 18);
  static const int _resultLimit = 80;
  static const int _allCategorySearchCalls = 12;
  static const int _singleCategorySearchCalls = 8;
  static const Set<String> _supportedLiveCategoryIds = <String>{
    'beauty_care',
    'health_clinic',
    'sport_fitness',
  };

  final FirebaseFunctions _functions;
  final Map<String, _GooglePlacesDirectoryCacheEntry> _cache =
      <String, _GooglePlacesDirectoryCacheEntry>{};

  Future<List<Map<String, dynamic>>> searchNearby({
    required Position position,
    required double radiusKm,
    required String categoryLabel,
    bool forceRefresh = false,
  }) async {
    return searchNearbyCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusKm: radiusKm,
      categoryLabel: categoryLabel,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<Map<String, dynamic>>> searchNearbyCoordinates({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String categoryLabel,
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      categoryLabel: categoryLabel,
    );
    final cached = _cache[key];
    if (!forceRefresh && cached != null && cached.isFresh) {
      return cached.items;
    }

    final category = BusinessCategories.byLabel(categoryLabel);
    if (category != null && !_supportedLiveCategoryIds.contains(category.id)) {
      return <Map<String, dynamic>>[];
    }

    final callable = _functions.httpsCallable(_functionName);
    final stopwatch = Stopwatch()..start();

    final HttpsCallableResult<dynamic> response;
    try {
      response = await callable
          .call(<String, dynamic>{
            'latitude': latitude,
            'longitude': longitude,
            'radiusMeters': (radiusKm * 1000).clamp(500, 50000).round(),
            'categoryId': category?.id ?? '',
            'categoryLabel': categoryLabel,
            'limit': _resultLimit,
            'maxSearchCalls': category == null
                ? _allCategorySearchCalls
                : _singleCategorySearchCalls,
          })
          .timeout(_callTimeout);
    } catch (error) {
      debugPrint(
        'FIX_EXPLORE_PLACES_FAILED category="${category?.id ?? categoryLabel}" '
        'radiusKm=${radiusKm.round()} elapsedMs=${stopwatch.elapsedMilliseconds} '
        'error=$error',
      );
      return cached?.items ?? <Map<String, dynamic>>[];
    }

    final payload = response.data;
    if (payload is! Map) return <Map<String, dynamic>>[];

    final rawItems = payload['items'];
    if (rawItems is! Iterable) return <Map<String, dynamic>>[];

    final items = rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);

    _cache[key] = _GooglePlacesDirectoryCacheEntry(
      loadedAt: DateTime.now(),
      items: items,
    );

    debugPrint(
      'FIX_EXPLORE_PLACES_DONE category="${category?.id ?? categoryLabel}" '
      'count=${items.length} elapsedMs=${stopwatch.elapsedMilliseconds}',
    );

    return items;
  }

  String _cacheKey({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String categoryLabel,
  }) {
    final category = BusinessCategories.byLabel(categoryLabel)?.id ?? 'all';
    return [
      latitude.toStringAsFixed(2),
      longitude.toStringAsFixed(2),
      radiusKm.round(),
      category,
    ].join(':');
  }
}

class _GooglePlacesDirectoryCacheEntry {
  const _GooglePlacesDirectoryCacheEntry({
    required this.loadedAt,
    required this.items,
  });

  final DateTime loadedAt;
  final List<Map<String, dynamic>> items;

  bool get isFresh {
    final age = DateTime.now().difference(loadedAt);
    return age < GooglePlacesDirectoryService._cacheTtl;
  }
}
