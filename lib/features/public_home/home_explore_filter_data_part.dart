part of 'home_explore_page.dart';

extension _HomeExploreFilterData on _HomeExplorePageState {
  List<BusinessDirectoryItem> _filteredBusinesses() {
    return _exploreController.filteredBusinesses(
      queryText: _exploreController.queryText,
      selectedCategory: _exploreController.selectedCategory,
      currentPosition: _exploreController.currentPosition,
      radiusKm: _exploreController.radiusKm,
      sortMode: _exploreController.sortMode,
    );
  }

  List<String> _categories() {
    return <String>[BusinessCategories.allLabel, ...BusinessCategories.labels];
  }

  IconData _sortModeIcon(HomeExploreSortMode mode) {
    switch (mode) {
      case HomeExploreSortMode.recommended:
        return Icons.auto_awesome_outlined;
      case HomeExploreSortMode.distance:
        return Icons.near_me_outlined;
      case HomeExploreSortMode.rating:
        return Icons.star_outline_rounded;
      case HomeExploreSortMode.category:
        return Icons.category_outlined;
      case HomeExploreSortMode.name:
        return Icons.sort_by_alpha_rounded;
    }
  }

  String _sortModeLabel(HomeExploreSortMode mode) {
    switch (mode) {
      case HomeExploreSortMode.recommended:
        return 'Bugün uygun';
      case HomeExploreSortMode.distance:
        return 'En yakın';
      case HomeExploreSortMode.rating:
        return 'En yüksek puan';
      case HomeExploreSortMode.category:
        return 'Kategori';
      case HomeExploreSortMode.name:
        return 'A-Z';
    }
  }
}
