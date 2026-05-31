import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/campaigns/campaign_models.dart';

void main() {
  group('CampaignCollections', () {
    test('keeps bulk message drafts business-only', () {
      expect(
        CampaignCollections.businessReadableCampaignCollections,
        contains(CampaignCollections.bulkMessageDrafts),
      );
      expect(
        CampaignCollections.customerReadableCampaignCollections,
        isNot(contains(CampaignCollections.bulkMessageDrafts)),
      );
    });
  });

  group('BulkMessageDraftInput', () {
    test('writes a ready draft payload with permission guard fields', () {
      final input = BulkMessageDraftInput(
        businessId: 'business_1',
        businessName: 'Fi Studio',
        title: 'Mayıs fırsatı',
        message: 'Bugüne özel bakım kampanyası başladı.',
        audience: 'Kampanya izni veren bireysel kullanıcılar',
        channel: 'Uygulama bildirimi',
        consentOnly: true,
        estimatedTargetCount: 120,
      );

      final data = input.toFirestoreMap(
        ownerUid: 'owner_1',
        serverTimestamp: FieldValue.serverTimestamp(),
      );

      expect(data['businessId'], 'business_1');
      expect(data['businessName'], 'Fi Studio');
      expect(data['status'], 'draft');
      expect(data['sendStatus'], 'draft_ready');
      expect(data['consentOnly'], isTrue);
      expect(data['estimatedTargetCount'], 120);
      expect(data['body'], data['message']);
      expect(data['ownerUid'], 'owner_1');
    });

    test('keeps explicit send status when a caller provides one', () {
      final input = BulkMessageDraftInput(
        businessId: 'business_1',
        title: 'Hatırlatma',
        message: 'Randevunuzu unutmayın.',
        audience: 'Son 30 günde randevu alan bireysel kullanıcılar',
        channel: 'Uygulama bildirimi',
        sendStatus: 'scheduled',
      );

      final data = input.toFirestoreMap(
        ownerUid: 'owner_1',
        serverTimestamp: FieldValue.serverTimestamp(),
      );

      expect(data['sendStatus'], 'scheduled');
    });
  });

  group('BulkMessageSendResult', () {
    test('parses callable response counts safely', () {
      final result = BulkMessageSendResult.fromMap(const <String, dynamic>{
        'ok': true,
        'draftId': 'draft_1',
        'attemptId': 'attempt_1',
        'sendStatus': 'sent',
        'targetCount': '12',
        'deliveredNotificationCount': 11,
        'alreadySent': true,
      });

      expect(result.ok, isTrue);
      expect(result.sent, isTrue);
      expect(result.draftId, 'draft_1');
      expect(result.attemptId, 'attempt_1');
      expect(result.alreadySent, isTrue);
      expect(result.targetCount, 12);
      expect(result.deliveredNotificationCount, 11);
    });
  });

  group('CampaignFieldReaders', () {
    test('reads first non-empty string by fallback order', () {
      final value = CampaignFieldReaders.firstString(
        const <String, dynamic>{'title': '  ', 'campaignTitle': 'Bakım Paketi'},
        const <String>['title', 'campaignTitle'],
      );

      expect(value, 'Bakım Paketi');
    });

    test('parses unix milliseconds and ISO date values', () {
      final fromMillis = CampaignFieldReaders.parseDate(1716700000000);
      final fromIso = CampaignFieldReaders.parseDate('2026-05-26T10:15:00');

      expect(fromMillis, isNotNull);
      expect(fromMillis!.year, 2024);
      expect(fromIso, DateTime(2026, 5, 26, 10, 15));
    });
  });
}
