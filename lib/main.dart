import 'dart:async';
import 'package:rxpro_mobile/features/auth/widgets/fix_session_loading_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'package:rxpro_mobile/core/session/session_role_gate.dart';
import 'package:rxpro_mobile/core/session/app_session_scope.dart';
import 'package:rxpro_mobile/core/session/app_role.dart';
import 'core/theme/rx_ui.dart';
import 'core/diagnostics/rx_runtime_diagnostics.dart';
import 'core/app_state/follow_cache_warmup_service.dart';
import 'core/app_state/fix_session_gate.dart';
import 'core/app_state/fix_shell_nav_state.dart';
import 'core/services/app_observability_service.dart';
import 'core/services/auth_service.dart';
import 'core/session/app_session.dart';
import 'core/session/app_session_controller.dart';
import 'core/realtime/rx_push_notification_service.dart';
import 'features/appointments/presentation/pages/appointment_entry_page.dart';
import 'features/appointments/presentation/pages/customer_appointments_page.dart';
import 'features/business_role/business_role_resolver.dart';
import 'features/campaigns/business_campaigns_page.dart';
import 'features/campaigns/customer_campaigns_page.dart';
import 'features/favorites/favorite_feed_page.dart';
import 'features/public_home/presentation/pages/account_entry_page.dart';
import 'features/auth/fix_login_gate_page.dart';
import 'features/accounting/business_accounting_shell.dart';
import 'features/public_home/home_explore_page.dart';
import 'features/public_home/guest_feature_preview_page.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      unawaited(
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]),
      );

      runApp(const FixBootstrapApp());
    },
    (error, stackTrace) {
      unawaited(
        AppObservabilityService.instance.recordError(
          error,
          stackTrace,
          fatal: true,
          reason: 'Uncaught root zone error',
        ),
      );
    },
  );
}

class FixBootstrapApp extends StatefulWidget {
  const FixBootstrapApp({super.key});

  @override
  State<FixBootstrapApp> createState() => _FixBootstrapAppState();
}

class _FixBootstrapAppState extends State<FixBootstrapApp> {
  late Future<void> _bootstrapFuture;
  String _bootstrapMessage = 'fix başlatılıyor...';

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    debugPrint('FIX_BOOTSTRAP_START');
    _setBootstrapMessage('Firebase bağlantısı hazırlanıyor...');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));

    debugPrint('FIX_BOOTSTRAP_FIREBASE_READY');
    _setBootstrapMessage('Servisler hazırlanıyor...');

    try {
      await AppObservabilityService.instance
          .initialize()
          .timeout(const Duration(seconds: 4));
      debugPrint('FIX_BOOTSTRAP_OBSERVABILITY_READY');
    } catch (error) {
      debugPrint('FIX_BOOTSTRAP_OBSERVABILITY_SKIPPED $error');
    }

    if (RxRuntimeDiagnostics.shouldSkipDeferredStartup) {
      debugPrint(
        'FIX_DEFERRED_STARTUP_DISABLED '
        'safeBoot=${RxRuntimeDiagnostics.safeBoot} '
        'flag=${RxRuntimeDiagnostics.disableDeferredStartup}',
      );
    } else {
      FirebaseMessaging.onBackgroundMessage(
        rxFirebaseMessagingBackgroundHandler,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_startDeferredStartupServices());
      });
    }

    debugPrint('FIX_BOOTSTRAP_DONE');
    _setBootstrapMessage('Oturum açılıyor...');
  }

  void _setBootstrapMessage(String message) {
    if (!mounted || _bootstrapMessage == message) return;
    setState(() {
      _bootstrapMessage = message;
    });
  }

  void _retryBootstrap() {
    setState(() {
      _bootstrapFuture = _bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const FixApp();
        }

        if (snapshot.hasError) {
          return _BootstrapMaterialShell(
            child: _StartupRecoveryPage(
              message:
                  'Uygulama servisleri başlatılamadı. İnternet bağlantısını kontrol edip tekrar deneyin.',
              onRetry: _retryBootstrap,
            ),
          );
        }

        return _BootstrapMaterialShell(
          child: FixSessionLoadingImage(message: _bootstrapMessage),
        );
      },
    );
  }
}

class _BootstrapMaterialShell extends StatelessWidget {
  const _BootstrapMaterialShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: RxColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: RxColors.primary,
          brightness: Brightness.light,
        ),
      ),
      home: child,
    );
  }
}

Future<void> _startDeferredStartupServices() async {
  await Future<void>.delayed(const Duration(seconds: 12));

  unawaited(
    _guardDeferredStartup(
      label: 'push_notifications',
      task: RxPushNotificationService.instance.initialize(),
      timeout: const Duration(seconds: 8),
    ),
  );

  await Future<void>.delayed(const Duration(seconds: 8));

  unawaited(
    _guardDeferredStartup(
      label: 'follow_cache_warmup',
      task: FollowCacheWarmupService().syncCurrentUserFollows(),
      timeout: const Duration(seconds: 6),
    ),
  );
}

Future<void> _guardDeferredStartup({
  required String label,
  required Future<void> task,
  required Duration timeout,
}) async {
  try {
    await task.timeout(timeout);
  } catch (error, stackTrace) {
    debugPrint('FI_DEFERRED_STARTUP_$label skipped: $error');
    unawaited(
      AppObservabilityService.instance.recordError(
        error,
        stackTrace,
        fatal: false,
        reason: 'Deferred startup service failed: $label',
      ),
    );
  }
}

class FixApp extends StatelessWidget {
  const FixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: RxPushNotificationService.navigatorKey,
      navigatorObservers: AppObservabilityService.instance.navigatorObservers,
      title: 'fix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: RxColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: RxColors.primary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: RxColors.background,
          foregroundColor: RxColors.text,
          titleTextStyle: TextStyle(
            color: RxColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          height: 66,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          iconTheme: WidgetStatePropertyAll(IconThemeData(size: 22)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: RxColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: RxRuntimeDiagnostics.safeBoot
          ? const _RuntimeDiagnosticHome()
          : ValueListenableBuilder<int>(
              valueListenable: FixSessionGate.sessionVersion,
              builder: (context, version, _) {
                return RoleGateShell(key: ValueKey('role_gate_$version'));
              },
            ),
    );
  }
}

class _RuntimeDiagnosticHome extends StatelessWidget {
  const _RuntimeDiagnosticHome();

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RxColors.background,
      appBar: AppBar(title: const Text('Tanı modu')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(
              Icons.health_and_safety_outlined,
              size: 46,
              color: RxColors.primary,
            ),
            const SizedBox(height: 14),
            const Text(
              'Uygulama izole modda açıldı.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: RxColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu ekran normal oturum akışını, push servislerini ve otomatik Keşfet yüklemesini ayırmak için kullanılır.',
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: RxColors.muted,
              ),
            ),
            const SizedBox(height: 18),
            _DiagnosticFlagTile(
              label: 'Safe boot',
              enabled: RxRuntimeDiagnostics.safeBoot,
            ),
            _DiagnosticFlagTile(
              label: 'Deferred startup kapalı',
              enabled: RxRuntimeDiagnostics.shouldSkipDeferredStartup,
            ),
            _DiagnosticFlagTile(
              label: 'Keşfet otomatik yükleme kapalı',
              enabled: RxRuntimeDiagnostics.disableExploreAutoLoad,
            ),
            _DiagnosticFlagTile(
              label: 'Keşfet render logları',
              enabled: RxRuntimeDiagnostics.verboseExploreRender,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _open(context, const RoleGateShell()),
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text('Normal oturum akışına gir'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _open(context, const FixLoginGatePage()),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Sadece giriş ekranını aç'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _open(context, const _DiagnosticExploreHost()),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Keşfet ekranını manuel aç'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticExploreHost extends StatelessWidget {
  const _DiagnosticExploreHost();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7FBFC),
      body: HomeExplorePage(),
    );
  }
}

class _DiagnosticFlagTile extends StatelessWidget {
  const _DiagnosticFlagTile({
    required this.label,
    required this.enabled,
  });

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        enabled ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        color: enabled ? RxColors.success : RxColors.muted,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: RxColors.text,
        ),
      ),
    );
  }
}

class RoleGateShell extends StatefulWidget {
  const RoleGateShell({super.key});

  @override
  State<RoleGateShell> createState() => _RoleGateShellState();
}

class _RoleGateShellState extends State<RoleGateShell> {
  final AuthService _authService = AuthService();
  AppSession? _lastSession;
  String? _observedUserId;
  bool _allowRoleRepair = false;
  Timer? _roleRepairTimer;
  bool _startupTimedOut = false;
  String _startupPhase = '';
  Timer? _startupTimer;

  static const Duration _startupTimeout = Duration(seconds: 10);

  void _syncObservedUser(User? user) {
    final nextUserId = user?.uid;
    if (_observedUserId == nextUserId) return;
    if (_observedUserId != null && _observedUserId != nextUserId) {
      _lastSession = null;
      _resetStartupTimeout();
      _resetRoleRepairDelay();
    }
    _observedUserId = nextUserId;
    unawaited(AppObservabilityService.instance.setUserId(nextUserId));
  }

  void _armRoleRepairDelay() {
    if (_allowRoleRepair || _roleRepairTimer != null) return;
    _roleRepairTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _allowRoleRepair = true;
      });
    });
  }

  void _resetRoleRepairDelay() {
    _roleRepairTimer?.cancel();
    _roleRepairTimer = null;
    if (_allowRoleRepair) {
      _allowRoleRepair = false;
    }
  }

  void _armStartupTimeout(String phase) {
    if (_startupPhase != phase) {
      _startupTimer?.cancel();
      _startupTimer = null;
      _startupTimedOut = false;
      _startupPhase = phase;
    }

    if (_startupTimer != null || _startupTimedOut) return;

    _startupTimer = Timer(_startupTimeout, () {
      if (!mounted) return;
      setState(() {
        _startupTimedOut = true;
      });
    });
  }

  void _resetStartupTimeout() {
    _startupTimer?.cancel();
    _startupTimer = null;
    _startupPhase = '';
    _startupTimedOut = false;
  }

  void _retryStartup() {
    _startupTimer?.cancel();
    _startupTimer = null;
    _startupTimedOut = false;
    _startupPhase = '';
    _resetRoleRepairDelay();
    FixSessionGate.refreshAfterAuthChange();
    if (mounted) setState(() {});
  }

  Future<void> _signOutForRecovery() async {
    try {
      await _authService
          .signOut(reason: 'startup_recovery')
          .timeout(const Duration(seconds: 8));
    } catch (error, stackTrace) {
      unawaited(
        AppObservabilityService.instance.recordError(
          error,
          stackTrace,
          fatal: false,
          reason: 'Startup recovery sign-out failed',
        ),
      );
    } finally {
      _lastSession = null;
      _resetStartupTimeout();
      _resetRoleRepairDelay();
      FixSessionGate.refreshAfterAuthChange();
    }
  }

  @override
  void dispose() {
    _roleRepairTimer?.cancel();
    _startupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: FixSessionGate.sessionVersion,
      builder: (context, sessionVersion, _) {
        return StreamBuilder<User?>(
          key: ValueKey('auth_stream_$sessionVersion'),
          stream: _authService.idTokenChanges(),
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;
            _syncObservedUser(user);

            if (authSnapshot.connectionState == ConnectionState.waiting &&
                _lastSession == null) {
              _armStartupTimeout('auth');

              if (_startupTimedOut) {
                return _StartupRecoveryPage(
                  message:
                      'Oturum kontrolü beklenenden uzun sürdü. Bağlantı yavaş olabilir.',
                  onRetry: _retryStartup,
                  onSignOut: _authService.currentUser == null
                      ? null
                      : _signOutForRecovery,
                );
              }

              return const _FixSessionLoadingPromo(
                message: 'Oturum kontrol ediliyor...',
              );
            }

            if (user == null) {
              _lastSession = null;
              _resetStartupTimeout();
              _resetRoleRepairDelay();

              return ValueListenableBuilder<bool>(
                valueListenable: FixSessionGate.guestMode,
                builder: (context, guestMode, _) {
                  if (guestMode) {
                    return GuestMainShell(
                      key: ValueKey('guest_shell_$sessionVersion'),
                    );
                  }

                  return FixLoginGatePage(
                    key: ValueKey('login_gate_$sessionVersion'),
                  );
                },
              );
            }

            return StreamBuilder<AppSession>(
              key: ValueKey('app_session_${user.uid}_$sessionVersion'),
              stream: AppSessionController.watchForUser(user),
              builder: (context, sessionSnapshot) {
                final freshSession = sessionSnapshot.data;

                if (freshSession != null && !freshSession.isInvalid) {
                  _lastSession = freshSession;
                  _resetStartupTimeout();
                  _resetRoleRepairDelay();
                }

                final session = freshSession != null && !freshSession.isInvalid
                    ? freshSession
                    : _lastSession;

                if (session == null) {
                  if (sessionSnapshot.connectionState ==
                          ConnectionState.active &&
                      freshSession != null &&
                      freshSession.isInvalid) {
                    _armRoleRepairDelay();

                    if (!_allowRoleRepair) {
                      return const _FixSessionLoadingPromo(
                        message: 'Hesap rolü kontrol ediliyor...',
                      );
                    }

                    return _RoleRepairPage(
                      key: ValueKey('role_repair_${user.uid}_$sessionVersion'),
                      message: freshSession.message,
                    );
                  }

                  _armStartupTimeout('session_${user.uid}');

                  if (_startupTimedOut) {
                    return _StartupRecoveryPage(
                      message:
                          'Hesap bilgileri beklenenden uzun sürdü. Uygulama kilitlenmedi; oturum servisi bekliyor.',
                      onRetry: _retryStartup,
                      onSignOut: _signOutForRecovery,
                    );
                  }

                  return const _FixSessionLoadingPromo(
                    message: 'Hesap bilgileri yükleniyor...',
                  );
                }

                if (session.isCorporate) {
                  if (session.businessId.trim().isEmpty) {
                    return _RoleRepairPage(
                      key: ValueKey(
                        'role_repair_business_missing_${session.uid}_$sessionVersion',
                      ),
                      message:
                          'Kurumsal hesap için businessId bağlantısı bulunamadı. Kurumsal kayıt bağlamı tamamlanmadan yönetim alanları açılamaz.',
                    );
                  }

                  return AppSessionScope(
                    session: session,
                    child: BusinessMainShell(
                      key: ValueKey(
                        'business_shell_${session.uid}_${session.businessId}',
                      ),
                      role: BusinessRoleResult.business(
                        businessId: session.businessId,
                        businessName: session.businessName,
                        businessData: session.businessData,
                      ),
                    ),
                  );
                }

                if (session.isIndividual) {
                  return AppSessionScope(
                    session: session,
                    child: CustomerMainShell(
                      key: ValueKey('individual_shell_${session.uid}'),
                    ),
                  );
                }

                return _RoleRepairPage(
                  key: ValueKey(
                    'role_repair_fallback_${user.uid}_$sessionVersion',
                  ),
                  message:
                      'Bu hesap için geçerli bir uygulama rolü bulunamadı.',
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FixSessionLoadingPromo extends StatelessWidget {
  const _FixSessionLoadingPromo({this.message = 'Oturum hazırlanıyor...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return FixSessionLoadingImage(message: message);
  }
}

class _StartupRecoveryPage extends StatelessWidget {
  const _StartupRecoveryPage({
    required this.message,
    required this.onRetry,
    this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RxColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_tethering_error_rounded,
                      size: 42,
                      color: RxColors.primary,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Bağlantı bekleniyor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: RxColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: RxColors.muted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tekrar dene'),
                    ),
                    if (onSignOut != null) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => unawaited(onSignOut!()),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Giriş ekranına dön'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleRepairPage extends StatelessWidget {
  const _RoleRepairPage({super.key, required this.message});

  final String message;
  static final AuthService _authService = AuthService();

  Future<void> _signOut() async {
    await _authService.signOut(reason: 'role_repair');
    FixSessionGate.refreshAfterAuthChange();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RxColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.privacy_tip_outlined,
                      size: 44,
                      color: Color(0xFF1DB954),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Rol doğrulaması gerekli',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: RxColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: RxColors.muted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Çıkış yap ve tekrar giriş yap'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
        FixShellNavState.individualIndex = index;
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

    const titles = ['Ön İzleme', 'Muhasebe', 'İşlemler', 'Kampanyalar', 'Hesap'];

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
  const _LazyShellStack({
    required this.index,
    required this.pages,
  });

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
