import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/data/business_duration_analytics_repository.dart';

void main() {
  group('BusinessDurationAppointment', () {
    test('fromMap returns completed appointment duration model', () {
      final item = BusinessDurationAppointment.fromMap(const {
        'status': 'completed',
        'serviceName': 'Cilt bakimi',
        'staffName': 'Ayse',
        'workDurationMinutes': '55',
        'durationMinutes': 45,
      });

      expect(item, isNotNull);
      expect(item!.serviceName, 'Cilt bakimi');
      expect(item.staffName, 'Ayse');
      expect(item.workDurationMinutes, 55);
      expect(item.plannedDurationMinutes, 45);
    });

    test('fromMap ignores incomplete or durationless appointments', () {
      expect(
        BusinessDurationAppointment.fromMap(const {
          'status': 'pending',
          'workDurationMinutes': 30,
        }),
        isNull,
      );
      expect(
        BusinessDurationAppointment.fromMap(const {'status': 'completed'}),
        isNull,
      );
    });

    test('fromMap supports completion and planned duration fallbacks', () {
      final item = BusinessDurationAppointment.fromMap(const {
        'isCompleted': true,
        'service': 'Masaj',
        'completedByName': 'Mehmet',
        'workDurationMinutes': 60,
        'serviceDurationMinutes': '50',
      });

      expect(item, isNotNull);
      expect(item!.serviceName, 'Masaj');
      expect(item.staffName, 'Mehmet');
      expect(item.plannedDurationMinutes, 50);
    });
  });
}
