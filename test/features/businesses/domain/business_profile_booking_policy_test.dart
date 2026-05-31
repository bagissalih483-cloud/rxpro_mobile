import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/domain/business_profile_booking_policy.dart';

void main() {
  group('BusinessProfileBookingPolicy', () {
    test('normalizes service id lists from mixed values', () {
      expect(BusinessProfileBookingPolicy.stringList([' s1 ', '', 's2', 3]), [
        's1',
        's2',
        '3',
      ]);
      expect(BusinessProfileBookingPolicy.stringList('s1'), isEmpty);
    });

    test('builds deterministic upcoming day labels', () {
      final days = BusinessProfileBookingPolicy.upcomingDays(
        now: DateTime(2026, 5, 29, 18, 45),
        count: 3,
      );

      expect(days, [
        DateTime(2026, 5, 29),
        DateTime(2026, 5, 30),
        DateTime(2026, 5, 31),
      ]);
      expect(BusinessProfileBookingPolicy.dateText(days.first), '29.05.2026');
      expect(BusinessProfileBookingPolicy.shortDay(days.first), 'Cum');
    });

    test('allows staff without explicit service restrictions', () {
      expect(
        BusinessProfileBookingPolicy.staffCanProvideService(
          serviceId: 'service-1',
          staffServiceIds: const [],
        ),
        isTrue,
      );
      expect(
        BusinessProfileBookingPolicy.staffCanProvideService(
          serviceId: 'service-1',
          staffServiceIds: const ['service-2'],
        ),
        isFalse,
      );
    });

    test('parses service duration with safe fallback', () {
      expect(BusinessProfileBookingPolicy.durationMinutes('45'), 45);
      expect(BusinessProfileBookingPolicy.durationMinutes(20.4), 20);
      expect(BusinessProfileBookingPolicy.durationMinutes('bad'), 30);
    });
  });
}
