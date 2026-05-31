part of 'business_owner_hub_page.dart';

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
              title: 'Kurumsal kullanıcı bağlantısı bulunamadı',
              text:
                  'Bu hesaba bağlı bir işletme bulunamadı. Lütfen kurumsal hesabınızla tekrar giriş yapın.',
            ),
          );
        }

        final id = business.id;
        final name = business.name;
        final data = Map<String, dynamic>.from(business.data);
        final permissionKey = _permissionForSection(widget.openSection);
        final session = AppSessionScope.maybeOf(context);
        if (permissionKey != null &&
            session != null &&
            !session.hasPermission(permissionKey)) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: RoleAccessDeniedCard(
              title: 'Yetki gerekli',
              description:
                  'Bu kurumsal alana erişmek için hesabınızda ilgili yetki tanımlı olmalı.',
            ),
          );
        }

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

  String? _permissionForSection(String? openSection) {
    switch (openSection) {
      case 'customers':
        return 'customersRead';
      case 'staff':
        return 'staffManage';
      case 'services':
        return 'servicesManage';
      case 'products':
        return 'productsManage';
      case 'finance':
      case 'pos':
        return 'financeRead';
      case 'campaigns':
      case 'bulkMessage':
      case 'bulkMessages':
      case 'stories':
        return 'campaignRead';
      case 'appointmentManagement':
      case 'live':
        return 'appointmentsRead';
      case 'duration':
      case 'logs':
        return 'managementRead';
    }
    return null;
  }
}
