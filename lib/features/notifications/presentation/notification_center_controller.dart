import '../data/notification_center_repository.dart';

abstract class NotificationCenterDataSource {
  String? get currentUid;

  Future<NotificationCenterScope> resolveScope({
    String? businessId,
    String? businessName,
  });

  Stream<List<NotificationCenterItem>> watchNotifications(
    NotificationCenterScope scope,
  );

  Future<void> markRead(String id);

  Future<int> markAllRead(List<NotificationCenterItem> items);
}

class NotificationCenterController {
  NotificationCenterController({
    NotificationCenterDataSource? repository,
    String? businessId,
    String? businessName,
  }) : _repository = repository ?? _FirebaseNotificationCenterDataSource(),
       _businessId = businessId,
       _businessName = businessName;

  final NotificationCenterDataSource _repository;
  String? _businessId;
  String? _businessName;
  String? _loadedUid;
  Future<NotificationCenterScope>? _scopeFuture;

  Future<NotificationCenterScope> get scopeFuture {
    refreshScopeIfNeeded();
    return _scopeFuture ??= _resolveScope();
  }

  void updateTarget({String? businessId, String? businessName}) {
    if (_businessId == businessId && _businessName == businessName) {
      return;
    }

    _businessId = businessId;
    _businessName = businessName;
    _scopeFuture = null;
    _loadedUid = null;
    refreshScopeIfNeeded();
  }

  void refreshScopeIfNeeded() {
    final uid = _repository.currentUid;
    if (_scopeFuture == null || _loadedUid != uid) {
      _loadedUid = uid;
      _scopeFuture = _resolveScope();
    }
  }

  Stream<List<NotificationCenterItem>> watchNotifications(
    NotificationCenterScope scope,
  ) {
    return _repository.watchNotifications(scope);
  }

  Future<void> markRead(String id) {
    return _repository.markRead(id);
  }

  Future<int> markAllRead(List<NotificationCenterItem> items) {
    return _repository.markAllRead(items);
  }

  Future<NotificationCenterScope> _resolveScope() {
    return _repository.resolveScope(
      businessId: _businessId,
      businessName: _businessName,
    );
  }
}

class _FirebaseNotificationCenterDataSource extends NotificationCenterRepository
    implements NotificationCenterDataSource {}
