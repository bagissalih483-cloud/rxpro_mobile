import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/appointments/domain/customer_appointment_status_policy.dart';

void main() {
  group('CustomerAppointmentStatusPolicy', () {
    final now = DateTime(2026, 5, 29, 12);

    test('matches customer identity aliases', () {
      expect(
        CustomerAppointmentStatusPolicy.matchesCurrentUser(
          {'clientUid': ' user-1 '},
          'user-1',
        ),
        isTrue,
      );
      expect(
        CustomerAppointmentStatusPolicy.matchesCurrentUser(
          {'customerUid': 'other'},
          'user-1',
        ),
        isFalse,
      );
    });

    test('separates active postponed cancelled and completed buckets', () {
      expect(
        CustomerAppointmentStatusPolicy.isActive(
          {
            'status': 'confirmed',
            'startAt': Timestamp.fromDate(DateTime(2026, 5, 29, 14)),
          },
          now: now,
        ),
        isTrue,
      );
      expect(
        CustomerAppointmentStatusPolicy.isPostponeRequested({
          'customerApprovalStatus': 'pending',
        }),
        isTrue,
      );
      expect(
        CustomerAppointmentStatusPolicy.isCancelled({'status': 'iptal edildi'}),
        isTrue,
      );
      expect(
        CustomerAppointmentStatusPolicy.isCompleted({'status': 'tamamland\u0131'}),
        isTrue,
      );
    });

    test('uses timestamp or iso start to detect past appointments', () {
      expect(
        CustomerAppointmentStatusPolicy.isPast(
          {'startAt': Timestamp.fromDate(DateTime(2026, 5, 29, 11))},
          now: now,
        ),
        isTrue,
      );
      expect(
        CustomerAppointmentStatusPolicy.isPast(
          {'startAtIso': '2026-05-29T13:00:00'},
          now: now,
        ),
        isFalse,
      );
    });

    test('keeps terminal statuses out of active and completed conflicts', () {
      expect(
        CustomerAppointmentStatusPolicy.isActive(
          {
            'status': 'cancelled',
            'startAtIso': '2026-05-29T14:00:00',
          },
          now: now,
        ),
        isFalse,
      );
      expect(
        CustomerAppointmentStatusPolicy.isCompleted(
          {'status': 'postpone_requested'},
          now: now,
        ),
        isFalse,
      );
    });
  });
}
