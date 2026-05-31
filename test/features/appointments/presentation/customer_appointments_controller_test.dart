import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/appointments/presentation/controllers/customer_appointments_controller.dart';

void main() {
  group('CustomerAppointmentsController', () {
    test('owns selected tab and refresh version', () async {
      final controller = CustomerAppointmentsController();

      expect(controller.selectedTab, 0);
      expect(controller.refreshVersion, 0);

      controller.selectTab(2);
      expect(controller.selectedTab, 2);

      await controller.refresh();
      expect(controller.refreshVersion, 1);

      controller.dispose();
    });
  });
}
