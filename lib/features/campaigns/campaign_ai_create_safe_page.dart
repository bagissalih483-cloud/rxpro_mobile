import 'package:flutter/material.dart';

import 'campaign_service.dart';

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

  String category = 'Genel';
  String tone = 'Modern';
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 7));

  bool generating = false;
  bool publishing = false;

  String resolvedBusinessId = '';
  String resolvedBusinessName = 'İşletme';

  String generatedTitle = '';
  String generatedBody = '';
  String generatedCta = '';

  String lastPublishedKey = '';
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
    super.dispose();
  }

  Future<void> _resolveBusinessContext() async {
    if ((widget.businessId ?? '').trim().isNotEmpty) {
      if (!mounted) return;
      setState(() {
        resolvedBusinessId = widget.businessId!.trim();
        resolvedBusinessName =
            (widget.businessName ?? 'İşletme').trim().isEmpty
            ? 'İşletme'
            : widget.businessName!.trim();
      });
      return;
    }

    try {
      final businessContext = await _campaignService
          .resolveOwnedBusinessForCurrentUser();

      if (businessContext == null || !businessContext.isResolved) {
        return;
      }

      if (!mounted) return;
      setState(() {
        resolvedBusinessId = businessContext.businessId;
        resolvedBusinessName = businessContext.businessName.trim().isEmpty
            ? 'İşletme'
            : businessContext.businessName.trim();
      });
    } catch (_) {
      // Context resolution is best-effort. The publish guard blocks publishing
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
    final initial = start ? startDate : endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );

    if (picked == null) return;

    setState(() {
      if (start) {
        startDate = picked;
        if (endDate.isBefore(startDate)) {
          endDate = startDate.add(const Duration(days: 7));
        }
      } else {
        endDate = picked.isBefore(startDate) ? startDate : picked;
      }
    });
  }

  Map<String, dynamic> _requestPayload() {
    final offer = _safeText(offerController.text);
    final audience = _safeText(audienceController.text);
    final notes = _safeText(noteController.text);

    return {
      'businessId': resolvedBusinessId,
      'businessName': resolvedBusinessName,
      'serviceName': category,
      'campaignType': 'Kampanya',
      'targetAudience': audience,
      'discountType': 'Kampanya',
      'discountValue': offer,
      'tone': tone,
      'managerBrief': notes,
      'startDateText': _formatDate(startDate),
      'endDateText': _formatDate(endDate),
      'dateEmphasisType': 'Tarih aralığı',
      'dateBadgeText': '${_formatDate(startDate)} - ${_formatDate(endDate)}',
      'category': category,
      'offer': offer,
      'audience': audience,
      'notes': notes,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  bool get canGenerate {
    return _safeText(offerController.text).isNotEmpty &&
        _safeText(audienceController.text).isNotEmpty &&
        !generating;
  }

  bool get canPublish {
    return generatedTitle.trim().isNotEmpty &&
        generatedBody.trim().isNotEmpty &&
        !publishing;
  }

  String _buildLocalTitle() {
    final offer = _safeText(offerController.text);
    if (offer.isEmpty) return '$category Kampanyası';
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

    return '$target için özel hazırlanan $offer kampanyamız ${_formatDate(startDate)} - ${_formatDate(endDate)} tarihleri arasında geçerlidir.$notePart';
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

    setState(() => generating = true);

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

      setState(() {
        generatedTitle = title.isEmpty ? _buildLocalTitle() : title;
        generatedBody = body.isEmpty ? _buildLocalBody() : body;
        generatedCta = cta.isEmpty ? 'Hemen randevu alın' : cta;
        lastPublishedKey = '';
      });

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

      setState(() {
        generatedTitle = _buildLocalTitle();
        generatedBody = _buildLocalBody();
        generatedCta = 'Hemen randevu alın';
        lastPublishedKey = '';
      });

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
        setState(() => generating = false);
      }
    }
  }

  String _publishKey() {
    return [
      resolvedBusinessId,
      generatedTitle.trim().toLowerCase(),
      generatedBody.trim().toLowerCase(),
      generatedCta.trim().toLowerCase(),
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ].join('|');
  }

  Future<void> _publishCampaign() async {
    if (!canPublish) return;

    if (resolvedBusinessId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşletme bilgisi çözümlenemedi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final requestKey = _publishKey();

    if (publishing) return;
    if (lastPublishedKey == requestKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu kampanya zaten yayınlandı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => publishing = true);

    try {
      final result = await _campaignService.publishCampaign(
        CampaignPublishInput(
          businessId: resolvedBusinessId,
          businessName: resolvedBusinessName,
          title: generatedTitle.trim(),
          body: generatedBody.trim(),
          cta: generatedCta.trim(),
          category: category,
          tone: tone,
          offer: _safeText(offerController.text),
          audience: _safeText(audienceController.text),
          notes: _safeText(noteController.text),
          startAt: startDate,
          endAt: endDate,
          clientRequestKey: requestKey,
          source: 'campaign_ai_create_safe_page_39E',
          aiPayload: <String, dynamic>{
            'generatedTitle': generatedTitle.trim(),
            'generatedBody': generatedBody.trim(),
            'generatedCta': generatedCta.trim(),
          },
        ),
      );

      if (!mounted) return;

      setState(() {
        lastPublishedKey = requestKey;
      });

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
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessLabel = resolvedBusinessName.trim().isEmpty
        ? 'İşletme'
        : resolvedBusinessName;

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
                    initialValue: category,
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
                      setState(() => category = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tone,
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
                      setState(() => tone = value);
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
                      label: Text('Başlangıç\n${_formatDate(startDate)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(start: false),
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text('Bitiş\n${_formatDate(endDate)}'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Ön İzleme',
              child: generatedTitle.trim().isEmpty
                  ? const Text(
                      'Henüz kampanya üretilmedi. Önce AI ile kampanya oluştur butonunu kullanın.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    )
                  : _PreviewCard(
                      title: generatedTitle,
                      body: generatedBody,
                      cta: generatedCta,
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
                onPressed: generating ? null : _generateAi,
                icon: generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(generating ? 'Oluşturuluyor...' : 'AI ile Oluştur'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: publishing ? null : _publishCampaign,
                icon: publishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish),
                label: Text(publishing ? 'Yayınlanıyor...' : 'Yayınla'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.body,
    required this.cta,
  });

  final String title;
  final String body;
  final String cta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: Color(0xFF475569), height: 1.35),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Bu buton kampanya kartı ön izlemesidir. Yayınlama işlemi alttaki ana butondan yapılır.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(cta),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
