import 'package:flutter/material.dart';

import 'bulk_message_create_controller.dart';
import 'campaign_models.dart';
import 'campaign_service.dart';

class BulkMessageCreatePage extends StatefulWidget {
  const BulkMessageCreatePage({
    super.key,
    this.businessId,
    this.businessName = 'İşletme',
    this.initialAudience,
    this.initialEstimatedTargetCount,
    this.audienceMetadata,
  });

  final String? businessId;
  final String businessName;
  final String? initialAudience;
  final int? initialEstimatedTargetCount;
  final Map<String, dynamic>? audienceMetadata;

  @override
  State<BulkMessageCreatePage> createState() => _BulkMessageCreatePageState();
}

class _BulkMessageCreatePageState extends State<BulkMessageCreatePage> {
  static const _defaultTargets = <String>[
    'Tüm kayıtlı bireysel kullanıcılar',
    'Son 30 günde randevu alan bireysel kullanıcılar',
    'Son 90 günde randevu alan bireysel kullanıcılar',
    'Pasif bireysel kullanıcılar',
    'Kampanya izni veren bireysel kullanıcılar',
  ];

  static const _channels = <String>[
    'Uygulama bildirimi',
    'Uygulama bildirimi + mesaj taslağı',
  ];

  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final CampaignService _campaignService = CampaignService();

  late final BulkMessageCreateController _controller;

  @override
  void initState() {
    super.initState();
    final initialAudience = widget.initialAudience?.trim();
    final target = initialAudience == null || initialAudience.isEmpty
        ? _defaultTargets.first
        : initialAudience;

    final targets = <String>[
      if (!_defaultTargets.contains(target)) target,
      ..._defaultTargets,
    ];

    _controller = BulkMessageCreateController(
      targets: targets,
      initialTarget: target,
      initialChannel: _channels.first,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  int get estimatedTargetCount {
    final initialAudience = widget.initialAudience?.trim();
    if (initialAudience != null &&
        initialAudience.isNotEmpty &&
        _controller.target == initialAudience &&
        widget.initialEstimatedTargetCount != null) {
      return widget.initialEstimatedTargetCount!;
    }

    switch (_controller.target) {
      case 'Son 30 günde randevu alan bireysel kullanıcılar':
        return 40;
      case 'Son 90 günde randevu alan bireysel kullanıcılar':
        return 95;
      case 'Pasif bireysel kullanıcılar':
        return 25;
      case 'Kampanya izni veren bireysel kullanıcılar':
        return 120;
      default:
        return 150;
    }
  }

  bool get canSave {
    return titleController.text.trim().isNotEmpty &&
        messageController.text.trim().isNotEmpty &&
        _controller.consentOnly &&
        !_controller.saving;
  }

  Future<void> _saveDraft() async {
    if (!canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başlık, mesaj ve izin kuralı zorunludur.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _controller.setSaving(true);

    try {
      final metadata = <String, dynamic>{
        if (widget.audienceMetadata != null) ...widget.audienceMetadata!,
        'selectedAudience': _controller.target,
        'selectedChannel': _controller.channel,
        'createdFrom': 'bulk_message_create_page',
      };

      await _campaignService.createBulkMessageDraft(
        BulkMessageDraftInput(
          businessId: widget.businessId ?? '',
          businessName: widget.businessName,
          title: titleController.text.trim(),
          message: messageController.text.trim(),
          audience: _controller.target,
          channel: _controller.channel,
          consentOnly: _controller.consentOnly,
          estimatedTargetCount: estimatedTargetCount,
          sendStatus: 'draft_ready',
          source: 'bulk_message_create_page_65V_customer_segments',
          audienceMetadata: metadata,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toplu mesaj taslağı kaydedildi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Taslak kaydedilemedi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) _controller.setSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Toplu Mesaj'),
            backgroundColor: const Color(0xFFF8FAFC),
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
          ),
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 130),
              children: [
            _InfoCard(
              title: widget.businessName,
              body:
                  'Bireysel kullanıcılara gönderilecek toplu mesaj güvenli taslak olarak kaydedilir. Gönderim onayı verilmeden gerçek gönderim yapılmaz.',
            ),
            const SizedBox(height: 14),
            _FieldCard(
              title: 'Mesaj Başlığı',
              child: TextField(
                controller: titleController,
                onChanged: (_) => _controller.refreshTextInputs(),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Örn. Mayıs kampanyası başladı',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FieldCard(
              title: 'Mesaj İçeriği',
              child: TextField(
                controller: messageController,
                onChanged: (_) => _controller.refreshTextInputs(),
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText:
                      'Bireysel kullanıcılara gönderilecek kısa ve net mesaj metni...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FieldCard(
              title: 'Hedef Bireysel Kullanıcı Grubu',
              child: DropdownButtonFormField<String>(
                initialValue: _controller.target,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _controller.targets.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _controller.selectTarget(value);
                },
              ),
            ),
            const SizedBox(height: 14),
            _FieldCard(
              title: 'Gönderim Kanalı',
              child: DropdownButtonFormField<String>(
                initialValue: _controller.channel,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _channels.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _controller.selectChannel(value);
                },
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              value: _controller.consentOnly,
              onChanged: _controller.setConsentOnly,
              title: const Text(
                'Sadece bildirim/kampanya izni olan bireysel kullanıcılara gönder',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: const Text(
                'İzin kuralı kapalıyken taslak kaydedilmez.',
              ),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(height: 14),
            _InfoCard(
              title: 'Tahmini hedef',
              body:
                  '$estimatedTargetCount bireysel kullanıcı. Gönderim onaylandığında kesin hedef listesi izinli kullanıcı havuzundan hesaplanır.',
            ),
          ],
        ),
      ),
          bottomNavigationBar: SafeArea(
            minimum: EdgeInsets.fromLTRB(18, 8, 18, 16 + bottomInset),
            child: FilledButton.icon(
              onPressed: _controller.saving ? null : _saveDraft,
              icon: _controller.saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _controller.saving
                    ? 'Kaydediliyor...'
                    : 'Mesaj Taslağını Kaydet',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.title, required this.child});

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
          const SizedBox(height: 10),
          child,
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
          const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
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
