class AppointmentBookingRequest {
  const AppointmentBookingRequest({
    required this.businessId,
    required this.businessName,
    required this.category,
    required this.serviceId,
    required this.serviceName,
    required this.businessStaffId,
    required this.staffName,
    required this.dateText,
    required this.timeText,
    this.staffUid = '',
    this.staffEmail = '',
    this.staffServiceIdsAtBooking = const <String>[],
    this.durationMinutes = 30,
  });

  final String businessId;
  final String businessName;
  final String category;

  final String serviceId;
  final String serviceName;

  /// Ana operasyonel personel anahtarıdır.
  /// businessStaff koleksiyonundaki doküman ID'sini ifade eder.
  final String businessStaffId;

  final String staffName;
  final String staffUid;
  final String staffEmail;
  final List<String> staffServiceIdsAtBooking;
  final int durationMinutes;

  final String dateText;
  final String timeText;

  bool get hasRequiredSelection =>
      businessId.trim().isNotEmpty &&
      serviceId.trim().isNotEmpty &&
      businessStaffId.trim().isNotEmpty &&
      dateText.trim().isNotEmpty &&
      timeText.trim().isNotEmpty;

  int get normalizedDurationMinutes {
    if (durationMinutes < 5) return 30;
    if (durationMinutes > 480) return 480;
    return durationMinutes;
  }
}
