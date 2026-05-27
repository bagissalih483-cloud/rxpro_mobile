import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/data/business_live_flow_repository.dart';

void main() {
  group('BusinessLiveFlowAppointment', () {
    test('detects active appointment statuses', () {
      expect(
        BusinessLiveFlowAppointment.fromMap(const {
          'status': 'active',
        }).isActive,
        isTrue,
      );
      expect(
        BusinessLiveFlowAppointment.fromMap(const {
          'appointmentStatus': 'in_progress',
        }).isActive,
        isTrue,
      );
      expect(
        BusinessLiveFlowAppointment.fromMap(const {
          'state': 'completed',
        }).isActive,
        isFalse,
      );
    });
  });

  group('BusinessLiveFlowStaff', () {
    test('detects busy staff from status or availability', () {
      expect(
        BusinessLiveFlowStaff.fromMap(const {
          'currentWorkStatus': 'busy',
        }).isBusy,
        isTrue,
      );
      expect(
        BusinessLiveFlowStaff.fromMap(const {'isAvailable': false}).isBusy,
        isTrue,
      );
      expect(
        BusinessLiveFlowStaff.fromMap(const {'workStatus': 'available'}).isBusy,
        isFalse,
      );
    });
  });

  group('BusinessLiveFlowActivityLog', () {
    test('uses title, type, and fallback values in order', () {
      expect(
        BusinessLiveFlowActivityLog.fromMap(const {'title': 'Started'}).title,
        'Started',
      );
      expect(
        BusinessLiveFlowActivityLog.fromMap(const {'type': 'completed'}).title,
        'completed',
      );
      expect(
        BusinessLiveFlowActivityLog.fromMap(const {}).title,
        'Son hareket kaydi alindi.',
      );
    });
  });
}
