class AppointmentSlotLockPolicy {
  const AppointmentSlotLockPolicy._();

  static List<String> slotIdsForRange({
    required String businessId,
    required String businessStaffId,
    required DateTime startAt,
    required DateTime endAt,
  }) {
    final ids = <String>[];
    var cursor = DateTime(
      startAt.year,
      startAt.month,
      startAt.day,
      startAt.hour,
      startAt.minute - (startAt.minute % 5),
    );
    final safeEnd = endAt.isAfter(startAt)
        ? endAt
        : startAt.add(const Duration(minutes: 30));

    while (cursor.isBefore(safeEnd)) {
      ids.add(slotId(
        businessId: businessId,
        businessStaffId: businessStaffId,
        time: cursor,
      ));
      cursor = cursor.add(const Duration(minutes: 5));
    }

    return ids;
  }

  static String slotId({
    required String businessId,
    required String businessStaffId,
    required DateTime time,
  }) {
    final date =
        '${time.year.toString().padLeft(4, '0')}'
        '${time.month.toString().padLeft(2, '0')}'
        '${time.day.toString().padLeft(2, '0')}';
    final clock =
        '${time.hour.toString().padLeft(2, '0')}'
        '${time.minute.toString().padLeft(2, '0')}';
    return [
      _safeDocPart(businessId),
      _safeDocPart(businessStaffId),
      date,
      clock,
    ].join('_');
  }

  static String _safeDocPart(String value) =>
      value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}
