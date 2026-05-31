import 'package:flutter/foundation.dart';

class BusinessAppointmentDashboardController extends ChangeNotifier {
  BusinessAppointmentDashboardController({DateTime? initialDay})
    : _selectedDay = initialDay ?? DateTime.now(),
      _visibleMonth = DateTime(
        (initialDay ?? DateTime.now()).year,
        (initialDay ?? DateTime.now()).month,
        1,
      );

  int _selectedMode = 0;
  DateTime _selectedDay;
  DateTime _visibleMonth;

  int get selectedMode => _selectedMode;
  DateTime get selectedDay => _selectedDay;
  DateTime get visibleMonth => _visibleMonth;

  void selectMode(int value) {
    if (_selectedMode == value) return;
    _selectedMode = value;
    notifyListeners();
  }

  void selectDay(DateTime value) {
    _selectedDay = value;
    notifyListeners();
  }

  void previousDay() {
    _selectedDay = _selectedDay.subtract(const Duration(days: 1));
    _visibleMonth = DateTime(_selectedDay.year, _selectedDay.month, 1);
    notifyListeners();
  }

  void nextDay() {
    _selectedDay = _selectedDay.add(const Duration(days: 1));
    _visibleMonth = DateTime(_selectedDay.year, _selectedDay.month, 1);
    notifyListeners();
  }

  void selectToday(DateTime now) {
    _selectedDay = now;
    _visibleMonth = DateTime(now.year, now.month, 1);
    notifyListeners();
  }

  void previousMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    notifyListeners();
  }

  void nextMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    notifyListeners();
  }

  void syncAfterManualAppointment(DateTime slot) {
    _selectedDay = DateTime(slot.year, slot.month, slot.day);
    _visibleMonth = DateTime(slot.year, slot.month, 1);
    _selectedMode = 0;
    notifyListeners();
  }
}
