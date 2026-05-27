import 'package:flutter/material.dart';

import 'campaign_models.dart';
import 'campaign_service.dart';

import '../businesses/business_profile_page.dart';

class CustomerCampaignsPage extends StatefulWidget {
  const CustomerCampaignsPage({super.key});

  @override
  State<CustomerCampaignsPage> createState() => _CustomerCampaignsPageState();
}

class _CustomerCampaignsPageState extends State<CustomerCampaignsPage>
    with AutomaticKeepAliveClientMixin<CustomerCampaignsPage> {
  late Future<List<_CampaignItem>> _future;
  int _selectedTab = 0;
  String _selectedCategory = 'Tümü';
  final CampaignService _campaignService = CampaignService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
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
    if (_selectedCategory == 'Tümü') return true;

    final c = item.category.toLowerCase();
    final selected = _selectedCategory.toLowerCase();

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

    if (_selectedTab == 0) {
      result = all.where(_isFresh);
    } else if (_selectedTab == 1) {
      result = all.where(_isActiveNow);
    } else if (_selectedTab == 2) {
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessProfilePage(
          businessId: item.businessId,
          businessName: item.businessName,
          category: item.category,
        ),
      ),
    );
  }

  void _openDetail(_CampaignItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
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
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Kurumsal Profile Git'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<List<_CampaignItem>>(
      future: _future,
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
                selected: _selectedTab,
                fresh: freshCount,
                active: activeCount,
                upcoming: upcomingCount,
                past: pastCount,
                onChanged: (v) => setState(() => _selectedTab = v),
              ),
              const SizedBox(height: 10),
              _CategoryScroller(
                categories: categories,
                selected: _selectedCategory,
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _InfoCard(
                  icon: Icons.hourglass_empty_rounded,
                  title: 'Kampanyalar hazırlanıyor',
                  text: 'Kampanyalar yükleniyor.',
                )
              else if (visible.isEmpty)
                const _InfoCard(
                  icon: Icons.local_offer_outlined,
                  title: 'Kampanya bulunamadı',
                  text:
                      'Bu filtrede kampanya yok. Farklı sekme veya kategori deneyin.',
                )
              else
                ...visible.map(
                  (item) => _CampaignCard(
                    item: item,
                    onTap: () => _openDetail(item),
                    onOpenBusiness: item.businessId.trim().isEmpty
                        ? null
                        : () => _openBusiness(item),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFEA580C)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_offer_rounded, color: Colors.white, size: 34),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kampanyalar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.selected,
    required this.fresh,
    required this.active,
    required this.upcoming,
    required this.past,
    required this.onChanged,
  });

  final int selected;
  final int fresh;
  final int active;
  final int upcoming;
  final int past;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabInfo('Güncel', fresh),
      _TabInfo('Aktif', active),
      _TabInfo('Yakında', upcoming),
      _TabInfo('Geçmiş', past),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return _Pill(
            label: tab.label,
            count: tab.count,
            selected: selected == index,
            onTap: () => onChanged(index),
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 94),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEA580C) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFEA580C) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          '$label ($count)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF374151),
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _CategoryScroller extends StatelessWidget {
  const _CategoryScroller({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = item == selected;

          return ChoiceChip(
            selected: isSelected,
            label: Text(item),
            onSelected: (_) => onChanged(item),
            selectedColor: const Color(0xFFFFEDD5),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFFEA580C)
                  : const Color(0xFFE5E7EB),
            ),
            labelStyle: TextStyle(
              color: isSelected
                  ? const Color(0xFF9A3412)
                  : const Color(0xFF475569),
              fontWeight: FontWeight.w900,
            ),
          );
        },
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.item,
    required this.onTap,
    required this.onOpenBusiness,
  });

  final _CampaignItem item;
  final VoidCallback onTap;
  final VoidCallback? onOpenBusiness;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Poster(item: item),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 17),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.businessName.isEmpty
                              ? 'İşletme'
                              : item.businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        item.dateRange,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (onOpenBusiness != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onOpenBusiness,
                        icon: const Icon(Icons.storefront_rounded),
                        label: const Text('Kurumsal Profile Git'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.item, this.large = false});

  final _CampaignItem item;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.from(item.templateStyle);
    final height = large ? 230.0 : 190.0;

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -14,
            child: Icon(
              palette.icon,
              size: 112,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.businessName.isEmpty ? 'fi Kampanya' : item.businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.discountText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: large ? 28 : 24,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Palette {
  const _Palette({required this.colors, required this.icon});

  final List<Color> colors;
  final IconData icon;

  static _Palette from(String style) {
    final clean = style.toLowerCase();

    if (clean.contains('health') ||
        clean.contains('saglik') ||
        clean.contains('sağlık')) {
      return const _Palette(
        colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        icon: Icons.health_and_safety_outlined,
      );
    }

    if (clean.contains('food') || clean.contains('yemek')) {
      return const _Palette(
        colors: [Color(0xFFB45309), Color(0xFFF97316)],
        icon: Icons.restaurant_menu_rounded,
      );
    }

    if (clean.contains('sport') || clean.contains('spor')) {
      return const _Palette(
        colors: [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
        icon: Icons.fitness_center_rounded,
      );
    }

    return const _Palette(
      colors: [Color(0xFF7C2D12), Color(0xFFEA580C)],
      icon: Icons.local_offer_rounded,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
      leading: Icon(icon, color: const Color(0xFFEA580C)),
      title: Text(label),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          children: [
            Icon(icon, size: 36, color: const Color(0xFF6B7280)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
      title: record.title.trim().isEmpty ? 'Kampanya' : record.title,
      description: record.body.trim().isEmpty
          ? 'Kampanya açıklaması henüz girilmedi.'
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
}
