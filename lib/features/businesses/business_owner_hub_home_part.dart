part of 'business_owner_hub_page.dart';

class _BusinessHubHomePage extends StatelessWidget {
  const _BusinessHubHomePage({
    required this.businessId,
    required this.businessName,
    required this.data,
  });
  final String businessId;
  final String businessName;
  final Map<String, dynamic> data;

  void _openSection(BuildContext context, String openSection) {
    Navigator.of(context).pushNamed(
      AppRoutes.businessOwnerHub,
      arguments: BusinessOwnerHubRouteArgs(
        businessId: businessId,
        initialData: data,
        openSection: openSection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = (data['categoryLabel'] ?? data['category'] ?? 'Genel')
        .toString()
        .trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Fix İşletme Merkezi'),
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _HubHeroCard(
            businessName: businessName,
            category: category.isEmpty ? 'Genel' : category,
          ),
          const SizedBox(height: 14),
          const _HubSectionHeader(
            title: 'Bugünün kısa yolu',
            subtitle: 'İşletmenin en sık kullanılan aksiyonları',
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HubGridAction(
                    width: width,
                    icon: Icons.calendar_month_outlined,
                    title: 'Randevular',
                    subtitle: 'Talepler ve takvim',
                    color: const Color(0xFF2563EB),
                    onTap: () =>
                        _openSection(context, 'appointmentManagement'),
                  ),
                  _HubGridAction(
                    width: width,
                    icon: Icons.groups_2_outlined,
                    title: 'Müşteriler',
                    subtitle: 'Geçmiş ve segment',
                    color: const Color(0xFF0F766E),
                    onTap: () => _openSection(context, 'customers'),
                  ),
                  _HubGridAction(
                    width: width,
                    icon: Icons.sms_outlined,
                    title: 'Toplu mesaj',
                    subtitle: 'Filtreli gönderim',
                    color: const Color(0xFFEA580C),
                    onTap: () => _openSection(context, 'bulkMessage'),
                  ),
                  _HubGridAction(
                    width: width,
                    icon: Icons.storefront_outlined,
                    title: 'Profil',
                    subtitle: 'Vitrin ön izleme',
                    color: const Color(0xFF7C3AED),
                    onTap: () => _openSection(context, 'preview'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const _HubSectionHeader(
            title: 'İşletme yönetimi',
            subtitle: 'Hizmet, ekip, finans ve canlı operasyon',
          ),
          _HubActionTile(
            icon: Icons.room_service_outlined,
            title: 'Hizmetler ve Paketler',
            text: 'Fiyat, süre, paket ve seans ayarlarını düzenle.',
            color: const Color(0xFF2563EB),
            onTap: () => _openSection(context, 'services'),
          ),
          _HubActionTile(
            icon: Icons.groups_outlined,
            title: 'Personel ve Yetkiler',
            text: 'Ekip, davet kodu, rol ve yetki düzenini yönet.',
            color: const Color(0xFF7C3AED),
            onTap: () => _openSection(context, 'staff'),
          ),
          _HubActionTile(
            icon: Icons.monitor_heart_outlined,
            title: 'Canlı Akış',
            text: 'Bugünün işlemleri, personel durumu ve aktif işler.',
            color: const Color(0xFF16A34A),
            onTap: () => _openSection(context, 'live'),
          ),
          _HubActionTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Finans ve Masraf',
            text: 'Gelir, gider, dönem özeti ve masraf takibi.',
            color: const Color(0xFF0F766E),
            onTap: () => _openSection(context, 'finance'),
          ),
          const SizedBox(height: 10),
          const _HubSectionHeader(
            title: 'Satış ve görünürlük',
            subtitle: 'Vitrin, kampanya, stok ve günlük satış',
          ),
          _HubActionTile(
            icon: Icons.campaign_outlined,
            title: 'Kampanyalar',
            text: 'Yayınlanan kampanyaları ve taslakları yönet.',
            color: const Color(0xFF9333EA),
            onTap: () => _openSection(context, 'campaigns'),
          ),
          _HubActionTile(
            icon: Icons.auto_stories_outlined,
            title: 'Hikaye Paylaş',
            text: 'Keşfet üstündeki hikaye alanında 24 saat görünür.',
            color: const Color(0xFF0891B2),
            onTap: () => _openSection(context, 'stories'),
          ),
          _HubActionTile(
            icon: Icons.receipt_long_rounded,
            title: 'Adisyon ve Satış',
            text: 'Açık adisyon, hızlı satış ve ödeme takibi.',
            color: const Color(0xFF2563EB),
            onTap: () => _openSection(context, 'pos'),
          ),
          _HubActionTile(
            icon: Icons.inventory_2_outlined,
            title: 'Stok ve Ürünler',
            text: 'Ürün kataloğu, stok hareketleri ve vitrin ürünleri.',
            color: const Color(0xFF059669),
            onTap: () => _openSection(context, 'products'),
          ),
        ],
      ),
    );
  }
}
