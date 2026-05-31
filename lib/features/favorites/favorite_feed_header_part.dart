part of 'favorite_feed_page.dart';

class _FavoriteHeader extends StatelessWidget {
  const _FavoriteHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favoriler',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Takip ettiğin işletmeler, kaydedilenler ve paylaşımlar.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _FavoriteTabs extends StatelessWidget {
  const _FavoriteTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      _FavoriteTabData(Icons.dynamic_feed_outlined, 'Paylaşımlar'),
      _FavoriteTabData(Icons.storefront_outlined, 'Takip'),
      _FavoriteTabData(Icons.bookmark_border_rounded, 'Kaydettiklerim'),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final selected = selectedIndex == index;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 19,
                      color: selected
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF6B7280),
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

class _FavoriteTabData {
  const _FavoriteTabData(this.icon, this.label);

  final IconData icon;
  final String label;
}
