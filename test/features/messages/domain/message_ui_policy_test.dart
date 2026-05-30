import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/messages/domain/message_ui_policy.dart';

void main() {
  group('MessageUiPolicy', () {
    test('resolves topic and status labels for message surfaces', () {
      expect(MessageUiPolicy.topicLabel('appointment'), 'Randevu');
      expect(
        MessageUiPolicy.topicLabel('business_customer'),
        'Musteri gorusmesi',
      );
      expect(
        MessageUiPolicy.customerNewMessageTopics,
        isNot(contains('business_customer')),
      );
      expect(MessageUiPolicy.topicLabel('unknown'), 'Genel');
      expect(MessageUiPolicy.statusLabel('closed'), 'Kapali');
      expect(MessageUiPolicy.statusLabel('open'), 'Acik');
    });

    test('returns role-aware input and empty inbox copy', () {
      expect(
        MessageUiPolicy.inputHint(isBusinessOwner: true),
        contains('Bireysel kullaniciya'),
      );
      expect(
        MessageUiPolicy.inputHint(isBusinessOwner: false),
        contains('Isletmeye'),
      );
      expect(
        MessageUiPolicy.emptyInboxTitle(isBusinessOwner: true),
        'Henuz musteri mesaji yok',
      );
      expect(
        MessageUiPolicy.emptyInboxTitle(isBusinessOwner: false),
        'Henuz mesajiniz yok',
      );
    });

    test('computes read receipt from the active role perspective', () {
      expect(
        MessageUiPolicy.readReceipt(
          isBusinessOwner: true,
          readByCustomer: true,
          readByBusiness: false,
        ),
        'Goruldu',
      );
      expect(
        MessageUiPolicy.readReceipt(
          isBusinessOwner: false,
          readByCustomer: true,
          readByBusiness: false,
        ),
        'Gonderildi',
      );
    });

    test('computes unread badge state from the active role perspective', () {
      expect(
        MessageUiPolicy.threadUnread(
          isBusinessOwner: true,
          unreadForCustomer: true,
          unreadForBusiness: false,
        ),
        isFalse,
      );
      expect(
        MessageUiPolicy.threadUnread(
          isBusinessOwner: false,
          unreadForCustomer: true,
          unreadForBusiness: false,
        ),
        isTrue,
      );
    });
  });
}
