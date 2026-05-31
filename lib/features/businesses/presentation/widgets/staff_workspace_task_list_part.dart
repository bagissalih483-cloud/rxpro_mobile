part of '../../staff_workspace_page.dart';

extension _StaffWorkspacePageStateTaskList on _StaffWorkspacePageState {
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
      case _StaffTaskTab.inProgress:
        emptyText =
            'Başlayan iş kaydı yok. İşleme alınan randevular burada takip edilecek.';
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
            readOnly:
                tab == _StaffTaskTab.completed ||
                tab == _StaffTaskTab.cancelled,
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
}
