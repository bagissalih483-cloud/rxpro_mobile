part of 'account_entry_menu.dart';

extension _AccountEntryMenuIndividualSections on AccountEntryMenu {
  List<Widget> _individualSections(
    BuildContext context,
    AccountEntryContext ctx,
  ) {
    final user = ctx.user;

    return [
      AccountActionGridSection(
        title: 'Profilim',
        subtitle: 'Ad soyad, telefon/e-posta ve temel hesap bilgileri.',
        icon: Icons.person_outline_rounded,
        items: [
          AccountActionGridItem(
            icon: Icons.person_outline_rounded,
            title: 'Profilimi düzenle',
            subtitle: 'Hesap bilgileri',
            color: const Color(0xFF2563EB),
            onTap: user == null
                ? () => onInfo(context, 'Profil için giriş yapılmalıdır.')
                : () => onOpenPage(
                    context,
                    AccountUserProfileLitePage(user: user),
                  ),
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
                  : 'Oturum aktif. Hesabın güvenli şekilde bağlı.',
            ),
          ),
        ],
      ),
      AccountActionGridSection(
        title: 'Kısayollar',
        subtitle: 'Randevu, favori, fırsat ve bildirimlerine hızlı eriş.',
        icon: Icons.dashboard_customize_outlined,
        items: [
          AccountActionGridItem(
            icon: Icons.calendar_month_outlined,
            title: 'Randevularım',
            subtitle: 'Aktif ve geçmiş',
            color: const Color(0xFF2563EB),
            onTap: () => FixShellNavState.setIndividualIndex(1),
          ),
          AccountActionGridItem(
            icon: Icons.notifications_none_rounded,
            title: 'Bildirimler',
            subtitle: 'Talepler ve uyarı',
            color: const Color(0xFFF59E0B),
            onTap: () => onOpenRoute(context, AppRoutes.notificationCenter),
          ),
          AccountActionGridItem(
            icon: Icons.favorite_border_rounded,
            title: 'Favorilerim',
            subtitle: 'Favori işletmeler',
            color: const Color(0xFFEF4444),
            onTap: () => FixShellNavState.setIndividualIndex(2),
          ),
          AccountActionGridItem(
            icon: Icons.sell_outlined,
            title: 'Fırsatlar',
            subtitle: 'Bana uygun',
            color: const Color(0xFF0EA5E9),
            onTap: () => FixShellNavState.setIndividualIndex(3),
          ),
        ],
      ),
      AccountActionGridSection(
        title: 'Tercihler',
        subtitle: 'Bildirim, kampanya izni, konum ve görünüm ayarları.',
        icon: Icons.tune_rounded,
        items: [
          AccountActionGridItem(
            icon: Icons.tune_rounded,
            title: 'Bildirim tercihleri',
            subtitle: 'Push izinleri',
            color: const Color(0xFF7C3AED),
            onTap: () =>
                onOpenRoute(context, AppRoutes.notificationPreferences),
          ),
          AccountActionGridItem(
            icon: Icons.settings_outlined,
            title: 'Ayarlar',
            subtitle: 'Konum ve görünüm',
            color: const Color(0xFF64748B),
            onTap: () =>
                onOpenPage(context, const AccountAppSettingsLitePage()),
          ),
        ],
      ),
      AccountActionGridSection(
        title: 'Bağlantılar',
        subtitle: 'Kurumsal hesaba geçiş ve personel bağlantısı.',
        icon: Icons.link_rounded,
        items: [
          AccountActionGridItem(
            icon: Icons.badge_outlined,
            title: 'Kurumsal',
            subtitle: 'İşletme hesabına bağlan',
            color: const Color(0xFF16A34A),
            onTap: () => onOpenRoute(context, AppRoutes.staffInviteCode),
          ),
        ],
      ),
      AccountActionGridSection(
        title: 'Sistem',
        subtitle: 'Yasal metinler, hesap silme ve güvenli çıkış işlemleri.',
        icon: Icons.security_outlined,
        items: [
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
