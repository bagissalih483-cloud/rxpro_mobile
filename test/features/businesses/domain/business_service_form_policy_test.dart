import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/businesses/domain/business_service_form_policy.dart';

void main() {
  group('BusinessServiceFormPolicy', () {
    test('normalizes service display fields and active state', () {
      final data = {
        FirestoreFields.serviceName: '  Cilt Bakımı ',
        FirestoreFields.serviceType: 'sessionPackage',
        FirestoreFields.category: ' Bakım ',
        FirestoreFields.bookingEnabled: true,
        FirestoreFields.isActive: true,
      };

      expect(BusinessServiceFormPolicy.serviceNameOf(data), 'Cilt Bakımı');
      expect(BusinessServiceFormPolicy.categoryOf(data), 'Bakım');
      expect(BusinessServiceFormPolicy.typeOf(data), 'sessionPackage');
      expect(BusinessServiceFormPolicy.typeLabelOf(data), 'Seanslı Paket');
      expect(BusinessServiceFormPolicy.isActive(data), isTrue);
      expect(BusinessServiceFormPolicy.sortKey(data), 'cilt bakımı');
    });

    test('parses price, duration, and session count with safe bounds', () {
      expect(BusinessServiceFormPolicy.parsePrice('125,50'), 125.5);
      expect(BusinessServiceFormPolicy.parsePrice('-10'), 0);
      expect(BusinessServiceFormPolicy.parseDuration(''), 45);
      expect(BusinessServiceFormPolicy.parseDuration('3'), 5);
      expect(BusinessServiceFormPolicy.parseDuration('900'), 480);
      expect(BusinessServiceFormPolicy.parseSessionCount(''), 1);
      expect(BusinessServiceFormPolicy.parseSessionCount('0'), 1);
      expect(BusinessServiceFormPolicy.parseSessionCount('999'), 120);
    });

    test('validates user-entered service form values', () {
      expect(BusinessServiceFormPolicy.validateName(' '), isNotNull);
      expect(BusinessServiceFormPolicy.validateName('Masaj'), isNull);
      expect(BusinessServiceFormPolicy.validatePrice('bad'), isNotNull);
      expect(BusinessServiceFormPolicy.validatePrice('100,25'), isNull);
      expect(BusinessServiceFormPolicy.validateDuration('4'), isNotNull);
      expect(BusinessServiceFormPolicy.validateDuration('45'), isNull);
      expect(
        BusinessServiceFormPolicy.validateSessionCount('', 'sessionPackage'),
        isNotNull,
      );
      expect(
        BusinessServiceFormPolicy.validateSessionCount('', 'single'),
        isNull,
      );
    });

    test('builds a normalized service payload', () {
      final payload = BusinessServiceFormPolicy.buildPayload(
        businessId: 'business_1',
        name: '  Lazer Paketi ',
        price: '1500,50',
        duration: '60',
        description: '  Paket açıklaması ',
        category: '',
        type: 'sessionPackage',
        sessionCount: '8',
        active: true,
      );

      expect(payload[FirestoreFields.businessId], 'business_1');
      expect(payload[FirestoreFields.serviceName], 'Lazer Paketi');
      expect(payload[FirestoreFields.price], 1500.5);
      expect(payload[FirestoreFields.durationMinutes], 60);
      expect(payload[FirestoreFields.description], 'Paket açıklaması');
      expect(payload[FirestoreFields.category], 'Genel');
      expect(payload[FirestoreFields.serviceTypeLabel], 'Seanslı Paket');
      expect(payload[FirestoreFields.sessionCount], 8);
      expect(payload['remainingSessionDefault'], 8);
      expect(payload[FirestoreFields.bookingEnabled], isTrue);
    });
  });
}
