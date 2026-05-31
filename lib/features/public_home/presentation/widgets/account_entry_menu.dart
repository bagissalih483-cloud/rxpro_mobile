import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/app/app_route_catalog.dart';
import 'package:rxpro_mobile/core/app_state/fix_shell_nav_state.dart';
import 'package:rxpro_mobile/features/public_home/presentation/models/account_entry_context.dart';
import 'package:rxpro_mobile/features/public_home/presentation/pages/account_entry_lite_pages.dart';
import 'package:rxpro_mobile/features/public_home/presentation/widgets/account_entry_cards.dart';

part 'account_entry_menu_corporate_part.dart';
part 'account_entry_menu_individual_part.dart';
part 'account_entry_menu_admin_part.dart';
part 'account_entry_menu_helpers_part.dart';
class AccountEntryMenu extends StatelessWidget {
  const AccountEntryMenu({
    required this.account,
    required this.openSections,
    required this.onToggle,
    required this.onOpenPage,
    required this.onOpenRoute,
    required this.onRequireLoginRoute,
    required this.onOpenBusinessModule,
    required this.onInfo,
    required this.onSignOut,
    super.key,
  });

  final AccountEntryContext account;
  final Set<int> openSections;
  final ValueChanged<int> onToggle;
  final Future<void> Function(BuildContext context, Widget page) onOpenPage;
  final Future<void> Function(
    BuildContext context,
    String routeName, {
    Object? arguments,
  })
  onOpenRoute;
  final Future<void> Function(
    BuildContext context,
    User? user,
    String routeName, {
    Object? arguments,
  })
  onRequireLoginRoute;
  final Future<void> Function(
    BuildContext context,
    AccountEntryContext account,
    String target,
  )
  onOpenBusinessModule;
  final void Function(BuildContext context, String text) onInfo;
  final Future<void> Function(BuildContext context) onSignOut;

  @override
  Widget build(BuildContext context) {
    final ctx = account;
    final loggedIn = ctx.user != null;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          AccountProfileHeaderCard(
            title: _displayNameOf(ctx.user),
            email: ctx.user?.email ?? 'Giriş yapılmadı',
            phone: ctx.user?.phoneNumber ?? '',
            photoUrl: _profilePhotoOf(ctx),
            isLoggedIn: loggedIn,
            badge: ctx.accountBadge,
          ),
          const SizedBox(height: 12),
          if (loggedIn && ctx.isPlatformAdmin) ...[
            ..._adminSections(context),
            const SizedBox(height: 12),
          ],
          if (loggedIn &&
              ctx.shouldShowStaffTasks &&
              !ctx.canOpenOwnerManagement) ...[
            _LiveFlowActionTile(
              onTap: () => onOpenRoute(context, AppRoutes.staffTasks),
            ),
            const SizedBox(height: 12),
          ],
          if (loggedIn && ctx.canOpenOwnerManagement)
            ..._corporateSections(context, ctx),
          if (loggedIn && ctx.shouldShowIndividualAccountBody)
            ..._individualSections(context, ctx),
          if (loggedIn) ...[
            const SizedBox(height: 12),
            AccountAuthBottomCard(
              isLoggedIn: true,
              title: 'Çıkış Yap',
              subtitle: 'Oturumu kapatıp açılış ekranına dön.',
              icon: Icons.logout_rounded,
              color: const Color(0xFFDC2626),
              onTap: () => onSignOut(context),
            ),
          ],
        ],
      ),
    );
  }
}
