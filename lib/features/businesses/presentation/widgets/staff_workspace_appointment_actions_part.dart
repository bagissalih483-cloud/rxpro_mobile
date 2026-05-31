part of '../../staff_workspace_page.dart';

extension _StaffWorkspacePageStateAppointmentActions on _StaffWorkspacePageState {
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
      var adisyonResult = const AppointmentAdisyonResult.skipped();
      try {
        adisyonResult = await AppointmentAdisyonService()
            .ensurePendingAdisyonForAppointment(
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
      } catch (_) {
        _show(
          'Randevu tamamlandı. Bekleyen adisyon oluşturulamadı; muhasebeden manuel açabilirsiniz.',
        );
      }
      await _writeActivityLog(
        type: 'appointment_completed_by_staff',
        title: 'İşlem tamamlandı',
        description: _appointmentTitle(data),
        appointmentId: doc.id,
        extra: {
          FirestoreFields.status: 'completed',
          FirestoreFields.time: _appointmentTime(data),
          'adisyonSaleId': adisyonResult.saleId,
          'adisyonCreated': adisyonResult.created,
        },
      );

      _show('İşlem tamamlandı olarak işaretlendi.');
      if (mounted) {
        await _showAdisyonBridgeSuggestion(data);
      }
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

  Future<void> _showAdisyonBridgeSuggestion(Map<String, dynamic> data) async {
    await showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 520,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Adisyon oluştur',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${_appointmentTitle(data)} tamamlandı. İstersen müşteri, hizmet, personel ve fiyat bilgisini kontrol etmek için Muhasebe sekmesine geçebilirsin.',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Saat: ${_appointmentTime(data)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Sonra'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          FixShellNavState.setCorporateIndex(2);
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          );
                        },
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        label: const Text('Muhasebeye git'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
