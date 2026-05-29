import '../data/notification_center_repository.dart';

class NotificationCenterViewPolicy {
  const NotificationCenterViewPolicy._();

  static NotificationCenterSummary summary({
    required NotificationCenterScope scope,
    required List<NotificationCenterItem> items,
  }) {
    final isBusiness = scope.businessId.trim().isNotEmpty;
    return NotificationCenterSummary(
      title: isBusiness
          ? 'Kurumsal Kullanici Bildirimleri'
          : 'Bireysel Kullanici Bildirimleri',
      subtitle: isBusiness
          ? scope.businessName
          : 'Randevu, kampanya ve sistem uyarilari',
      total: items.length,
      unread: unreadCount(items),
    );
  }

  static NotificationCenterEmptyCopy emptyCopy(NotificationCenterScope scope) {
    return NotificationCenterEmptyCopy(
      title: 'Bildirim yok',
      body: scope.businessId.trim().isNotEmpty
          ? 'Bu kurumsal kullanici icin henuz bildirim olusmadi.'
          : 'Hesabiniz icin henuz bildirim olusmadi.',
    );
  }

  static int unreadCount(List<NotificationCenterItem> items) {
    return items.where((item) => !item.isRead).length;
  }

  static bool opensCustomerAppointments(NotificationCenterItem item) {
    final normalizedRoute = item.route.toLowerCase();
    final normalizedType = item.type.toLowerCase();

    return normalizedRoute == 'customerappointments' ||
        normalizedRoute == 'customer_appointments' ||
        (normalizedType.contains('appointment') &&
            !normalizedRoute.contains('business'));
  }
}

class NotificationCenterSummary {
  const NotificationCenterSummary({
    required this.title,
    required this.subtitle,
    required this.total,
    required this.unread,
  });

  final String title;
  final String subtitle;
  final int total;
  final int unread;
}

class NotificationCenterEmptyCopy {
  const NotificationCenterEmptyCopy({required this.title, required this.body});

  final String title;
  final String body;
}
