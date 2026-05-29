import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_fields.dart';

class BusinessLocationData {
  const BusinessLocationData({
    this.lat,
    this.lng,
    this.address = '',
    this.googleMapsUri = '',
    this.placeId = '',
  });

  final double? lat;
  final double? lng;
  final String address;
  final String googleMapsUri;
  final String placeId;

  bool get hasCoordinate => lat != null && lng != null;

  String get mapsDestination {
    if (hasCoordinate) {
      return '${lat!.toStringAsFixed(7)},${lng!.toStringAsFixed(7)}';
    }

    return address.trim();
  }

  double distanceKmFrom({required double? latitude, required double? longitude}) {
    if (latitude == null || longitude == null || lat == null || lng == null) {
      return double.infinity;
    }

    return BusinessLocationParser.distanceKm(
      fromLat: latitude,
      fromLng: longitude,
      toLat: lat!,
      toLng: lng!,
    );
  }
}

class BusinessLocationParser {
  const BusinessLocationParser._();

  static BusinessLocationData fromMap(Map<String, dynamic> data) {
    final location = data[FirestoreFields.location];
    final geometry = data['geometry'];
    final geometryLocation = geometry is Map ? geometry['location'] : null;

    final lat = _firstCoordinate(
      values: <dynamic>[
        data[FirestoreFields.lat],
        data[FirestoreFields.latitude],
        data['locationLat'],
        data['googleLat'],
        if (location is GeoPoint) location.latitude,
        if (location is Map) location['lat'],
        if (location is Map) location['latitude'],
        if (geometryLocation is Map) geometryLocation['lat'],
        if (geometryLocation is Map) geometryLocation['latitude'],
      ],
      latitude: true,
    );

    final lng = _firstCoordinate(
      values: <dynamic>[
        data[FirestoreFields.lng],
        data[FirestoreFields.longitude],
        data['locationLng'],
        data['googleLng'],
        if (location is GeoPoint) location.longitude,
        if (location is Map) location['lng'],
        if (location is Map) location['lon'],
        if (location is Map) location['longitude'],
        if (geometryLocation is Map) geometryLocation['lng'],
        if (geometryLocation is Map) geometryLocation['lon'],
        if (geometryLocation is Map) geometryLocation['longitude'],
      ],
      latitude: false,
    );

    return BusinessLocationData(
      lat: lat,
      lng: lng,
      address: _firstNonEmpty(<dynamic>[
        data[FirestoreFields.fullAddress],
        data[FirestoreFields.address],
        data['formattedAddress'],
        data['formatted_address'],
        data['vicinity'],
      ]),
      googleMapsUri: _firstNonEmpty(<dynamic>[
        data['googleMapsUri'],
        data['google_maps_uri'],
        data['googleMapsUrl'],
        data['mapsUrl'],
        data['mapUrl'],
        data['url'],
        data['Harita'],
      ]),
      placeId: _firstNonEmpty(<dynamic>[
        data['googlePlaceId'],
        data['source_place_id'],
        data['placeId'],
        data['place_id'],
      ]),
    );
  }

  static double distanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    const earthRadiusKm = 6371.0088;
    final dLat = _radians(toLat - fromLat);
    final dLng = _radians(toLng - fromLng);
    final fromLatRad = _radians(fromLat);
    final toLatRad = _radians(toLat);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(fromLatRad) *
            math.cos(toLatRad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double? parseCoordinate(dynamic value, {required bool latitude}) {
    if (value == null) return null;
    if (value is num) return _valid(value.toDouble(), latitude: latitude);

    final compact = value
        .toString()
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.');
    if (compact.isEmpty) return null;

    final direct = double.tryParse(compact);
    if (direct != null) return _valid(direct, latitude: latitude);

    final match = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(compact);
    if (match == null) return null;

    final parsed = double.tryParse(match.group(0)!.replaceAll(',', '.'));
    return _valid(parsed, latitude: latitude);
  }

  static double? _firstCoordinate({
    required List<dynamic> values,
    required bool latitude,
  }) {
    for (final value in values) {
      final parsed = parseCoordinate(value, latitude: latitude);
      if (parsed != null) return parsed;
    }

    return null;
  }

  static double? _valid(double? value, {required bool latitude}) {
    if (value == null || value.isNaN || value.isInfinite) return null;
    final max = latitude ? 90 : 180;
    if (value < -max || value > max) return null;

    return value;
  }

  static double _radians(double degree) => degree * math.pi / 180;

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return _cleanLegacyEncoding(text);
    }

    return '';
  }

  static String _cleanLegacyEncoding(String text) {
    return text
        .replaceAll('Ä°', 'İ')
        .replaceAll('Ä±', 'ı')
        .replaceAll('ÄŸ', 'ğ')
        .replaceAll('Äž', 'Ğ')
        .replaceAll('Ã¼', 'ü')
        .replaceAll('Ãœ', 'Ü')
        .replaceAll('ÅŸ', 'ş')
        .replaceAll('Åž', 'Ş')
        .replaceAll('Ã¶', 'ö')
        .replaceAll('Ã–', 'Ö')
        .replaceAll('Ã§', 'ç')
        .replaceAll('Ã‡', 'Ç')
        .replaceAll('â€™', '’')
        .replaceAll('â€¢', '•');
  }
}
