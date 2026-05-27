import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_cache_service.dart';
import 'package:rxpro_mobile/core/theme/rx_ui.dart';

import '../models/home_explore_category_style.dart';
import 'home_explore_route_distance_chip.dart';

class HomeExploreBusinessCard extends StatelessWidget {
  const HomeExploreBusinessCard({
    super.key,
    required this.item,
    required this.distanceKm,
    required this.origin,
    required this.onTap,
    required this.onDirections,
    this.onClaim,
    this.showRouteDistance = false,
  });

  final BusinessDirectoryItem item;
  final double distanceKm;
  final Position? origin;
  final VoidCallback onTap;
  final VoidCallback onDirections;
  final VoidCallback? onClaim;
  final bool showRouteDistance;

  @override
  Widget build(BuildContext context) {
    if (!item.isMember) {
      return _DirectoryOnlyBusinessCard(
        item: item,
        distanceKm: distanceKm,
        origin: origin,
        onDirections: onDirections,
        onClaim: onClaim,
        showRouteDistance: showRouteDistance,
      );
    }

    final location = item.locationLabel.trim();
    final title = _titleLabel(item.name);
    final category = item.category.trim().isEmpty
        ? 'İşletme'
        : item.category.trim();
    final style = HomeExploreCategoryStyles.forLabel(category);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: style.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: style.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: style.accent.withValues(alpha: 0.12),
                    backgroundImage: item.logoUrl.trim().isEmpty
                        ? null
                        : NetworkImage(item.logoUrl),
                    child: item.logoUrl.trim().isEmpty
                        ? Text(
                            _initials(item.name),
                            style: TextStyle(
                              color: style.accent,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF17384A),
                                  height: 1.05,
                                ),
                              ),
                            ),
                            const RxStatusChip(
                              label: 'Üye',
                              color: RxColors.success,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: RxStatusChip(
                            label: category,
                            icon: style.icon,
                            color: style.accent,
                            compact: true,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          location.isEmpty ? 'Konum bilgisi yok' : location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF829198),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _BusinessMetaChip(
                  icon: Icons.star_rounded,
                  label: item.ratingAvg > 0
                      ? item.ratingAvg.toStringAsFixed(1)
                      : 'Yeni',
                  color: const Color(0xFFF5B13B),
                ),
                if (distanceKm.isFinite)
                  _BusinessMetaChip(
                    icon: Icons.near_me_outlined,
                    label: _proximityLabel(distanceKm),
                    color: style.accent,
                  ),
                HomeExploreRouteDistanceChip(
                  business: item,
                  origin: origin,
                  color: style.accent,
                  enabled: showRouteDistance,
                ),
                TextButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: const Text('Yol tarifi al'),
                ),
                FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('Profil'),
                  style: FilledButton.styleFrom(
                    backgroundColor: style.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _distanceLabel(double value) {
    if (!value.isFinite) return '';
    if (value < 1) return '${(value * 1000).round()} m';
    return '${value.toStringAsFixed(1)} km';
  }

  static String _proximityLabel(double value) {
    final distance = _distanceLabel(value);
    if (distance.isEmpty) return '';
    return 'Yaklaşık $distance yakınında';
  }

  static String _titleLabel(String text) {
    final value = text.trim();
    if (value.isEmpty) return 'İŞLETME';
    return value.toUpperCase();
  }

  static String _initials(String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'F';
    if (words.length == 1) {
      return words.first.characters.take(2).toString().toUpperCase();
    }

    return '${words.first.characters.first}${words[1].characters.first}'
        .toUpperCase();
  }
}

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
                  child: Icon(
                    style.icon,
                    color: style.accent,
                  ),
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

class _BusinessMetaChip extends StatelessWidget {
  const _BusinessMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF17384A),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
