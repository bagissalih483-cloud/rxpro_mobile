import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/notifications/data/notification_center_repository.dart';
import 'package:rxpro_mobile/features/notifications/domain/notification_center_view_policy.dart';

void main() {
  group('NotificationCenterViewPolicy', () {
    test('builds personal summary and unread count', () {
      final summary = NotificationCenterViewPolicy.summary(
        scope: const NotificationCenterScope.user(uid: 'u1'),
        items: const [
          _TestItem(id: 'n1', isRead: false),
          _TestItem(id: 'n2', isRead: true),
        ],
      );

      expect(summary.title, 'Bireysel Kullanici Bildirimleri');
      expect(summary.total, 2);
      expect(summary.unread, 1);
    });

    test('builds business empty copy', () {
      final copy = NotificationCenterViewPolicy.emptyCopy(
        const NotificationCenterScope.business(
          uid: 'u1',
          businessId: 'b1',
          businessName: 'Fix',
        ),
      );

      expect(copy.title, 'Bildirim yok');
      expect(copy.body, contains('kurumsal'));
    });

    test('routes customer appointment notifications only', () {
      expect(
        NotificationCenterViewPolicy.opensCustomerAppointments(
          const _TestItem(
            id: 'n1',
            type: 'appointment',
            route: 'customerAppointments',
          ),
        ),
        isTrue,
      );
      expect(
        NotificationCenterViewPolicy.opensCustomerAppointments(
          const _TestItem(
            id: 'n2',
            type: 'appointment',
            route: 'businessAppointments',
          ),
        ),
        isFalse,
      );
    });
  });
}

class _TestItem extends NotificationCenterItem {
  const _TestItem({
    required super.id,
    super.title = 'Title',
    super.body = '',
    super.type = 'general',
    super.route = '',
    super.isRead = false,
    super.createdMillis = 0,
    super.createdText = 'Yeni',
  });
}
