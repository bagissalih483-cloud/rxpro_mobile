import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_cache_service.dart';
import 'package:rxpro_mobile/core/theme/rx_ui.dart';

import '../models/home_explore_category_style.dart';
import 'home_explore_route_distance_chip.dart';

part 'home_explore_directory_card_part.dart';
part 'home_explore_meta_chip_part.dart';
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
                RxPrimaryActionButton(
                  onPressed: onTap,
                  icon: Icons.calendar_month_outlined,
                  label: 'Randevu Al',
                  color: style.accent,
                ),
                RxSecondaryActionButton(
                  onPressed: onTap,
                  icon: Icons.info_outline_rounded,
                  label: 'Detay',
                  color: style.accent,
                ),
                TextButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: const Text('Yol Tarifi'),
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
    if (value.isEmpty) return 'İşletme';
    return value;
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
