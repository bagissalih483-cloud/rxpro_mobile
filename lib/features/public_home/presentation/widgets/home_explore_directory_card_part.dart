part of 'home_explore_business_cards.dart';

class _DirectoryOnlyBusinessCard extends StatelessWidget {
  const _DirectoryOnlyBusinessCard({
    required this.item,
    required this.distanceKm,
    required this.origin,
    required this.onDirections,
    this.onClaim,
    this.showRouteDistance = false,
  });

  final BusinessDirectoryItem item;
  final double distanceKm;
  final Position? origin;
  final VoidCallback onDirections;
  final VoidCallback? onClaim;
  final bool showRouteDistance;

  @override
  Widget build(BuildContext context) {
    final location = item.locationLabel.trim();
    final title = HomeExploreBusinessCard._titleLabel(item.name);
    final category = item.category.trim().isEmpty
        ? 'İşletme'
        : item.category.trim();
    final style = HomeExploreCategoryStyles.forLabel(category);
    final meta = <String>[
      category,
      if (location.isNotEmpty) location,
    ].join(' • ');

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: style.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: style.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: style.accent.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(style.icon, color: style.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF17384A),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (distanceKm.isFinite)
                  _BusinessMetaChip(
                    icon: Icons.near_me_outlined,
                    label: HomeExploreBusinessCard._proximityLabel(distanceKm),
                    color: style.accent,
                  ),
                HomeExploreRouteDistanceChip(
                  business: item,
                  origin: origin,
                  color: style.accent,
                  enabled: showRouteDistance,
                ),
              ],
            ),
            if (showRouteDistance && origin != null && item.hasCoordinate)
              const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onDirections,
                icon: const Icon(Icons.directions_outlined, size: 18),
                label: const Text('Yol tarifi al'),
                style: FilledButton.styleFrom(
                  foregroundColor: style.accent,
                  backgroundColor: style.accent.withValues(alpha: 0.11),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onClaim,
                    icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                    label: const Text('Bu işletme benim'),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Google Maps',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
