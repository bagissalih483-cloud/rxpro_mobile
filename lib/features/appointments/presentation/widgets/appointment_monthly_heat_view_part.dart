part of 'appointment_dashboard_views.dart';

class AppointmentMonthlyHeatView extends StatelessWidget {
  const AppointmentMonthlyHeatView({
    super.key,
    required this.visibleMonth,
    required this.selectedDay,
    required this.appointments,
    required this.staffCount,
    required this.capacityForDay,
    required this.heatColor,
    required this.dayOnly,
    required this.sameDay,
    required this.dateOf,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDay,
    required this.onCreateAppointment,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final List<Map<String, dynamic>> appointments;
  final int staffCount;
  final int Function(int) capacityForDay;
  final Color Function(double) heatColor;
  final DateTime Function(DateTime) dayOnly;
  final bool Function(DateTime, DateTime) sameDay;
  final DateTime? Function(Map<String, dynamic>) dateOf;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<DateTime> onCreateAppointment;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      visibleMonth.year,
      visibleMonth.month,
    );

    final counts = <DateTime, int>{};

    for (final data in appointments) {
      final dt = dateOf(data);
      if (dt == null) continue;

      if (dt.year != visibleMonth.year || dt.month != visibleMonth.month) {
        continue;
      }

      final key = dayOnly(dt);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final capacity = capacityForDay(staffCount);
    final monthNames = [
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${monthNames[visibleMonth.month - 1]} ${visibleMonth.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Renk yoğunluğu günlük randevu sayısının teorik kapasiteye oranına göre hesaplanır.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          itemCount: daysInMonth,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final day = DateTime(
              visibleMonth.year,
              visibleMonth.month,
              index + 1,
            );
            final count = counts[dayOnly(day)] ?? 0;
            final ratio = count / capacity;
            final selected = sameDay(day, selectedDay);
            final bg = heatColor(ratio);
            final dark = ratio >= 0.75;

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                onSelectDay(day);
                onCreateAppointment(day);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? Colors.black87 : const Color(0xFFE2E8F0),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: dark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: dark ? Colors.white : const Color(0xFF475569),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const AppointmentHeatLegend(),
      ],
    );
  }
}
