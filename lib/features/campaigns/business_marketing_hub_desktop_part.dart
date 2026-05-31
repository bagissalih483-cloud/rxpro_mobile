part of 'business_marketing_hub_page.dart';

extension _BusinessMarketingHubDesktop on BusinessMarketingHubPage {
  Widget _buildDesktopMarketingHub(BuildContext context) {
    return RxAdaptiveContentWidth(
      desktopMaxWidth: 1280,
      tabletMaxWidth: 980,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: ListView(
        padding: EdgeInsets.zero,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          _MarketingCommandBand(
            onCampaigns: () => _open(
              context,
              AppRoutes.businessCampaigns,
              _pageArgs,
            ),
            onAiCampaign: () => _open(
              context,
              AppRoutes.campaignAiCreate,
              _campaignToolArgs(),
            ),
          ),
          const SizedBox(height: 18),
          const _MarketingSectionHeader(
            title: 'Pazarlama Merkezi',
            subtitle: 'Kampanya, mesaj, AI ve vitrin yayınları.',
          ),
          const SizedBox(height: 10),
          RxResponsiveGrid(
            minItemWidth: 260,
            spacing: 12,
            maxColumns: 4,
            children: [
              _MarketingDesktopActionCard(
                icon: Icons.local_offer_outlined,
                title: 'Kampanyalar',
                subtitle: 'Aktif, taslak ve raporlar',
                color: const Color(0xFF10B981),
                onTap: () => _open(
                  context,
                  AppRoutes.businessCampaigns,
                  _pageArgs,
                ),
              ),
              _MarketingDesktopActionCard(
                icon: Icons.sms_outlined,
                title: 'Toplu Mesaj',
                subtitle: 'Segment bazlı hedef kitle',
                color: const Color(0xFFEA580C),
                onTap: () => _open(
                  context,
                  AppRoutes.bulkMessageCreate,
                  _campaignToolArgs(),
                ),
              ),
              _MarketingDesktopActionCard(
                icon: Icons.auto_awesome_outlined,
                title: 'AI Kampanya',
                subtitle: 'Metin ve fikir önerisi',
                color: const Color(0xFF9333EA),
                onTap: () => _open(
                  context,
                  AppRoutes.campaignAiCreate,
                  _campaignToolArgs(),
                ),
              ),
              _MarketingDesktopActionCard(
                icon: Icons.auto_stories_outlined,
                title: 'Hikaye Paylaş',
                subtitle: '24 saatlik vitrin yayını',
                color: const Color(0xFF0891B2),
                onTap: () => _open(
                  context,
                  AppRoutes.businessStoryCreate,
                  _pageArgs,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _MarketingSectionHeader(
            title: 'Büyüme Aksiyonları',
            subtitle: 'Boş saatleri ve eski müşterileri tekrar gelire bağla.',
          ),
          const SizedBox(height: 10),
          RxResponsiveGrid(
            minItemWidth: 360,
            spacing: 12,
            maxColumns: 2,
            children: [
              _MarketingDesktopListTile(
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
              _MarketingDesktopListTile(
                icon: Icons.history_toggle_off_outlined,
                title: 'Eski Müşteriyi Çağır',
                subtitle:
                    'Uzun süredir gelmeyen müşteri segmentine mesaj hazırla.',
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
              _MarketingDesktopListTile(
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
              _MarketingDesktopListTile(
                icon: Icons.groups_2_outlined,
                title: 'Müşteri Segmentleri',
                subtitle: 'Ana müşteri dosyasını hedef kitle seçimi için aç.',
                color: const Color(0xFF334155),
                onTap: () => _openOwnerHub(context, 'customers'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
