part of '../main.dart';

class RoleGateShell extends StatefulWidget {
  const RoleGateShell({super.key});

  @override
  State<RoleGateShell> createState() => _RoleGateShellState();
}

class _RoleGateShellState extends State<RoleGateShell> {
  final AuthService _authService = AuthService();
  final RoleGateController _controller = RoleGateController();
  AppSession? _lastSession;
  String? _observedUserId;
  Timer? _roleRepairTimer;
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
    if (_controller.allowRoleRepair || _roleRepairTimer != null) return;
    _roleRepairTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _controller.setAllowRoleRepair(true);
    });
  }

  void _resetRoleRepairDelay() {
    _roleRepairTimer?.cancel();
    _roleRepairTimer = null;
    _controller.setAllowRoleRepair(false, notify: false);
  }

  void _armStartupTimeout(String phase) {
    if (_startupPhase != phase) {
      _startupTimer?.cancel();
      _startupTimer = null;
      _controller.setStartupTimedOut(false, notify: false);
      _startupPhase = phase;
    }

    if (_startupTimer != null || _controller.startupTimedOut) return;

    _startupTimer = Timer(_startupTimeout, () {
      if (!mounted) return;
      _controller.setStartupTimedOut(true);
    });
  }

  void _resetStartupTimeout() {
    _startupTimer?.cancel();
    _startupTimer = null;
    _startupPhase = '';
    _controller.setStartupTimedOut(false, notify: false);
  }

  void _retryStartup() {
    _startupTimer?.cancel();
    _startupTimer = null;
    _controller.setStartupTimedOut(false, notify: false);
    _startupPhase = '';
    _resetRoleRepairDelay();
    FixSessionGate.refreshAfterAuthChange();
    if (mounted) _controller.requestRefresh();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
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

              if (_controller.startupTimedOut) {
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

                    if (!_controller.allowRoleRepair) {
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

                  if (_controller.startupTimedOut) {
                    return _StartupRecoveryPage(
                      message:
                          'Hesap bilgileri beklenenden uzun sürdü. Bağlantını kontrol edip tekrar deneyebilirsin.',
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
