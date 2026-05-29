import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_cache_service.dart';
import 'package:rxpro_mobile/core/theme/rx_ui.dart';
import 'package:rxpro_mobile/features/stories/business_story_rail.dart';

import 'home_explore_business_cards.dart';
import 'home_explore_filter_widgets.dart';
import 'home_explore_shell_widgets.dart';

class HomeExploreContentList extends StatelessWidget {
  const HomeExploreContentList({
    super.key,
    required this.loadingBusinesses,
    required this.hasCompletedInitialBusinessLoad,
    required this.businessLoadError,
    required this.waitingForManualLoad,
    required this.allItems,
    required this.filteredItems,
    required this.categories,
    required this.categoryCounts,
    required this.searchController,
    required this.selectedCategory,
    required this.currentPosition,
    required this.radiusKm,
    required this.filterPanel,
    required this.scrollController,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onCategorySelected,
    required this.onManualLoad,
    required this.onResetFilters,
    required this.onOpenBusiness,
    required this.onOpenDirections,
    required this.onClaimBusiness,
  });

  final bool loadingBusinesses;
  final bool hasCompletedInitialBusinessLoad;
  final Object? businessLoadError;
  final bool waitingForManualLoad;
  final List<BusinessDirectoryItem> allItems;
  final List<BusinessDirectoryItem> filteredItems;
  final List<String> categories;
  final Map<String, int> categoryCounts;
  final TextEditingController searchController;
  final String selectedCategory;
  final Position? currentPosition;
  final double radiusKm;
  final Widget filterPanel;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onManualLoad;
  final VoidCallback onResetFilters;
  final ValueChanged<BusinessDirectoryItem> onOpenBusiness;
  final ValueChanged<BusinessDirectoryItem> onOpenDirections;
  final ValueChanged<BusinessDirectoryItem> onClaimBusiness;

  @override
  Widget build(BuildContext context) {
    final sectionTitle = currentPosition == null
        ? 'Kayıtlı işletmeler'
        : 'Yakındaki işletmeler';
    final emptyTitle = loadingBusinesses
        ? 'İşletmeler yükleniyor'
        : currentPosition == null
        ? 'Sonuç bulunamadı'
        : '${radiusKm.round()} km içinde sonuç yok';
    final emptyText = loadingBusinesses || !hasCompletedInitialBusinessLoad
        ? 'Kayıtlı işletmeler hazırlanıyor. Konum alınırsa seçili kilometreye göre yakın işletmeler öne taşınacak.'
        : currentPosition == null
        ? 'Aramayı temizleyin veya kategori filtresini değiştirerek kayıtlı işletmeleri listeleyin.'
        : 'Bu konum ve kilometre aralığında kategoriye uygun işletme bulunamadı. Kilometre aralığını büyütün veya konumu tekrar alın.';

    if (businessLoadError != null && allItems.isEmpty) {
      return ExploreInfoState(
        icon: Icons.error_outline,
        title: 'Keşfet yüklenemedi',
        text: businessLoadError.toString(),
        actionText: 'Tekrar dene',
        onAction: onRefresh,
      );
    }

    return ListView(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      children: [
          if (loadingBusinesses && allItems.isEmpty) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 10),
          ],
          HomeExploreSearchBox(
            controller: searchController,
            onChanged: onSearchChanged,
            onClear: onSearchCleared,
          ),
          const SizedBox(height: 10),
          const BusinessStoryRail(compact: true),
          const SizedBox(height: 10),
          HomeExploreCategoryRow(
            categories: categories,
            selectedCategory: selectedCategory,
            counts: categoryCounts,
            onSelected: onCategorySelected,
          ),
          const SizedBox(height: 10),
          filterPanel,
          const SizedBox(height: 14),
          RxSectionHeader(
            title: sectionTitle,
            subtitle: currentPosition == null
                ? 'Konumdan bağımsız tüm kayıtlı işletmeler.'
                : '${radiusKm.round()} km içinde kayıtlı işletmeler önce gösterilir.',
            trailing: RxStatusChip(
              label: '${filteredItems.length} sonuç',
              color: RxColors.success,
              compact: true,
            ),
          ),
          const SizedBox(height: 10),
          if (waitingForManualLoad)
            ExploreInfoState(
              icon: Icons.pause_circle_outline_rounded,
              title: 'Keşfet beklemede',
              text:
                  'Tanı modu otomatik işletme yüklemesini durdurdu. Bu ekran açık kalırsa sorun veri yükleme adımında değildir.',
              actionText: 'Keşfet verisini yükle',
              onAction: onManualLoad,
            )
          else if (loadingBusinesses && allItems.isEmpty)
            ...List.generate(
              4,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: RxSkeletonCard(height: 108),
              ),
            )
          else if (filteredItems.isEmpty)
            ExploreInfoState(
              icon: loadingBusinesses
                  ? Icons.explore_outlined
                  : Icons.search_off,
              title: emptyTitle,
              text: emptyText,
              actionText: loadingBusinesses ? null : 'Filtreleri temizle',
              onAction: loadingBusinesses ? null : onResetFilters,
            )
          else
            ...filteredItems
                .take(200)
                .toList(growable: false)
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    key: ValueKey('explore_business_${entry.value.id}'),
                    child: HomeExploreBusinessCard(
                      item: entry.value,
                      distanceKm: entry.value.distanceKmFrom(currentPosition),
                      origin: currentPosition,
                      showRouteDistance: entry.key < 2,
                      onTap: () => onOpenBusiness(entry.value),
                      onDirections: () => onOpenDirections(entry.value),
                      onClaim: entry.value.isMember
                          ? null
                          : () => onClaimBusiness(entry.value),
                    ),
                  ),
                ),
      ],
    );
  }
}
