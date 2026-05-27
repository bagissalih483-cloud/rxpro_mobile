import 'package:flutter/material.dart';

class CustomerAppointmentTabs extends StatelessWidget {
  const CustomerAppointmentTabs({
    super.key,
    required this.selectedIndex,
    required this.activeCount,
    required this.postponedCount,
    required this.pastCount,
    required this.cancelledCount,
    required this.onChanged,
  });

  final int selectedIndex;
  final int activeCount;
  final int postponedCount;
  final int pastCount;
  final int cancelledCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Aktif', activeCount),
      ('Erteleme', postponedCount),
      ('Geçmiş', pastCount),
      ('İptal', cancelledCount),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${tabs[index].$1} (${tabs[index].$2})',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: selected
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class CustomerAppointmentInfoLine extends StatelessWidget {
  const CustomerAppointmentInfoLine({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF64748B)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerEmptyAppointments extends StatelessWidget {
  const CustomerEmptyAppointments({super.key, required this.tab});

  final int tab;

  @override
  Widget build(BuildContext context) {
    final text = tab == 0
        ? 'Aktif randevunuz yok.'
        : tab == 1
        ? 'Erteleme talebiniz bulunmuyor.'
        : tab == 2
        ? 'Geçmiş randevunuz bulunmuyor.'
        : 'İptal edilen randevunuz yok.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 42,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerAppointmentStatusOnlyLine extends StatelessWidget {
  const CustomerAppointmentStatusOnlyLine({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
