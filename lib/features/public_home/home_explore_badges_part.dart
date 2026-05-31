part of 'home_explore_page.dart';

extension _HomeExploreBadges on _HomeExplorePageState {
  void _openMessages() {
    if (!_sessionRepository.isSignedIn) {
      GuestRequiredSheet.show(
        context,
        title: 'Giriş yapmanız gerekiyor',
        message:
            'Mesajlarınızı görüntülemek için bireysel veya kurumsal hesapla giriş yapmanız gerekir.',
      );
      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.messagesInbox);
  }

  void _openNotifications() {
    if (!_sessionRepository.isSignedIn) {
      GuestRequiredSheet.show(
        context,
        title: 'Giriş yapmanız gerekiyor',
        message:
            'Bildirimlerinizi görüntülemek ve randevu güncellemelerini takip etmek için giriş yapmanız gerekir.',
      );
      return;
    }

    final session = AppSessionScope.maybeOf(context);
    final sessionBusinessId = session?.isCorporate == true
        ? session!.businessId.trim()
        : '';
    final widgetBusinessId = (widget.notificationBusinessId ?? '').trim();
    final bid = widgetBusinessId.isNotEmpty
        ? widgetBusinessId
        : sessionBusinessId;
    final widgetBusinessName = widget.notificationBusinessName?.trim();
    final businessName = widgetBusinessName?.isNotEmpty == true
        ? widgetBusinessName
        : session?.businessName;

    Navigator.of(context).pushNamed(
      AppRoutes.notificationCenter,
      arguments: NotificationCenterRouteArgs(
        businessId: bid.isEmpty ? null : bid,
        businessName: businessName,
      ),
    );
  }

  Stream<int> _liveUnreadMessagesCountStream() {
    final scope = _badgeScope();
    if (scope == null) return Stream<int>.value(0);

    final key = _badgeStreamKey(scope);
    if (_unreadMessagesStreamKey == key && _unreadMessagesStream != null) {
      return _unreadMessagesStream!;
    }

    _unreadMessagesStreamKey = key;
    _unreadMessagesStream = _badgeRepository.watchUnreadMessagesCount(
      uid: scope.uid,
      previewMode: scope.useBusinessBadge,
      businessId: scope.businessId,
    );
    return _unreadMessagesStream!;
  }

  Stream<int> _liveUnreadNotificationsCountStream() {
    final scope = _badgeScope();
    if (scope == null) return Stream<int>.value(0);

    final key = _badgeStreamKey(scope);
    if (_unreadNotificationsStreamKey == key &&
        _unreadNotificationsStream != null) {
      return _unreadNotificationsStream!;
    }

    _unreadNotificationsStreamKey = key;
    _unreadNotificationsStream = _badgeRepository.watchUnreadNotificationsCount(
      uid: scope.uid,
      previewMode: scope.useBusinessBadge,
      businessId: scope.businessId,
    );
    return _unreadNotificationsStream!;
  }

  _ExploreBadgeScope? _badgeScope() {
    final uid = _sessionRepository.currentUid();
    if (uid == null) return null;

    final session = AppSessionScope.maybeOf(context);
    final sessionBusinessId = session?.isCorporate == true
        ? session!.businessId.trim()
        : '';
    final widgetBusinessId = (widget.notificationBusinessId ?? '').trim();
    final businessId = widgetBusinessId.isNotEmpty
        ? widgetBusinessId
        : sessionBusinessId;
    final useBusinessBadge =
        (widget.previewMode || session?.isCorporate == true) &&
        businessId.isNotEmpty;
    return _ExploreBadgeScope(
      uid,
      businessId,
      useBusinessBadge: useBusinessBadge,
    );
  }

  String _badgeStreamKey(_ExploreBadgeScope scope) {
    return [
      scope.uid,
      scope.useBusinessBadge ? 'business' : 'customer',
      scope.businessId,
    ].join('|');
  }

  void _clearBadgeStreams() {
    _unreadMessagesStreamKey = null;
    _unreadMessagesStream = null;
    _unreadNotificationsStreamKey = null;
    _unreadNotificationsStream = null;
  }
}
