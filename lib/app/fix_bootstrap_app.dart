part of '../main.dart';

class FixBootstrapApp extends StatefulWidget {
  const FixBootstrapApp({super.key});

  @override
  State<FixBootstrapApp> createState() => _FixBootstrapAppState();
}

class _FixBootstrapAppState extends State<FixBootstrapApp> {
  final FixBootstrapController _controller = FixBootstrapController();

  @override
  void initState() {
    super.initState();
    _controller.setBootstrapFuture(_bootstrap());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    debugPrint('FIX_BOOTSTRAP_START');
    _setBootstrapMessage('Fix hazırlanıyor...');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));

    debugPrint('FIX_BOOTSTRAP_FIREBASE_READY');
    _setBootstrapMessage('Yakındaki güvenilir işletmeleri keşfet.');

    try {
      await FirebaseAppCheckBootstrap.activate().timeout(
        const Duration(seconds: 8),
      );
      debugPrint('FIX_BOOTSTRAP_APP_CHECK_READY');
    } catch (error, stackTrace) {
      debugPrint('FIX_BOOTSTRAP_APP_CHECK_SKIPPED $error');
      unawaited(
        AppObservabilityService.instance.recordError(
          error,
          stackTrace,
          fatal: false,
          reason: 'Firebase App Check activation failed',
        ),
      );
    }

    try {
      await AppObservabilityService.instance.initialize().timeout(
        const Duration(seconds: 4),
      );
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
    _setBootstrapMessage('Hesabın yükleniyor...');
  }

  void _setBootstrapMessage(String message) {
    if (!mounted) return;
    _controller.setBootstrapMessage(message);
  }

  void _retryBootstrap() {
    _controller.setBootstrapFuture(_bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FutureBuilder<void>(
          future: _controller.bootstrapFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                !snapshot.hasError) {
              return const FixApp();
            }

            if (snapshot.hasError) {
              return _BootstrapMaterialShell(
                child: _StartupRecoveryPage(
                  message:
                      'Fix şu anda açılamadı. İnternet bağlantını kontrol edip tekrar deneyebilirsin.',
                  onRetry: _retryBootstrap,
                ),
              );
            }

            return _BootstrapMaterialShell(
              child: FixSessionLoadingImage(
                message: _controller.bootstrapMessage,
              ),
            );
          },
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
      title: 'Fix',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const RxAdaptiveScrollBehavior(),
      builder: (context, child) {
        return RxAdaptiveAppFrame(child: child ?? const SizedBox.shrink());
      },
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: RxColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: RxColors.primary,
          brightness: Brightness.light,
        ),
        snackBarTheme: _fixSnackBarTheme(),
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
      onGenerateRoute: AppRouteCatalog.onGenerateRoute,
      onUnknownRoute: AppRouteCatalog.onUnknownRoute,
      title: 'Fix',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const RxAdaptiveScrollBehavior(),
      builder: (context, child) {
        return RxAdaptiveAppFrame(
          onDismiss: () {
            final navigator =
                RxPushNotificationService.navigatorKey.currentState;
            if (navigator != null && navigator.canPop()) {
              navigator.maybePop();
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: RxColors.surface,
          selectedIconTheme: IconThemeData(color: RxColors.primary, size: 24),
          unselectedIconTheme: IconThemeData(color: RxColors.muted, size: 22),
          selectedLabelTextStyle: TextStyle(
            color: RxColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: RxColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
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
        snackBarTheme: _fixSnackBarTheme(),
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

SnackBarThemeData _fixSnackBarTheme() {
  return SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF0F172A),
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
    elevation: 8,
    insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
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
      appBar: AppBar(title: const Text('Sistem tanılama')),
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
              'Uygulama tanılama modunda açıldı.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: RxColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu ekran oturum, bildirim ve Keşfet yükleme adımlarını ayrı ayrı kontrol etmek için kullanılır.',
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
              label: 'Keşfet teknik günlükleri',
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
  const _DiagnosticFlagTile({required this.label, required this.enabled});

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
