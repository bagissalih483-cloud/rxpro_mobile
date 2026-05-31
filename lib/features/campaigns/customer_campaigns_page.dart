import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/responsive/rx_adaptive_modal.dart';
import '../../core/services/app_observability_service.dart';
import '../../core/theme/rx_ui.dart';
import 'campaign_models.dart';
import 'campaign_service.dart';
import 'customer_campaigns_controller.dart';

part 'customer_campaigns_widgets.dart';
part 'customer_campaigns_card_widgets.dart';
part 'customer_campaigns_poster_widgets.dart';
part 'customer_campaigns_info_widgets.dart';

class CustomerCampaignsPage extends StatefulWidget {
  const CustomerCampaignsPage({super.key});

  @override
  State<CustomerCampaignsPage> createState() => _CustomerCampaignsPageState();
}

class _CustomerCampaignsPageState extends State<CustomerCampaignsPage>
    with AutomaticKeepAliveClientMixin<CustomerCampaignsPage> {
  final CampaignService _campaignService = CampaignService();
  late final CustomerCampaignsController<_CampaignItem> _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = CustomerCampaignsController<_CampaignItem>(load: _load);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _controller.refresh();
  }

  Future<List<_CampaignItem>> _load() async {
    final records = await _campaignService.listCustomerCampaigns();

    final list = records
        .map(_CampaignItem.fromRecord)
        .where((item) => item.visible)
        .toList();

    list.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return list;
  }

  bool _isActiveNow(_CampaignItem item) {
    final now = DateTime.now();
    final started = item.startAt == null || !item.startAt!.isAfter(now);
    final notExpired = item.endAt == null || !item.endAt!.isBefore(now);
    return item.active && started && notExpired;
  }

  bool _isUpcoming(_CampaignItem item) {
    final now = DateTime.now();
    return item.active && item.startAt != null && item.startAt!.isAfter(now);
  }

  bool _isPast(_CampaignItem item) {
    final now = DateTime.now();
    return item.endAt != null && item.endAt!.isBefore(now);
  }

  bool _isFresh(_CampaignItem item) {
    if (!_isActiveNow(item)) return false;
    final base = item.createdAt ?? item.startAt;
    if (base == null) return false;
    return DateTime.now().difference(base).inDays <= 14;
  }

  bool _matchesCategory(_CampaignItem item) {
    if (_controller.selectedCategory == 'Tümü') return true;

    final c = item.category.toLowerCase();
    final selected = _controller.selectedCategory.toLowerCase();

    if (c == selected) return true;
    if (selected == 'genel') return true;
    if (selected == 'güzellik' && c.contains('güzellik')) return true;
    if (selected == 'sağlık' &&
        (c.contains('sağlık') || c.contains('saglik'))) {
      return true;
    }
    if (selected == 'spor' && c.contains('spor')) return true;
    if (selected == 'yemek' &&
        (c.contains('yemek') ||
            c.contains('restaurant') ||
            c.contains('restoran'))) {
      return true;
    }
    if (selected == 'alışveriş' &&
        (c.contains('alışveriş') ||
            c.contains('alisveris') ||
            c.contains('market'))) {
      return true;
    }
    if (selected == 'otomotiv' &&
        (c.contains('oto') || c.contains('otomotiv') || c.contains('araç'))) {
      return true;
    }
    if (selected == 'eğitim' &&
        (c.contains('eğitim') || c.contains('egitim') || c.contains('kurs'))) {
      return true;
    }
    if (selected == 'teknoloji' &&
        (c.contains('teknoloji') ||
            c.contains('telefon') ||
            c.contains('bilgisayar'))) {
      return true;
    }
    if (selected == 'eğlence' &&
        (c.contains('eğlence') || c.contains('eglence'))) {
      return true;
    }
    if (selected == 'hizmet' && c.contains('hizmet')) return true;

    return false;
  }

  List<_CampaignItem> _filtered(List<_CampaignItem> all) {
    Iterable<_CampaignItem> result;

    if (_controller.selectedTab == 0) {
      result = all.where(_isFresh);
    } else if (_controller.selectedTab == 1) {
      result = all.where(_isActiveNow);
    } else if (_controller.selectedTab == 2) {
      result = all.where(_isUpcoming);
    } else {
      result = all.where(_isPast);
    }

    result = result.where(_matchesCategory);

    final out = result.toList();
    out.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return out;
  }

  List<String> _categories(List<_CampaignItem> list) {
    final ordered = <String>[
      'Tümü',
      'Genel',
      'Güzellik',
      'Sağlık',
      'Spor',
      'Yemek',
      'Alışveriş',
      'Otomotiv',
      'Eğitim',
      'Teknoloji',
      'Eğlence',
      'Hizmet',
    ];

    final dynamic = <String>{};

    for (final item in list) {
      final clean = item.category.trim();
      if (clean.isNotEmpty && !ordered.contains(clean)) {
        dynamic.add(clean);
      }
    }

    return [...ordered, ...dynamic.toList()..sort()];
  }

  void _openBusiness(_CampaignItem item) {
    if (item.businessId.trim().isEmpty) return;

    Navigator.of(context).pushNamed(
      AppRoutes.businessProfile,
      arguments: BusinessProfileRouteArgs(
        businessId: item.businessId,
        businessName: item.businessName,
        category: item.category,
      ),
    );
  }

  Future<void> _reportCampaign(_CampaignItem item, String reason) async {
    try {
      await _campaignService.reportCampaign(
        campaign: item.toCampaignRecord(),
        reason: reason,
      );
      await AppObservabilityService.instance.logCampaignReportSubmitted(
        campaignId: item.id,
        businessId: item.businessId,
        reason: reason,
        sourceCollection: item.sourceCollection,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fırsat şikayeti alındı.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şikayet gönderilemedi. Tekrar deneyin.')),
      );
    }
  }

  void _openReportSheet(_CampaignItem item) {
    showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 480,
      builder: (context) {
        const reasons = <String, String>{
          'spam': 'Spam veya yanıltıcı',
          'inappropriate': 'Uygunsuz içerik',
          'expired': 'Geçersiz veya bitmiş fırsat',
          'other': 'Diğer',
        };

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.flag_outlined),
                title: Text('Fırsatı şikayet et'),
              ),
              ...reasons.entries.map(
                (entry) => ListTile(
                  title: Text(entry.value),
                  onTap: () {
                    Navigator.pop(context);
                    _reportCampaign(item, entry.key);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openDetail(_CampaignItem item) {
    AppObservabilityService.instance.logCampaignViewed(
      campaignId: item.id,
      businessId: item.businessId,
      category: item.category,
      sourceCollection: item.sourceCollection,
    );
    showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 640,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            children: [
              _Poster(item: item, large: true),
              const SizedBox(height: 14),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: const TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 14),
              _DetailRow(
                icon: Icons.storefront_rounded,
                label: 'İşletme',
                value: item.businessName.isEmpty
                    ? 'İşletme'
                    : item.businessName,
              ),
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'Kategori',
                value: item.category.isEmpty ? 'Genel' : item.category,
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Geçerlilik',
                value: item.dateRange,
              ),
              if (item.businessId.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openBusiness(item);
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Fırsattan Randevu Al'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openReportSheet(item);
                  },
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Fırsatı Şikayet Et'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: FutureBuilder<List<_CampaignItem>>(
            future: _controller.future,
            builder: (context, snapshot) {
              final all = snapshot.data ?? <_CampaignItem>[];
              final visible = _filtered(all);
              final categories = _categories(all);

              final freshCount = all.where(_isFresh).length;
              final activeCount = all.where(_isActiveNow).length;
              final upcomingCount = all.where(_isUpcoming).length;
              final pastCount = all.where(_isPast).length;

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                  children: [
                    const _Header(),
                    const SizedBox(height: 12),
                    _Tabs(
                      selected: _controller.selectedTab,
                      fresh: freshCount,
                      active: activeCount,
                      upcoming: upcomingCount,
                      past: pastCount,
                      onChanged: _controller.selectTab,
                    ),
                    const SizedBox(height: 10),
                    _CategoryScroller(
                      categories: categories,
                      selected: _controller.selectedCategory,
                      onChanged: _controller.selectCategory,
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const _InfoCard(
                        icon: Icons.hourglass_empty_rounded,
                        title: 'Fırsatlar hazırlanıyor',
                        text: 'Fırsatlar yükleniyor.',
                      )
                    else if (visible.isEmpty)
                      const _InfoCard(
                        icon: Icons.local_offer_outlined,
                        title: 'Fırsat bulunamadı',
                        text:
                            'Bu filtrede fırsat yok. Farklı sekme veya kategori deneyin.',
                      )
                    else
                      ...visible.map(
                        (item) => _CampaignCard(
                          item: item,
                          onTap: () => _openDetail(item),
                          onOpenBusiness: item.businessId.trim().isEmpty
                              ? null
                              : () => _openBusiness(item),
                          onReport: () => _openReportSheet(item),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CampaignItem {
  const _CampaignItem({
    required this.id,
    required this.sourceCollection,
    required this.businessId,
    required this.businessName,
    required this.category,
    required this.title,
    required this.description,
    required this.discountText,
    required this.status,
    required this.visible,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.templateStyle,
  });

  final String id;
  final String sourceCollection;
  final String businessId;
  final String businessName;
  final String category;
  final String title;
  final String description;
  final String discountText;
  final String status;
  final bool visible;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? createdAt;
  final String templateStyle;

  bool get active {
    final clean = status.trim().toLowerCase();
    return clean.isEmpty ||
        clean == 'active' ||
        clean == 'aktif' ||
        clean == 'published' ||
        clean == 'yayinda' ||
        clean == 'yayında';
  }

  DateTime get sortDate => startAt ?? createdAt ?? DateTime(1970);

  String get dateRange {
    final s = _format(startAt);
    final e = _format(endAt);

    if (s.isEmpty && e.isEmpty) return 'Süre belirtilmedi';
    if (s.isEmpty) return '$e tarihine kadar';
    if (e.isEmpty) return '$s itibarıyla';
    return '$s - $e';
  }

  factory _CampaignItem.fromRecord(CampaignRecord record) {
    final campaignType = CampaignFieldReaders.firstString(
      record.raw,
      const <String>['campaignType'],
    );
    final businessName = CampaignFieldReaders.firstString(
      record.raw,
      const <String>['businessName', 'shopName', 'companyName'],
    );
    final templateStyle = CampaignFieldReaders.firstString(
      record.raw,
      const <String>['templateStyle', 'posterStyle', 'style'],
    );

    return _CampaignItem(
      id: record.id,
      sourceCollection: record.sourceCollection,
      businessId: record.businessId,
      businessName: businessName,
      category: record.category.trim().isEmpty ? 'Genel' : record.category,
      title: record.title.trim().isEmpty ? 'Fırsat' : record.title,
      description: record.body.trim().isEmpty
          ? 'Fırsat açıklaması henüz girilmedi.'
          : record.body,
      discountText: _normalizeOffer(
        record.offer.trim().isEmpty ? 'Özel fırsat' : record.offer,
        campaignType,
      ),
      status: record.status,
      visible: record.visible,
      startAt: record.startAt,
      endAt: record.endAt,
      createdAt: record.createdAt,
      templateStyle: templateStyle.trim().isEmpty ? 'premium' : templateStyle,
    );
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

  CampaignRecord toCampaignRecord() {
    return CampaignRecord(
      id: id,
      sourceCollection: sourceCollection,
      businessId: businessId,
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
      raw: <String, dynamic>{
        'businessName': businessName,
        'templateStyle': templateStyle,
      },
    );
  }
}
