part of 'appointment_dashboard_views.dart';

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
