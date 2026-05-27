import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/messages/domain/message_ui_policy.dart';

void main() {
  group('MessageUiPolicy', () {
    test('resolves topic and status labels for message surfaces', () {
      expect(MessageUiPolicy.topicLabel('appointment'), 'Randevu');
      expect(
        MessageUiPolicy.topicLabel('business_customer'),
        'Müşteri görüşmesi',
      );
      expect(
        MessageUiPolicy.customerNewMessageTopics,
        isNot(contains('business_customer')),
      );
      expect(MessageUiPolicy.topicLabel('unknown'), 'Genel');
      expect(MessageUiPolicy.statusLabel('closed'), 'Kapalı');
      expect(MessageUiPolicy.statusLabel('open'), 'Açık');
    });

    test('returns role-aware input and empty inbox copy', () {
      expect(
        MessageUiPolicy.inputHint(isBusinessOwner: true),
        contains('Bireysel kullanıcıya'),
      );
      expect(
        MessageUiPolicy.inputHint(isBusinessOwner: false),
        contains('İşletmeye'),
      );
      expect(
        MessageUiPolicy.emptyInboxTitle(isBusinessOwner: true),
        'Henüz müşteri mesajı yok',
      );
      expect(
        MessageUiPolicy.emptyInboxTitle(isBusinessOwner: false),
        'Henüz mesajınız yok',
      );
    });

    test('computes read receipt from the active role perspective', () {
      expect(
        MessageUiPolicy.readReceipt(
          isBusinessOwner: true,
          readByCustomer: true,
          readByBusiness: false,
        ),
        'Görüldü',
      );
      expect(
        MessageUiPolicy.readReceipt(
          isBusinessOwner: false,
          readByCustomer: true,
          readByBusiness: false,
        ),
        'Gönderildi',
      );
    });
  });
}
