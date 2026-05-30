import 'package:rxpro_mobile/core/realtime/data/rx_notification_repository.dart';

class RxNotificationService {
  RxNotificationService._();

  static final RxNotificationRepository _repository =
      RxNotificationRepository();

  static Future<void> createUserNotification({
    required String recipientUid,
    required String type,
    required String title,
    required String body,
    String? actorUid,
    String? businessId,
    String? businessName,
    String? route,
    Map<String, dynamic>? data,
  }) {
    return _repository.createUserNotification(
      recipientUid: recipientUid,
      type: type,
      title: title,
      body: body,
      actorUid: actorUid,
      businessId: businessId,
      businessName: businessName,
      route: route,
      data: data,
    );
  }

  static Future<void> createBusinessNotification({
    required String businessId,
    required String type,
    required String title,
    required String body,
    String? recipientUid,
    String? actorUid,
    String? businessName,
    String? route,
    Map<String, dynamic>? data,
  }) {
    return _repository.createBusinessNotification(
      businessId: businessId,
      type: type,
      title: title,
      body: body,
      recipientUid: recipientUid,
      actorUid: actorUid,
      businessName: businessName,
      route: route,
      data: data,
    );
  }

  static Future<void> markRead(String notificationId) {
    return _repository.markRead(notificationId);
  }

  static Future<void> markUnread(String notificationId) {
    return _repository.markUnread(notificationId);
  }
}
