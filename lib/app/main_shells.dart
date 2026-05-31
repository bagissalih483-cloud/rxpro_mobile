part of '../main.dart';

class GuestMainShell extends StatefulWidget {
  const GuestMainShell({super.key});

  @override
  State<GuestMainShell> createState() => _GuestMainShellState();
}

class _GuestMainShellState extends State<GuestMainShell> {
  late final MainShellController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MainShellController(FixShellNavState.guestIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const titles = ['Keşfet', 'Randevu', 'Favoriler', 'Fırsatlar', 'Giriş'];

  @override
  Widget build(BuildContext context) {
    final version = FixSessionGate.sessionVersion.value;

    final pages = [
      HomeExplorePage(key: ValueKey('guest_home_$version')),
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
      const GuestFeaturePreviewPage(
        icon: Icons.favorite_rounded,
        title: 'Favorilerini kaydetmek için giriş yap',
        description:
            'Beğendiğin kurumsal kullanıcıları takip edebilir, fırsat ve paylaşımlarını tek yerde görebilirsin.',
        bullets: [
          'Takip edilen kurumsal kullanıcıları kaydetme',
          'Paylaşım ve fırsat akışını kişiselleştirme',
          'Sonraki girişlerde kaldığın yerden devam etme',
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return _RxShellScaffold(
          selectedIndex: _controller.selectedIndex,
          titles: titles,
          pages: pages,
          onSelected: (index) {
            FixShellNavState.guestIndex = index;
            _controller.selectIndex(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Keşfet',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Randevu',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favoriler',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_offer_outlined),
              selectedIcon: Icon(Icons.local_offer),
              label: 'Fırsatlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Giriş',
            ),
          ],
        );
      },
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
  late final MainShellController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MainShellController(FixShellNavState.individualIndex);
    if (FixShellNavState.individualIndexNotifier.value !=
        _controller.selectedIndex) {
      FixShellNavState.individualIndexNotifier.value =
          _controller.selectedIndex;
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
    _controller.dispose();
    super.dispose();
  }

  void _handleExternalTabChange() {
    final nextIndex = FixShellNavState.individualIndexNotifier.value;
    if (!mounted || _controller.selectedIndex == nextIndex) return;

    _controller.selectIndex(nextIndex);
  }

  static const titles = ['Keşfet', 'Randevu', 'Favoriler', 'Fırsatlar', 'Hesap'];

  @override
  Widget build(BuildContext context) {
    final userKey = _authService.currentUser?.uid ?? 'guest';

    final pages = [
      HomeExplorePage(key: ValueKey('individual_home_$userKey')),
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
        key: ValueKey('individual_favorite_gate_$userKey'),
        allowedRoles: const {AppRole.individual},
        title: 'Favoriler bireysel kullanıcı alanıdır',
        description:
            'Favori ve takip akışı sadece bireysel kullanıcı hesabıyla kullanılabilir.',
        child: FavoriteFeedPage(key: ValueKey('individual_favorite_$userKey')),
      ),
      SessionRoleGate(
        key: ValueKey('individual_campaigns_gate_$userKey'),
        allowedRoles: const {AppRole.individual},
        title: 'Fırsatlar bireysel kullanıcı alanıdır',
        description:
            'Fırsatları hesabına bağlı takip etmek için bireysel kullanıcı olarak giriş yapmalısın.',
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return _RxShellScaffold(
          selectedIndex: _controller.selectedIndex,
          titles: titles,
          pages: pages,
          onSelected: (index) {
            FixShellNavState.setIndividualIndex(index);
            _controller.selectIndex(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Keşfet',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Randevu',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favoriler',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_offer_outlined),
              selectedIcon: Icon(Icons.local_offer),
              label: 'Fırsatlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Hesap',
            ),
          ],
        );
      },
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
  late final MainShellController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MainShellController(FixShellNavState.corporateIndex);
    if (FixShellNavState.corporateIndexNotifier.value !=
        _controller.selectedIndex) {
      FixShellNavState.corporateIndexNotifier.value =
          _controller.selectedIndex;
    }
    FixShellNavState.corporateIndexNotifier.addListener(
      _handleExternalTabChange,
    );
  }

  @override
  void dispose() {
    FixShellNavState.corporateIndexNotifier.removeListener(
      _handleExternalTabChange,
    );
    _controller.dispose();
    super.dispose();
  }

  void _handleExternalTabChange() {
    final nextIndex = FixShellNavState.corporateIndexNotifier.value;
    if (!mounted || _controller.selectedIndex == nextIndex) return;

    _controller.selectIndex(nextIndex);
  }

  @override
  void didUpdateWidget(covariant BusinessMainShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.role.businessId != widget.role.businessId) {
      FixShellNavState.setCorporateIndex(0);
      _controller.selectIndex(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userKey = _authService.currentUser?.uid ?? 'nouid';
    final sessionKey = '${widget.role.businessId}_$userKey';

    final pages = [
      SessionRoleGate(
        key: ValueKey('corporate_management_gate_$sessionKey'),
        permissionKey: 'managementRead',
        allowedRoles: const {AppRole.corporateOwner, AppRole.corporateStaff},
        title: 'Kurumsal yönetim alanı',
        description:
            'Bu alan müşteri keşfi değil; işletme düzeni, müşteri, personel, hizmet ve stok yönetimi için açılır.',
        child: BusinessManagementHomePage(
          key: ValueKey('corporate_management_$sessionKey'),
          businessId: widget.role.businessId,
          businessName: widget.role.businessName,
          businessData: widget.role.businessData,
        ),
      ),
      SessionRoleGate(
        key: ValueKey('corporate_appointments_gate_$sessionKey'),
        allowedRoles: const {AppRole.corporateOwner, AppRole.corporateStaff},
        permissionKey: 'appointmentsRead',
        title: 'Kurumsal randevu alanı',
        description:
            'Mevcut randevu grid sistemi bu sekmenin ana akışı olarak korunur.',
        child: BusinessAppointmentDashboardPage(
          key: ValueKey('corporate_appointments_$sessionKey'),
          businessId: widget.role.businessId,
          businessName: widget.role.businessName,
          businessData: widget.role.businessData,
        ),
      ),
      SessionRoleGate(
        key: ValueKey('corporate_accounting_gate_$sessionKey'),
        allowedRoles: const {AppRole.corporateOwner, AppRole.corporateStaff},
        permissionKey: 'financeRead',
        title: 'Kurumsal muhasebe alanı',
        description:
            'Muhasebe ekranı sadece kurumsal kullanıcı ve finans yetkisi bulunan personel için açılır.',
        child: BusinessAccountingShell(
          key: ValueKey('corporate_accounting_$sessionKey'),
        ),
      ),
      SessionRoleGate(
        key: ValueKey('corporate_marketing_gate_$sessionKey'),
        allowedRoles: const {AppRole.corporateOwner, AppRole.corporateStaff},
        permissionKey: 'campaignRead',
        title: 'Kurumsal pazarlama alanı',
        description:
            'Kampanya, toplu mesaj, AI kampanya ve vitrin yayınları tek pazarlama merkezinden açılır.',
        child: BusinessMarketingHubPage(
          key: ValueKey('corporate_marketing_$sessionKey'),
          businessId: widget.role.businessId,
          businessName: widget.role.businessName,
          businessData: widget.role.businessData,
        ),
      ),
      SessionRoleGate(
        key: ValueKey('corporate_account_gate_$sessionKey'),
        allowedRoles: const {AppRole.corporateOwner, AppRole.corporateStaff},
        title: 'Kurumsal hesap alanı',
        description:
            'Bu hesap alanı profil, müşteri gibi gör, bildirim, yasal metin ve oturum işlemleri için açılır.',
        child: AccountEntryPage(key: ValueKey('corporate_account_$sessionKey')),
      ),
    ];

    const titles = [
      'Yönetim',
      'Randevu',
      'Muhasebe',
      'Pazarlama',
      'Hesap',
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final session = AppSessionScope.maybeOf(context);
        final visibleIndexes = <int>[
          if (session == null ||
              session.hasOwnerAuthority ||
              session.hasPermission('managementRead'))
            0,
          if (session == null ||
              session.hasOwnerAuthority ||
              session.hasPermission('appointmentsRead'))
            1,
          if (session == null ||
              session.hasOwnerAuthority ||
              session.hasPermission('financeRead'))
            2,
          if (session == null ||
              session.hasOwnerAuthority ||
              session.hasPermission('campaignRead'))
            3,
          4,
        ];
        final visibleTitles = visibleIndexes
            .map((index) => titles[index])
            .toList(growable: false);
        final visiblePages = visibleIndexes
            .map((index) => pages[index])
            .toList(growable: false);
        final visibleDestinations = visibleIndexes
            .map((index) => _businessDestinations[index])
            .toList(growable: false);

        return _RxShellScaffold(
          selectedIndex: _controller.selectedIndex,
          titles: visibleTitles,
          pages: visiblePages,
          onSelected: (index) {
            FixShellNavState.setCorporateIndex(index);
            _controller.selectIndex(index);
          },
          destinations: visibleDestinations,
          tabletMiniDockHiddenTitles: const {'Muhasebe'},
        );
      },
    );
  }
}

const List<NavigationDestination> _businessDestinations = [
  NavigationDestination(
    icon: Icon(Icons.business_center_outlined),
    selectedIcon: Icon(Icons.business_center),
    label: 'Yönetim',
  ),
  NavigationDestination(
    icon: Icon(Icons.calendar_month_outlined),
    selectedIcon: Icon(Icons.calendar_month),
    label: 'Randevu',
  ),
  NavigationDestination(
    icon: Icon(Icons.account_balance_wallet_outlined),
    selectedIcon: Icon(Icons.account_balance_wallet),
    label: 'Muhasebe',
  ),
  NavigationDestination(
    icon: Icon(Icons.campaign_outlined),
    selectedIcon: Icon(Icons.campaign),
    label: 'Pazarlama',
  ),
  NavigationDestination(
    icon: Icon(Icons.person_outline),
    selectedIcon: Icon(Icons.person),
    label: 'Hesap',
  ),
];

class _RxShellScaffold extends StatefulWidget {
  const _RxShellScaffold({
    required this.selectedIndex,
    required this.titles,
    required this.pages,
    required this.onSelected,
    required this.destinations,
    this.tabletMiniDockHiddenTitles = const <String>{},
  });

  final int selectedIndex;
  final List<String> titles;
  final List<Widget> pages;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;
  final Set<String> tabletMiniDockHiddenTitles;

  @override
  State<_RxShellScaffold> createState() => _RxShellScaffoldState();
}

class _RxShellScaffoldState extends State<_RxShellScaffold> {
  DateTime? _lastBackPressedAt;

  Future<bool> _handleBackPressed(int safeIndex) async {
    if (safeIndex != 0) {
      widget.onSelected(0);
      _lastBackPressedAt = null;
      return false;
    }

    final now = DateTime.now();
    final shouldExit =
        _lastBackPressedAt != null &&
        now.difference(_lastBackPressedAt!) < const Duration(seconds: 2);

    if (shouldExit) return true;

    _lastBackPressedAt = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Çıkmak için tekrar geri tuşuna basın.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return RxAdaptiveShellScaffold(
      selectedIndex: widget.selectedIndex,
      titles: widget.titles,
      pages: widget.pages,
      destinations: widget.destinations,
      onSelected: widget.onSelected,
      onBackPressed: _handleBackPressed,
      tabletMiniDockHiddenTitles: widget.tabletMiniDockHiddenTitles,
    );
  }
}
