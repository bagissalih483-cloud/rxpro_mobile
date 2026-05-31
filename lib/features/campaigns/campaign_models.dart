import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignCollections {
  const CampaignCollections._();

  static const String campaigns = 'campaigns';
  static const String businessCampaigns = 'businessCampaigns';
  static const String campaignReports = 'campaignReports';
  static const String bulkMessageDrafts = 'bulkMessageDrafts';

  static const List<String> businessReadableCampaignCollections = <String>[
    businessCampaigns,
    bulkMessageDrafts,
  ];

  static const List<String> customerReadableCampaignCollections = <String>[
    businessCampaigns,
  ];
}

class CampaignBusinessContext {
  const CampaignBusinessContext({
    required this.businessId,
    required this.businessName,
    required this.ownerUid,
    required this.sourceCollection,
  });

  final String businessId;
  final String businessName;
  final String ownerUid;
  final String sourceCollection;

  bool get isResolved => businessId.trim().isNotEmpty;

  factory CampaignBusinessContext.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String sourceCollection,
  }) {
    final data = doc.data() ?? <String, dynamic>{};
    return CampaignBusinessContext(
      businessId: doc.id,
      businessName: CampaignFieldReaders.firstString(data, const <String>[
        'businessName',
        'name',
        'title',
        'displayName',
      ]),
      ownerUid: CampaignFieldReaders.firstString(data, const <String>[
        'ownerUid',
        'ownerId',
        'uid',
        'userId',
      ]),
      sourceCollection: sourceCollection,
    );
  }
}

class CampaignRecord {
  const CampaignRecord({
    required this.id,
    required this.sourceCollection,
    required this.businessId,
    required this.title,
    required this.body,
    required this.status,
    required this.category,
    required this.cta,
    required this.offer,
    required this.ownerUid,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
    required this.raw,
  });

  final String id;
  final String sourceCollection;
  final String businessId;
  final String title;
  final String body;
  final String status;
  final String category;
  final String cta;
  final String offer;
  final String ownerUid;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  bool get isPublished {
    final normalized = status.toLowerCase().trim();
    return normalized == 'published' ||
        normalized == 'active' ||
        normalized == 'aktif' ||
        normalized == 'yayinda' ||
        normalized == 'yayında';
  }

  bool get isDraft {
    final normalized = status.toLowerCase().trim();
    return normalized == 'draft' ||
        normalized == 'taslak' ||
        normalized == 'pending';
  }

  bool get isPassive {
    final normalized = status.toLowerCase().trim();
    return normalized == 'passive' ||
        normalized == 'pasif' ||
        normalized == 'archived' ||
        normalized == 'unpublished';
  }

  bool get visible {
    final moderationStatus = CampaignFieldReaders.firstString(
      raw,
      const <String>['moderationStatus', 'reviewStatus'],
    ).toLowerCase();
    final hidden =
        raw['hidden'] == true ||
        raw['isHidden'] == true ||
        moderationStatus == 'hidden' ||
        moderationStatus == 'blocked' ||
        moderationStatus == 'removed';

    return !isPassive && !hidden;
  }

  DateTime get sortDate {
    return updatedAt ??
        createdAt ??
        startAt ??
        endAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory CampaignRecord.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String sourceCollection,
  }) {
    final data = doc.data() ?? <String, dynamic>{};
    return CampaignRecord(
      id: doc.id,
      sourceCollection: sourceCollection,
      businessId: CampaignFieldReaders.firstString(data, const <String>[
        'businessId',
        'businessDocId',
        'companyId',
      ]),
      title: CampaignFieldReaders.firstString(data, const <String>[
        'title',
        'campaignTitle',
        'headline',
      ]),
      body: CampaignFieldReaders.firstString(data, const <String>[
        'body',
        'message',
        'description',
        'text',
      ]),
      status: CampaignFieldReaders.firstString(data, const <String>[
        'status',
        'state',
      ]),
      category: CampaignFieldReaders.firstString(data, const <String>[
        'category',
        'businessCategory',
        'targetCategory',
      ]),
      cta: CampaignFieldReaders.firstString(data, const <String>[
        'cta',
        'callToAction',
        'buttonText',
      ]),
      offer: CampaignFieldReaders.firstString(data, const <String>[
        'offer',
        'discount',
        'discountText',
        'campaignOffer',
      ]),
      ownerUid: CampaignFieldReaders.firstString(data, const <String>[
        'ownerUid',
        'createdBy',
        'uid',
      ]),
      startAt: CampaignFieldReaders.firstDate(data, const <String>[
        'startAt',
        'startsAt',
        'startDate',
      ]),
      endAt: CampaignFieldReaders.firstDate(data, const <String>[
        'endAt',
        'endsAt',
        'endDate',
      ]),
      createdAt: CampaignFieldReaders.firstDate(data, const <String>[
        'createdAt',
        'createdDate',
      ]),
      updatedAt: CampaignFieldReaders.firstDate(data, const <String>[
        'updatedAt',
        'publishedAt',
      ]),
      raw: Map<String, dynamic>.from(data),
    );
  }
}

class CampaignDraftInput {
  const CampaignDraftInput({
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.body,
    required this.offer,
    required this.audience,
    required this.notes,
    required this.category,
    required this.cta,
    required this.startAt,
    required this.endAt,
    this.clientRequestKey,
    this.aiPayload,
    this.tone = '',
    this.source = 'campaign_service',
    this.status = 'published',
    this.visible = true,
  });

  final String businessId;
  final String businessName;
  final String title;
  final String body;
  final String offer;
  final String audience;
  final String notes;
  final String category;
  final String cta;
  final DateTime startAt;
  final DateTime endAt;
  final String? clientRequestKey;
  final Map<String, dynamic>? aiPayload;
  final String tone;
  final String source;
  final String status;
  final bool visible;

  Map<String, dynamic> toFirestoreMap({
    required String ownerUid,
    required FieldValue serverTimestamp,
  }) {
    return <String, dynamic>{
      'businessId': businessId.trim(),
      'businessName': businessName.trim(),
      'title': title.trim(),
      'body': body.trim(),
      'description': body.trim(),
      'offer': offer.trim(),
      'audience': audience.trim(),
      'notes': notes.trim(),
      'category': category.trim(),
      'cta': cta.trim(),
      'tone': tone.trim(),
      'status': status.trim().isEmpty ? 'published' : status.trim(),
      'ownerUid': ownerUid.trim(),
      'createdBy': ownerUid.trim(),
      'isVisible': visible,
      'visible': visible,
      'isActive': visible,
      'published': visible,
      'startAt': Timestamp.fromDate(startAt),
      'startDate': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'endDate': Timestamp.fromDate(endAt),
      'updatedAt': serverTimestamp,
      'createdAt': serverTimestamp,
      'source': source.trim().isEmpty ? 'campaign_service' : source.trim(),
      if (clientRequestKey != null && clientRequestKey!.trim().isNotEmpty)
        'clientRequestKey': clientRequestKey!.trim(),
      if (aiPayload != null) 'aiPayload': aiPayload,
    };
  }
}

class BulkMessageDraftInput {
  const BulkMessageDraftInput({
    required this.businessId,
    this.businessName = '',
    required this.title,
    required this.message,
    required this.audience,
    required this.channel,
    this.consentOnly = true,
    this.estimatedTargetCount = 0,
    this.sendStatus = 'draft_ready',
    this.source = 'campaign_service',
    this.scheduledAt,
    this.audienceMetadata,
  });

  final String businessId;
  final String businessName;
  final String title;
  final String message;
  final String audience;
  final String channel;
  final bool consentOnly;
  final int estimatedTargetCount;
  final String sendStatus;
  final String source;
  final DateTime? scheduledAt;
  final Map<String, dynamic>? audienceMetadata;

  BulkMessageDraftInput copyWith({
    String? businessId,
    String? businessName,
    String? title,
    String? message,
    String? audience,
    String? channel,
    bool? consentOnly,
    int? estimatedTargetCount,
    String? sendStatus,
    String? source,
    DateTime? scheduledAt,
    Map<String, dynamic>? audienceMetadata,
  }) {
    return BulkMessageDraftInput(
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      title: title ?? this.title,
      message: message ?? this.message,
      audience: audience ?? this.audience,
      channel: channel ?? this.channel,
      consentOnly: consentOnly ?? this.consentOnly,
      estimatedTargetCount: estimatedTargetCount ?? this.estimatedTargetCount,
      sendStatus: sendStatus ?? this.sendStatus,
      source: source ?? this.source,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      audienceMetadata: audienceMetadata ?? this.audienceMetadata,
    );
  }

  Map<String, dynamic> toFirestoreMap({
    required String ownerUid,
    required FieldValue serverTimestamp,
  }) {
    return <String, dynamic>{
      'businessId': businessId.trim(),
      'businessName': businessName.trim(),
      'title': title.trim(),
      'message': message.trim(),
      'body': message.trim(),
      'audience': audience.trim(),
      'target': audience.trim(),
      'channel': channel.trim(),
      'consentOnly': consentOnly,
      'estimatedTargetCount': estimatedTargetCount,
      'ownerUid': ownerUid.trim(),
      'createdBy': ownerUid.trim(),
      'status': 'draft',
      'sendStatus': sendStatus.trim().isEmpty
          ? 'draft_ready'
          : sendStatus.trim(),
      'source': source.trim().isEmpty ? 'campaign_service' : source.trim(),
      'createdAt': serverTimestamp,
      'updatedAt': serverTimestamp,
      if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt!),
      if (audienceMetadata != null && audienceMetadata!.isNotEmpty)
        'audienceMetadata': Map<String, dynamic>.from(audienceMetadata!),
    };
  }
}

class BulkMessageSendResult {
  const BulkMessageSendResult({
    required this.ok,
    required this.draftId,
    required this.attemptId,
    required this.sendStatus,
    required this.targetCount,
    required this.deliveredNotificationCount,
    this.alreadySent = false,
    this.alreadySending = false,
  });

  final bool ok;
  final String draftId;
  final String attemptId;
  final String sendStatus;
  final int targetCount;
  final int deliveredNotificationCount;
  final bool alreadySent;
  final bool alreadySending;

  bool get sent => sendStatus == 'sent';
  bool get hasNoEligibleRecipients => sendStatus == 'no_eligible_recipients';

  factory BulkMessageSendResult.fromMap(Map<String, dynamic> data) {
    return BulkMessageSendResult(
      ok: data['ok'] == true,
      draftId: data['draftId']?.toString().trim() ?? '',
      attemptId: data['attemptId']?.toString().trim() ?? '',
      sendStatus: data['sendStatus']?.toString().trim() ?? '',
      targetCount: _intValue(data['targetCount']),
      deliveredNotificationCount: _intValue(data['deliveredNotificationCount']),
      alreadySent: data['alreadySent'] == true,
      alreadySending: data['alreadySending'] == true,
    );
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CampaignFieldReaders {
  const CampaignFieldReaders._();

  static String firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static DateTime? firstDate(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      final parsed = parseDate(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  static DateTime? parseDate(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
