part of 'account_entry_menu.dart';

extension _AccountEntryMenuAdminSections on AccountEntryMenu {
  List<Widget> _adminSections(BuildContext context) {
    return [
      AccountActionGridSection(
        title: 'Admin',
        subtitle: 'Doğrulama kuyruğu ve güvenlik kayıtları.',
        icon: Icons.admin_panel_settings_outlined,
        items: [
          AccountActionGridItem(
            icon: Icons.verified_user_outlined,
            title: 'Moderasyon',
            subtitle: 'Talepler ve güvenlik kayıtları',
            color: const Color(0xFF4F46E5),
            onTap: () => onOpenRoute(context, AppRoutes.adminModeration),
          ),
        ],
      ),
    ];
  }
}
