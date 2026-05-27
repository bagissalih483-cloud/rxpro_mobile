import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_cache_service.dart';

void main() {
  group('BusinessDirectoryItem', () {
    test('parses live Google Places directory payload', () {
      final item = BusinessDirectoryItem.fromMap(<String, dynamic>{
        'id': 'google_places_1',
        'businessName': 'Test Dental Clinic',
        'formattedAddress': 'Ataturk Cd. No: 1',
        'nationalPhoneNumber': '0412 000 00 00',
        'googleMapsUri': 'https://maps.google.com/?cid=1',
        'placeId': 'places/test-dental-clinic',
        'types': <String>['dental_clinic', 'health'],
        'location': <String, dynamic>{
          'latitude': 37.9144,
          'longitude': 40.2306,
        },
        'ratingAvg': 4.7,
        'ratingCount': 83,
        'source': 'google_places_live',
      });

      expect(item.id, 'google_places_1');
      expect(item.name, 'Test Dental Clinic');
      expect(item.address, 'Ataturk Cd. No: 1');
      expect(item.phone, '0412 000 00 00');
      expect(item.placeId, 'places/test-dental-clinic');
      expect(item.mapsUrl, startsWith('https://maps.google.com'));
      expect(item.hasCoordinate, isTrue);
      expect(item.isMember, isFalse);
      expect(item.ratingAvg, 4.7);
      expect(item.ratingCount, 83);
      expect(item.category, 'Sağlık & Klinik');
      expect(item.source, 'google_places_live');
    });

    test('classifies supported Google Places type groups', () {
      final sport = BusinessDirectoryItem.fromMap(<String, dynamic>{
        'id': 'google_places_3',
        'businessName': 'Pilates Studio',
        'types': <String>['yoga_studio'],
      });
      final health = BusinessDirectoryItem.fromMap(<String, dynamic>{
        'id': 'google_places_4',
        'businessName': 'Medical Center',
        'types': <String>['medical_center'],
      });

      expect(sport.category, 'Spor & Fitness');
      expect(health.category, 'Sağlık & Klinik');
    });

    test('cleans legacy mojibake labels from directory payloads', () {
      final item = BusinessDirectoryItem.fromMap(<String, dynamic>{
        'id': 'google_places_2',
        'businessName': 'GÃ¼zel Klinik',
        'category': 'SaÄŸlÄ±k & Klinik',
        'address': 'Ä°stanbul',
        'placeId': 'places/legacy-text',
      });

      expect(item.name, 'Güzel Klinik');
      expect(item.category, 'Sağlık & Klinik');
      expect(item.address, 'İstanbul');
    });
    test('uses district cache tags for a clean explore location label', () {
      final item = BusinessDirectoryItem.fromMap(<String, dynamic>{
        'id': 'google_cached_1',
        'businessName': 'Fix Studio',
        'category': 'Güzellik & Bakım',
        'address': 'Atatürk Blv. No: 10, Karaköprü/Şanlıurfa',
        'city': 'Şanlıurfa',
        'district': 'Karaköprü',
        'areaLabel': 'Atatürk Blv.',
        'placeId': 'places/fix-studio',
      });

      expect(item.locationLabel, 'Atatürk Blv. / Karaköprü / Şanlıurfa');
    });
  });
}
