part of 'business_appointment_management_page.dart';

extension _BusinessAppointmentManagementData on BusinessAppointmentManagementPage {
  Stream<QuerySnapshot<Map<String, dynamic>>> _appointments() {
    return BusinessAppointmentManagementPage._appointmentRepository.watchAppointments(businessId: businessId);
  }

  String _clean(dynamic value) => value?.toString().trim() ?? '';

  String _statusOf(Map<String, dynamic> data) {
    return _clean(
      data['status'] ??
          data['appointmentStatus'] ??
          data['state'] ??
          data['bookingStatus'],
    ).toLowerCase();
  }

  String _field(
    Map<String, dynamic> data,
    List<String> keys, [
    String fallback = '-',
  ]) {
    for (final key in keys) {
      final value = _clean(data[key]);
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  bool _isCancelled(Map<String, dynamic> data) {
    final s = _statusOf(data);
    final approval = _clean(
      data['customerApprovalStatus'] ?? data['postponeRequestStatus'],
    ).toLowerCase();

    return s.contains('cancel') ||
        s.contains('iptal') ||
        s == 'postpone_rejected' ||
        s == 'reschedule_rejected' ||
        approval == 'rejected' ||
        approval == 'declined' ||
        data['isCancelled'] == true;
  }

  bool _isCompleted(Map<String, dynamic> data) {
    final s = _statusOf(data);

    return s == 'completed' ||
        s == 'done' ||
        s == 'finished' ||
        s == 'tamamlandı' ||
        s == 'tamamlandı' ||
        s == 'sonuçlandı' ||
        s == 'sonuçlandı' ||
        s == 'resulted' ||
        data['isCompleted'] == true ||
        data['completed'] == true;
  }

  bool _hasPostpone(Map<String, dynamic> data) {
    final s = _statusOf(data);
    final approval = _clean(
      data['customerApprovalStatus'] ?? data['postponeRequestStatus'],
    ).toLowerCase();

    return s == 'postpone_requested' ||
        s == 'reschedule_requested' ||
        approval == 'pending';
  }

  bool _isCurrent(Map<String, dynamic> data) {
    if (_isCancelled(data) || _isCompleted(data) || _hasPostpone(data)) {
      return false;
    }
    return true;
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _dateText(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    return '$d.$m.$y';
  }

  String _timeText(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ignore: unused_element
  bool _sameAppointmentSlot(
    Map<String, dynamic> data,
    String dateKey,
    String visibleDate,
    String time,
  ) {
    final d1 = _clean(data['appointmentDate']);
    final d2 = _clean(data['dateText']);
    final d3 = _clean(data['dateKey']);
    final d4 = _clean(data['postponeRequestedDateKey']);
    final t1 = _clean(data['appointmentTime']);
    final t2 = _clean(data['timeText']);
    final t3 = _clean(data['postponeRequestedTimeText']);

    final sameDate =
        d1 == dateKey ||
        d1 == visibleDate ||
        d2 == dateKey ||
        d2 == visibleDate ||
        d3 == dateKey ||
        d4 == dateKey;

    final sameTime = t1 == time || t2 == time || t3 == time;

    return sameDate && sameTime;
  }

  // ignore: unused_element
  bool _blocksSlot(Map<String, dynamic> data) {
    if (_isCancelled(data) || _isCompleted(data)) return false;

    final s = _statusOf(data);
    if (s == 'postpone_requested' ||
        s == 'reschedule_requested' ||
        s == 'cancel_requested') {
      return false;
    }

    return true;
  }

  Future<bool> _slotHasConflict({
    required String currentAppointmentId,
    required String dateKey,
    required String visibleDate,
    required String time,
  }) async {
    return BusinessAppointmentManagementPage._appointmentRepository.slotHasConflict(
      businessId: businessId,
      currentAppointmentId: currentAppointmentId,
      dateKey: dateKey,
      visibleDate: visibleDate,
      time: time,
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String tab,
  ) {
    DateTime sortDateOf(Map<String, dynamic> data) {
      final raw =
          data['startAt'] ??
          data['appointmentStartAt'] ??
          data['startAtIso'] ??
          data['appointmentDateTime'] ??
          data['dateTime'];

      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;

      final rawText = raw?.toString().trim() ?? '';
      final parsedRaw = DateTime.tryParse(rawText);
      if (parsedRaw != null) return parsedRaw;

      final dateText = _clean(
        data['dateText'] ??
            data['appointmentDate'] ??
            data['date'] ??
            data['dayText'],
      );

      final timeText = _clean(
        data['timeText'] ??
            data['appointmentTime'] ??
            data['time'] ??
            data['hourText'],
      );

      final direct = DateTime.tryParse('$dateText $timeText');
      if (direct != null) return direct;

      final dateParts = dateText.split(RegExp(r'[./-]'));

      int? day;
      int? month;
      int? year;

      if (dateParts.length >= 3) {
        final a = int.tryParse(dateParts[0]);
        final b = int.tryParse(dateParts[1]);
        final c = int.tryParse(dateParts[2]);

        if (a != null && b != null && c != null) {
          if (a > 1900) {
            year = a;
            month = b;
            day = c;
          } else {
            day = a;
            month = b;
            year = c;
          }
        }
      }

      final timeParts = timeText.split(':');
      final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
      final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

      if (day != null && month != null && year != null && year > 1900) {
        return DateTime(year, month, day, hour, minute);
      }

      return DateTime(2999, 12, 31);
    }

    final result = docs.where((doc) {
      final data = doc.data();

      if (tab == 'cancelled') return _isCancelled(data);
      if (tab == 'postponed') return _hasPostpone(data);

      return _isCurrent(data);
    }).toList();

    result.sort((a, b) {
      final aa = sortDateOf(a.data());
      final bb = sortDateOf(b.data());
      return bb.compareTo(aa);
    });

    return result;
  }
}
