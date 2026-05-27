import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/businesses/business_geo_index.dart';

void main() {
  group('BusinessGeoIndex', () {
    test('encodes a stable geohash for a known coordinate', () {
      final hash = BusinessGeoIndex.encode(
        latitude: 37.1960292,
        longitude: 38.8116446,
      );

      expect(hash, startsWith('syee'));
      expect(hash.length, 9);
    });

    test('builds payload prefixes for Firestore indexing', () {
      final payload = BusinessGeoIndex.payload(
        latitude: 37.1960292,
        longitude: 38.8116446,
      );

      expect(payload['geoHash']!.length, 9);
      expect(payload['geoHash4'], payload['geoHash']!.substring(0, 4));
      expect(payload['geoHash5'], payload['geoHash']!.substring(0, 5));
      expect(payload['geoHash6'], payload['geoHash']!.substring(0, 6));
      expect(payload['geoHash7'], payload['geoHash']!.substring(0, 7));
    });

    test('chooses practical index precision by radius', () {
      expect(BusinessGeoIndex.fieldForRadiusKm(0.5), 'geoHash7');
      expect(BusinessGeoIndex.fieldForRadiusKm(3), 'geoHash6');
      expect(BusinessGeoIndex.fieldForRadiusKm(15), 'geoHash5');
      expect(BusinessGeoIndex.fieldForRadiusKm(25), 'geoHash4');
    });

    test('nearby prefixes include the center prefix', () {
      final prefixes = BusinessGeoIndex.nearbyPrefixes(
        latitude: 37.1960292,
        longitude: 38.8116446,
        radiusKm: 25,
      );
      final center = BusinessGeoIndex.encode(
        latitude: 37.1960292,
        longitude: 38.8116446,
        precision: 4,
      );

      expect(prefixes, contains(center));
      expect(prefixes.length, greaterThanOrEqualTo(4));
    });
  });
}
