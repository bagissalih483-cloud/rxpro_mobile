import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/account/account_mode.dart';
import 'package:rxpro_mobile/core/account/account_mode_resolver.dart';
import 'package:rxpro_mobile/core/session/app_session_scope.dart';
import 'package:rxpro_mobile/core/session/app_session.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/campaigns/bulk_message_create_page.dart';
import 'package:rxpro_mobile/features/campaigns/business_campaigns_page.dart';

import 'package:rxpro_mobile/features/businesses/business_activity_logs_page.dart';
import 'package:rxpro_mobile/features/businesses/business_duration_analytics_page.dart';
import 'package:rxpro_mobile/features/businesses/presentation/pages/business_finance_page.dart';
import 'package:rxpro_mobile/features/businesses/business_profile_page.dart';
import 'package:rxpro_mobile/features/businesses/business_services_manage_page.dart';
import 'package:rxpro_mobile/features/businesses/presentation/pages/business_staff_manage_page.dart';
import 'package:rxpro_mobile/features/messages/messages_inbox_page.dart';
import 'package:rxpro_mobile/core/app_state/fix_session_gate.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';
import 'package:rxpro_mobile/features/businesses/business_live_flow_page.dart';
import 'package:rxpro_mobile/features/businesses/business_appointment_management_page.dart';
import 'package:rxpro_mobile/features/businesses/business_customers_page.dart';
import 'package:rxpro_mobile/features/public_home/data/account_entry_repository.dart';
import 'package:rxpro_mobile/features/public_home/presentation/models/account_entry_context.dart';
import 'package:rxpro_mobile/features/public_home/presentation/widgets/account_entry_menu.dart';
import 'package:rxpro_mobile/features/stories/business_story_create_page.dart';

/// Account entry keeps account lookup and sign-out behind services.
class AccountEntryPage extends StatefulWidget {
  const AccountEntryPage({super.key});

  @override
  State<AccountEntryPage> createState() => _AccountEntryPageState();
}

class _AccountEntryPageState extends State<AccountEntryPage> {
  final Set<int> _open = <int>{};
  final AccountEntryRepository _repository = AccountEntryRepository();
  final AuthService _authService = AuthService();
  Future<AccountEntryContext>? _contextFuture;
  String? _loadedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshContextIfNeeded();
  }

  // 45B_SESSION_SCOPE_PATCH
  // Hesabım sekmesinde AppSessionScope varsa onu ana kaynak kabul eder.
  // Böylece sekmeye her girişte yeniden Firestore context çözme hissi azalır.
  void _refreshContextIfNeeded() {
    final currentUser = _authService.currentUser;
    final scoped = _scopedAccountSession(context);

    if (scoped != null && scoped.isAuthenticated && currentUser != null) {
      final scopedKey =
          '${scoped.uid}|${scoped.role.name}|${scoped.businessId}';
      if (_contextFuture == null || _loadedUid != scopedKey) {
        _loadedUid = scopedKey;
        _contextFuture = Future<AccountEntryContext>.value(
          _contextFromScopedSession(scoped),
        );
      }
      return;
    }

    final uid = currentUser?.uid;
    if (_contextFuture == null || _loadedUid != uid) {
      _loadedUid = uid;
      _contextFuture = _loadContext();
    }
  }

  AccountEntryContext _contextFromScopedSession(AppSession session) {
    return AccountEntryContext.fromSession(session, _authService.currentUser);
  }

  void _toggle(int index) {
    setState(() {
      if (_open.contains(index)) {
        _open.remove(index);
      } else {
        _open.add(index);
      }
    });
  }

  Future<AccountEntryContext> _loadContext() async {
    final user = _authService.currentUser;
    if (user == null) return AccountEntryContext.guest();

    Map<String, dynamic> userData = <String, dynamic>{};
    try {
      userData = await _repository.fetchUserData(user.uid);
    } catch (_) {}
    final accountMode = AccountModeResolver.fromUserData(userData);
    final isCorporateUserFromUserDoc = accountMode.isCorporate;

    AccountEntryBusinessContext? business;

    if (isCorporateUserFromUserDoc) {
      final possibleBusinessIds = <String>[
        (userData[FirestoreFields.ownedBusinessId] ?? '').toString(),
        (userData[FirestoreFields.businessId] ?? '').toString(),
        (userData[FirestoreFields.activeBusinessId] ?? '').toString(),
        (userData[FirestoreFields.selectedBusinessId] ?? '').toString(),
      ].where((e) => e.trim().isNotEmpty).toSet().toList();

      for (final id in possibleBusinessIds) {
        business = await _tryBusinessById(id);
        if (business != null) break;
      }

      business ??= await _tryBusinessByOwner(user.uid);
    }

    final isBusiness = accountMode.isCorporate;

    return AccountEntryContext(
      user: user,
      userData: userData,
      isBusiness: isBusiness,
      accountMode: accountMode,
      business: business,
    );
  }

  Future<AccountEntryBusinessContext?> _tryBusinessById(String id) async {
    final business = await _repository.tryBusinessById(id);
    return business == null
        ? null
        : AccountEntryBusinessContext.fromRepository(business);
  }

  Future<AccountEntryBusinessContext?> _tryBusinessByOwner(String uid) async {
    final business = await _repository.tryBusinessByOwner(uid);
    return business == null
        ? null
        : AccountEntryBusinessContext.fromRepository(business);
  }

  Future<void> _openLogin(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Giriş işlemi artık uygulama açılışındaki fix ekranından yapılır.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openPage(BuildContext context, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    setState(() {
      _contextFuture = null;
      _loadedUid = null;
      _refreshContextIfNeeded();
    });
  }

  Future<void> _openRoute(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    await Navigator.of(context).pushNamed(routeName, arguments: arguments);
    if (!mounted) return;
    setState(() {
      _contextFuture = null;
      _loadedUid = null;
      _refreshContextIfNeeded();
    });
  }

  Future<void> _requireLoginRoute(
    BuildContext context,
    User? user,
    String routeName, {
    Object? arguments,
  }) async {
    if (user == null) {
      await _openLogin(context);
      return;
    }
    await _openRoute(context, routeName, arguments: arguments);
  }

  void _businessMissing(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Kurumsal kullanıcı bağlantısı bulunamadı. Önce Uygulama Yönetimi > Kurumsal Profilimi Düzenle alanından hesabı eşitle.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openBusinessModule(
    BuildContext context,
    AccountEntryContext ctx,
    String target,
  ) async {
    final business = ctx.business;
    if (ctx.user == null) {
      await _openLogin(context);
      return;
    }

    if (business == null) {
      _businessMissing(context);
      return;
    }

    switch (target) {
      case 'services':
        await _openPage(
          context,
          BusinessServicesManagePage(
            businessId: business.id,
            businessData: business.data,
          ),
        );
        return;
      case 'staff':
        await _openPage(
          context,
          BusinessStaffManagePage(
            businessId: business.id,
            businessData: business.data,
          ),
        );
        return;
      case 'appointmentManagement':
        await _openPage(
          context,
          BusinessAppointmentManagementPage(
            businessId: business.id,
            businessName: business.name,
          ),
        );
        return;
      case 'finance':
        await _openPage(
          context,
          BusinessFinancePage(
            businessId: business.id,
            businessName: business.name,
          ),
        );
        return;
      case 'duration':
        await _openPage(
          context,
          BusinessDurationAnalyticsPage(
            businessId: business.id,
            businessName: business.name,
          ),
        );
        return;
      case 'logs':
        await _openPage(
          context,
          BusinessActivityLogsPage(
            businessId: business.id,
            businessName: business.name,
          ),
        );
        return;
      case 'live':
        await _openPage(
          context,
          BusinessLiveFlowPage(
            businessId: business.id,
            businessName: business.name,
          ),
        );
        return;
      case 'customers':
        await _openPage(
          context,
          BusinessCustomersPage(
            businessId: business.id,
            businessName: business.name,
          ),
        );
        return;
      case 'messages':
        await _openPage(context, const MessagesInboxPage());
        return;
      case 'campaigns':
        await _openPage(
          context,
          BusinessCampaignsPage(
            businessId: business.id,
            businessName: business.name,
          ),
        );
        return;
      case 'bulkMessage':
        await _openPage(
          context,
          BulkMessageCreatePage(
            businessId: business.id,
            businessName: business.name,
          ),
        );
        return;
      case 'preview':
        await _openPage(
          context,
          BusinessProfilePage(
            businessId: business.id,
            businessName: business.name,
            category: business.category.isEmpty ? 'Genel' : business.category,
          ),
        );
        return;
      case 'stories':
        await _openPage(
          context,
          BusinessStoryCreatePage(
            businessId: business.id,
            businessName: business.name,
            businessLogoUrl:
                (business.data['logoUrl'] ?? business.data['photoUrl'] ?? '')
                    .toString(),
            category: business.category.isEmpty ? 'Genel' : business.category,
          ),
        );
        return;
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await _authService.signOut(reason: 'account_entry');
    FixSessionGate.refreshAfterAuthChange();
    if (!context.mounted) return;

    setState(() {
      _contextFuture = null;
      _loadedUid = null;
      _open.clear();
      _refreshContextIfNeeded();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Çıkış yapıldı.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _info(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scopedSession = _scopedAccountSession(context);

    if (scopedSession != null && scopedSession.isAuthenticated) {
      final scopedKey =
          '${scopedSession.uid}|${scopedSession.role.name}|${scopedSession.businessId}';
      if (_contextFuture == null || _loadedUid != scopedKey) {
        _loadedUid = scopedKey;
        _contextFuture = Future<AccountEntryContext>.value(
          AccountEntryContext.fromSession(
            scopedSession,
            _authService.currentUser,
          ),
        );
      }
    } else {
      _refreshContextIfNeeded();
    }

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges(),
      initialData: _authService.currentUser,
      builder: (context, authSnapshot) {
        final liveUser = authSnapshot.data;

        if (liveUser == null && _loadedUid != null) {
          _contextFuture = null;
          _loadedUid = null;
          _refreshContextIfNeeded();
        }

        return FutureBuilder<AccountEntryContext>(
          future: _contextFuture,
          builder: (context, contextSnapshot) {
            final ctx =
                contextSnapshot.data ?? AccountEntryContext.pending(user: liveUser);

            return AccountEntryMenu(
              account: ctx,
              openSections: _open,
              onToggle: _toggle,
              onOpenPage: _openPage,
              onOpenRoute: _openRoute,
              onRequireLoginRoute: _requireLoginRoute,
              onOpenBusinessModule: _openBusinessModule,
              onInfo: _info,
              onSignOut: _signOut,
            );
          },
        );
      },
    );
  }
}

AppSession? _scopedAccountSession(BuildContext context) {
  return AppSessionScope.maybeOf(context);
}
