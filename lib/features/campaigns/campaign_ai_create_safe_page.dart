import 'package:flutter/material.dart';

import 'campaign_ai_create_controller.dart';
import 'campaign_service.dart';

part 'campaign_ai_create_safe_widgets_part.dart';

class CampaignAiCreateSafePage extends StatefulWidget {
  const CampaignAiCreateSafePage({
    super.key,
    this.businessId,
    this.businessName,
  });

  final String? businessId;
  final String? businessName;

  @override
  State<CampaignAiCreateSafePage> createState() =>
      _CampaignAiCreateSafePageState();
}

class _CampaignAiCreateSafePageState extends State<CampaignAiCreateSafePage> {
  final offerController = TextEditingController();
  final audienceController = TextEditingController();
  final noteController = TextEditingController();

  final CampaignAiCreateController _controller = CampaignAiCreateController();
  final CampaignService _campaignService = CampaignService();

  final categories = const [
    'Genel',
    'Güzellik',
    'Saç',
    'Cilt Bakımı',
    'Masaj',
    'Tırnak',
    'Lazer',
    'Diğer',
  ];

  final tones = const ['Modern', 'Samimi', 'Profesyonel', 'Lüks', 'Enerjik'];

  @override
  void initState() {
    super.initState();
    _resolveBusinessContext();
  }

  @override
  void dispose() {
    offerController.dispose();
    audienceController.dispose();
    noteController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolveBusinessContext() async {
    if ((widget.businessId ?? '').trim().isNotEmpty) {
      if (!mounted) return;
      _controller.applyBusinessContext(
        businessId: widget.businessId!.trim(),
        businessName: widget.businessName ?? 'İşletme',
      );
      return;
    }

    try {
      final businessContext = await _campaignService
          .resolveOwnedBusinessForCurrentUser();

      if (businessContext == null || !businessContext.isResolved) {
        return;
      }

      if (!mounted) return;
      _controller.applyBusinessContext(
        businessId: businessContext.businessId,
        businessName: businessContext.businessName,
      );
    } catch (_) {
      // Context resolution is best-effort. The publish guard blocks _controller.publishing
      // if no business context can be resolved.
    }
  }

  String _formatDate(DateTime value) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  String _safeText(String value) => value.trim();

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _controller.startDate : _controller.endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );

    if (picked == null) return;

    _controller.setDate(start: start, picked: picked);
  }

  Map<String, dynamic> _requestPayload() {
    final offer = _safeText(offerController.text);
    final audience = _safeText(audienceController.text);
    final notes = _safeText(noteController.text);

    return {
      'businessId': _controller.resolvedBusinessId,
      'businessName': _controller.resolvedBusinessName,
      'serviceName': _controller.category,
      'campaignType': 'Kampanya',
      'targetAudience': audience,
      'discountType': 'Kampanya',
      'discountValue': offer,
      'tone': _controller.tone,
      'managerBrief': notes,
      'startDateText': _formatDate(_controller.startDate),
      'endDateText': _formatDate(_controller.endDate),
      'dateEmphasisType': 'Tarih aralığı',
      'dateBadgeText':
          '${_formatDate(_controller.startDate)} - ${_formatDate(_controller.endDate)}',
      'category': _controller.category,
      'offer': offer,
      'audience': audience,
      'notes': notes,
      'startDate': _controller.startDate.toIso8601String(),
      'endDate': _controller.endDate.toIso8601String(),
    };
  }

  bool get canGenerate {
    return _controller.canGenerate(
      offer: offerController.text,
      audience: audienceController.text,
    );
  }

  bool get canPublish {
    return _controller.canPublish;
  }

  String _buildLocalTitle() {
    final offer = _safeText(offerController.text);
    if (offer.isEmpty) return '${_controller.category} Kampanyası';
    return '$offer fırsatını kaçırmayın';
  }

  String _buildLocalBody() {
    final audience = _safeText(audienceController.text);
    final offer = _safeText(offerController.text);
    final notes = _safeText(noteController.text);

    final target = audience.isEmpty
        ? 'değerli bireysel kullanıcılarımız'
        : audience;
    final notePart = notes.isEmpty ? '' : ' $notes';

    return '$target için özel hazırlanan $offer kampanyamız ${_formatDate(_controller.startDate)} - ${_formatDate(_controller.endDate)} tarihleri arasında geçerlidir.$notePart';
  }

  Map<String, dynamic> _extractAiMap(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};

    final data = Map<String, dynamic>.from(raw);

    final variants = data['variants'];
    if (variants is List && variants.isNotEmpty) {
      final first = variants.first;
      if (first is Map) {
        final variant = Map<String, dynamic>.from(first);
        variant['ok'] = data['ok'] ?? data['success'] ?? true;
        variant['usedFallback'] = data['usedFallback'] ?? false;
        variant['aiProvider'] = data['aiProvider'] ?? '';
        variant['aiModel'] = data['aiModel'] ?? '';
        variant['fallbackReason'] =
            data['fallbackReason'] ?? data['error'] ?? '';
        return variant;
      }
    }

    for (final key in const [
      'campaign',
      'result',
      'data',
      'content',
      'output',
      'ai',
      'payload',
    ]) {
      final nested = data[key];
      if (nested is Map) {
        final normalized = Map<String, dynamic>.from(nested);
        if (normalized.isNotEmpty) return normalized;
      }
    }

    return data;
  }

  String _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;

      final normalized = value.toString().trim();
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }

    return '';
  }

  String _shortAiError(Object? error) {
    if (error == null) return 'Bilinmeyen hata';

    final raw = error.toString().trim();
    if (raw.isEmpty) return 'Bilinmeyen hata';

    return raw.length > 220 ? '${raw.substring(0, 220)}...' : raw;
  }

  Future<Map<String, dynamic>> _callCampaignAiFunction(
    Map<String, dynamic> payload,
  ) async {
    return _campaignService.generateCampaignAi(payload);
  }

  Future<void> _generateAi() async {
    if (!canGenerate) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen teklif ve hedef kitle alanlarını doldurun.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _controller.beginGenerate();

    try {
      final rawResult = await _callCampaignAiFunction(_requestPayload());
      final data = _extractAiMap(rawResult);

      final title = _firstNonEmpty(data, [
        'title',
        'headline',
        'campaignTitle',
        'baslik',
        'başlık',
      ]);

      final body = _firstNonEmpty(data, [
        'description',
        'body',
        'message',
        'text',
        'copy',
        'campaignText',
        'reklamMetni',
        'metin',
      ]);

      final cta = _firstNonEmpty(data, [
        'cta',
        'buttonText',
        'callToAction',
        'actionText',
      ]);

      if (title.isEmpty && body.isEmpty) {
        throw Exception(
          'AI endpoint cevap verdi ancak title/description alanları boş geldi.',
        );
      }

      if (!mounted) return;

      _controller.applyGenerated(
        title: title.isEmpty ? _buildLocalTitle() : title,
        body: body.isEmpty ? _buildLocalBody() : body,
        cta: cta.isEmpty ? 'Hemen randevu alın' : cta,
      );

      final usedFallback = data['usedFallback'] == true;
      final fallbackReason = _firstNonEmpty(data, [
        'fallbackReason',
        'error',
        'message',
      ]);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            usedFallback
                ? 'Function şablon döndürdü: ${fallbackReason.isEmpty ? 'AI cevabı alınamadı.' : fallbackReason}'
                : 'AI kampanya taslağı hazırlandı.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 7),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _controller.applyGenerated(
        title: _buildLocalTitle(),
        body: _buildLocalBody(),
        cta: 'Hemen randevu alın',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI bağlantı hatası: ${_shortAiError(error)}. Yerel şablon kullanıldı.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        _controller.finishGenerate();
      }
    }
  }

  String _publishKey() {
    return _controller.publishKey();
  }

  Future<void> _publishCampaign() async {
    if (!canPublish) return;

    if (_controller.resolvedBusinessId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşletme bilgisi çözümlenemedi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final requestKey = _publishKey();

    if (_controller.publishing) return;
    if (_controller.lastPublishedKey == requestKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu kampanya zaten yayınlandı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _controller.beginPublish();

    try {
      final result = await _campaignService.publishCampaign(
        CampaignPublishInput(
          businessId: _controller.resolvedBusinessId,
          businessName: _controller.resolvedBusinessName,
          title: _controller.generatedTitle.trim(),
          body: _controller.generatedBody.trim(),
          cta: _controller.generatedCta.trim(),
          category: _controller.category,
          tone: _controller.tone,
          offer: _safeText(offerController.text),
          audience: _safeText(audienceController.text),
          notes: _safeText(noteController.text),
          startAt: _controller.startDate,
          endAt: _controller.endDate,
          clientRequestKey: requestKey,
          source: 'campaign_ai_create_safe_page_39E',
          aiPayload: <String, dynamic>{
            'generatedTitle': _controller.generatedTitle.trim(),
            'generatedBody': _controller.generatedBody.trim(),
            'generatedCta': _controller.generatedCta.trim(),
          },
        ),
      );

      if (!mounted) return;

      _controller.markPublished(requestKey);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.duplicate
                ? 'Bu kampanya zaten mevcut.'
                : 'Kampanya yayınlandı.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yayınlama başarısız: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) _controller.finishPublish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final businessLabel = _controller.resolvedBusinessName.trim().isEmpty
            ? 'İşletme'
            : _controller.resolvedBusinessName;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('AI Kampanya Oluştur'),
            backgroundColor: const Color(0xFFF8FAFC),
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
          ),
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
              children: [
                _InfoCard(
                  title: businessLabel,
                  body:
                      'Yapay zeka destekli kampanya metni oluşturun, ön izleyin ve tek dokunuşla yayınlayın.',
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Kampanya Detayları',
                  child: Column(
                    children: [
                      TextField(
                        controller: offerController,
                        decoration: const InputDecoration(
                          labelText: 'Teklif / fırsat',
                          hintText: 'Örn. tüm saç kesimlerinde %20 indirim',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: audienceController,
                        decoration: const InputDecoration(
                          labelText: 'Hedef kitle',
                          hintText:
                              'Örn. son 30 günde gelen bireysel kullanıcılar',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _controller.category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: categories.map((item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          _controller.setCategory(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _controller.tone,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Yazım tonu',
                          border: OutlineInputBorder(),
                        ),
                        items: tones.map((item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          _controller.setTone(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Ek notlar',
                          hintText:
                              'Örn. premium görünüm olsun, yeni bireysel kullanıcı vurgusu yapılsın.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Tarih Aralığı',
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(start: true),
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            'Başlangıç\n${_formatDate(_controller.startDate)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(start: false),
                          icon: const Icon(Icons.event_available_outlined),
                          label: Text(
                            'Bitiş\n${_formatDate(_controller.endDate)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Ön İzleme',
                  child: _controller.generatedTitle.trim().isEmpty
                      ? const Text(
                          'Henüz kampanya üretilmedi. Önce AI ile kampanya oluştur butonunu kullanın.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        )
                      : _PreviewCard(
                          title: _controller.generatedTitle,
                          body: _controller.generatedBody,
                          cta: _controller.generatedCta,
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _controller.generating ? null : _generateAi,
                    icon: _controller.generating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _controller.generating
                          ? 'Oluşturuluyor...'
                          : 'AI ile Oluştur',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _controller.publishing ? null : _publishCampaign,
                    icon: _controller.publishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.publish),
                    label: Text(
                      _controller.publishing ? 'Yayınlanıyor...' : 'Yayınla',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
