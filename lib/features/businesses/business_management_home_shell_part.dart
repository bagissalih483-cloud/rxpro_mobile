part of 'business_management_home_page.dart';

class BusinessManagementHomePage extends StatefulWidget {
  const BusinessManagementHomePage({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.businessData,
  });

  final String businessId;
  final String businessName;
  final Map<String, dynamic> businessData;

  @override
  State<BusinessManagementHomePage> createState() =>
      _BusinessManagementHomePageState();
}

class _BusinessManagementHomePageState
    extends State<BusinessManagementHomePage> {
  late final BusinessManagementHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BusinessManagementHomeController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openOwnerHub(
    BuildContext context,
    String section, {
    String? permissionKey,
  }) {
    final session = AppSessionScope.maybeOf(context);
    if (permissionKey != null &&
        permissionKey.trim().isNotEmpty &&
        session != null &&
        !session.hasPermission(permissionKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu yönetim alanı için yetkiniz yok.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.businessOwnerHub,
      arguments: BusinessOwnerHubRouteArgs(
        businessId: widget.businessId,
        initialData: widget.businessData,
        openSection: section,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = _firstText([
      widget.businessData['categoryLabel'],
      widget.businessData['category'],
    ], fallback: 'Genel');

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _ManagementHeroCard(
              businessName: widget.businessName,
              category: category,
            ),
            const SizedBox(height: 12),
            _TodaySummaryCard(
              expanded: _controller.summaryExpanded,
              onToggle: _controller.toggleSummary,
            ),
            const SizedBox(height: 16),
            const _ManagementSectionHeader(
              title: 'Hızlı İşlemler',
              subtitle: 'İşletme düzenini hızlıca güncelle.',
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 980
                    ? 4
                    : constraints.maxWidth >= 640
                    ? 3
                    : 2;
                final itemWidth =
                    (constraints.maxWidth - (10 * (columns - 1))) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ManagementActionCard(
                      width: itemWidth,
                      icon: Icons.groups_2_outlined,
                      title: 'Müşteri ekle',
                      subtitle: 'Kayıt ve geçmiş',
                      color: const Color(0xFF0F766E),
                      onTap: () => _openOwnerHub(
                        context,
                        'customers',
                        permissionKey: 'customersRead',
                      ),
                    ),
                    _ManagementActionCard(
                      width: itemWidth,
                      icon: Icons.group_add_outlined,
                      title: 'Personel ekle',
                      subtitle: 'Yetki ve davet',
                      color: const Color(0xFF7C3AED),
                      onTap: () => _openOwnerHub(
                        context,
                        'staff',
                        permissionKey: 'staffManage',
                      ),
                    ),
                    _ManagementActionCard(
                      width: itemWidth,
                      icon: Icons.room_service_outlined,
                      title: 'Hizmet ekle',
                      subtitle: 'Süre ve fiyat',
                      color: const Color(0xFF2563EB),
                      onTap: () => _openOwnerHub(
                        context,
                        'services',
                        permissionKey: 'servicesManage',
                      ),
                    ),
                    _ManagementActionCard(
                      width: itemWidth,
                      icon: Icons.inventory_2_outlined,
                      title: 'Ürün ekle',
                      subtitle: 'Katalog ve miktar',
                      color: const Color(0xFF059669),
                      onTap: () => _openOwnerHub(
                        context,
                        'products',
                        permissionKey: 'productsManage',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            const _ManagementSectionHeader(
              title: 'İşletme Düzeni',
              subtitle: 'Müşteri, ekip, hizmet ve stok sınıflandırması.',
            ),
            _ManagementListTile(
              icon: Icons.groups_2_outlined,
              title: 'Müşteriler',
              subtitle: 'Kayıtlar, notlar, geçmiş ve birebir mesaj bağlantısı.',
              color: const Color(0xFF0F766E),
              onTap: () => _openOwnerHub(
                context,
                'customers',
                permissionKey: 'customersRead',
              ),
            ),
            _ManagementListTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Personel & Yetki',
              subtitle: 'Rol, kurumsal giriş kodu ve işletme erişimleri.',
              color: const Color(0xFF7C3AED),
              onTap: () => _openOwnerHub(
                context,
                'staff',
                permissionKey: 'staffManage',
              ),
            ),
            _ManagementListTile(
              icon: Icons.room_service_outlined,
              title: 'Hizmetler',
              subtitle: 'Hizmet, paket, süre, fiyat ve personel ataması.',
              color: const Color(0xFF2563EB),
              onTap: () => _openOwnerHub(
                context,
                'services',
                permissionKey: 'servicesManage',
              ),
            ),
            _ManagementListTile(
              icon: Icons.inventory_2_outlined,
              title: 'Ürün / Stok',
              subtitle: 'Ürün tanımı, kritik stok ve aktif/pasif durumu.',
              color: const Color(0xFF059669),
              onTap: () => _openOwnerHub(
                context,
                'products',
                permissionKey: 'productsManage',
              ),
            ),
            const SizedBox(height: 10),
            const _ManagementSectionHeader(
              title: 'Operasyon',
              subtitle: 'Süre analizi ve işlem hareketleri.',
            ),
            _ManagementListTile(
              icon: Icons.timer_outlined,
              title: 'Süre analizi',
              subtitle: 'Hizmet süreleri ve operasyon verimliliği.',
              color: const Color(0xFFEA580C),
              onTap: () => _openOwnerHub(context, 'duration'),
            ),
            _ManagementListTile(
              icon: Icons.manage_history_outlined,
              title: 'Hareketler',
              subtitle: 'İşlem geçmişi ve kurumsal aktivite kayıtları.',
              color: const Color(0xFF334155),
              onTap: () => _openOwnerHub(context, 'logs'),
            ),
          ],
        );
      },
    );
  }
}

class BusinessManagementHomeController extends ChangeNotifier {
  bool _summaryExpanded = false;

  bool get summaryExpanded => _summaryExpanded;

  void toggleSummary() {
    _summaryExpanded = !_summaryExpanded;
    notifyListeners();
  }
}
