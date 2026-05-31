part of 'home_explore_page.dart';

extension _HomeExploreHeaderFilter on _HomeExplorePageState {
  Widget _buildHeader() {
    final session = AppSessionScope.maybeOf(context);
    final businessPhotoUrl =
        (session?.businessData['logoUrl'] ??
                session?.businessData['photoUrl'] ??
                session?.businessData['imageUrl'] ??
                '')
            .toString()
            .trim();
    final userPhotoUrl =
        (session?.userData['photoUrl'] ??
                session?.userData['imageUrl'] ??
                session?.userData['avatarUrl'] ??
                '')
            .toString()
            .trim();
    final photoUrl = businessPhotoUrl.isNotEmpty
        ? businessPhotoUrl
        : userPhotoUrl;
    final sessionBusinessName = session?.businessName.trim() ?? '';
    final displayName = widget.previewMode
        ? (sessionBusinessName.isNotEmpty ? sessionBusinessName : 'fix')
        : session?.isAuthenticated == true
        ? session!.displayName
        : 'Misafir';

    return ExploreHomeHeader(
      displayName: displayName,
      photoUrl: photoUrl,
      showName: !(widget.previewMode || session?.isCorporate == true),
      messagesButton: _buildHeaderBadgeButton(
        stream: _liveUnreadMessagesCountStream(),
        icon: Icons.chat_bubble_outline,
        onTap: _openMessages,
      ),
      notificationsButton: _buildHeaderBadgeButton(
        stream: _liveUnreadNotificationsCountStream(),
        icon: Icons.notifications_none_rounded,
        onTap: _openNotifications,
      ),
    );
  }

  Widget _buildHeaderBadgeButton({
    required Stream<int> stream,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        return ExploreHeaderIconButton(
          icon: icon,
          count: snapshot.data ?? 0,
          onTap: onTap,
        );
      },
    );
  }

  Widget _buildFilterPanel() {
    return HomeExploreControlPanel<HomeExploreSortMode>(
      hasPosition: _exploreController.currentPosition != null,
      loadingLocation: _exploreController.loadingLocation,
      radiusKm: _exploreController.radiusKm,
      onLocationPressed: _requestLocation,
      onRadiusChanged: _exploreController.setRadiusKm,
      onRadiusChangeEnd: (_) {
        final position = _exploreController.currentPosition;
        if (position != null) {
          unawaited(
            _reloadExploreBusinesses(
              position: position,
              forceRefresh: true,
              replaceWithEmpty: true,
            ).then((applied) {
              if (applied) {
                _exploreController.markLocationQueryApplied(position);
              }
            }),
          );
          return;
        }

        unawaited(
          _reloadExploreBusinesses(forceRefresh: true, replaceWithEmpty: true),
        );
      },
      sortModes: const [
        HomeExploreSortMode.recommended,
        HomeExploreSortMode.rating,
        HomeExploreSortMode.category,
        HomeExploreSortMode.name,
      ],
      selectedSortMode: _exploreController.sortMode,
      sortLabelBuilder: _sortModeLabel,
      sortIconBuilder: _sortModeIcon,
      onSortSelected: _exploreController.setSortMode,
      primarySortMode: HomeExploreSortMode.distance,
      primarySortLabel: 'En yakın',
    );
  }
}
