import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/businesses/data/business_appointment_management_repository.dart';
import 'package:rxpro_mobile/features/businesses/presentation/widgets/business_appointment_management_widgets.dart';

/// Business appointment management keeps database writes behind repositories.
class BusinessAppointmentManagementPage extends StatelessWidget {
  const BusinessAppointmentManagementPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  static final BusinessAppointmentManagementRepository _appointmentRepository =
      BusinessAppointmentManagementRepository();

  Stream<QuerySnapshot<Map<String, dynamic>>> _appointments() {
    return _appointmentRepository.watchAppointments(businessId: businessId);
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
        s == 'tamamlandi' ||
        s == 'tamamlandı' ||
        s == 'sonuclandi' ||
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
    return _appointmentRepository.slotHasConflict(
      businessId: businessId,
      currentAppointmentId: currentAppointmentId,
      dateKey: dateKey,
      visibleDate: visibleDate,
      time: time,
    );
  }

  // ignore: unused_element
  Future<void> _notifyCustomer({
    required Map<String, dynamic> appointment,
    required String title,
    required String body,
    required String type,
    String? appointmentId,
  }) async {
    await _appointmentRepository.notifyCustomer(
      appointment: appointment,
      appointmentId: appointmentId,
      businessId: businessId,
      businessName: businessName,
      type: type,
      title: title,
      body: body,
    );
  }

  Future<String?> _askReason(BuildContext context) async {
    String reason = '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('İptal gerekçesi'),
              content: TextField(
                key: const ValueKey('business-cancel-reason-field'),
                maxLines: 4,
                onChanged: (value) {
                  reason = value.trim();
                  setDialogState(() {});
                },
                decoration: const InputDecoration(
                  hintText:
                      'Bireysel kullanıcıya iletilecek iptal gerekçesini yazın.',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: reason.trim().isEmpty
                      ? null
                      : () => Navigator.of(dialogContext).pop(reason.trim()),
                  child: const Text('İptal Et'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_PostponeDraft?> _askPostpone(BuildContext context) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String note = '';

    return showDialog<_PostponeDraft>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dateLabel = selectedDate == null
                ? 'Tarih seç'
                : _dateText(selectedDate!);
            final timeLabel = selectedTime == null
                ? 'Saat seç'
                : _timeText(selectedTime!);

            final canSubmit =
                selectedDate != null &&
                selectedTime != null &&
                note.trim().isNotEmpty;

            return AlertDialog(
              title: const Text('Erteleme talebi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate:
                              selectedDate ??
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );

                        if (picked == null) return;
                        setDialogState(() => selectedDate = picked);
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(dateLabel),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );

                        if (picked == null) return;
                        setDialogState(() => selectedTime = picked);
                      },
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(timeLabel),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('business-postpone-note-field'),
                      maxLines: 3,
                      onChanged: (value) {
                        note = value.trim();
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText:
                            'Bireysel kullanıcıya iletilecek erteleme notu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: !canSubmit
                      ? null
                      : () => Navigator.of(dialogContext).pop(
                          _PostponeDraft(
                            date: selectedDate!,
                            time: selectedTime!,
                            note: note.trim(),
                          ),
                        ),
                  child: const Text('Talep Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cancelAppointment(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final reason = await _askReason(context);
    if (reason == null || reason.trim().isEmpty) return;

    final data = doc.data();

    await _appointmentRepository.cancelAppointment(
      appointmentId: doc.id,
      appointment: data,
      businessId: businessId,
      businessName: businessName,
      reason: reason,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Randevu iptal edildi ve bireysel kullanıcıya bildirim kaydı oluşturuldu.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _requestPostpone(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final payload = await _askPostpone(context);
    if (payload == null) return;

    final data = doc.data();
    final newDateKey = _dateKey(payload.date);
    final newDateText = _dateText(payload.date);
    final newTimeText = _timeText(payload.time);
    final newStartAt = _combine(payload.date, payload.time);

    final conflict = await _slotHasConflict(
      currentAppointmentId: doc.id,
      dateKey: newDateKey,
      visibleDate: newDateText,
      time: newTimeText,
    );

    if (conflict) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seçilen tarih ve saatte mevcut bir randevu var. Başka zaman seçin.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _appointmentRepository.requestPostpone(
      appointmentId: doc.id,
      appointment: data,
      businessId: businessId,
      businessName: businessName,
      request: BusinessAppointmentPostponeRequest(
        dateKey: newDateKey,
        dateText: newDateText,
        timeText: newTimeText,
        startAt: newStartAt,
        note: payload.note,
      ),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Erteleme talebi bireysel kullanıcının onayına gönderildi.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
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

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF64748B)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _postponeAppointment(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    return _requestPostpone(context, doc);
  }

  Widget _appointmentCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String tab,
  ) {
    final data = doc.data();

    final customer = _field(data, [
      'customerName',
      'clientName',
      'name',
    ], 'Bireysel Kullanıcı');

    final service = _field(data, ['serviceName', 'title'], 'Hizmet');
    final staff = _field(data, ['staffName', 'employeeName'], '');
    final date = _field(data, ['dateText', 'appointmentDate'], '-');
    final time = _field(data, ['timeText', 'appointmentTime'], '-');

    final cancelReason = _field(data, ['cancellationReason'], '');

    final postponeDate = _field(data, [
      'postponeRequestedDateText',
      'postponedDateText',
    ], '');

    final postponeTime = _field(data, [
      'postponeRequestedTimeText',
      'postponedTimeText',
    ], '');

    final postponeNote = _field(data, [
      'postponeRequestNote',
      'postponedNote',
    ], '');

    final bg = tab == 'postponed'
        ? const Color(0xFFFFF7D6)
        : tab == 'cancelled'
        ? const Color(0xFFFFE4E6)
        : tab == 'completed'
        ? const Color(0xFFDCFCE7)
        : Colors.white;

    final accent = tab == 'postponed'
        ? const Color(0xFFD97706)
        : tab == 'cancelled'
        ? const Color(0xFFDC2626)
        : tab == 'completed'
        ? const Color(0xFF16A34A)
        : const Color(0xFF2563EB);

    return Card(
      elevation: 0,
      color: bg,
      margin: const EdgeInsets.fromLTRB(16, 7, 16, 9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: accent,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => showBusinessCustomerQuickProfile(
                      context: context,
                      businessId: businessId,
                      businessName: businessName,
                      data: data,
                      customerName: customer,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        customer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                if (tab == 'completed')
                  const BusinessAppointmentStatusPill(
                    text: 'Sonuçlandı',
                    color: Color(0xFF16A34A),
                  )
                else if (tab == 'cancelled')
                  const BusinessAppointmentStatusPill(
                    text: 'İptal',
                    color: Color(0xFFDC2626),
                  )
                else if (tab == 'postponed')
                  const BusinessAppointmentStatusPill(
                    text: 'Bekliyor',
                    color: Color(0xFFD97706),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              service,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$date • $time',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (staff.isNotEmpty && staff != '-') ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    size: 15,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Personel: $staff',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (tab == 'postponed' &&
                postponeDate.isNotEmpty &&
                postponeDate != '-') ...[
              const SizedBox(height: 7),
              Text(
                'Erteleme talebi: $postponeDate ${postponeTime == '-' ? '' : postponeTime}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF92400E),
                  fontSize: 12,
                ),
              ),
              if (postponeNote.isNotEmpty && postponeNote != '-') ...[
                const SizedBox(height: 2),
                Text(
                  'Not: $postponeNote',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
            if (tab == 'cancelled' &&
                cancelReason.isNotEmpty &&
                cancelReason != '-') ...[
              const SizedBox(height: 7),
              Text(
                'İptal gerekçesi: $cancelReason',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF991B1B),
                  fontSize: 12,
                ),
              ),
            ],
            if (tab == 'current') ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    SizedBox(
                      height: 32,
                      child: OutlinedButton.icon(
                        onPressed: () => _postponeAppointment(context, doc),
                        icon: const Icon(Icons.schedule_outlined, size: 15),
                        label: const Text(
                          'Ertele',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(78, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      child: FilledButton.icon(
                        onPressed: () => _cancelAppointment(context, doc),
                        icon: const Icon(Icons.cancel_outlined, size: 15),
                        label: const Text(
                          'İptal',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          minimumSize: const Size(74, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tabBody(String tab) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _appointments(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _empty('Randevular okunamadı: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = _filter(snapshot.data?.docs ?? [], tab);

        if (docs.isEmpty) {
          if (tab == 'cancelled') {
            return _empty('İptal edilen randevu yok.');
          }
          if (tab == 'postponed') {
            return _empty('Bekleyen erteleme talebi yok.');
          }
          return _empty('Mevcut randevu yok.');
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 18),
          itemCount: docs.length,
          itemBuilder: (context, index) =>
              _appointmentCard(context, docs[index], tab),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      key: ValueKey('business-appointments-$businessId'),
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Randevu Yönetimi'),
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Mevcut'),
              Tab(text: 'İptal'),
              Tab(text: 'Erteleme'),
            ],
          ),
        ),
        body: Column(
          children: [
            BusinessAppointmentSummaryCard(
              businessName: businessName,
              stream: _appointments(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _tabBody('current'),
                  _tabBody('cancelled'),
                  _tabBody('postponed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
