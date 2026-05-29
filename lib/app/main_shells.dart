part of '../main.dart';

class GuestMainShell extends StatefulWidget {
  const GuestMainShell({super.key});

  @override
  State<GuestMainShell> createState() => _GuestMainShellState();
}

class _GuestMainShellState extends State<GuestMainShell> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = FixShellNavState.guestIndex;
  }

  static const titles = ['Keşfet', 'Favori', 'Randevu', 'Kampanya', 'Giriş'];

  @override
  Widget build(BuildContext context) {
    final version = FixSessionGate.sessionVersion.value;

    final pages = [
      HomeExplorePage(key: ValueKey('guest_home_$version')),
      const GuestFeaturePreviewPage(
        icon: Icons.favorite_rounded,
        title: 'Favorilerini kaydetmek için giriş yap',
        description:
            'Beğendiğin kurumsal kullanıcıları takip edebilir, kampanya ve paylaşımlarını tek yerde görebilirsin.',
        bullets: [
          'Takip edilen kurumsal kullanıcıları kaydetme',
          'Paylaşım ve kampanya akışını kişiselleştirme',
          'Sonraki girişlerde kaldığın yerden devam etme',
        ],
      ),
      const GuestFeaturePreviewPage(
        icon: Icons.calendar_month_rounded,
        title: 'Randevu almak için bireysel hesap gerekli',
        description:
            'Randevu oluşturma, erteleme, iptal ve bildirim takibi için bireysel kullanıcı hesabıyla devam etmelisin.',
        bullets: [
          'Randevu geçmişi ve aktif randevular',
          'Erteleme ve iptal bildirimleri',
          'Kurumsal kullanıcılarla güvenli işlem akışı',
        ],
      ),
      CustomerCampaignsPage(key: ValueKey('guest_campaigns_$version')),
      const GuestFeaturePreviewPage(
        icon: Icons.login_rounded,
        title: 'fix hesabınla devam et',
        description:
            'Bireysel kullanıcı veya kurumsal kullanıcı hesabı oluşturarak uygulamanın tüm özelliklerini kullanabilirsin.',
        bullets: [
          'Bireysel kullanıcı olarak keşfet, takip et ve randevu al',
          'Kurumsal kullanıcı olarak randevu, kampanya ve operasyon yönet',
          'Bildirimler ve işlem geçmişi hesabına bağlı saklansın',
        ],
      ),
    ];

    return _RxShellScaffold(
      selectedIndex: selectedIndex,
      titles: titles,
      pages: pages,
      onSelected: (index) {
        FixShellNavState.guestIndex = index;
        setState(() => selectedIndex = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Keşfet',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite),
          label: 'Favori',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Randevu',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_offer_outlined),
          selectedIcon: Icon(Icons.local_offer),
          label: 'Kampanya',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Giriş',
        ),
      ],
    );
  }
}

class CustomerMainShell extends StatefulWidget {
  const CustomerMainShell({super.key});

  @override
  State<CustomerMainShell> createState() => _CustomerMainShellState();
}

class _CustomerMainShellState extends State<CustomerMainShell> {
  final AuthService _authService = AuthService();
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = FixShellNavState.individualIndex;
    if (FixShellNavState.individualIndexNotifier.value != selectedIndex) {
      FixShellNavState.individualIndexNotifier.value = selectedIndex;
    }
    FixShellNavState.individualIndexNotifier.addListener(
      _handleExternalTabChange,
    );
  }

  @override
  void dispose() {
    FixShellNavState.individualIndexNotifier.removeListener(
      _handleExternalTabChange,
    );
    super.dispose();
  }

  void _handleExternalTabChange() {
    final nextIndex = FixShellNavState.individualIndexNotifier.value;
    if (!mounted || selectedIndex == nextIndex) return;

    setState(() => selectedIndex = nextIndex);
  }

  static const titles = ['Keşfet', 'Favori', 'Randevu', 'Kampanya', 'Hesap'];

  @override
  Widget build(BuildContext context) {
    final userKey = _authService.currentUser?.uid ?? 'guest';

    final pages = [
      HomeExplorePage(key: ValueKey('individual_home_$userKey')),
      SessionRoleGate(
        key: ValueKey('individual_favorite_gate_$userKey'),
        allowedRoles: const {AppRole.individual},
        title: 'Favoriler bireysel kullanıcı alanıdır',
        description:
            'Favori ve takip akışı sadece bireysel kullanıcı hesabıyla kullanılabilir.',
        child: FavoriteFeedPage(key: ValueKey('individual_favorite_$userKey')),
      ),
      SessionRoleGate(
        key: ValueKey('individual_appointments_gate_$userKey'),
        allowedRoles: const {AppRole.individual},
        title: 'Randevularım bireysel kullanıcı alanıdır',
        description:
            'Randevu oluşturma, iptal, erteleme ve geçmiş takibi için bireysel kullanıcı hesabı gerekir.',
        child: CustomerAppointmentsPage(
          key: ValueKey('individual_appointments_$userKey'),
        ),
      ),
      SessionRoleGate(
        key: ValueKey('individual_campaigns_gate_$userKey'),
        allowedRoles: const {AppRole.individual},
        title: 'Kampanyalar bireysel kullanıcı alanıdır',
        description:
            'Kampanyaları hesabına bağlı takip etmek için bireysel kullanıcı olarak giriş yapmalısın.',
        child: CustomerCampaignsPage(
          key: ValueKey('individual_campaigns_$userKey'),
        ),
      ),
      SessionRoleGate(
        key: ValueKey('individual_account_gate_$userKey'),
        allowedRoles: const {AppRole.individual},
        title: 'Bireysel hesap alanı',
        description:
            'Bu hesap alanı sadece bireysel kullanıcı oturumu için açılır.',
        child: AccountEntryPage(key: ValueKey('individual_account_$userKey')),
      ),
    ];

    return _RxShellScaffold(
      selectedIndex: selectedIndex,
      titles: titles,
      pages: pages,
      onSelected: (index) {
        FixShellNavState.setIndividualIndex(index);
        if (selectedIndex != index) {
          setState(() => selectedIndex = index);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Keşfet',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite),
          label: 'Favori',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Randevu',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_offer_outlined),
          selectedIcon: Icon(Icons.local_offer),
          label: 'Kampanya',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Hesap',
        ),
      ],
    );
  }
}

class BusinessMainShell extends StatefulWidget {
  const BusinessMainShell({super.key, required this.role});

  final BusinessRoleResult role;

  @override
  State<BusinessMainShell> createState() => _BusinessMainShellState();
}

class _BusinessMainShellState extends State<BusinessMainShell> {
  final AuthService _authService = AuthService();
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = FixShellNavState.corporateIndex;
  }

  @override
  void didUpdateWidget(covariant BusinessMainShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.role.businessId != widget.role.businessId) {
      FixShellNavState.corporateIndex = 0;
      selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userKey = _authService.currentUser?.uid ?? 'nouid';
    final sessionKey = '${widget.role.businessId}_$userKey';

    final pages = [
      SessionRoleGate(
        key: ValueKey('corporate_preview_gate_$sessionKey'),
        allowedRoles: const {AppRole.corporateOwner, AppRole.corporateStaff},
        title: 'Kurumsal ön izleme alanı',
        description:
            'Bu alan sadece kurumsal kullanıcı veya yetkili kurumsal personel hesabıyla açılır.',
        child: HomeExplorePage(
          key: ValueKey('corporate_preview_$sessionKey'),
          previewMode: true,
          notificationBusinessId: widget.role.businessId,
          notificationBusinessName: widget.role.businessName,
        ),
      ),
      SessionRoleGate(
        key: ValueKey('corporate_accounting_gate_$sessionKey'),
        allowedRoles: const {AppRole.corporateOwner, AppRole.corporateStaff},
        permissionKey: 'financeRead',
        title: 'Kurumsal muhasebe alan\u0131',
        description:
            'Muhasebe ekran\u0131 sadece kurumsal kullan\u0131c\u0131 ve finans yetkisi bulunan personel i\u00e7in a\u00e7\u0131l\u0131r.',
        child: BusinessAccountingShell(
          key: ValueKey('corporate_accounting_$sessionKey'),
        ),
      ),
      SessionRoleGate(
        key: ValueKey('corporate_appointments_gate_$sessionKey'),
        allowedRoles: const {AppRole.corporateOwner, AppRole.corporateStaff},
        permissionKey: 'appointmentsRead',
        title: 'Kurumsal işlem yönetimi',
        description:
            'Bu alan bireysel randevularım ekranı değildir; sadece kurumsal işlem yönetimi için açılır.',
        child: BusinessAppointmentDashboardPage(
          key: ValueKey('corporate_appointments_$sessionKey'),
          businessId: widget.role.businessId,
          businessName: widget.role.businessName,
          businessData: widget.role.businessData,
        ),
      ),
      SessionRoleGate(
        key: ValueKey('corporate_campaigns_gate_$sessionKey'),
        allowedRoles: const {AppRole.corporateOwner, AppRole.corporateStaff},
        permissionKey: 'campaignRead',
        title: 'Kurumsal kampanya alanı',
        description:
            'Kampanya yönetimi sadece kurumsal kullanıcı ve yetkili personel için açılır.',
        child: BusinessCampaignsPage(
          key: ValueKey('corporate_campaigns_$sessionKey'),
          businessId: widget.role.businessId,
          businessName: widget.role.businessName,
        ),
      ),
      SessionRoleGate(
        key: ValueKey('corporate_account_gate_$sessionKey'),
        allowedRoles: const {AppRole.corporateOwner, AppRole.corporateStaff},
        title: 'Kurumsal hesap alanı',
        description:
            'Bu hesap alanı sadece kurumsal kullanıcı veya yetkili personel oturumu için açılır.',
        child: AccountEntryPage(key: ValueKey('corporate_account_$sessionKey')),
      ),
    ];

    const titles = [
      'Ön İzleme',
      'Muhasebe',
      'İşlemler',
      'Kampanyalar',
      'Hesap',
    ];

    return _RxShellScaffold(
      selectedIndex: selectedIndex,
      titles: titles,
      pages: pages,
      onSelected: (index) {
        FixShellNavState.corporateIndex = index;
        setState(() => selectedIndex = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Ön İzleme',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Muhasebe',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: 'İşlemler',
        ),
        NavigationDestination(
          icon: Icon(Icons.campaign_outlined),
          selectedIcon: Icon(Icons.campaign),
          label: 'Kampanyalar',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Hesap',
        ),
      ],
    );
  }
}

class _RxShellScaffold extends StatelessWidget {
  const _RxShellScaffold({
    required this.selectedIndex,
    required this.titles,
    required this.pages,
    required this.onSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final List<String> titles;
  final List<Widget> pages;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final safeIndex = selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[safeIndex],
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: false,
      ),
      body: _LazyShellStack(index: safeIndex, pages: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: onSelected,
        destinations: destinations,
      ),
    );
  }
}

class _LazyShellStack extends StatefulWidget {
  const _LazyShellStack({required this.index, required this.pages});

  final int index;
  final List<Widget> pages;

  @override
  State<_LazyShellStack> createState() => _LazyShellStackState();
}

class _LazyShellStackState extends State<_LazyShellStack> {
  final Set<int> _visited = <int>{};

  @override
  void initState() {
    super.initState();
    _visited.add(widget.index);
  }

  @override
  void didUpdateWidget(covariant _LazyShellStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited
      ..removeWhere((index) => index >= widget.pages.length)
      ..add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final index in _visited)
          Offstage(
            offstage: index != widget.index,
            child: TickerMode(
              enabled: index == widget.index,
              child: SizedBox.expand(
                child: KeyedSubtree(
                  key: PageStorageKey<String>('shell_page_$index'),
                  child: widget.pages[index],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
