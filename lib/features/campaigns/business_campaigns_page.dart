import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import 'campaign_service.dart';
import 'domain/business_campaign_item_view_model.dart';

class BusinessCampaignsPage extends StatefulWidget {
  const BusinessCampaignsPage({
    super.key,
    this.businessId,
    this.businessName = 'İşletme',
  });

  final String? businessId;
  final String businessName;

  @override
  State<BusinessCampaignsPage> createState() => _BusinessCampaignsPageState();
}

class _BusinessCampaignsPageState extends State<BusinessCampaignsPage> {
  late Future<List<BusinessCampaignItemViewModel>> future;
  int selectedTab = 0;
  bool _sendingBulkDraft = false;
  final CampaignService _campaignService = CampaignService();

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<void> _refresh() async {
    final next = _load();

    if (!mounted) return;

    setState(() {
      future = next;
    });

    await next;
  }

  Future<List<BusinessCampaignItemViewModel>> _load() async {
    final records = await _campaignService.listBusinessCampaigns(
      businessId: widget.businessId?.trim() ?? '',
    );

    final list = records.map(BusinessCampaignItemViewModel.fromRecord).toList();
    list.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return list;
  }

  bool _isPublished(BusinessCampaignItemViewModel item) {
    final s = item.status.toLowerCase();
    if (item.isBulkDraft && s == 'sent') return true;

    return item.visible &&
        (s.isEmpty ||
            s == 'active' ||
            s == 'aktif' ||
            s == 'published' ||
            s == 'yayinda' ||
            s == 'yayında');
  }

  bool _isDraft(BusinessCampaignItemViewModel item) {
    final s = item.status.toLowerCase();
    return s == 'draft' ||
        s == 'taslak' ||
        s == 'draft_ready' ||
        s == 'ready' ||
        s == 'scheduled' ||
        s == 'send_failed';
  }

  bool _isPassive(BusinessCampaignItemViewModel item) {
    final s = item.status.toLowerCase();
    return !item.visible ||
        s == 'passive' ||
        s == 'pasif' ||
        s == 'removed' ||
        s == 'yayindan_kaldirildi' ||
        s == 'yayından kaldırıldı' ||
        s == 'no_eligible_recipients';
  }

  List<BusinessCampaignItemViewModel> _filtered(
    List<BusinessCampaignItemViewModel> all,
  ) {
    if (selectedTab == 0) {
      return all.where(_isPublished).toList();
    }

    if (selectedTab == 1) {
      return all.where(_isDraft).toList();
    }

    return all.where(_isPassive).toList();
  }

  Future<void> _unpublish(BusinessCampaignItemViewModel item) async {
    try {
      await _campaignService.markCampaignPassive(item.toCampaignRecord());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yayından kaldırıldı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _refresh();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kampanya güncellenemedi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openAiCampaign() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.campaignAiCreate,
      arguments: BusinessCampaignToolRouteArgs(
        businessId: widget.businessId,
        businessName: widget.businessName,
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _openBulkMessage() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.bulkMessageCreate,
      arguments: BusinessCampaignToolRouteArgs(
        businessId: widget.businessId,
        businessName: widget.businessName,
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _sendBulkDraft(BusinessCampaignItemViewModel item) async {
    if (_sendingBulkDraft) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sendingBulkDraft = true);

    try {
      final result = await _campaignService.sendBulkMessageDraft(item.id);
      if (!mounted) return;

      var text = 'Toplu mesaj durumu: ${result.sendStatus}.';
      if (result.alreadySending) {
        text = 'Bu toplu mesaj zaten gönderiliyor.';
      } else if (result.alreadySent) {
        text = 'Bu toplu mesaj daha önce gönderilmiş.';
      } else if (result.sent) {
        text =
            'Toplu mesaj gönderildi: ${result.deliveredNotificationCount} bildirim.';
      } else if (result.hasNoEligibleRecipients) {
        text = 'Gönderime uygun izinli müşteri bulunamadı.';
      }

      messenger.showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );

      await _refresh();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Toplu mesaj gönderilemedi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingBulkDraft = false);
      }
    }
  }

  void _openDetail(BusinessCampaignItemViewModel item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return _BusinessCampaignDetailSheet(
          item: item,
          businessName: widget.businessName,
          sendingBulkDraft: _sendingBulkDraft,
          onSendBulkDraft: item.canSendBulkDraft
              ? () => _sendBulkDraft(item)
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Kampanya Yönetimi'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: FutureBuilder<List<BusinessCampaignItemViewModel>>(
        future: future,
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];
          final published = all.where(_isPublished).length;
          final draft = all.where(_isDraft).length;
          final passive = all.where(_isPassive).length;
          final filtered = _filtered(all);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              children: [
                _HeroCard(published: published, draft: draft, passive: passive),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _openAiCampaign,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('AI Kampanya Oluştur'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openBulkMessage,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Toplu Mesaj'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _BusinessTabs(
                  selected: selectedTab,
                  published: published,
                  draft: draft,
                  passive: passive,
                  onChanged: (v) => setState(() => selectedTab = v),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const _InfoBox(
                    icon: Icons.hourglass_empty_rounded,
                    title: 'Kampanyalar yükleniyor',
                    text: 'İşletme kampanyaları hazırlanıyor.',
                  )
                else if (filtered.isEmpty)
                  const _InfoBox(
                    icon: Icons.campaign_outlined,
                    title: 'Kampanya bulunamadı',
                    text: 'Bu sekmede gösterilecek kampanya yok.',
                  )
                else
                  ...filtered.map(
                    (item) => _BusinessCampaignCard(
                      item: item,
                      onTap: () => _openDetail(item),
                      onUnpublish: _isPublished(item) && !item.isBulkDraft
                          ? () => _unpublish(item)
                          : null,
                    ),
                  ),
                const SizedBox(height: 16),
                const _InfoBox(
                  icon: Icons.info_outline_rounded,
                  title: 'Yayın Mantığı',
                  text:
                      'AI kampanya oluşturma, taslak üretim ve yayınlama süreci tek akışta korunur. Bu ekran yayınlanan, taslak ve pasif kampanyaların takibini kolaylaştırır.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.published,
    required this.draft,
    required this.passive,
  });

  final int published;
  final int draft;
  final int passive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.campaign_rounded, color: Colors.white),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kampanyalarım',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _HeroStat(label: 'Yayında', value: published)),
              const SizedBox(width: 8),
              Expanded(child: _HeroStat(label: 'Taslak', value: draft)),
              const SizedBox(width: 8),
              Expanded(child: _HeroStat(label: 'Pasif', value: passive)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessTabs extends StatelessWidget {
  const _BusinessTabs({
    required this.selected,
    required this.published,
    required this.draft,
    required this.passive,
    required this.onChanged,
  });

  final int selected;
  final int published;
  final int draft;
  final int passive;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabInfo('Yayında', published),
      _TabInfo('Taslak', draft),
      _TabInfo('Yayından Kaldırılan', passive),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = tabs[index];
          final isSelected = selected == index;

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(index),
            child: Container(
              constraints: const BoxConstraints(minWidth: 104),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                '${item.label} (${item.count})',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabInfo {
  const _TabInfo(this.label, this.count);

  final String label;
  final int count;
}

class _BusinessCampaignCard extends StatelessWidget {
  const _BusinessCampaignCard({
    required this.item,
    required this.onTap,
    required this.onUnpublish,
  });

  final BusinessCampaignItemViewModel item;
  final VoidCallback onTap;
  final VoidCallback? onUnpublish;

  @override
  Widget build(BuildContext context) {
    final published = onUnpublish != null;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: published
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    child: Icon(
                      published
                          ? Icons.local_offer_rounded
                          : Icons.edit_note_rounded,
                      color: published
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  _StatusChip(text: item.statusLabel),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              _InfoLine(label: 'Kategori', value: item.category),
              _InfoLine(label: 'Fırsat', value: item.discountText),
              if (item.isBulkDraft)
                _InfoLine(label: 'Gönderim', value: item.deliverySummary),
              _InfoLine(label: 'Geçerlilik', value: item.dateRange),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.open_in_full_rounded),
                    label: const Text('Detay'),
                  ),
                  const Spacer(),
                  if (onUnpublish != null)
                    OutlinedButton.icon(
                      onPressed: onUnpublish,
                      icon: const Icon(Icons.visibility_off_outlined),
                      label: const Text('Yayından Kaldır'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessCampaignDetailSheet extends StatelessWidget {
  const _BusinessCampaignDetailSheet({
    required this.item,
    required this.businessName,
    required this.sendingBulkDraft,
    required this.onSendBulkDraft,
  });

  final BusinessCampaignItemViewModel item;
  final String businessName;
  final bool sendingBulkDraft;
  final VoidCallback? onSendBulkDraft;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Icon(
                  item.statusLabel == 'Yayında'
                      ? Icons.local_offer_rounded
                      : Icons.edit_note_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName.trim().isEmpty ? 'İşletme' : businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(text: item.statusLabel),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.description,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _DetailTile(
            icon: Icons.category_outlined,
            label: 'Kategori',
            value: item.category.trim().isEmpty ? 'Genel' : item.category,
          ),
          _DetailTile(
            icon: Icons.sell_outlined,
            label: 'Fırsat',
            value: item.discountText.trim().isEmpty
                ? 'Özel fırsat'
                : item.discountText,
          ),
          _DetailTile(
            icon: Icons.calendar_today_outlined,
            label: 'Geçerlilik',
            value: item.dateRange,
          ),
          if (item.isBulkDraft)
            _DetailTile(
              icon: Icons.notifications_active_outlined,
              label: 'Gönderim',
              value: item.deliverySummary,
            ),
          if (onSendBulkDraft != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: sendingBulkDraft
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        onSendBulkDraft?.call();
                      },
                icon: sendingBulkDraft
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  sendingBulkDraft ? 'Gönderiliyor...' : 'Toplu Mesajı Gönder',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sadece uygulama bildirimi izni olan bağlı müşterilere gönderilir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(label),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = text == 'Yayında'
        ? const Color(0xFF16A34A)
        : text == 'Taslak'
        ? const Color(0xFFD97706)
        : const Color(0xFF64748B);

    return Chip(
      label: Text(text),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide(color: color.withValues(alpha: 0.18)),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          children: [
            Icon(icon, size: 34, color: const Color(0xFF64748B)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}


