import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/appointments/appointment_status_mapper.dart';
import 'package:rxpro_mobile/features/appointments/domain/appointment_state_transition_policy.dart';

void main() {
  group('AppointmentStateTransitionPolicy', () {
    test('allows customer cancellation from legacy active status', () {
      expect(
        AppointmentStateTransitionPolicy.canCancelByCustomer('active'),
        isTrue,
      );
    });

    test('blocks cancellation from terminal statuses', () {
      expect(
        AppointmentStateTransitionPolicy.canCancelByCustomer('completed'),
        isFalse,
      );
      expect(
        AppointmentStateTransitionPolicy.canCancelByCustomer('cancelled'),
        isFalse,
      );
      expect(
        AppointmentStateTransitionPolicy.canCancelByCustomer('noShow'),
        isFalse,
      );
    });

    test('creates canonical customer cancellation fields', () {
      final fields =
          AppointmentStateTransitionPolicy.customerCancellationFields(
            reason: ' Plan degisti ',
          );

      expect(fields['status'], 'cancelledByUser');
      expect(fields['appointmentStatus'], 'cancelledByUser');
      expect(fields['state'], 'cancelledByUser');
      expect(fields['isActive'], isFalse);
      expect(fields['isCancelled'], isTrue);
      expect(fields['cancelReason'], 'Plan degisti');
      expect(fields['cancellationReason'], 'Plan degisti');
    });

    test('maps legacy active and cancelled values into canonical buckets', () {
      expect(
        AppointmentStatusMapper.toKey(
          AppointmentStatusMapper.fromAny('active'),
        ),
        'pending',
      );
      expect(
        AppointmentStatusMapper.toKey(
          AppointmentStatusMapper.fromAny('cancelled'),
        ),
        'cancelledByUser',
      );
    });
  });
}
