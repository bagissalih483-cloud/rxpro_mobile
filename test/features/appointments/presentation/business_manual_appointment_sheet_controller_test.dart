import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/appointments/presentation/business_manual_appointment_sheet_controller.dart';

void main() {
  test('tracks selected manual appointment form state', () {
    final controller = BusinessManualAppointmentSheetController();

    controller.applyInitial(
      selectedDate: DateTime(2026, 5, 30),
      selectedTime: const TimeOfDay(hour: 13, minute: 45),
      selectedStaffId: 'staff-1',
    );
    controller.applyService('service-1');
    controller.selectDate(DateTime(2026, 6, 1));
    controller.selectTime(const TimeOfDay(hour: 9, minute: 15));
    controller.selectStaff('staff-2');
    controller.setSaving(true);

    expect(controller.selectedDate, DateTime(2026, 6, 1));
    expect(controller.selectedTime, const TimeOfDay(hour: 9, minute: 15));
    expect(controller.selectedStaffId, 'staff-2');
    expect(controller.selectedServiceId, 'service-1');
    expect(controller.saving, isTrue);
  });
}
