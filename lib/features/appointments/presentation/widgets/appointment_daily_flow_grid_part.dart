part of 'appointment_dashboard_views.dart';

extension _AppointmentDailyFlowGrid on AppointmentDailyFlowView {
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


  Widget _buildDailyFlowGrid({
    required BuildContext context,
    required List<Map<String, dynamic>> dayAppointments,
    required List<DateTime> slots,
    required DateTime start,
    required int fullDurationMinutes,
    required bool isToday,
    required double redLineTop,
    required double timeWidth,
    required double cellWidth,
    required double headerHeight,
    required double rowHeight,
    required double gridLineWidth,
    required double gridWidth,
    required double gridHeight,
  }) {
    return Expanded(
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

                  for (
                    var staffIndex = 0;
                    staffIndex < staff.length;
                    staffIndex++
                  )
                    for (
                      var slotIndex = 0;
                      slotIndex < slots.length;
                      slotIndex++
                    )
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
    );
  }
}
