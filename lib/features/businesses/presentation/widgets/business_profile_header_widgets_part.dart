part of '../../business_profile_page.dart';

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.icon,
    required this.text,
    this.color = RxColors.primary,
    this.bg = const Color(0xFFEFF6FF),
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessBookingDisabledCard extends StatelessWidget {
  const _BusinessBookingDisabledCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFF7ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFFED7AA)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Color(0xFFC2410C)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kurumsal hesap a\u00e7\u0131kken randevu alma kapat\u0131ld\u0131. Bu ekran sadece bireysel kullan\u0131c\u0131lar\u0131n randevu talebi olu\u015fturmas\u0131 i\u00e7indir.',
                style: TextStyle(
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({
    required this.selectedIndex,
    required this.onChanged,
    this.hideAppointment = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool hideAppointment;

  @override
  Widget build(BuildContext context) {
    final tabs = <_TabData>[
      const _TabData(icon: Icons.home_outlined, label: 'Tan\u0131t\u0131m'),
      if (!hideAppointment)
        const _TabData(icon: Icons.calendar_month_outlined, label: 'Randevu'),
      const _TabData(icon: Icons.chat_outlined, label: 'Yorumlar'),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.028),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final selected = selectedIndex == index;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? RxColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 20,
                      color: selected ? RxColors.primary : RxColors.muted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: selected ? RxColors.primary : RxColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TabData {
  final IconData icon;
  final String label;

  const _TabData({required this.icon, required this.label});
}
