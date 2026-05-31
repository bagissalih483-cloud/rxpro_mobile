part of 'business_appointment_management_page.dart';

class _PostponeDraft {
  const _PostponeDraft({
    required this.date,
    required this.time,
    required this.note,
  });

  final DateTime date;
  final TimeOfDay time;
  final String note;
}
