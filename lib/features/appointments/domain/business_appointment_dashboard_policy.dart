import 'dart:math' as math;

import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

class BusinessAppointmentDashboardStaffOption {
  const BusinessAppointmentDashboardStaffOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class BusinessAppointmentDashboardPolicy {
  const BusinessAppointmentDashboardPolicy._();

  static const _documentIdField = '__docId';

  static int openingHour(Map<String, dynamic> businessData) {
    final raw = businessData[FirestoreFields.openingHour];
    if (raw is num) return raw.toInt().clamp(0, 23);
    return 9;
  }

  static int closingHour(Map<String, dynamic> businessData) {
    final raw = businessData[FirestoreFields.closingHour];
    if (raw is num) return raw.toInt().clamp(1, 24);
    return 20;
  }

  static int slotMinutes(Map<String, dynamic> businessData) {
    final raw = businessData[FirestoreFields.slotMinutes];
    if (raw is num) return raw.toInt().clamp(15, 120);
    return 30;
  }

  static DateTime dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime? dateOf(Map<String, dynamic> data) {
    final startAt = data[FirestoreFields.startAt];
    if (startAt is DateTime) return startAt;

    final iso =
        (data[FirestoreFields.startAtIso] ??
                data[FirestoreFields.appointmentDateIso] ??
                '')
            .toString();
    if (iso.isNotEmpty) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) return parsed;
    }

    final dateText =
        (data[FirestoreFields.appointmentDate] ??
                data[FirestoreFields.dateText] ??
                '')
            .toString();
    final timeText =
        (data[FirestoreFields.appointmentTime] ??
                data[FirestoreFields.timeText] ??
                '09:00')
            .toString();
    final parsedDate = parseTrDate(dateText);
    if (parsedDate == null) return null;

    final parts = timeText.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 9;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

    return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, h, m);
  }

  static DateTime? parseTrDate(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    final iso = DateTime.tryParse(clean);
    if (iso != null) return iso;

    final match = RegExp(
      r'(\d{1,2})[./-](\d{1,2})[./-](\d{4})',
    ).firstMatch(clean);
    if (match == null) return null;

    final d = int.tryParse(match.group(1) ?? '');
    final m = int.tryParse(match.group(2) ?? '');
    final y = int.tryParse(match.group(3) ?? '');
    if (d == null || m == null || y == null) return null;

    return DateTime(y, m, d);
  }

  static String clean(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static bool isCancelledOrPassive(Map<String, dynamic> data) {
    final status = clean(
      data[FirestoreFields.status] ??
          data[FirestoreFields.appointmentStatus] ??
          data[FirestoreFields.state] ??
          data[FirestoreFields.bookingStatus],
    ).toLowerCase();

    return data[FirestoreFields.isCancelled] == true ||
        status.contains('cancel') ||
        status.contains('iptal') ||
        status.contains('passive') ||
        status.contains('pasif');
  }

  static String staffIdOf(Map<String, dynamic> data) {
    return clean(
      data[FirestoreFields.staffId] ??
          data[FirestoreFields.staffUid] ??
          data[FirestoreFields.employeeId] ??
          data[FirestoreFields.personnelId],
    );
  }

  static String staffNameOf(Map<String, dynamic> data) {
    return clean(
      data[FirestoreFields.staffName] ??
          data[FirestoreFields.employeeName] ??
          data[FirestoreFields.personnelName] ??
          data[FirestoreFields.workerName] ??
          'Personel',
    );
  }

  static String customerNameOf(Map<String, dynamic> data) {
    return clean(
      data[FirestoreFields.customerName] ??
          data[FirestoreFields.clientName] ??
          data[FirestoreFields.userName] ??
          data[FirestoreFields.name] ??
          'Müşteri',
    );
  }

  static String serviceNameOf(Map<String, dynamic> data) {
    return clean(
      data[FirestoreFields.serviceName] ??
          data[FirestoreFields.service] ??
          'Randevu',
    );
  }

  static String timeText(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String dateTitle(DateTime value) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  static List<Map<String, dynamic>> activeAppointmentsForMonth({
    required Iterable<Map<String, dynamic>> appointments,
    required DateTime visibleMonth,
  }) {
    return appointments
        .where((data) {
          if (isCancelledOrPassive(data)) return false;
          final dt = dateOf(data);
          return dt != null &&
              dt.year == visibleMonth.year &&
              dt.month == visibleMonth.month;
        })
        .toList(growable: false);
  }

  static List<BusinessAppointmentDashboardStaffOption> staffOptions({
    required Iterable<Map<String, dynamic>> staffRows,
    required Iterable<Map<String, dynamic>> appointments,
  }) {
    final staff = <BusinessAppointmentDashboardStaffOption>[];
    final seen = <String>{};

    void addStaff(String id, String name) {
      final cleanId = clean(id);
      final cleanName = clean(name);
      if (cleanId.isEmpty && cleanName.isEmpty) return;
      final key = cleanId.isEmpty ? cleanName : cleanId;
      if (!seen.add(key)) return;

      staff.add(
        BusinessAppointmentDashboardStaffOption(
          id: cleanId.isEmpty ? cleanName : cleanId,
          name: cleanName.isEmpty ? 'Personel' : cleanName,
        ),
      );
    }

    for (final data in staffRows) {
      addStaff(
        clean(
          data[FirestoreFields.staffId] ??
              data[FirestoreFields.staffUid] ??
              data[_documentIdField],
        ),
        clean(
          data[FirestoreFields.staffName] ??
              data[FirestoreFields.name] ??
              data[FirestoreFields.displayName] ??
              data[FirestoreFields.fullName] ??
              'Personel',
        ),
      );
    }

    if (staff.isEmpty) {
      for (final data in appointments) {
        addStaff(staffIdOf(data), staffNameOf(data));
      }
    }

    if (!seen.contains('default')) {
      staff.add(
        const BusinessAppointmentDashboardStaffOption(
          id: 'default',
          name: 'Yönetim / Manuel',
        ),
      );
    }

    return List.unmodifiable(staff);
  }

  static int capacityForDay({
    required int openingHour,
    required int closingHour,
    required int slotMinutes,
    required int staffCount,
  }) {
    final perStaff = (((closingHour - openingHour) * 60) / slotMinutes).floor();
    return math.max(1, perStaff * math.max(1, staffCount));
  }
}
