import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

/// Notification service foundation.
///
/// 51C-T foundation only:
/// - This service is NOT wired into UI yet.
/// - Existing notification writes remain unchanged.
/// - Existing Cloud Functions push trigger remains untouched.
/// - Rules/index deploy is not touched.
///
/// Future target:
/// UI / Domain Service -> NotificationService -> notifications collection
class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection(FirestoreCollections.notifications);

  CollectionReference<Map<String, dynamic>> get _customerNotifications =>
      _db.collection(FirestoreCollections.customerNotifications);

  Future<DocumentReference<Map<String, dynamic>>> createNotification({
    required String targetUid,
    required String title,
    required String body,
    String targetScope = 'user',
    String type = 'general',
    String notificationType = 'general',
    String businessId = '',
    String businessName = '',
    String receiverUid = '',
    String customerUid = '',
    String userId = '',
    String threadId = '',
    String messageId = '',
    String source = 'notification_service_51C_T',
    String sourceModule = 'notification_service_51C_T',
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final cleanTargetUid = targetUid.trim();
    final cleanTargetScope = targetScope.trim().isEmpty
        ? 'user'
        : targetScope.trim().toLowerCase();

    final data = <String, dynamic>{
      ...extra,
      FirestoreFields.targetScope: cleanTargetScope,
      FirestoreFields.recipientUid: cleanTargetUid,
      FirestoreFields.targetUid: cleanTargetUid,
      FirestoreFields.userId: userId.trim().isNotEmpty
          ? userId.trim()
          : cleanTargetUid,
      FirestoreFields.receiverUid: receiverUid.trim().isNotEmpty
          ? receiverUid.trim()
          : cleanTargetUid,
      FirestoreFields.customerUid: customerUid.trim().isNotEmpty
          ? customerUid.trim()
          : cleanTargetUid,
      FirestoreFields.businessId: businessId.trim(),
      FirestoreFields.businessName: businessName.trim(),
      FirestoreFields.type: type,
      FirestoreFields.notificationType: notificationType,
      FirestoreFields.title: title,
      FirestoreFields.body: body,
      FirestoreFields.message: body,
      FirestoreFields.threadId: threadId.trim(),
      FirestoreFields.messageId: messageId.trim(),
      FirestoreFields.isRead: false,
      FirestoreFields.read: false,
      FirestoreFields.readAt: null,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdAtIso: DateTime.now().toIso8601String(),
      FirestoreFields.source: source,
      FirestoreFields.sourceModule: sourceModule,
    };

    return _notifications.add(data);
  }

  /// 51C-T compatibility helper for the legacy customerNotifications mirror.
  ///
  /// Not wired yet. It exists to move old mirror writes out of UI later.
  Future<DocumentReference<Map<String, dynamic>>> createCustomerNotification({
    required String targetUid,
    required String title,
    required String body,
    String targetScope = 'user',
    String type = 'general',
    String notificationType = 'general',
    String businessId = '',
    String businessName = '',
    String receiverUid = '',
    String customerUid = '',
    String userId = '',
    String threadId = '',
    String messageId = '',
    String source = 'notification_service_51C_T',
    String sourceModule = 'notification_service_51C_T',
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final cleanTargetUid = targetUid.trim();
    final cleanTargetScope = targetScope.trim().isEmpty
        ? 'user'
        : targetScope.trim().toLowerCase();

    final data = <String, dynamic>{
      ...extra,
      FirestoreFields.targetScope: cleanTargetScope,
      FirestoreFields.recipientUid: cleanTargetUid,
      FirestoreFields.targetUid: cleanTargetUid,
      FirestoreFields.userId: userId.trim().isNotEmpty
          ? userId.trim()
          : cleanTargetUid,
      FirestoreFields.receiverUid: receiverUid.trim().isNotEmpty
          ? receiverUid.trim()
          : cleanTargetUid,
      FirestoreFields.customerUid: customerUid.trim().isNotEmpty
          ? customerUid.trim()
          : cleanTargetUid,
      FirestoreFields.businessId: businessId.trim(),
      FirestoreFields.businessName: businessName.trim(),
      FirestoreFields.type: type,
      FirestoreFields.notificationType: notificationType,
      FirestoreFields.title: title,
      FirestoreFields.body: body,
      FirestoreFields.message: body,
      FirestoreFields.threadId: threadId.trim(),
      FirestoreFields.messageId: messageId.trim(),
      FirestoreFields.isRead: false,
      FirestoreFields.read: false,
      FirestoreFields.readAt: null,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdAtIso: DateTime.now().toIso8601String(),
      FirestoreFields.source: source,
      FirestoreFields.sourceModule: sourceModule,
    };

    return _customerNotifications.add(data);
  }

  Future<void> markNotificationRead(String notificationId) {
    final cleanId = notificationId.trim();
    if (cleanId.isEmpty) return Future<void>.value();

    return _notifications.doc(cleanId).set(<String, dynamic>{
      FirestoreFields.isRead: true,
      FirestoreFields.read: true,
      FirestoreFields.readAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.sourceModule: 'notification_service_51C_T',
    }, SetOptions(merge: true));
  }
}
