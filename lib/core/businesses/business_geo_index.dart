class BusinessGeoIndex {
  const BusinessGeoIndex._();

  static const _alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';

  static String encode({
    required double latitude,
    required double longitude,
    int precision = 9,
  }) {
    if (precision <= 0) return '';

    var latRange = const GeoHashRange(-90, 90);
    var lngRange = const GeoHashRange(-180, 180);
    var evenBit = true;
    var bit = 0;
    var ch = 0;
    final buffer = StringBuffer();

    while (buffer.length < precision) {
      if (evenBit) {
        final mid = lngRange.mid;
        if (longitude >= mid) {
          ch = (ch << 1) + 1;
          lngRange = GeoHashRange(mid, lngRange.max);
        } else {
          ch = ch << 1;
          lngRange = GeoHashRange(lngRange.min, mid);
        }
      } else {
        final mid = latRange.mid;
        if (latitude >= mid) {
          ch = (ch << 1) + 1;
          latRange = GeoHashRange(mid, latRange.max);
        } else {
          ch = ch << 1;
          latRange = GeoHashRange(latRange.min, mid);
        }
      }

      evenBit = !evenBit;

      if (++bit == 5) {
        buffer.write(_alphabet[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return buffer.toString();
  }

  static Map<String, String> payload({
    required double latitude,
    required double longitude,
  }) {
    final full = encode(latitude: latitude, longitude: longitude);

    return <String, String>{
      'geoHash': full,
      'geoHash4': full.substring(0, 4),
      'geoHash5': full.substring(0, 5),
      'geoHash6': full.substring(0, 6),
      'geoHash7': full.substring(0, 7),
    };
  }

  static String fieldForRadiusKm(double radiusKm) {
    if (radiusKm <= 1) return 'geoHash7';
    if (radiusKm <= 5) return 'geoHash6';
    if (radiusKm <= 20) return 'geoHash5';

    return 'geoHash4';
  }

  static int precisionForRadiusKm(double radiusKm) {
    switch (fieldForRadiusKm(radiusKm)) {
      case 'geoHash7':
        return 7;
      case 'geoHash6':
        return 6;
      case 'geoHash5':
        return 5;
      default:
        return 4;
    }
  }

  static List<String> nearbyPrefixes({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    final precision = precisionForRadiusKm(radiusKm);
    final center = encode(
      latitude: latitude,
      longitude: longitude,
      precision: precision,
    );
    final cell = decodeBounds(center);
    final latSpan = cell.lat.max - cell.lat.min;
    final lngSpan = cell.lng.max - cell.lng.min;
    final latCenter = cell.lat.mid;
    final lngCenter = cell.lng.mid;
    final values = <String>{};

    for (var latOffset = -1; latOffset <= 1; latOffset++) {
      for (var lngOffset = -1; lngOffset <= 1; lngOffset++) {
        final lat = (latCenter + latSpan * latOffset)
            .clamp(-89.999999, 89.999999)
            .toDouble();
        final lng = _wrapLongitude(lngCenter + lngSpan * lngOffset);
        values.add(encode(latitude: lat, longitude: lng, precision: precision));
      }
    }

    return values.toList(growable: false)..sort();
  }

  static GeoHashBounds decodeBounds(String hash) {
    var latRange = const GeoHashRange(-90, 90);
    var lngRange = const GeoHashRange(-180, 180);
    var evenBit = true;

    for (final codeUnit in hash.codeUnits) {
      final idx = _alphabet.indexOf(String.fromCharCode(codeUnit));
      if (idx < 0) continue;

      for (var mask = 16; mask != 0; mask >>= 1) {
        if (evenBit) {
          lngRange = _split(lngRange, (idx & mask) != 0);
        } else {
          latRange = _split(latRange, (idx & mask) != 0);
        }

        evenBit = !evenBit;
      }
    }

    return GeoHashBounds(lat: latRange, lng: lngRange);
  }

  static GeoHashRange _split(GeoHashRange range, bool upper) {
    return upper
        ? GeoHashRange(range.mid, range.max)
        : GeoHashRange(range.min, range.mid);
  }

  static double _wrapLongitude(double value) {
    var wrapped = value;
    while (wrapped < -180) {
      wrapped += 360;
    }
    while (wrapped > 180) {
      wrapped -= 360;
    }

    return wrapped;
  }
}

class GeoHashBounds {
  const GeoHashBounds({required this.lat, required this.lng});

  final GeoHashRange lat;
  final GeoHashRange lng;
}

class GeoHashRange {
  const GeoHashRange(this.min, this.max);

  final double min;
  final double max;

  double get mid => (min + max) / 2;
}
