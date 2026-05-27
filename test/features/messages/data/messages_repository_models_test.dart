import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/messages/data/messages_repository.dart';

void main() {
  group('Message repository models', () {
    test('MessageItem reads server timestamp as sortable ISO text', () {
      final item = MessageItem.fromData(
        id: 'msg_1',
        data: <String, dynamic>{
          FirestoreFields.senderUid: 'owner_1',
          FirestoreFields.senderName: 'Fix Studio',
          FirestoreFields.senderRole: 'business',
          FirestoreFields.text: 'Merhaba',
          FirestoreFields.readByCustomer: false,
          FirestoreFields.readByBusiness: true,
          FirestoreFields.createdAt: Timestamp.fromDate(
            DateTime.utc(2026, 5, 26, 12),
          ),
        },
      );

      expect(item.createdAt, '2026-05-26T12:00:00.000Z');
      expect(item.senderUid, 'owner_1');
      expect(item.readByBusiness, isTrue);
    });

    test('MessageThreadItem falls back to local ISO last message date', () {
      final item = MessageThreadItem.fromData(
        id: 'thread_1',
        data: const <String, dynamic>{
          FirestoreFields.businessId: 'business_1',
          FirestoreFields.businessName: 'Fix Studio',
          FirestoreFields.customerUid: 'user_1',
          FirestoreFields.customerName: 'Ayşe',
          FirestoreFields.lastMessage: 'Görüşmek üzere',
          FirestoreFields.lastMessageAtLocalIso: '2026-05-26T15:00:00',
          FirestoreFields.unreadForCustomer: true,
          FirestoreFields.topic: 'business_customer',
        },
      );

      expect(item.lastMessageAt, '2026-05-26T15:00:00.000');
      expect(item.unreadForCustomer, isTrue);
      expect(item.topic, 'business_customer');
    });

    test('MessageBusinessItem detects self-owned businesses safely', () {
      const item = MessageBusinessItem(
        id: 'business_1',
        name: 'Fix Studio',
        category: 'Güzellik',
        ownerUids: <String>['owner_1', 'owner_2'],
      );

      expect(item.isOwnedBy('owner_1'), isTrue);
      expect(item.isOwnedBy(' owner_2 '), isTrue);
      expect(item.isOwnedBy('customer_1'), isFalse);
      expect(item.isOwnedBy(''), isFalse);
    });
  });
}
