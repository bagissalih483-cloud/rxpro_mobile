part of 'appointment_dashboard_views.dart';

class AppointmentDailyFlowView extends StatelessWidget {
  const AppointmentDailyFlowView({
    super.key,
    required this.selectedDay,
    required this.staff,
    required this.appointments,
    required this.openingHour,
    required this.closingHour,
    required this.slotMinutes,
    required this.sameDay,
    required this.dateOf,
    required this.timeText,
    required this.dateTitle,
    required this.staffIdOf,
    required this.staffNameOf,
    required this.customerNameOf,
    required this.serviceNameOf,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onToday,
    required this.onCreateAppointment,
  });

  final DateTime selectedDay;
  final List<AppointmentStaffLite> staff;
  final List<Map<String, dynamic>> appointments;
  final int openingHour;
  final int closingHour;
  final int slotMinutes;
  final bool Function(DateTime, DateTime) sameDay;
  final DateTime? Function(Map<String, dynamic>) dateOf;
  final String Function(DateTime) timeText;
  final String Function(DateTime) dateTitle;
  final String Function(Map<String, dynamic>) staffIdOf;
  final String Function(Map<String, dynamic>) staffNameOf;
  final String Function(Map<String, dynamic>) customerNameOf;
  final String Function(Map<String, dynamic>) serviceNameOf;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onToday;
  final void Function(DateTime slot, AppointmentStaffLite staff)
  onCreateAppointment;

  @override
  Widget build(BuildContext context) {
    final dayAppointments = appointments.where((data) {
      final dt = dateOf(data);
      return dt != null && sameDay(dt, selectedDay);
    }).toList();

    final start = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      openingHour,
    );

    final end = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      closingHour,
    );

    final slots = <DateTime>[];
    var cursor = start;
    while (cursor.isBefore(end)) {
      slots.add(cursor);
      cursor = cursor.add(Duration(minutes: slotMinutes));
    }

    final now = DateTime.now();
    final isToday = sameDay(now, selectedDay);
    final fullDurationMinutes = end.difference(start).inMinutes;

    final clampedMinutes = !isToday
        ? 0
        : now.isBefore(start)
        ? 0
        : now.isAfter(end)
        ? fullDurationMinutes
        : now.difference(start).inMinutes;

    const timeWidth = 64.0;
    const cellWidth = 150.0;
    const headerHeight = 42.0;
    const rowHeight = 66.0;
    const gridLineWidth = 1.4;

    final gridWidth = timeWidth + (staff.length * cellWidth);
    final gridHeight = headerHeight + (slots.length * rowHeight);

    final redLineTop =
        headerHeight +
        ((clampedMinutes / slotMinutes) * rowHeight).clamp(
          0.0,
          slots.length * rowHeight,
        );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: onPreviousDay,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      dateTitle(selectedDay),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${dayAppointments.length} randevu',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onNextDay,
                icon: const Icon(Icons.chevron_right),
              ),
              TextButton(onPressed: onToday, child: const Text('Bugün')),
            ],
          ),
        ),
        _buildDailyFlowGrid(
          context: context,
          dayAppointments: dayAppointments,
          slots: slots,
          start: start,
          fullDurationMinutes: fullDurationMinutes,
          isToday: isToday,
          redLineTop: redLineTop,
          timeWidth: timeWidth,
          cellWidth: cellWidth,
          headerHeight: headerHeight,
          rowHeight: rowHeight,
          gridLineWidth: gridLineWidth,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
        ),
      ],
    );
  }
}
