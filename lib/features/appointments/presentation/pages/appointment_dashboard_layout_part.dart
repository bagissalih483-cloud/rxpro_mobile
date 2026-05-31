part of 'appointment_entry_page.dart';

class _AppointmentWideSidePanel extends StatelessWidget {
  const _AppointmentWideSidePanel({
    required this.businessName,
    required this.selectedDay,
    required this.appointments,
    required this.staff,
    required this.sameDay,
    required this.dateOf,
    required this.timeText,
    required this.dateTitle,
    required this.customerNameOf,
    required this.serviceNameOf,
    required this.onOpenLiveFlow,
    required this.onCreateAppointment,
  });

  final String businessName;
  final DateTime selectedDay;
  final List<Map<String, dynamic>> appointments;
  final List<AppointmentStaffLite> staff;
  final bool Function(DateTime, DateTime) sameDay;
  final DateTime? Function(Map<String, dynamic>) dateOf;
  final String Function(DateTime) timeText;
  final String Function(DateTime) dateTitle;
  final String Function(Map<String, dynamic>) customerNameOf;
  final String Function(Map<String, dynamic>) serviceNameOf;
  final VoidCallback onOpenLiveFlow;
  final VoidCallback onCreateAppointment;

  @override
  Widget build(BuildContext context) {
    final dayAppointments = appointments
        .where((data) {
          final date = dateOf(data);
          return date != null && sameDay(date, selectedDay);
        })
        .toList()
      ..sort((a, b) {
        final left = dateOf(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = dateOf(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return left.compareTo(right);
      });

    return Container(
      width: 336,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          _AppointmentPanelHeader(
            businessName: businessName,
            selectedDayLabel: dateTitle(selectedDay),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AppointmentPanelMetric(
                  label: 'Randevu',
                  value: '${dayAppointments.length}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AppointmentPanelMetric(
                  label: 'Personel',
                  value: '${staff.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onOpenLiveFlow,
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: const Text('Canlı Akışı Aç'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCreateAppointment,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Manuel Randevu'),
          ),
          const SizedBox(height: 18),
          const Text(
            'Günlük Akış',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          if (dayAppointments.isEmpty)
            const _AppointmentPanelEmpty()
          else
            for (final item in dayAppointments.take(6))
              _AppointmentPanelTile(
                time: _timeLabel(item),
                customer: customerNameOf(item),
                service: serviceNameOf(item),
              ),
        ],
      ),
    );
  }

  String _timeLabel(Map<String, dynamic> data) {
    final date = dateOf(data);
    return date == null ? '--:--' : timeText(date);
  }
}

class _AppointmentPanelHeader extends StatelessWidget {
  const _AppointmentPanelHeader({
    required this.businessName,
    required this.selectedDayLabel,
  });

  final String businessName;
  final String selectedDayLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Randevu Paneli',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              businessName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selectedDayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentPanelMetric extends StatelessWidget {
  const _AppointmentPanelMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEFFBF4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentPanelTile extends StatelessWidget {
  const _AppointmentPanelTile({
    required this.time,
    required this.customer,
    required this.service,
  });

  final String time;
  final String customer;
  final String service;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: const Color(0xFFF8FAFC),
        leading: Text(time, style: const TextStyle(fontWeight: FontWeight.w900)),
        title: Text(
          customer,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          service,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _AppointmentPanelEmpty extends StatelessWidget {
  const _AppointmentPanelEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Text(
        'Seçili gün için randevu yok.',
        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
      ),
    );
  }
}
