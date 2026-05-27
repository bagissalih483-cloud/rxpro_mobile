import '../campaign_models.dart';

class BusinessCampaignItemViewModel {
  const BusinessCampaignItemViewModel({
    required this.id,
    required this.sourceCollection,
    required this.title,
    required this.description,
    required this.category,
    required this.discountText,
    required this.status,
    required this.visible,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    this.targetCount = 0,
    this.deliveredNotificationCount = 0,
  });

  final String id;
  final String sourceCollection;
  final String title;
  final String description;
  final String category;
  final String discountText;
  final String status;
  final bool visible;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? createdAt;
  final int targetCount;
  final int deliveredNotificationCount;

  DateTime get sortDate => createdAt ?? startAt ?? DateTime(1970);

  bool get isBulkDraft =>
      sourceCollection == CampaignCollections.bulkMessageDrafts;

  String get deliverySummary {
    if (!isBulkDraft) return '';
    if (targetCount <= 0 && deliveredNotificationCount <= 0) {
      return 'Henüz gönderilmedi';
    }
    return '$targetCount hedef / $deliveredNotificationCount bildirim';
  }

  bool get canSendBulkDraft {
    final s = status.toLowerCase().trim();
    return isBulkDraft &&
        visible &&
        (s == 'draft' ||
            s == 'draft_ready' ||
            s == 'ready' ||
            s == 'scheduled' ||
            s == 'send_failed');
  }

  CampaignRecord toCampaignRecord() {
    return CampaignRecord(
      id: id,
      sourceCollection: sourceCollection,
      businessId: '',
      title: title,
      body: description,
      status: status,
      category: category,
      cta: '',
      offer: discountText,
      ownerUid: '',
      startAt: startAt,
      endAt: endAt,
      createdAt: createdAt,
      updatedAt: null,
      raw: const <String, dynamic>{},
    );
  }

  String get statusLabel {
    final s = status.toLowerCase();

    if (!visible ||
        s == 'passive' ||
        s == 'pasif' ||
        s == 'removed' ||
        s == 'yayindan_kaldirildi' ||
        s == 'yayından kaldırıldı') {
      return 'Pasif';
    }

    if (s == 'draft' ||
        s == 'taslak' ||
        s == 'draft_ready' ||
        s == 'ready' ||
        s == 'scheduled') {
      return 'Taslak';
    }
    if (isBulkDraft && s == 'send_failed') return 'Hata';
    if (isBulkDraft && s == 'sent') return 'Gönderildi';
    if (isBulkDraft && s == 'no_eligible_recipients') return 'Hedef yok';
    if (isBulkDraft && s == 'sending') return 'Gönderiliyor';

    return 'Yayında';
  }

  String get dateRange {
    final s = _format(startAt);
    final e = _format(endAt);

    if (s.isEmpty && e.isEmpty) return 'Süre belirtilmedi';
    if (s.isEmpty) return '$e tarihine kadar';
    if (e.isEmpty) return '$s itibarıyla';

    return '$s - $e';
  }

  factory BusinessCampaignItemViewModel.fromRecord(CampaignRecord record) {
    final isBulkDraft =
        record.sourceCollection == CampaignCollections.bulkMessageDrafts;
    final campaignType = CampaignFieldReaders.firstString(
      record.raw,
      const <String>['campaignType'],
    );
    final audience = CampaignFieldReaders.firstString(
      record.raw,
      const <String>['audience', 'target'],
    );
    final channel = CampaignFieldReaders.firstString(
      record.raw,
      const <String>['channel'],
    );
    final sendStatus = CampaignFieldReaders.firstString(
      record.raw,
      const <String>['sendStatus'],
    );
    final targetCount = _readInt(record.raw['targetCount']);
    final deliveredNotificationCount = _readInt(
      record.raw['deliveredNotificationCount'],
    );

    return BusinessCampaignItemViewModel(
      id: record.id,
      sourceCollection: record.sourceCollection,
      title: record.title.trim().isEmpty
          ? (isBulkDraft ? 'Toplu mesaj taslağı' : 'Kampanya')
          : record.title,
      description: record.body.trim().isEmpty
          ? (isBulkDraft
                ? 'Toplu mesaj içeriği henüz girilmedi.'
                : 'Kampanya açıklaması henüz girilmedi.')
          : record.body,
      category: isBulkDraft
          ? 'Toplu mesaj'
          : (record.category.trim().isEmpty ? 'Genel' : record.category),
      discountText: isBulkDraft
          ? _bulkDraftTargetText(audience: audience, channel: channel)
          : _normalizeOffer(
              record.offer.trim().isEmpty ? 'Özel fırsat' : record.offer,
              campaignType,
            ),
      status: isBulkDraft && sendStatus.trim().isNotEmpty
          ? sendStatus
          : record.status,
      visible: record.visible,
      startAt: record.startAt,
      endAt: record.endAt,
      createdAt: record.createdAt,
      targetCount: targetCount,
      deliveredNotificationCount: deliveredNotificationCount,
    );
  }

  static String _bulkDraftTargetText({
    required String audience,
    required String channel,
  }) {
    final target = audience.trim().isEmpty ? 'Hedef grup seçildi' : audience;
    final delivery = channel.trim().isEmpty ? '' : ' • $channel';
    return '$target$delivery';
  }

  static String _normalizeOffer(String value, String type) {
    final text = value.trim();
    if (text.isEmpty) return 'Özel fırsat';

    if (type == 'percent') {
      final clean = text.replaceAll('%', '').trim();
      return clean.isEmpty ? text : '%$clean';
    }

    if (type == 'amount') {
      return text.toLowerCase().contains('tl') ? text : '$text TL';
    }

    return text;
  }

  static String _format(DateTime? date) {
    if (date == null) return '';

    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();

    return '$d.$m.$y';
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
