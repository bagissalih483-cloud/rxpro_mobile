import 'package:flutter/material.dart';

import 'business_activity_logs_page.dart';
import 'business_duration_analytics_page.dart';
import 'business_pos_page.dart';
import 'business_products_page.dart';
import 'presentation/pages/business_finance_page.dart';
import 'business_services_manage_page.dart';
import 'presentation/pages/business_staff_manage_page.dart';
import 'business_live_flow_page.dart';
import 'business_profile_page.dart';
import 'business_appointment_management_page.dart';
import 'business_customers_page.dart';
import '../campaigns/bulk_message_create_page.dart';
import '../campaigns/business_campaigns_page.dart';
import '../stories/business_story_create_page.dart';
import 'data/registered_business_gateway_repository.dart';

class BusinessOwnerHubPage extends StatefulWidget {
  const BusinessOwnerHubPage({
    super.key,
    this.businessId,
    this.initialData,
    this.openSection,
  });
  final String? businessId;
  final Map<String, dynamic>? initialData;
  final String? openSection;
  @override
  State<BusinessOwnerHubPage> createState() => _BusinessOwnerHubPageState();
}

class _ResolvedBusiness {
  const _ResolvedBusiness({
    required this.id,
    required this.name,
    required this.data,
    required this.source,
  });
  final String id;
  final String name;
  final Map<String, dynamic> data;
  final String source;
}

class _BusinessOwnerHubPageState extends State<BusinessOwnerHubPage> {
  final RegisteredBusinessGatewayRepository _gatewayRepository =
      RegisteredBusinessGatewayRepository();

  Future<_ResolvedBusiness?> _resolveBusiness() async {
    final resolved = await _gatewayRepository.resolveOwnerHubBusiness(
      businessId: widget.businessId,
      initialData: widget.initialData,
    );

    if (resolved == null) return null;

    return _ResolvedBusiness(
      id: resolved.id,
      name: resolved.title,
      data: Map<String, dynamic>.from(resolved.data),
      source: resolved.source,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_gatewayRepository.hasCurrentUser) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: _StateBox(
          icon: Icons.lock_outline_rounded,
          title: 'Giriş gerekli',
          text:
              'Kurumsal Kullanıcı yönetimi için işletme hesabıyla giriş yapılmalı.',
        ),
      );
    }

    return FutureBuilder<_ResolvedBusiness?>(
      future: _resolveBusiness(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final business = snapshot.data;
        if (business == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: _StateBox(
              icon: Icons.store_mall_directory_outlined,
              title: 'Kurumsal Kullanıcı bağlantısı bulunamadı',
              text:
                  'Bu hesaba bağlı işletme kaydı bulunamadı. Önce Uygulama Yönetimi > Kurumsal Kullanıcı Profilimi Düzenle alanından işletme kaydını oluştur veya eşitle.',
            ),
          );
        }

        final id = business.id;
        final name = business.name;
        final data = Map<String, dynamic>.from(business.data);

        switch (widget.openSection ?? 'home') {
          case 'services':
            return BusinessServicesManagePage(
              businessId: id,
              businessData: data,
            );
          case 'staff':
            return BusinessStaffManagePage(businessId: id, businessData: data);
          case 'appointmentManagement':
            return BusinessAppointmentManagementPage(
              businessId: id,
              businessName: name,
            );
          case 'finance':
            return BusinessFinancePage(businessId: id, businessName: name);
          case 'duration':
            return BusinessDurationAnalyticsPage(
              businessId: id,
              businessName: name,
            );
          case 'logs':
            return BusinessActivityLogsPage(businessId: id, businessName: name);
          case 'live':
            return BusinessLiveFlowPage(businessId: id, businessName: name);
          case 'customers':
            return BusinessCustomersPage(businessId: id, businessName: name);
          case 'bulkMessage':
          case 'bulkMessages':
            return BulkMessageCreatePage(businessId: id, businessName: name);
          case 'campaigns':
            return BusinessCampaignsPage(businessId: id, businessName: name);
          case 'pos':
            return const BusinessPosPage();
          case 'products':
            return const BusinessProductsPage();
          case 'stories':
            return BusinessStoryCreatePage(
              businessId: id,
              businessName: name,
              businessLogoUrl: (data['logoUrl'] ?? data['photoUrl'] ?? '')
                  .toString(),
              category: (data['category'] ?? 'Genel').toString(),
            );
          case 'preview':
            return BusinessProfilePage(
              businessId: id,
              businessName: name,
              category: (data['category'] ?? 'Genel').toString(),
            );
          default:
            return _BusinessHubHomePage(
              businessId: id,
              businessName: name,
              data: data,
            );
        }
      },
    );
  }
}

class _BusinessHubHomePage extends StatelessWidget {
  const _BusinessHubHomePage({
    required this.businessId,
    required this.businessName,
    required this.data,
  });
  final String businessId;
  final String businessName;
  final Map<String, dynamic> data;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
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
                    onTap: () => _open(
                      context,
                      BusinessAppointmentManagementPage(
                        businessId: businessId,
                        businessName: businessName,
                      ),
                    ),
                  ),
                  _HubGridAction(
                    width: width,
                    icon: Icons.groups_2_outlined,
                    title: 'Müşteriler',
                    subtitle: 'Geçmiş ve segment',
                    color: const Color(0xFF0F766E),
                    onTap: () => _open(
                      context,
                      BusinessCustomersPage(
                        businessId: businessId,
                        businessName: businessName,
                      ),
                    ),
                  ),
                  _HubGridAction(
                    width: width,
                    icon: Icons.sms_outlined,
                    title: 'Toplu mesaj',
                    subtitle: 'Filtreli gönderim',
                    color: const Color(0xFFEA580C),
                    onTap: () => _open(
                      context,
                      BulkMessageCreatePage(
                        businessId: businessId,
                        businessName: businessName,
                      ),
                    ),
                  ),
                  _HubGridAction(
                    width: width,
                    icon: Icons.storefront_outlined,
                    title: 'Profil',
                    subtitle: 'Vitrin ön izleme',
                    color: const Color(0xFF7C3AED),
                    onTap: () => _open(
                      context,
                      BusinessProfilePage(
                        businessId: businessId,
                        businessName: businessName,
                        category: category.isEmpty ? 'Genel' : category,
                      ),
                    ),
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
            onTap: () => _open(
              context,
              BusinessServicesManagePage(
                businessId: businessId,
                businessData: data,
              ),
            ),
          ),
          _HubActionTile(
            icon: Icons.groups_outlined,
            title: 'Personel ve Yetkiler',
            text: 'Ekip, davet kodu, rol ve yetki düzenini yönet.',
            color: const Color(0xFF7C3AED),
            onTap: () => _open(
              context,
              BusinessStaffManagePage(
                businessId: businessId,
                businessData: data,
              ),
            ),
          ),
          _HubActionTile(
            icon: Icons.monitor_heart_outlined,
            title: 'Canlı Akış',
            text: 'Bugünün işlemleri, personel durumu ve aktif işler.',
            color: const Color(0xFF16A34A),
            onTap: () => _open(
              context,
              BusinessLiveFlowPage(
                businessId: businessId,
                businessName: businessName,
              ),
            ),
          ),
          _HubActionTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Finans ve Masraf',
            text: 'Gelir, gider, dönem özeti ve masraf takibi.',
            color: const Color(0xFF0F766E),
            onTap: () => _open(
              context,
              BusinessFinancePage(
                businessId: businessId,
                businessName: businessName,
              ),
            ),
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
            onTap: () => _open(
              context,
              BusinessCampaignsPage(
                businessId: businessId,
                businessName: businessName,
              ),
            ),
          ),
          _HubActionTile(
            icon: Icons.auto_stories_outlined,
            title: 'Hikaye Paylaş',
            text: 'Keşfet üstündeki hikaye alanında 24 saat görünür.',
            color: const Color(0xFF0891B2),
            onTap: () => _open(
              context,
              BusinessStoryCreatePage(
                businessId: businessId,
                businessName: businessName,
                businessLogoUrl: (data['logoUrl'] ?? data['photoUrl'] ?? '')
                    .toString(),
                category: category.isEmpty ? 'Genel' : category,
              ),
            ),
          ),
          _HubActionTile(
            icon: Icons.receipt_long_rounded,
            title: 'Adisyon ve Satış',
            text: 'Açık adisyon, hızlı satış ve ödeme takibi.',
            color: const Color(0xFF2563EB),
            onTap: () => _open(context, const BusinessPosPage()),
          ),
          _HubActionTile(
            icon: Icons.inventory_2_outlined,
            title: 'Stok ve Ürünler',
            text: 'Ürün kataloğu, stok hareketleri ve vitrin ürünleri.',
            color: const Color(0xFF059669),
            onTap: () => _open(context, const BusinessProductsPage()),
          ),
        ],
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: _InfoCard(icon: icon, title: title, text: text),
    ),
  );
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0F766E), size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    height: 1.35,
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

class _HubHeroCard extends StatelessWidget {
  const _HubHeroCard({
    required this.businessName,
    required this.category,
  });

  final String businessName;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7EDEA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE9FFF4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE9FFF4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Aktif',
              style: TextStyle(
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubSectionHeader extends StatelessWidget {
  const _HubSectionHeader({
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
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _HubGridAction extends StatelessWidget {
  const _HubGridAction({
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
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 96,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 23),
                    const Spacer(),
                    Icon(Icons.arrow_forward_rounded, color: color, size: 18),
                  ],
                ),
                const Spacer(),
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
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubActionTile extends StatelessWidget {
  const _HubActionTile({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
