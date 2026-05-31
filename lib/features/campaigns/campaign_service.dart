import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import '../../core/realtime/rx_notification_service.dart';
import '../../core/services/app_observability_service.dart';
import 'campaign_models.dart';
import 'campaign_repository.dart';
import 'domain/campaign_ai_response_decoder.dart';

class CampaignService {
  CampaignService({
    CampaignRepository? repository,
    FirebaseFunctions? functions,
  }) : _repository = repository ?? CampaignRepository(),
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final CampaignRepository _repository;
  final FirebaseFunctions _functions;

  Future<CampaignBusinessContext?> resolveOwnedBusinessForCurrentUser() {
    return _repository.resolveOwnedBusinessForCurrentUser();
  }

  Future<List<CampaignRecord>> listBusinessCampaigns({
    required String businessId,
    int limit = 300,
  }) {
    return _repository.listBusinessCampaigns(
      businessId: businessId,
      limit: limit,
    );
  }

  Future<List<CampaignRecord>> listCustomerCampaigns({int limit = 300}) {
    return _repository.listCustomerCampaigns(limit: limit);
  }

  Future<Map<String, dynamic>> generateCampaignAi(
    Map<String, dynamic> payload,
  ) async {
    final projectId = Firebase.app().options.projectId.trim();

    if (projectId.isEmpty) {
      throw Exception('Firebase projectId bulunamadı.');
    }

    final idToken = await _repository.currentUser?.getIdToken();
    final uri = Uri.parse(
      'https://europe-west1-$projectId.cloudfunctions.net/generateCampaignAiHttp',
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            if ((idToken ?? '').trim().isNotEmpty)
              'Authorization': 'Bearer $idToken',
          },
          body: utf8.encode(jsonEncode(payload)),
        )
        .timeout(const Duration(seconds: 60));

    final decoded = CampaignAiResponseDecoder.decodeBodyBytes(
      response.bodyBytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _firstNonEmpty(decoded, const [
        'error',
        'message',
        'details',
      ]);

      throw Exception(
        message.isEmpty
            ? 'HTTP ${response.statusCode}: AI endpoint başarısız döndü.'
            : 'HTTP ${response.statusCode}: $message',
      );
    }

    if (decoded.isEmpty) {
      throw Exception('AI endpoint boş cevap döndürdü.');
    }

    return decoded;
  }

  Future<void> markCampaignPassive(CampaignRecord campaign) {
    return _repository.markCampaignPassive(campaign);
  }

  Future<void> reportCampaign({
    required CampaignRecord campaign,
    required String reason,
  }) {
    return _repository.reportCampaign(campaign: campaign, reason: reason);
  }

  Future<DocumentReference<Map<String, dynamic>>> createBulkMessageDraft(
    BulkMessageDraftInput input,
  ) async {
    final context = await _effectiveBusinessContext(
      businessId: input.businessId,
      businessName: input.businessName,
    );

    _require(context.businessId, 'İşletme hesabı bilgisi bulunamadı.');
    _require(input.title, 'Mesaj başlığı zorunludur.');
    _require(input.message, 'Mesaj içeriği zorunludur.');

    if (!input.consentOnly) {
      throw StateError('Toplu mesaj taslağı için izin kuralı zorunludur.');
    }

    return _repository.createBulkMessageDraft(
      input.copyWith(
        businessId: context.businessId,
        businessName: context.businessName,
        source: input.source.trim().isEmpty
            ? 'campaign_service_bulk_message'
            : input.source,
      ),
    );
  }

  Future<BulkMessageSendResult> sendBulkMessageDraft(String draftId) async {
    final id = draftId.trim();
    if (id.isEmpty) {
      throw StateError('Toplu mesaj taslak bilgisi bulunamadı.');
    }

    final callable = _functions.httpsCallable('sendBulkMessageDraft');
    final response = await callable.call(<String, dynamic>{'draftId': id});
    final payload = response.data;

    if (payload is! Map) {
      throw StateError('Toplu mesaj servisi geçersiz cevap döndürdü.');
    }

    return BulkMessageSendResult.fromMap(Map<String, dynamic>.from(payload));
  }

  Future<CampaignPublishResult> publishCampaign(
    CampaignPublishInput input,
  ) async {
    final context = await _effectiveBusinessContext(
      businessId: input.businessId,
      businessName: input.businessName,
    );

    _require(context.businessId, 'İşletme hesabı bilgisi bulunamadı.');
    _require(input.title, 'Kampanya başlığı zorunludur.');
    _require(input.body, 'Kampanya metni zorunludur.');

    final requestKey = input.clientRequestKey.trim();
    if (requestKey.isNotEmpty) {
      final existing = await _repository.findBusinessCampaignByClientRequestKey(
        requestKey,
      );

      if (existing != null) {
        return CampaignPublishResult.duplicate(
          campaignId: existing.id,
          clientRequestKey: requestKey,
        );
      }
    }

    final doc = await _repository.createBusinessCampaignDraft(
      CampaignDraftInput(
        businessId: context.businessId,
        businessName: context.businessName,
        title: input.title,
        body: input.body,
        offer: input.offer,
        audience: input.audience,
        notes: input.notes,
        category: input.category,
        cta: input.cta,
        tone: input.tone,
        startAt: input.startAt,
        endAt: input.endAt,
        clientRequestKey: requestKey.isEmpty ? null : requestKey,
        aiPayload: input.aiPayload,
        source: input.source.trim().isEmpty
            ? 'campaign_service_publish'
            : input.source,
        status: 'active',
        visible: true,
      ),
    );

    await RxNotificationService.createBusinessNotification(
      businessId: context.businessId,
      businessName: context.businessName,
      recipientUid: _repository.currentUser?.uid,
      actorUid: _repository.currentUser?.uid,
      type: 'campaign_published',
      title: 'Kampanya yayınlandı',
      body: input.title.trim().isEmpty
          ? 'Yeni kampanya başarıyla yayına alındı.'
          : input.title.trim(),
      route: 'businessCampaigns',
      data: <String, dynamic>{
        'campaignId': doc.id,
        if (requestKey.isNotEmpty) 'clientRequestKey': requestKey,
        'category': input.category,
        'tone': input.tone,
      },
    );

    await AppObservabilityService.instance.logCampaignCreated(
      campaignId: doc.id,
      businessId: context.businessId,
      category: input.category,
    );

    return CampaignPublishResult.created(
      campaignId: doc.id,
      clientRequestKey: requestKey,
    );
  }

  Future<_CampaignBusinessValues> _effectiveBusinessContext({
    required String businessId,
    required String businessName,
  }) async {
    final cleanBusinessId = businessId.trim();
    final cleanBusinessName = businessName.trim();

    if (cleanBusinessId.isNotEmpty) {
      return _CampaignBusinessValues(
        businessId: cleanBusinessId,
        businessName: cleanBusinessName.isEmpty ? 'İşletme' : cleanBusinessName,
      );
    }

    final resolved = await _repository.resolveOwnedBusinessForCurrentUser();
    if (resolved == null || !resolved.isResolved) {
      return const _CampaignBusinessValues(businessId: '', businessName: '');
    }

    return _CampaignBusinessValues(
      businessId: resolved.businessId,
      businessName: resolved.businessName.trim().isEmpty
          ? 'İşletme'
          : resolved.businessName.trim(),
    );
  }

  static void _require(String value, String message) {
    if (value.trim().isEmpty) {
      throw StateError(message);
    }
  }

  static String _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return '';
  }
}

class CampaignPublishInput {
  const CampaignPublishInput({
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.body,
    required this.cta,
    required this.category,
    required this.tone,
    required this.offer,
    required this.audience,
    required this.notes,
    required this.startAt,
    required this.endAt,
    required this.clientRequestKey,
    this.aiPayload,
    this.source = 'campaign_ai_create_safe_page',
  });

  final String businessId;
  final String businessName;
  final String title;
  final String body;
  final String cta;
  final String category;
  final String tone;
  final String offer;
  final String audience;
  final String notes;
  final DateTime startAt;
  final DateTime endAt;
  final String clientRequestKey;
  final Map<String, dynamic>? aiPayload;
  final String source;
}

class CampaignPublishResult {
  const CampaignPublishResult._({
    required this.campaignId,
    required this.clientRequestKey,
    required this.created,
    required this.duplicate,
  });

  factory CampaignPublishResult.created({
    required String campaignId,
    required String clientRequestKey,
  }) {
    return CampaignPublishResult._(
      campaignId: campaignId,
      clientRequestKey: clientRequestKey,
      created: true,
      duplicate: false,
    );
  }

  factory CampaignPublishResult.duplicate({
    required String campaignId,
    required String clientRequestKey,
  }) {
    return CampaignPublishResult._(
      campaignId: campaignId,
      clientRequestKey: clientRequestKey,
      created: false,
      duplicate: true,
    );
  }

  final String campaignId;
  final String clientRequestKey;
  final bool created;
  final bool duplicate;
}

class _CampaignBusinessValues {
  const _CampaignBusinessValues({
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;
}
