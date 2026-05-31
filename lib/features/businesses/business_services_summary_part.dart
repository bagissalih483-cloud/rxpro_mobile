part of 'business_services_manage_page.dart';

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.activeCount, required this.passiveCount});

  final int activeCount;
  final int passiveCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniMetric(
            title: 'Aktif',
            value: '$activeCount',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniMetric(
            title: 'Pasif',
            value: '$passiveCount',
            icon: Icons.pause_circle_outline_rounded,
            color: const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
