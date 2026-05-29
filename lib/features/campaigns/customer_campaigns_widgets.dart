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
              'Kampanyalar',
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
      _TabInfo('Güncel', fresh),
      _TabInfo('Aktif', active),
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

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.item,
    required this.onTap,
    required this.onOpenBusiness,
    required this.onReport,
  });

  final _CampaignItem item;
  final VoidCallback onTap;
  final VoidCallback? onOpenBusiness;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Poster(item: item),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 17),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.businessName.isEmpty
                              ? 'İşletme'
                              : item.businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        item.dateRange,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (onOpenBusiness != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onOpenBusiness,
                            icon: const Icon(Icons.storefront_rounded),
                            label: const Text('Kurumsal Profile Git'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          tooltip: 'Şikayet et',
                          onPressed: onReport,
                          icon: const Icon(Icons.flag_outlined),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton.outlined(
                        tooltip: 'Şikayet et',
                        onPressed: onReport,
                        icon: const Icon(Icons.flag_outlined),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.item, this.large = false});

  final _CampaignItem item;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.from(item.templateStyle);
    final height = large ? 230.0 : 190.0;

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -14,
            child: Icon(
              palette.icon,
              size: 112,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.businessName.isEmpty ? 'fi Kampanya' : item.businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.discountText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: large ? 28 : 24,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Palette {
  const _Palette({required this.colors, required this.icon});

  final List<Color> colors;
  final IconData icon;

  static _Palette from(String style) {
    final clean = style.toLowerCase();

    if (clean.contains('health') ||
        clean.contains('saglik') ||
        clean.contains('sağlık')) {
      return const _Palette(
        colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        icon: Icons.health_and_safety_outlined,
      );
    }

    if (clean.contains('food') || clean.contains('yemek')) {
      return const _Palette(
        colors: [Color(0xFFB45309), Color(0xFFF97316)],
        icon: Icons.restaurant_menu_rounded,
      );
    }

    if (clean.contains('sport') || clean.contains('spor')) {
      return const _Palette(
        colors: [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
        icon: Icons.fitness_center_rounded,
      );
    }

    return const _Palette(
      colors: [Color(0xFF7C2D12), Color(0xFFEA580C)],
      icon: Icons.local_offer_rounded,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: const Color(0xFFEA580C)),
      title: Text(label),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          children: [
            Icon(icon, size: 36, color: const Color(0xFF6B7280)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
