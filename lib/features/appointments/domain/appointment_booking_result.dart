class AppointmentBookingResult {
  const AppointmentBookingResult({
    required this.success,
    required this.message,
    this.appointmentId = '',
    this.serviceName = '',
    this.staffName = '',
    this.dateText = '',
    this.timeText = '',
  });

  final bool success;
  final String message;
  final String appointmentId;

  final String serviceName;
  final String staffName;
  final String dateText;
  final String timeText;

  factory AppointmentBookingResult.success({
    required String appointmentId,
    required String serviceName,
    required String staffName,
    required String dateText,
    required String timeText,
  }) {
    return AppointmentBookingResult(
      success: true,
      message: 'Randevu başarıyla oluşturuldu.',
      appointmentId: appointmentId,
      serviceName: serviceName,
      staffName: staffName,
      dateText: dateText,
      timeText: timeText,
    );
  }

  factory AppointmentBookingResult.failure(String message) {
    return AppointmentBookingResult(success: false, message: message);
  }
}
