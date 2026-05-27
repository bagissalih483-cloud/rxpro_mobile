import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/appointments/domain/service_staff_compatibility_policy.dart';

void main() {
  group('ServiceStaffCompatibilityPolicy pure helpers', () {
    test(
      'stringList returns normalized string values from iterable values',
      () {
        expect(
          ServiceStaffCompatibilityPolicy.stringList(['a', ' b ', 3, null, '']),
          ['a', 'b', '3', 'null'],
        );
      },
    );

    test('stringList returns empty list for null and scalar values', () {
      expect(ServiceStaffCompatibilityPolicy.stringList(null), isEmpty);
      expect(ServiceStaffCompatibilityPolicy.stringList('abc'), isEmpty);
      expect(ServiceStaffCompatibilityPolicy.stringList(12), isEmpty);
    });
  });
}
