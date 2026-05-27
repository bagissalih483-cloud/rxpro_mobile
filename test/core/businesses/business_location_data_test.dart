import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/businesses/business_location_data.dart';

void main() {
  group('BusinessLocationParser', () {
    test('parses Google Places geometry location', () {
      final location = BusinessLocationParser.fromMap({
        'formattedAddress': 'Akbayır, Karaköprü',
        'googleMapsUri': 'https://maps.google.com/?cid=123',
        'placeId': 'google-place-1',
        'geometry': {
          'location': {'lat': 37.1960292, 'lng': 38.8116446},
        },
      });

      expect(location.lat, 37.1960292);
      expect(location.lng, 38.8116446);
      expect(location.address, 'Akbayır, Karaköprü');
      expect(location.placeId, 'google-place-1');
      expect(location.hasCoordinate, isTrue);
    });

    test('normalizes comma and whitespace separated coordinates', () {
      final location = BusinessLocationParser.fromMap({
        'lat': '37,162850999999 996',
        'lng': '38,792016',
      });

      expect(location.lat, closeTo(37.162850999999996, 0.000000000001));
      expect(location.lng, 38.792016);
    });

    test('computes nearby business distance in kilometers', () {
      final distance = BusinessLocationParser.distanceKm(
        fromLat: 37.1960,
        fromLng: 38.8116,
        toLat: 37.2160,
        toLng: 38.8051,
      );

      expect(distance, greaterThan(2));
      expect(distance, lessThan(3));
    });
  });
}
