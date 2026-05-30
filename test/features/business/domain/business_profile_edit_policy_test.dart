import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/business/domain/business_profile_edit_policy.dart';

void main() {
  group('BusinessProfileEditPolicy', () {
    test('selects the first non-empty profile field', () {
      expect(
        BusinessProfileEditPolicy.firstNonEmpty(['', '  ', 'Fix Studio']),
        'Fix Studio',
      );
    });

    test('validates required identity and description fields', () {
      expect(BusinessProfileEditPolicy.validateBusinessName('F'), isNotNull);
      expect(BusinessProfileEditPolicy.validateBusinessName('Fix'), isNull);
      expect(BusinessProfileEditPolicy.validateDescription('short'), isNotNull);
      expect(
        BusinessProfileEditPolicy.validateDescription('Enough profile text'),
        isNull,
      );
      expect(
        BusinessProfileEditPolicy.validateRequired(' ', 'Required'),
        'Required',
      );
    });

    test('validates optional email and website values only when present', () {
      expect(BusinessProfileEditPolicy.validateOptionalEmail(''), isNull);
      expect(
        BusinessProfileEditPolicy.validateOptionalEmail('bad-email'),
        isNotNull,
      );
      expect(
        BusinessProfileEditPolicy.validateOptionalEmail('fix@example.com'),
        isNull,
      );

      expect(BusinessProfileEditPolicy.validateOptionalUrl(''), isNull);
      expect(BusinessProfileEditPolicy.validateOptionalUrl('fix.com'), isNotNull);
      expect(
        BusinessProfileEditPolicy.validateOptionalUrl('https://fix.com'),
        isNull,
      );
    });

    test('computes storefront readiness percent from required assets', () {
      final readiness = BusinessProfileEditPolicy.readiness(
        businessName: 'Fix',
        description: 'Detailed profile',
        city: 'Sanliurfa',
        district: 'Karakopru',
        address: 'Main street',
        workingHours: '09:00-18:00',
        hasLocation: true,
        hasLogo: false,
        hasCover: false,
      );

      expect(readiness.completed, 7);
      expect(readiness.total, 9);
      expect(readiness.percent, 78);
    });
  });
}
