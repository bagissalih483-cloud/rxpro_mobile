import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'business_directory_cache_service.dart';

class BusinessRouteInfo {
  const BusinessRouteInfo({
    required this.distanceMeters,
    required this.durationSeconds,
    this.source = '',
  });

  final int distanceMeters;
  final int durationSeconds;
  final String source;

  bool get isUsable => distanceMeters > 0;

  double get distanceKm => distanceMeters / 1000;

  String get distanceLabel {
    if (distanceMeters < 1000) return '$distanceMeters m';
    if (distanceKm < 10) return '${distanceKm.toStringAsFixed(1)} km';
    return '${distanceKm.round()} km';
  }

  String get durationLabel {
    if (durationSeconds <= 0) return '';

    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes dk';

    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (remainder == 0) return '$hours sa';
    return '$hours sa $remainder dk';
  }

  String get summaryLabel {
    final duration = durationLabel;
    if (duration.isEmpty) return 'Araçla $distanceLabel';
    return 'Araçla $distanceLabel · $duration';
  }

  factory BusinessRouteInfo.fromMap(Map<dynamic, dynamic> data) {
    return BusinessRouteInfo(
      distanceMeters: _toInt(data['distanceMeters']),
      durationSeconds: _toInt(data['durationSeconds']),
      source: data['source']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class BusinessRouteDistanceService {
  BusinessRouteDistanceService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  static const _functionName = 'calculateBusinessRouteInfo';
  static const _callTimeout = Duration(seconds: 9);
  static const _cacheTtl = Duration(minutes: 15);

  final FirebaseFunctions _functions;
  final Map<String, _BusinessRouteCacheEntry> _cache =
      <String, _BusinessRouteCacheEntry>{};

  Future<BusinessRouteInfo?> calculate({
    required Position? origin,
    required BusinessDirectoryItem business,
  }) async {
    if (origin == null || !business.hasCoordinate) return null;

    final key = _cacheKey(origin: origin, business: business);
    final cached = _cache[key];
    if (cached != null && cached.isFresh) return cached.info;

    final callable = _functions.httpsCallable(_functionName);
    try {
      final response = await callable
          .call(<String, dynamic>{
            'originLatitude': origin.latitude,
            'originLongitude': origin.longitude,
            'destinationLatitude': business.lat,
            'destinationLongitude': business.lng,
          })
          .timeout(_callTimeout);

      final payload = response.data;
      if (payload is! Map) return null;

      final info = BusinessRouteInfo.fromMap(payload);
      if (!info.isUsable) return null;

      _cache[key] = _BusinessRouteCacheEntry(
        loadedAt: DateTime.now(),
        info: info,
      );
      return info;
    } catch (error) {
      debugPrint(
        'FIX_ROUTE_DISTANCE_FAILED business=${business.id} error=$error',
      );
      return null;
    }
  }

  String _cacheKey({
    required Position origin,
    required BusinessDirectoryItem business,
  }) {
    final destination = business.placeId.trim().isNotEmpty
        ? business.placeId.trim()
        : '${business.lat?.toStringAsFixed(5)},'
              '${business.lng?.toStringAsFixed(5)}';

    return [
      origin.latitude.toStringAsFixed(3),
      origin.longitude.toStringAsFixed(3),
      destination,
    ].join(':');
  }
}

class _BusinessRouteCacheEntry {
  const _BusinessRouteCacheEntry({
    required this.loadedAt,
    required this.info,
  });

  final DateTime loadedAt;
  final BusinessRouteInfo info;

  bool get isFresh =>
      DateTime.now().difference(loadedAt) <
      BusinessRouteDistanceService._cacheTtl;
}
