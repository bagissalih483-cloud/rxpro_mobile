class BusinessManualAppointmentStaffOption {
  const BusinessManualAppointmentStaffOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class BusinessManualAppointmentPolicy {
  const BusinessManualAppointmentPolicy._();

  static String clean(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static DateTime dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime startAt({
    required DateTime date,
    required int hour,
    required int minute,
  }) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static int durationMinutes(String? value) {
    final parsed = int.tryParse(clean(value));
    if (parsed == null) return 30;
    return parsed.clamp(5, 480).toInt();
  }

  static List<BusinessManualAppointmentStaffOption> staffOptions(
    Iterable<BusinessManualAppointmentStaffOption> staff,
  ) {
    final seen = <String>{};
    final options = <BusinessManualAppointmentStaffOption>[];

    for (final item in staff) {
      final id = clean(item.id).isEmpty ? clean(item.name) : clean(item.id);
      final name = clean(item.name);
      if (id.isEmpty && name.isEmpty) continue;

      final key = id.isEmpty ? name : id;
      if (!seen.add(key)) continue;

      options.add(
        BusinessManualAppointmentStaffOption(
          id: id,
          name: name.isEmpty ? id : name,
        ),
      );
    }

    return List.unmodifiable(options);
  }

  static String initialStaffId({
    required BusinessManualAppointmentStaffOption? initialStaff,
    required Iterable<BusinessManualAppointmentStaffOption> staffOptions,
  }) {
    final initialId = clean(initialStaff?.id);
    final initialName = clean(initialStaff?.name);
    if (initialId.isNotEmpty) return initialId;
    if (initialName.isNotEmpty) return initialName;

    final options = staffOptions.toList(growable: false);
    return options.isEmpty ? '' : options.first.id;
  }

  static BusinessManualAppointmentStaffOption selectedStaff({
    required Iterable<BusinessManualAppointmentStaffOption> staffOptions,
    required String selectedStaffId,
  }) {
    final options = staffOptions.toList(growable: false);
    for (final item in options) {
      if (item.id == selectedStaffId) return item;
    }

    return options.isEmpty
        ? const BusinessManualAppointmentStaffOption(
            id: 'default',
            name: 'Genel',
          )
        : options.first;
  }

  static String dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String dateText(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }

  static String timeText(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String? validateCustomerName(String? value) {
    if (clean(value).length < 2) return 'Müşteri adı gerekli.';
    return null;
  }

  static String? validateServiceName(String? value) {
    if (clean(value).isEmpty) return 'Hizmet adı gerekli.';
    return null;
  }

  static String? validateDuration(String? value) {
    final parsed = int.tryParse(clean(value));
    if (parsed == null || parsed < 5) return 'Geçerli süre girin.';
    return null;
  }
}
