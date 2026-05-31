part of 'business_campaigns_page.dart';

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
  late final BusinessCampaignsController _controller;
  final CampaignService _campaignService = CampaignService();

  @override
  void initState() {
    super.initState();
    _controller = BusinessCampaignsController(load: _load);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _controller.refresh();
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
    if (_controller.selectedTab == 0) {
      return all.where(_isPublished).toList();
    }

    if (_controller.selectedTab == 1) {
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
    if (_controller.sendingBulkDraft) return;

    final messenger = ScaffoldMessenger.of(context);
    _controller.setSendingBulkDraft(true);

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
        _controller.setSendingBulkDraft(false);
      }
    }
  }

  void _openDetail(BusinessCampaignItemViewModel item) {
    showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 620,
      builder: (context) {
        return _BusinessCampaignDetailSheet(
          item: item,
          businessName: widget.businessName,
          sendingBulkDraft: _controller.sendingBulkDraft,
          onSendBulkDraft: item.canSendBulkDraft
              ? () => _sendBulkDraft(item)
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return RxKeyboardShortcutScope(
      onCreate: () {
        _openAiCampaign();
      },
      onRefresh: () {
        _refresh();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Kampanya Yönetimi'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: FutureBuilder<List<BusinessCampaignItemViewModel>>(
        future: _controller.future,
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
                  selected: _controller.selectedTab,
                  published: published,
                  draft: draft,
                  passive: passive,
                  onChanged: _controller.selectTab,
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
                  RxResponsiveGrid(
                    itemCount: filtered.length,
                    maxColumns: 2,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _BusinessCampaignCard(
                        item: item,
                        onTap: () => _openDetail(item),
                        onUnpublish: _isPublished(item) && !item.isBulkDraft
                            ? () => _unpublish(item)
                            : null,
                      );
                    },
                  ),
                const SizedBox(height: 16),
                const _InfoBox(
                  icon: Icons.info_outline_rounded,
                  title: 'Yayın Mantığı',
                  text:
                      'AI önerileri, taslaklar ve yayınlanan kampanyalar tek akışta takip edilir. Böylece aktif, pasif ve hazırlık aşamasındaki çalışmalar kolayca ayrılır.',
                ),
              ],
            ),
          );
        },
      ),
      ),
        );
      },
    );
  }
}
