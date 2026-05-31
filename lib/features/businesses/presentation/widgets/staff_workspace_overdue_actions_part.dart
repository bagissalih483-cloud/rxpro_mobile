part of '../../staff_workspace_page.dart';

extension _StaffWorkspacePageStateOverdueActions on _StaffWorkspacePageState {
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
}
