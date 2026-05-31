import 'package:flutter/foundation.dart';
import 'package:rxpro_mobile/features/businesses/domain/business_profile_booking_policy.dart';

class BusinessProfileBookingController extends ChangeNotifier {
  String? _selectedServiceId;
  String? _selectedServiceName;
  String? _selectedStaffId;
  String? _selectedStaffName;
  String? _selectedStaffUid;
  String? _selectedStaffEmail;
  List<String> _selectedStaffServiceIds = const <String>[];
  int _selectedServiceDurationMinutes = 30;
  String? _selectedDateText;
  String? _selectedTimeText;
  bool _saving = false;
  int _expandedBookingSection = 0;

  String? get selectedServiceId => _selectedServiceId;
  String? get selectedServiceName => _selectedServiceName;
  String? get selectedStaffId => _selectedStaffId;
  String? get selectedStaffName => _selectedStaffName;
  String? get selectedStaffUid => _selectedStaffUid;
  String? get selectedStaffEmail => _selectedStaffEmail;
  List<String> get selectedStaffServiceIds {
    return List.unmodifiable(_selectedStaffServiceIds);
  }

  int get selectedServiceDurationMinutes => _selectedServiceDurationMinutes;
  String? get selectedDateText => _selectedDateText;
  String? get selectedTimeText => _selectedTimeText;
  bool get saving => _saving;
  int get expandedBookingSection => _expandedBookingSection;

  bool get hasRequiredSelection {
    return _selectedServiceId != null &&
        _selectedStaffId != null &&
        _selectedDateText != null &&
        _selectedTimeText != null;
  }

  bool selectedStaffCanProvideService(String serviceId) {
    if (_selectedStaffId == null) return true;
    return BusinessProfileBookingPolicy.staffCanProvideService(
      serviceId: serviceId,
      staffServiceIds: _selectedStaffServiceIds,
    );
  }

  void toggleSection(int section) {
    _expandedBookingSection = _expandedBookingSection == section ? -1 : section;
    notifyListeners();
  }

  void selectService({
    required String id,
    required String name,
    required int durationMinutes,
  }) {
    _selectedServiceId = id;
    _selectedServiceName = name;
    _selectedServiceDurationMinutes = durationMinutes;

    if (!selectedStaffCanProvideService(id)) {
      _clearStaff();
    }

    _expandedBookingSection = _selectedStaffId == null ? 1 : 2;
    notifyListeners();
  }

  void selectStaff({
    required String id,
    required String name,
    required String uid,
    required String email,
    required List<String> serviceIds,
  }) {
    _selectedStaffId = id;
    _selectedStaffName = name;
    _selectedStaffUid = uid;
    _selectedStaffEmail = email;
    _selectedStaffServiceIds = List.unmodifiable(serviceIds);

    if (_selectedServiceId != null &&
        !BusinessProfileBookingPolicy.staffCanProvideService(
          serviceId: _selectedServiceId!,
          staffServiceIds: _selectedStaffServiceIds,
        )) {
      _clearService();
    }

    _expandedBookingSection = _selectedServiceId == null ? 0 : 2;
    notifyListeners();
  }

  void selectDate(String value) {
    _selectedDateText = value;
    _expandedBookingSection = 3;
    notifyListeners();
  }

  void selectTime(String value) {
    _selectedTimeText = value;
    _expandedBookingSection = -1;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    _saving = value;
    notifyListeners();
  }

  void resetAfterBooking() {
    _clearService();
    _clearStaff();
    _selectedDateText = null;
    _selectedTimeText = null;
    _expandedBookingSection = 0;
    notifyListeners();
  }

  void _clearService() {
    _selectedServiceId = null;
    _selectedServiceName = null;
    _selectedServiceDurationMinutes = 30;
  }

  void _clearStaff() {
    _selectedStaffId = null;
    _selectedStaffName = null;
    _selectedStaffUid = null;
    _selectedStaffEmail = null;
    _selectedStaffServiceIds = const <String>[];
  }
}
