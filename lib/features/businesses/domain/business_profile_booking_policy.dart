class BusinessProfileBookingPolicy {
  const BusinessProfileBookingPolicy._();

  static const defaultTimes = <String>[
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
  ];

  static List<String> stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  static List<DateTime> upcomingDays({
    required DateTime now,
    int count = 21,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(count, (index) => today.add(Duration(days: index)));
  }

  static String dateText(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String shortDay(DateTime date) {
    const names = <String>['Pzt', 'Sal', '\u00c7ar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return names[date.weekday - 1];
  }

  static bool staffCanProvideService({
    required String serviceId,
    required List<String> staffServiceIds,
  }) {
    if (staffServiceIds.isEmpty) return true;
    return staffServiceIds.contains(serviceId);
  }

  static int durationMinutes(Object? value, {int fallback = 30}) {
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.round();
    return int.tryParse(value?.toString().trim() ?? '') ?? fallback;
  }
}
