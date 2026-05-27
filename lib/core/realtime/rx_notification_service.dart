import 'package:cloud_firestore/cloud_firestore.dart';

class RxNotificationService {
  const RxNotificationService._();

  static CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('notifications');

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
  }) async {
    final uid = recipientUid.trim();
    if (uid.isEmpty) return;

    await _safeCreate({
      'recipientUid': uid,
      'targetScope': 'user',
      'businessId': (businessId ?? '').trim(),
      'businessName': (businessName ?? '').trim(),
      'actorUid': (actorUid ?? '').trim(),
      'type': type.trim().isEmpty ? 'general' : type.trim(),
      'title': title.trim().isEmpty ? 'Bildirim' : title.trim(),
      'body': body.trim(),
      'route': (route ?? '').trim(),
      'data': data ?? <String, dynamic>{},
      'isRead': false,
      'readAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtIso': DateTime.now().toIso8601String(),
      'source': 'rx_notification_service_40B',
    });
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
  }) async {
    final bid = businessId.trim();
    if (bid.isEmpty) return;

    await _safeCreate({
      'recipientUid': (recipientUid ?? '').trim(),
      'targetScope': 'business',
      'businessId': bid,
      'businessName': (businessName ?? '').trim(),
      'actorUid': (actorUid ?? '').trim(),
      'type': type.trim().isEmpty ? 'business' : type.trim(),
      'title': title.trim().isEmpty
          ? 'Kurumsal kullanıcı bildirimi'
          : title.trim(),
      'body': body.trim(),
      'route': (route ?? '').trim(),
      'data': data ?? <String, dynamic>{},
      'isRead': false,
      'readAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtIso': DateTime.now().toIso8601String(),
      'source': 'rx_notification_service_40B',
    });
  }

  static Future<void> markRead(String notificationId) async {
    final id = notificationId.trim();
    if (id.isEmpty) return;

    await _col.doc(id).set({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> markUnread(String notificationId) async {
    final id = notificationId.trim();
    if (id.isEmpty) return;

    await _col.doc(id).set({
      'isRead': false,
      'readAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> _safeCreate(Map<String, dynamic> payload) async {
    try {
      await _col.add(payload);
    } catch (_) {
      // Bildirim yazımı ana işlem akışını bozmasın.
    }
  }
}
