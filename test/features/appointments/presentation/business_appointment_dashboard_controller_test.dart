import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/appointments/presentation/business_appointment_dashboard_controller.dart';

void main() {
  test('tracks day, month, mode, and manual appointment sync', () {
    final controller = BusinessAppointmentDashboardController(
      initialDay: DateTime(2026, 5, 30),
    );

    expect(controller.selectedMode, 0);
    expect(controller.selectedDay, DateTime(2026, 5, 30));
    expect(controller.visibleMonth, DateTime(2026, 5, 1));

    controller.selectMode(1);
    controller.nextDay();
    expect(controller.selectedMode, 1);
    expect(controller.selectedDay, DateTime(2026, 5, 31));
    expect(controller.visibleMonth, DateTime(2026, 5, 1));

    controller.nextDay();
    expect(controller.selectedDay, DateTime(2026, 6, 1));
    expect(controller.visibleMonth, DateTime(2026, 6, 1));

    controller.previousMonth();
    expect(controller.visibleMonth, DateTime(2026, 5, 1));

    controller.syncAfterManualAppointment(DateTime(2026, 7, 14, 13, 30));
    expect(controller.selectedMode, 0);
    expect(controller.selectedDay, DateTime(2026, 7, 14));
    expect(controller.visibleMonth, DateTime(2026, 7, 1));
  });
}
