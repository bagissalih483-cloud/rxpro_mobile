part of 'customer_campaigns_page.dart';

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
                item.businessName.isEmpty ? 'Fix Fırsat' : item.businessName,
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
