import 'package:flutter/material.dart';

import 'package:rxpro_mobile/app/app_routes.dart';
import 'package:rxpro_mobile/core/responsive/rx_desktop_layout.dart';
import 'package:rxpro_mobile/core/responsive/rx_keyboard_shortcuts.dart';
import 'package:rxpro_mobile/core/responsive/rx_responsive_grid.dart';

part 'business_marketing_hub_desktop_part.dart';
part 'business_marketing_hub_desktop_widgets_part.dart';

class BusinessMarketingHubPage extends StatelessWidget {
  const BusinessMarketingHubPage({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.businessData,
  });

  final String businessId;
  final String businessName;
  final Map<String, dynamic> businessData;

  void _open(BuildContext context, String routeName, Object arguments) {
    Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  void _openOwnerHub(BuildContext context, String section) {
    Navigator.of(context).pushNamed(
      AppRoutes.businessOwnerHub,
      arguments: BusinessOwnerHubRouteArgs(
        businessId: businessId,
        initialData: businessData,
        openSection: section,
      ),
    );
  }

  BusinessPageRouteArgs get _pageArgs {
    return BusinessPageRouteArgs(
      businessId: businessId,
      businessName: businessName,
      businessLogoUrl: _firstText([
        businessData['logoUrl'],
        businessData['photoUrl'],
        businessData['imageUrl'],
      ], fallback: ''),
      category: _firstText([
        businessData['categoryLabel'],
        businessData['category'],
      ], fallback: 'Genel'),
    );
  }

  BusinessCampaignToolRouteArgs _campaignToolArgs({
    String? audience,
    Map<String, dynamic>? metadata,
  }) {
    return BusinessCampaignToolRouteArgs(
      businessId: businessId,
      businessName: businessName,
      initialAudience: audience,
      audienceMetadata: metadata,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 900) {
      return RxKeyboardShortcutScope(
        onCreate: () => _open(
          context,
          AppRoutes.campaignAiCreate,
          _campaignToolArgs(),
        ),
        child: this._buildDesktopMarketingHub(context),
      );
    }

    return RxKeyboardShortcutScope(
      onCreate: () => _open(
        context,
        AppRoutes.campaignAiCreate,
        _campaignToolArgs(),
      ),
      child: RxAdaptiveContentWidth(
        tabletMaxWidth: 720,
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
        const _MarketingHeroCard(),
        const SizedBox(height: 16),
        const _MarketingSectionHeader(
          title: 'Pazarlama Merkezi',
          subtitle: 'Kampanya, mesaj, AI ve vitrin yayınları.',
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MarketingActionCard(
                  width: itemWidth,
                  icon: Icons.local_offer_outlined,
                  title: 'Kampanyalar',
                  subtitle: 'Aktif ve taslak',
                  color: const Color(0xFF10B981),
                  onTap: () => _open(
                    context,
                    AppRoutes.businessCampaigns,
                    _pageArgs,
                  ),
                ),
                _MarketingActionCard(
                  width: itemWidth,
                  icon: Icons.sms_outlined,
                  title: 'Toplu Mesaj',
                  subtitle: 'Hedef kitle',
                  color: const Color(0xFFEA580C),
                  onTap: () => _open(
                    context,
                    AppRoutes.bulkMessageCreate,
                    _campaignToolArgs(),
                  ),
                ),
                _MarketingActionCard(
                  width: itemWidth,
                  icon: Icons.auto_awesome_outlined,
                  title: 'AI Kampanya',
                  subtitle: 'Metin önerisi',
                  color: const Color(0xFF9333EA),
                  onTap: () => _open(
                    context,
                    AppRoutes.campaignAiCreate,
                    _campaignToolArgs(),
                  ),
                ),
                _MarketingActionCard(
                  width: itemWidth,
                  icon: Icons.auto_stories_outlined,
                  title: 'Hikaye Paylaş',
                  subtitle: '24 saat vitrin',
                  color: const Color(0xFF0891B2),
                  onTap: () => _open(
                    context,
                    AppRoutes.businessStoryCreate,
                    _pageArgs,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const _MarketingSectionHeader(
          title: 'Büyüme Aksiyonları',
          subtitle: 'Boş saatleri ve eski müşterileri tekrar gelire bağla.',
        ),
        _MarketingListTile(
          icon: Icons.event_available_outlined,
          title: 'Boş Saati Doldur',
          subtitle: 'Randevu boşluklarını kampanya fikrine çevir.',
          color: const Color(0xFF2563EB),
          onTap: () => _open(
            context,
            AppRoutes.campaignAiCreate,
            _campaignToolArgs(
              audience: 'Boş saat doldurma',
              metadata: const <String, dynamic>{'intent': 'empty_slot'},
            ),
          ),
        ),
        _MarketingListTile(
          icon: Icons.history_toggle_off_outlined,
          title: 'Eski Müşteriyi Çağır',
          subtitle: 'Uzun süredir gelmeyen müşteri segmentine mesaj hazırla.',
          color: const Color(0xFF0F766E),
          onTap: () => _open(
            context,
            AppRoutes.bulkMessageCreate,
            _campaignToolArgs(
              audience: 'Eski müşteriler',
              metadata: const <String, dynamic>{'segment': 'inactive'},
            ),
          ),
        ),
        _MarketingListTile(
          icon: Icons.dynamic_feed_outlined,
          title: 'Paylaşım Oluştur',
          subtitle: 'Kurumsal profil vitrini için tanıtım yayını.',
          color: const Color(0xFF7C3AED),
          onTap: () => _open(
            context,
            AppRoutes.businessProfilePostCreate,
            BusinessProfilePostCreateRouteArgs(
              businessId: businessId,
              businessName: businessName,
            ),
          ),
        ),
        _MarketingListTile(
          icon: Icons.groups_2_outlined,
          title: 'Müşteri Segmentleri',
          subtitle: 'Ana müşteri dosyasını hedef kitle seçimi için aç.',
          color: const Color(0xFF334155),
          onTap: () => _openOwnerHub(context, 'customers'),
        ),
          ],
        ),
      ),
    );
  }

}

class _MarketingHeroCard extends StatelessWidget {
  const _MarketingHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF312E81),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          _MarketingHeroIcon(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pazarlama',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kampanya, mesaj ve vitrin yayınları tek yerde.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFC7D2FE),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketingHeroIcon extends StatelessWidget {
  const _MarketingHeroIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.campaign_rounded, color: Colors.white),
      ),
    );
  }
}

class _MarketingSectionHeader extends StatelessWidget {
  const _MarketingSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MarketingActionCard extends StatelessWidget {
  const _MarketingActionCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _MarketingSurface(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MarketingIcon(icon: icon, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketingListTile extends StatelessWidget {
  const _MarketingListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _MarketingSurface(
        onTap: onTap,
        child: Row(
          children: [
            _MarketingIcon(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}

class _MarketingSurface extends StatelessWidget {
  const _MarketingSurface({
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MarketingIcon extends StatelessWidget {
  const _MarketingIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

String _firstText(List<Object?> values, {required String fallback}) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return fallback;
}
