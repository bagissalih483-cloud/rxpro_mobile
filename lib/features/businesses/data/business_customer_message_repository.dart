import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/services/app_observability_service.dart';

class BusinessCustomerMessageRepository {
  BusinessCustomerMessageRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> sendMessage(BusinessCustomerMessageDraft draft) async {
    final text = draft.text.trim();
    if (text.isEmpty) {
      throw ArgumentError.value(draft.text, 'text', 'message cannot be empty');
    }

    final nowIso = DateTime.now().toIso8601String();
    final messageId = _firestore.collection('_ids').doc().id;
    final senderUid = _auth.currentUser?.uid ?? draft.businessId;
    final senderName = draft.businessName.trim().isEmpty
        ? 'İşletme'
        : draft.businessName.trim();

    final threadData = <String, dynamic>{
      FirestoreFields.threadId: draft.threadId,
      FirestoreFields.businessId: draft.businessId,
      FirestoreFields.businessName: draft.businessName,
      FirestoreFields.businessUid: draft.businessId,
      FirestoreFields.senderUid: senderUid,
      FirestoreFields.senderName: senderName,
      FirestoreFields.customerUid: draft.customerUid,
      FirestoreFields.customerId: draft.customerUid,
      FirestoreFields.userId: draft.customerUid,
      FirestoreFields.targetUid: draft.customerUid,
      FirestoreFields.receiverUid: draft.customerUid,
      FirestoreFields.customerName: draft.customerName,
      FirestoreFields.customerEmail: draft.customerEmail,
      FirestoreFields.customerPhone: draft.customerPhone,
      FirestoreFields.participants: [draft.businessId, draft.customerUid],
      FirestoreFields.participantUids: [draft.businessId, draft.customerUid],
      FirestoreFields.userIds: [draft.businessId, draft.customerUid],
      FirestoreFields.type: 'business_customer',
      FirestoreFields.chatType: 'business_customer',
      FirestoreFields.lastMessage: text,
      FirestoreFields.lastMessageText: text,
      FirestoreFields.lastMessageSenderRole: 'business',
      FirestoreFields.lastSenderRole: 'business',
      FirestoreFields.unreadForCustomer: true,
      FirestoreFields.unreadForBusiness: false,
      FirestoreFields.status: 'open',
      FirestoreFields.topic: 'business_customer',
      FirestoreFields.lastMessageAt: FieldValue.serverTimestamp(),
      FirestoreFields.lastMessageAtLocalIso: nowIso,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAtLocalIso: nowIso,
      FirestoreFields.createdAtLocalIso: nowIso,
      FirestoreFields.source: 'business_customer_direct_message_page',
    };

    final messageData = <String, dynamic>{
      FirestoreFields.messageId: messageId,
      FirestoreFields.threadId: draft.threadId,
      FirestoreFields.conversationId: draft.threadId,
      FirestoreFields.chatId: draft.threadId,
      FirestoreFields.businessId: draft.businessId,
      FirestoreFields.businessName: draft.businessName,
      FirestoreFields.businessUid: draft.businessId,
      FirestoreFields.customerUid: draft.customerUid,
      FirestoreFields.customerId: draft.customerUid,
      FirestoreFields.userId: draft.customerUid,
      FirestoreFields.targetUid: draft.customerUid,
      FirestoreFields.receiverUid: draft.customerUid,
      FirestoreFields.toUid: draft.customerUid,
      FirestoreFields.customerName: draft.customerName,
      FirestoreFields.customerEmail: draft.customerEmail,
      FirestoreFields.customerPhone: draft.customerPhone,
      FirestoreFields.senderUid: senderUid,
      FirestoreFields.senderName: senderName,
      FirestoreFields.senderRole: 'business',
      FirestoreFields.senderType: 'business',
      FirestoreFields.fromRole: 'business',
      FirestoreFields.receiverRole: 'customer',
      FirestoreFields.toRole: 'customer',
      FirestoreFields.body: text,
      FirestoreFields.message: text,
      FirestoreFields.text: text,
      FirestoreFields.content: text,
      FirestoreFields.messageType: 'text',
      FirestoreFields.recalled: false,
      FirestoreFields.readByCustomer: false,
      FirestoreFields.readByBusiness: true,
      FirestoreFields.isRead: false,
      FirestoreFields.read: false,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdAtLocalIso: nowIso,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.source: 'business_customer_direct_message_page',
    };

    final notificationData = <String, dynamic>{
      FirestoreFields.targetUid: draft.customerUid,
      FirestoreFields.userId: draft.customerUid,
      FirestoreFields.customerUid: draft.customerUid,
      FirestoreFields.receiverUid: draft.customerUid,
      FirestoreFields.businessId: draft.businessId,
      FirestoreFields.businessName: draft.businessName,
      FirestoreFields.type: 'business_customer_message',
      FirestoreFields.notificationType: 'message',
      'title': '${draft.businessName} mesaj gönderdi',
      FirestoreFields.body: text,
      FirestoreFields.message: text,
      FirestoreFields.threadId: draft.threadId,
      FirestoreFields.isRead: false,
      FirestoreFields.read: false,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdAtLocalIso: nowIso,
      FirestoreFields.source: 'business_customer_direct_message_page',
    };

    var reliableWriteCount = 0;

    if (await _safeWrite(
      _firestore
          .collection(FirestoreCollections.chatThreads)
          .doc(draft.threadId)
          .set({
            ...threadData,
            FirestoreFields.createdAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
    )) {
      reliableWriteCount++;
    }

    await _safeWrite(
      _firestore
          .collection(FirestoreCollections.chatThreads)
          .doc(draft.threadId)
          .collection(FirestoreCollections.messages)
          .doc(messageId)
          .set(messageData, SetOptions(merge: true)),
    );

    await _safeWrite(
      _firestore
          .collection(FirestoreCollections.messageThreads)
          .doc(draft.threadId)
          .set({
            ...threadData,
            FirestoreFields.createdAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
    );

    await _safeWrite(
      _firestore
          .collection(FirestoreCollections.messageThreads)
          .doc(draft.threadId)
          .collection(FirestoreCollections.messages)
          .doc(messageId)
          .set(messageData, SetOptions(merge: true)),
    );

    await _safeWrite(
      _firestore
          .collection(FirestoreCollections.conversations)
          .doc(draft.threadId)
          .set({
            ...threadData,
            FirestoreFields.createdAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
    );

    await _safeWrite(
      _firestore
          .collection(FirestoreCollections.conversations)
          .doc(draft.threadId)
          .collection(FirestoreCollections.messages)
          .doc(messageId)
          .set(messageData, SetOptions(merge: true)),
    );

    if (await _safeWrite(
      _firestore
          .collection(FirestoreCollections.businessCustomerMessages)
          .doc(messageId)
          .set(messageData, SetOptions(merge: true)),
    )) {
      reliableWriteCount++;
    }

    if (await _safeWrite(
      _firestore
          .collection(FirestoreCollections.messages)
          .doc(messageId)
          .set(messageData, SetOptions(merge: true)),
    )) {
      reliableWriteCount++;
    }

    await _safeWrite(
      _firestore
          .collection(FirestoreCollections.customerMessages)
          .doc(messageId)
          .set(messageData, SetOptions(merge: true)),
    );

    await _safeWrite(
      _firestore
          .collection(FirestoreCollections.directMessages)
          .doc(messageId)
          .set(messageData, SetOptions(merge: true)),
    );

    await _safeWrite(
      _firestore
          .collection(FirestoreCollections.userMessages)
          .doc(draft.customerUid)
          .collection(FirestoreCollections.messages)
          .doc(messageId)
          .set(messageData, SetOptions(merge: true)),
    );

    await _safeWrite(
      _firestore
          .collection(FirestoreCollections.users)
          .doc(draft.customerUid)
          .collection(FirestoreCollections.messages)
          .doc(messageId)
          .set(messageData, SetOptions(merge: true)),
    );

    if (await _safeWrite(
      _firestore
          .collection(FirestoreCollections.notifications)
          .doc()
          .set(notificationData),
    )) {
      reliableWriteCount++;
    }

    await _safeWrite(
      _firestore
          .collection(FirestoreCollections.customerNotifications)
          .doc()
          .set(notificationData),
    );

    if (reliableWriteCount == 0) {
      throw StateError('Message could not be written to any primary store.');
    }

    await AppObservabilityService.instance.logMessageSent(
      threadId: draft.threadId,
      senderRole: 'business',
      businessId: draft.businessId,
    );
  }

  Future<bool> _safeWrite(Future<dynamic> future) async {
    try {
      await future;
      return true;
    } catch (_) {
      return false;
    }
  }
}

class BusinessCustomerMessageDraft {
  const BusinessCustomerMessageDraft({
    required this.threadId,
    required this.businessId,
    required this.businessName,
    required this.customerUid,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.text,
  });

  final String threadId;
  final String businessId;
  final String businessName;
  final String customerUid;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String text;
}
