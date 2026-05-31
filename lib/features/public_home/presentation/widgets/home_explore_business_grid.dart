import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_cache_service.dart';
import 'package:rxpro_mobile/core/responsive/rx_breakpoints.dart';

import 'home_explore_business_cards.dart';

class HomeExploreBusinessGrid extends StatelessWidget {
  const HomeExploreBusinessGrid({
    super.key,
    required this.items,
    required this.origin,
    required this.onOpenBusiness,
    required this.onOpenDirections,
    required this.onClaimBusiness,
  });

  final List<BusinessDirectoryItem> items;
  final Position? origin;
  final ValueChanged<BusinessDirectoryItem> onOpenBusiness;
  final ValueChanged<BusinessDirectoryItem> onOpenDirections;
  final ValueChanged<BusinessDirectoryItem> onClaimBusiness;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceClass = RxBreakpoints.fromWidth(constraints.maxWidth);
        final columns = _columnsFor(deviceClass, constraints.maxWidth);
        final visibleItems = items.take(200).toList(growable: false);

        if (columns == 1) {
          return Column(
            children: [
              for (final entry in visibleItems.asMap().entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  key: ValueKey('explore_business_${entry.value.id}'),
                  child: _card(entry.key, entry.value),
                ),
            ],
          );
        }

        const spacing = 12.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final entry in visibleItems.asMap().entries)
              SizedBox(
                width: width,
                key: ValueKey('explore_business_${entry.value.id}'),
                child: _card(entry.key, entry.value),
              ),
          ],
        );
      },
    );
  }

  int _columnsFor(RxDeviceClass deviceClass, double width) {
    if (deviceClass.isDesktopWide && width >= 1280) return 3;
    if (deviceClass.usesWideNavigation || width >= 760) return 2;
    return 1;
  }

  Widget _card(int index, BusinessDirectoryItem item) {
    return HomeExploreBusinessCard(
      item: item,
      distanceKm: item.distanceKmFrom(origin),
      origin: origin,
      showRouteDistance: index < 2,
      onTap: () => onOpenBusiness(item),
      onDirections: () => onOpenDirections(item),
      onClaim: item.isMember ? null : () => onClaimBusiness(item),
    );
  }
}
