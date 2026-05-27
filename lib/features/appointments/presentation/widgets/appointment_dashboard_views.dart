import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/appointments/presentation/models/appointment_dashboard_models.dart';

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

  int _staffIndexFor(Map<String, dynamic> data) {
    final sid = staffIdOf(data);
    final sname = staffNameOf(data);

    for (var i = 0; i < staff.length; i++) {
      final item = staff[i];
      if (item.id == 'default') return i;
      if (sid.isNotEmpty && sid == item.id) return i;
      if (sname.isNotEmpty && sname == item.name) return i;
    }

    return staff.isEmpty ? 0 : 0;
  }

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
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(MediaQuery.of(context).size.width, gridWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: gridWidth,
                  height: gridHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: AppointmentGridPainter(
                            staffCount: staff.length,
                            slotCount: slots.length,
                            timeWidth: timeWidth,
                            cellWidth: cellWidth,
                            headerHeight: headerHeight,
                            rowHeight: rowHeight,
                            lineWidth: gridLineWidth,
                          ),
                        ),
                      ),

                      Positioned(
                        left: 0,
                        top: 0,
                        width: timeWidth,
                        height: headerHeight,
                        child: const Center(
                          child: Text(
                            'Saat',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      for (var i = 0; i < staff.length; i++)
                        Positioned(
                          left: timeWidth + (i * cellWidth),
                          top: 0,
                          width: cellWidth,
                          height: headerHeight,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                staff[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),

                      for (var i = 0; i < slots.length; i++)
                        Positioned(
                          left: 0,
                          top: headerHeight + (i * rowHeight),
                          width: timeWidth,
                          height: rowHeight,
                          child: Center(
                            child: Text(
                              timeText(slots[i]),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),

                      for (var staffIndex = 0;
                          staffIndex < staff.length;
                          staffIndex++)
                        for (var slotIndex = 0;
                            slotIndex < slots.length;
                            slotIndex++)
                          Positioned(
                            left: timeWidth + (staffIndex * cellWidth),
                            top: headerHeight + (slotIndex * rowHeight),
                            width: cellWidth,
                            height: rowHeight,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => onCreateAppointment(
                                  slots[slotIndex],
                                  staff[staffIndex],
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),

                      for (final data in dayAppointments)
                        Builder(
                          builder: (context) {
                            final dt = dateOf(data);
                            if (dt == null) return const SizedBox.shrink();

                            final minutesFromStart = dt
                                .difference(start)
                                .inMinutes;
                            if (minutesFromStart < 0 ||
                                minutesFromStart >= fullDurationMinutes) {
                              return const SizedBox.shrink();
                            }

                            final staffIndex = _staffIndexFor(data);
                            final left =
                                timeWidth + (staffIndex * cellWidth) + 6;
                            final top =
                                headerHeight +
                                ((minutesFromStart / slotMinutes) * rowHeight) +
                                7;

                            return Positioned(
                              left: left,
                              top: top,
                              width: cellWidth - 12,
                              height: math.max(42, rowHeight - 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF0284C7),
                                    width: 1.3,
                                  ),
                                ),
                                child: Text(
                                  '${customerNameOf(data)}\n${serviceNameOf(data)}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      if (isToday)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: redLineTop,
                          child: IgnorePointer(
                            child: Container(height: 3, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AppointmentGridPainter extends CustomPainter {
  const AppointmentGridPainter({
    required this.staffCount,
    required this.slotCount,
    required this.timeWidth,
    required this.cellWidth,
    required this.headerHeight,
    required this.rowHeight,
    required this.lineWidth,
  });

  final int staffCount;
  final int slotCount;
  final double timeWidth;
  final double cellWidth;
  final double headerHeight;
  final double rowHeight;
  final double lineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.white;
    final timeBgPaint = Paint()..color = const Color(0xFFF1F5F9);
    final headerBgPaint = Paint()..color = Colors.white;
    final linePaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Offset.zero & size, bgPaint);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, headerHeight),
      headerBgPaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(0, headerHeight, timeWidth, size.height - headerHeight),
      timeBgPaint,
    );

    // Dış çerçeve
    canvas.drawRect(
      Rect.fromLTWH(
        lineWidth / 2,
        lineWidth / 2,
        size.width - lineWidth,
        size.height - lineWidth,
      ),
      linePaint,
    );

    // Header alt çizgisi
    canvas.drawLine(
      Offset(0, headerHeight),
      Offset(size.width, headerHeight),
      linePaint,
    );

    // Yatay saat çizgileri, tüm genişlik boyunca tek parça
    for (var i = 0; i <= slotCount; i++) {
      final y = headerHeight + (i * rowHeight);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Saat sütunu ayrımı
    canvas.drawLine(
      Offset(timeWidth, 0),
      Offset(timeWidth, size.height),
      linePaint,
    );

    // Personel kolon çizgileri
    for (var i = 1; i <= staffCount; i++) {
      final x = timeWidth + (i * cellWidth);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AppointmentGridPainter oldDelegate) {
    return oldDelegate.staffCount != staffCount ||
        oldDelegate.slotCount != slotCount ||
        oldDelegate.timeWidth != timeWidth ||
        oldDelegate.cellWidth != cellWidth ||
        oldDelegate.headerHeight != headerHeight ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.lineWidth != lineWidth;
  }
}

// ignore: unused_element
class AppointmentSlotCell extends StatelessWidget {
  const AppointmentSlotCell({
    super.key,
    required this.width,
    required this.slot,
    required this.slotMinutes,
    required this.staff,
    required this.appointments,
    required this.dateOf,
    required this.staffIdOf,
    required this.staffNameOf,
    required this.customerNameOf,
    required this.serviceNameOf,
  });

  final double width;
  final DateTime slot;
  final int slotMinutes;
  final AppointmentStaffLite staff;
  final List<Map<String, dynamic>> appointments;
  final DateTime? Function(Map<String, dynamic>) dateOf;
  final String Function(Map<String, dynamic>) staffIdOf;
  final String Function(Map<String, dynamic>) staffNameOf;
  final String Function(Map<String, dynamic>) customerNameOf;
  final String Function(Map<String, dynamic>) serviceNameOf;

  bool _matchesStaff(Map<String, dynamic> data) {
    final sid = staffIdOf(data);
    final sname = staffNameOf(data);
    if (staff.id == 'default') return true;
    return sid == staff.id || sname == staff.name;
  }

  @override
  Widget build(BuildContext context) {
    final slotEnd = slot.add(Duration(minutes: slotMinutes));
    final hits = appointments.where((data) {
      final dt = dateOf(data);
      if (dt == null) return false;
      return _matchesStaff(data) && !dt.isBefore(slot) && dt.isBefore(slotEnd);
    }).toList();

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: hits.isEmpty
          ? const SizedBox.shrink()
          : ListView(
              padding: EdgeInsets.zero,
              children: hits.map((data) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 6,
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF38BDF8)),
                  ),
                  child: Text(
                    '${customerNameOf(data)}\n${serviceNameOf(data)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

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

class AppointmentHeatLegend extends StatelessWidget {
  const AppointmentHeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      AppointmentLegendItem('Boş', Color(0xFFFFFFFF)),
      AppointmentLegendItem('Az', Color(0xFFFFE4E6)),
      AppointmentLegendItem('Orta', Color(0xFFFCA5A5)),
      AppointmentLegendItem('Yoğun', Color(0xFFEF4444)),
      AppointmentLegendItem('Çok yoğun', Color(0xFF991B1B)),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class AppointmentErrorCard extends StatelessWidget {
  const AppointmentErrorCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Text(
          'Randevu verisi okunamadı:\n$message',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
