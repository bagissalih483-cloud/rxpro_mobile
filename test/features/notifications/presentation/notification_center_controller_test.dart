import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/notifications/data/notification_center_repository.dart';
import 'package:rxpro_mobile/features/notifications/presentation/notification_center_controller.dart';

void main() {
  group('NotificationCenterController', () {
    test('caches scope until uid or target changes', () async {
      final source = _FakeNotificationCenterDataSource(uid: 'u1');
      final controller = NotificationCenterController(repository: source);

      final first = await controller.scopeFuture;
      final second = await controller.scopeFuture;

      expect(first.uid, 'u1');
      expect(identical(first, second), isTrue);
      expect(source.resolveCalls, 1);

      source.uid = 'u2';
      final third = await controller.scopeFuture;

      expect(third.uid, 'u2');
      expect(source.resolveCalls, 2);

      controller.updateTarget(businessId: 'b1', businessName: 'Fix');
      final fourth = await controller.scopeFuture;

      expect(fourth.businessId, 'b1');
      expect(fourth.businessName, 'Fix');
      expect(source.resolveCalls, 3);
    });

    test('delegates read actions to the data source', () async {
      final source = _FakeNotificationCenterDataSource(uid: 'u1');
      final controller = NotificationCenterController(repository: source);
      final unread = const NotificationCenterItem(
        id: 'n1',
        title: 'T',
        body: 'B',
        type: 'general',
        route: '',
        isRead: false,
        createdMillis: 0,
        createdText: 'Yeni',
      );

      await controller.markRead('n1');
      final count = await controller.markAllRead([unread]);

      expect(source.markReadIds, ['n1']);
      expect(count, 1);
      expect(source.markAllReadCalls, 1);
    });
  });
}

class _FakeNotificationCenterDataSource
    implements NotificationCenterDataSource {
  _FakeNotificationCenterDataSource({required this.uid});

  String? uid;
  int resolveCalls = 0;
  int markAllReadCalls = 0;
  final List<String> markReadIds = [];

  @override
  String? get currentUid => uid;

  @override
  Future<NotificationCenterScope> resolveScope({
    String? businessId,
    String? businessName,
  }) async {
    resolveCalls += 1;
    final cleanBusinessId = businessId?.trim() ?? '';
    if (cleanBusinessId.isNotEmpty) {
      return NotificationCenterScope.business(
        uid: uid,
        businessId: cleanBusinessId,
        businessName: businessName ?? '',
      );
    }

    final cleanUid = uid?.trim() ?? '';
    return cleanUid.isEmpty
        ? const NotificationCenterScope.guest()
        : NotificationCenterScope.user(uid: cleanUid);
  }

  @override
  Stream<List<NotificationCenterItem>> watchNotifications(
    NotificationCenterScope scope,
  ) {
    return const Stream<List<NotificationCenterItem>>.empty();
  }

  @override
  Future<void> markRead(String id) async {
    markReadIds.add(id);
  }

  @override
  Future<int> markAllRead(List<NotificationCenterItem> items) async {
    markAllReadCalls += 1;
    return items.where((item) => !item.isRead).length;
  }
}
