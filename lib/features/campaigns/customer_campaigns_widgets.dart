part of 'customer_campaigns_page.dart';

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFEA580C)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_offer_rounded, color: Colors.white, size: 34),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fırsatlar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.selected,
    required this.fresh,
    required this.active,
    required this.upcoming,
    required this.past,
    required this.onChanged,
  });

  final int selected;
  final int fresh;
  final int active;
  final int upcoming;
  final int past;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabInfo('Sana uygun', fresh),
      _TabInfo('Bugün geçerli', active),
      _TabInfo('Yakında', upcoming),
      _TabInfo('Geçmiş', past),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return _Pill(
            label: tab.label,
            count: tab.count,
            selected: selected == index,
            onTap: () => onChanged(index),
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 94),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEA580C) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFEA580C) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          '$label ($count)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF374151),
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _CategoryScroller extends StatelessWidget {
  const _CategoryScroller({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = item == selected;

          return ChoiceChip(
            selected: isSelected,
            label: Text(item),
            onSelected: (_) => onChanged(item),
            selectedColor: const Color(0xFFFFEDD5),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFFEA580C)
                  : const Color(0xFFE5E7EB),
            ),
            labelStyle: TextStyle(
              color: isSelected
                  ? const Color(0xFF9A3412)
                  : const Color(0xFF475569),
              fontWeight: FontWeight.w900,
            ),
          );
        },
      ),
    );
  }
}
