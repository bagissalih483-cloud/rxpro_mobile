part of 'business_campaigns_page.dart';

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.published,
    required this.draft,
    required this.passive,
  });

  final int published;
  final int draft;
  final int passive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.campaign_rounded, color: Colors.white),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kampanyalarım',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroStat(label: 'Yayında', value: published),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStat(label: 'Taslak', value: draft),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStat(label: 'Pasif', value: passive),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessTabs extends StatelessWidget {
  const _BusinessTabs({
    required this.selected,
    required this.published,
    required this.draft,
    required this.passive,
    required this.onChanged,
  });

  final int selected;
  final int published;
  final int draft;
  final int passive;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabInfo('Yayında', published),
      _TabInfo('Taslak', draft),
      _TabInfo('Yayından Kaldırılan', passive),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = tabs[index];
          final isSelected = selected == index;

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(index),
            child: Container(
              constraints: const BoxConstraints(minWidth: 104),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                '${item.label} (${item.count})',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabInfo {
  const _TabInfo(this.label, this.count);

  final String label;
  final int count;
}
