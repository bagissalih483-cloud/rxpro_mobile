part of 'account_entry_menu.dart';

extension _AccountEntryMenuCorporateSections on AccountEntryMenu {
  List<Widget> _corporateSections(
    BuildContext context,
    AccountEntryContext ctx,
  ) {
    return [
      AccountActionGridSection(
        title: 'Profil ve vitrin',
        subtitle: 'Profil düzenleme, müşteri gibi görme ve çalışma düzeni.',
        icon: Icons.storefront_outlined,
        items: [
          AccountActionGridItem(
            icon: Icons.edit_note_rounded,
            title: 'Profil düzenle',
            subtitle: 'Vitrin bilgileri',
            color: const Color(0xFF7C3AED),
            onTap: () => onRequireLoginRoute(
              context,
              ctx.user,
              AppRoutes.businessProfileEditEntry,
            ),
          ),
          AccountActionGridItem(
            icon: Icons.visibility_outlined,
            title: 'Müşteri gibi gör',
            subtitle: 'Keşfet ön izleme',
            color: const Color(0xFF0EA5E9),
            onTap: () => onOpenBusinessModule(context, ctx, 'preview'),
          ),
          AccountActionGridItem(
            icon: Icons.schedule_outlined,
            title: 'Çalışma saatleri',
            subtitle: 'Profil ayarları',
            color: const Color(0xFF0F766E),
            onTap: () => onRequireLoginRoute(
              context,
              ctx.user,
              AppRoutes.businessProfileEditEntry,
            ),
          ),
        ],
      ),
      AccountActionGridSection(
        title: 'Bildirim / Güvenlik',
        subtitle: 'Bildirimler, oturum güvenliği ve yasal işlemler.',
        icon: Icons.settings_outlined,
        items: [
          AccountActionGridItem(
            icon: Icons.notifications_none_rounded,
            title: 'Bildirimler',
            subtitle: 'Sistem uyarıları',
            color: const Color(0xFFF59E0B),
            onTap: () => onOpenRoute(context, AppRoutes.notificationCenter),
          ),
          AccountActionGridItem(
            icon: Icons.settings_outlined,
            title: 'Ayarlar',
            subtitle: 'Bildirim ve görünüm',
            color: const Color(0xFF64748B),
            onTap: () =>
                onOpenPage(context, const AccountAppSettingsLitePage()),
          ),
          AccountActionGridItem(
            icon: Icons.tune_rounded,
            title: 'Bildirim tercihleri',
            subtitle: 'Push izinleri',
            color: const Color(0xFF7C3AED),
            onTap: () =>
                onOpenRoute(context, AppRoutes.notificationPreferences),
          ),
          AccountActionGridItem(
            icon: Icons.cloud_done_outlined,
            title: 'Oturum',
            subtitle: ctx.pending ? 'Hazırlanıyor' : 'Bağlantı aktif',
            color: const Color(0xFF475569),
            onTap: () => onInfo(
              context,
              ctx.pending
                  ? 'Hesap bağlamı hazırlanıyor.'
                  : 'Oturum bağlantısı aktif. Hesap: ${ctx.user?.email ?? ctx.user?.uid}',
            ),
          ),
          AccountActionGridItem(
            icon: Icons.policy_outlined,
            title: 'Yasal metinler',
            subtitle: 'KVKK ve şartlar',
            color: const Color(0xFF334155),
            onTap: () => onOpenRoute(context, AppRoutes.legalDocuments),
          ),
          AccountActionGridItem(
            icon: Icons.delete_outline_rounded,
            title: 'Hesabı sil',
            subtitle: 'Veri talebi',
            color: const Color(0xFFDC2626),
            onTap: () => onOpenRoute(context, AppRoutes.accountDeletionRequest),
          ),
        ],
      ),
    ];
  }
}
