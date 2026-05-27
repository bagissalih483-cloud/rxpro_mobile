part of '../../staff_workspace_page.dart';

extension _StaffWorkspacePageStateActions on _StaffWorkspacePageState {
  Future<void> _writeActivityLog({
    required String type,
    required String title,
    required String description,
    String? appointmentId,
    String? expenseId,
    Map<String, dynamic>? extra,
  }) async {
    await _workspaceRepository.writeActivityLog(
      businessId: _businessId,
      staffId: _staffId,
      staffName: _staffName,
      type: type,
      title: title,
      description: description,
      appointmentId: appointmentId,
      expenseId: expenseId,
      extra: extra,
    );
  }

  Future<void> _markAppointment(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool complete,
  }) async {
    final userUid = _currentUid;
    if (userUid.isEmpty) return;

    final data = doc.data();

    final canCompleteAny = _isPrivilegedTaskViewer();
    final canCompleteAssigned = _can('completeAssignedAppointments');

    final assignedToMe = _matchesAssignedStaff(data);
    if (!canCompleteAny && !(canCompleteAssigned && assignedToMe)) {
      _show('Bu randevuyu tamamlama yetkin yok.');
      return;
    }
    if (complete &&
        !TaskStatusFilter.canComplete(data[FirestoreFields.status])) {
      _show('Bu randevu tamamlanmaya uygun durumda değil.');
      return;
    }

    if (!complete && !TaskStatusFilter.canStart(data[FirestoreFields.status])) {
      _show('Bu randevu başlatılmaya uygun durumda değil.');
      return;
    }
    if (complete) {
      final completedAtLocal = DateTime.now();
      final workDurationMinutes = _calculateWorkDurationMinutes(
        data,
        completedAtLocal,
      );

      await _workspaceRepository.completeAppointment(
        appointmentId: doc.id,
        staffId: _staffId,
        staffName: _staffName,
        hasStarted:
            data[FirestoreFields.startedAt] != null ||
            data[FirestoreFields.workStartedAtLocalIso] != null,
        completedAtLocal: completedAtLocal,
        workDurationMinutes: workDurationMinutes,
      );
      await FinanceRecordService().createIncomeFromCompletedAppointment(
        appointmentId: doc.id,
        appointmentData: {
          ...data,
          FirestoreFields.status: 'completed',
          FirestoreFields.appointmentStatus: 'completed',
          FirestoreFields.state: 'completed',
          'completedAt': completedAtLocal,
          FirestoreFields.workCompletedAtLocalIso: completedAtLocal
              .toIso8601String(),
        },
        businessId: _businessId,
        actorUid: userUid,
        actorName: _staffName,
        staffId: _staffId,
        staffName: _staffName,
      );
      await _writeActivityLog(
        type: 'appointment_completed_by_staff',
        title: 'İşlem tamamlandı',
        description: _appointmentTitle(data),
        appointmentId: doc.id,
        extra: {
          FirestoreFields.status: 'completed',
          FirestoreFields.time: _appointmentTime(data),
        },
      );

      _show('İşlem tamamlandı olarak işaretlendi.');
    } else {
      await _workspaceRepository.startAppointment(
        appointmentId: doc.id,
        staffId: _staffId,
        staffName: _staffName,
      );

      await _writeActivityLog(
        type: 'appointment_started_by_staff',
        title: 'İşlem başlatıldı',
        description: _appointmentTitle(data),
        appointmentId: doc.id,
        extra: {
          'status': 'inProgress',
          FirestoreFields.time: _appointmentTime(data),
        },
      );

      _show('İşlem başlatıldı.');
    }
  }

  Future<void> _createOverdueReminder(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    if (!_isOverdueAppointment(data)) {
      _show('Bu randevu için süre aşımı uyarısı gerekmiyor.');
      return;
    }

    await _workspaceRepository.createOverdueReminder(
      appointmentId: doc.id,
      businessId: _businessId,
      staffName: _staffName,
      appointmentTitle: _appointmentTitle(data),
      status: _statusValue(data),
      time: _appointmentTime(data),
    );
    await _writeActivityLog(
      type: 'appointment_overdue_warning_created',
      title: 'Sonuçlanmamış randevu uyarısı',
      description: _appointmentTitle(data),
      appointmentId: doc.id,
      extra: {
        FirestoreFields.status: _statusValue(data),
        FirestoreFields.time: _appointmentTime(data),
      },
    );

    _show('Sonuçlanmamış randevu uyarısı oluşturuldu.');
  }

  Future<void> _cancelAppointmentNoShow(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final userUid = _currentUid;
    if (userUid.isEmpty) return;

    final data = doc.data();

    final canCancel =
        _can('cancelAppointments') ||
        _can('updateAppointments') ||
        _can('completeAnyAppointments');

    if (!canCancel) {
      _show('Bu randevuyu iptal/gelmedi olarak işaretleme yetkin yok.');
      return;
    }
    if (!_isPrivilegedTaskViewer() && !_matchesAssignedStaff(data)) {
      _show(
        'Sadece sana atanmış randevuyu iptal/gelmedi olarak işaretleyebilirsin.',
      );
      return;
    }
    if (!_isOverdueAppointment(data)) {
      _show(
        'İptal/gelmedi işlemi için randevu saatinin geçmiş olması gerekir.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Randevu iptal / gelmedi'),
          content: Text(
            '${_appointmentTitle(data)} kaydı iptal/gelmedi olarak işaretlensin mi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('İptal / gelmedi'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _workspaceRepository.cancelAppointmentNoShow(
      appointmentId: doc.id,
      businessId: _businessId,
      staffId: _staffId,
      staffName: _staffName,
      appointmentTitle: _appointmentTitle(data),
      time: _appointmentTime(data),
    );

    await _writeActivityLog(
      type: 'appointment_cancelled_no_show_by_staff',
      title: 'Randevu iptal / gelmedi',
      description: _appointmentTitle(data),
      appointmentId: doc.id,
      extra: {
        FirestoreFields.status: 'noShow',
        'reason': 'no_show_or_late_cancel_after_appointment_time',
        FirestoreFields.time: _appointmentTime(data),
      },
    );

    _show('Randevu iptal/gelmedi olarak işaretlendi.');
  }

  Widget _buildTaskList({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required _StaffTaskTab tab,
  }) {
    String emptyText;
    switch (tab) {
      case _StaffTaskTab.queue:
        emptyText =
            'İş kuyruğunda sonuçlanmamış randevu yok. Yeni veya devam eden işler burada görünecek.';
        break;
      case _StaffTaskTab.completed:
        emptyText =
            'Tamamlanan iş kaydı yok. Personel işi bitirdiğinde kayıt burada listelenecek.';
        break;
      case _StaffTaskTab.cancelled:
        emptyText =
            'İptal/gelmedi kaydı yok. Süresi geçen ve iptal edilen kayıtlar burada tutulacak.';
        break;
    }

    if (docs.isEmpty) {
      return _InfoBox(text: emptyText);
    }

    return SizedBox(
      height: 440,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          final data = doc.data();
          final overdue = _isOverdueAppointment(data);

          return _AppointmentWorkTile(
            title: _appointmentTitle(data),
            time: _appointmentTime(data),
            status: _statusValue(data),
            statusLabel: _statusLabel(data),
            isOverdue: overdue,
            readOnly: tab != _StaffTaskTab.queue,
            onStart: () => _markAppointment(doc, complete: false),
            onComplete: () => _markAppointment(doc, complete: true),
            onCreateReminder: overdue
                ? () => _createOverdueReminder(doc)
                : null,
            onCancelNoShow: overdue
                ? () => _cancelAppointmentNoShow(doc)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _openExpenseSheet() async {
    if (!_can('enterExpenses')) {
      _show('Masraf girme yetkin yok.');
      return;
    }

    final title = TextEditingController();
    final amount = TextEditingController();
    final note = TextEditingController();

    String category = 'Malzeme';
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> save() async {
              final userUid = _currentUid;
              if (userUid.isEmpty) return;

              final titleText = title.text.trim();
              final amountValue =
                  double.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;

              if (titleText.isEmpty || amountValue <= 0) {
                _show('Masraf adı ve tutarı zorunlu.');
                return;
              }

              if (!_can('enterExpenses')) {
                _show('Gider / masraf islemleri icin yetkin yok.');
                return;
              }

              if (!_StaffWorkspacePageState._staffExpenseLiveWriteEnabled) {
                _show(
                  'Masraf kaydi su an guvenli modda kapali. Muhasebe canli yazma acilinca etkinlesecek.',
                );
                return;
              }

              setSheetState(() => saving = true);

              try {
                final expenseId = await _workspaceRepository.createExpense(
                  businessId: _businessId,
                  staffId: _staffId,
                  createdByName:
                      (widget.memberData[FirestoreFields.staffName] ??
                              _currentEmail)
                          .toString(),
                  title: titleText,
                  category: category,
                  amount: amountValue,
                  note: note.text.trim(),
                );

                await _writeActivityLog(
                  type: 'expense_created_by_staff',
                  title: 'Masraf girildi',
                  description:
                      '$titleText - ${amountValue.toStringAsFixed(2)} TL',
                  expenseId: expenseId,
                  extra: {
                    FirestoreFields.category: category,
                    FirestoreFields.amount: amountValue,
                  },
                );

                if (!context.mounted) return;
                Navigator.pop(context);
                _show('Masraf kaydı eklendi.');
              } finally {
                if (context.mounted) {
                  setSheetState(() => saving = false);
                }
              }
            }

            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Masraf Gir',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bu kayıt kurumsal kullanıcının finans ve masraf analizinde kullanılacak.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Masraf adı *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              const [
                                    'Malzeme',
                                    'Kira',
                                    'Personel',
                                    'Reklam',
                                    'Elektrik / Su',
                                    'Komisyon',
                                    'Bakım / Onarım',
                                    'Diğer',
                                  ]
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() => category = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Tutar *',
                            suffixText: 'TL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Not',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Kaydediliyor...' : 'Masrafı Kaydet'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    title.dispose();
    amount.dispose();
    note.dispose();
  }

  void _show(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
