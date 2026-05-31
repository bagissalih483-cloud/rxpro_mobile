import 'package:flutter/material.dart';

class BusinessManualAppointmentSheetController extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedStaffId = '';
  String _selectedServiceId = '';
  bool _saving = false;

  DateTime get selectedDate => _selectedDate;
  TimeOfDay get selectedTime => _selectedTime;
  String get selectedStaffId => _selectedStaffId;
  String get selectedServiceId => _selectedServiceId;
  bool get saving => _saving;

  void applyInitial({
    required DateTime selectedDate,
    required TimeOfDay selectedTime,
    required String selectedStaffId,
  }) {
    _selectedDate = selectedDate;
    _selectedTime = selectedTime;
    _selectedStaffId = selectedStaffId;
  }

  void applyService(String value) {
    if (_selectedServiceId == value) return;
    _selectedServiceId = value;
    notifyListeners();
  }

  void selectDate(DateTime value) {
    _selectedDate = value;
    notifyListeners();
  }

  void selectTime(TimeOfDay value) {
    _selectedTime = value;
    notifyListeners();
  }

  void selectStaff(String value) {
    if (_selectedStaffId == value) return;
    _selectedStaffId = value;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    _saving = value;
    notifyListeners();
  }
}
