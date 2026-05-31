part of 'business_management_home_page.dart';

class _ManagementHeroCard extends StatelessWidget {
  const _ManagementHeroCard({
    required this.businessName,
    required this.category,
  });

  final String businessName;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName.trim().isEmpty ? 'Kurumsal Hesap' : businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.expanded,
    required this.onToggle,
  });

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.today_outlined,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Bugün: -- randevu · -- bekleyen · -- kasa',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: _TodayMetricGrid(),
                ),
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: Duration(milliseconds: 180),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayMetricGrid extends StatelessWidget {
  const _TodayMetricGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 6
            : constraints.maxWidth >= 640
            ? 3
            : 2;
        final itemWidth =
            (constraints.maxWidth - (8 * (columns - 1))) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _TodayMetric(width: 0, label: 'Randevu', value: '--'),
            _TodayMetric(width: 0, label: 'Bekleyen', value: '--'),
            _TodayMetric(width: 0, label: 'Boş saat', value: '--'),
            _TodayMetric(width: 0, label: 'Yeni müşteri', value: '--'),
            _TodayMetric(width: 0, label: 'Cevap bekleyen', value: '--'),
            _TodayMetric(width: 0, label: 'Kasa', value: '--'),
          ].map((item) => item.copyWith(width: itemWidth)).toList(),
        );
      },
    );
  }
}

class _TodayMetric extends StatelessWidget {
  const _TodayMetric({
    required this.width,
    required this.label,
    required this.value,
  });

  final double width;
  final String label;
  final String value;

  _TodayMetric copyWith({required double width}) {
    return _TodayMetric(width: width, label: label, value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
