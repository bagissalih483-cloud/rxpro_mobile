part of 'business_appointment_management_page.dart';

extension _BusinessAppointmentManagementActions on BusinessAppointmentManagementPage {
  // ignore: unused_element
  Future<void> _notifyCustomer({
    required Map<String, dynamic> appointment,
    required String title,
    required String body,
    required String type,
    String? appointmentId,
  }) async {
    await BusinessAppointmentManagementPage._appointmentRepository.notifyCustomer(
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
              title: const Text('Randevu iptal gerekçesi'),
              content: TextField(
                key: const ValueKey('business-cancel-reason-field'),
                maxLines: 4,
                onChanged: (value) {
                  reason = value.trim();
                  setDialogState(() {});
                },
                decoration: const InputDecoration(
                  hintText:
                      'İşletmeye iletmek istediğiniz not',
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
                            'İşletmeye iletmek istediğiniz not',
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

    await BusinessAppointmentManagementPage._appointmentRepository.cancelAppointment(
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

    await BusinessAppointmentManagementPage._appointmentRepository.requestPostpone(
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

  Future<void> _postponeAppointment(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    return _requestPostpone(context, doc);
  }
}
