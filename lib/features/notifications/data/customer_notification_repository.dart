import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerNotificationRepository {
  CustomerNotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(CustomerNotificationFieldNames.notifications);

  Stream<List<CustomerNotificationDocument>> watchCustomerNotifications({
    required String uid,
    bool includeMetadataChanges = true,
  }) {
    final controller = StreamController<List<CustomerNotificationDocument>>();
    final merged = <String, CustomerNotificationDocument>{};
    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emit() {
      if (controller.isClosed) return;

      final list = merged.values.toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(list);
    }

    void listenField(String field) {
      final sub = _notifications
          .where(field, isEqualTo: uid)
          .snapshots(includeMetadataChanges: includeMetadataChanges)
          .listen((snapshot) {
            for (final change in snapshot.docChanges) {
              final id = change.doc.id;

              if (change.type == DocumentChangeType.removed) {
                merged.remove(id);
                continue;
              }

              merged[id] = CustomerNotificationDocument.fromDoc(change.doc);
            }

            emit();
          }, onError: (_) => emit());

      subs.add(sub);
    }

    listenField(CustomerNotificationFieldNames.recipientUid);
    listenField(CustomerNotificationFieldNames.targetUid);
    listenField(CustomerNotificationFieldNames.customerUid);
    listenField(CustomerNotificationFieldNames.userId);

    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  Future<void> markCustomerNotificationRead(String id) async {
    await _notifications.doc(id).set(<String, dynamic>{
      CustomerNotificationFieldNames.read: true,
      CustomerNotificationFieldNames.isRead: true,
      CustomerNotificationFieldNames.readAt: DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllCustomerNotificationsRead(
    List<CustomerNotificationDocument> list,
  ) async {
    final batch = _firestore.batch();

    for (final item in list.where((notification) => !notification.read)) {
      final ref = _notifications.doc(item.id);
      batch.set(ref, <String, dynamic>{
        CustomerNotificationFieldNames.read: true,
        CustomerNotificationFieldNames.isRead: true,
        CustomerNotificationFieldNames.readAt: DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}

class CustomerNotificationDocument {
  const CustomerNotificationDocument({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.businessName,
    required this.read,
    required this.createdAt,
  });

  factory CustomerNotificationDocument.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return CustomerNotificationDocument(
      id: doc.id,
      title: data[CustomerNotificationFieldNames.title]?.toString() ?? '',
      body: data[CustomerNotificationFieldNames.body]?.toString() ?? '',
      type:
          data[CustomerNotificationFieldNames.type]?.toString() ??
          CustomerNotificationTypes.general,
      businessName:
          data[CustomerNotificationFieldNames.businessName]?.toString() ?? '',
      read:
          data[CustomerNotificationFieldNames.read] == true ||
          data[CustomerNotificationFieldNames.isRead] == true,
      createdAt:
          (data[CustomerNotificationFieldNames.createdAtLocalIso] ??
                  data[CustomerNotificationFieldNames.createdAt] ??
                  data[CustomerNotificationFieldNames.readAt] ??
                  '')
              .toString(),
    );
  }

  final String id;
  final String title;
  final String body;
  final String type;
  final String businessName;
  final bool read;
  final String createdAt;
}

class CustomerNotificationFieldNames {
  const CustomerNotificationFieldNames._();

  static const notifications = 'notifications';

  static const recipientUid = 'recipientUid';
  static const targetUid = 'targetUid';
  static const customerUid = 'customerUid';
  static const userId = 'userId';

  static const title = 'title';
  static const body = 'body';
  static const type = 'type';
  static const businessName = 'businessName';

  static const read = 'read';
  static const isRead = 'isRead';
  static const readAt = 'readAt';

  static const createdAt = 'createdAt';
  static const createdAtLocalIso = 'createdAtLocalIso';
}

class CustomerNotificationTypes {
  const CustomerNotificationTypes._();

  static const general = 'general';
  static const bulkMessage = 'bulkMessage';
  static const appointment = 'appointment';
  static const message = 'message';
  static const system = 'system';
}
