import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/app_state/fix_shell_nav_state.dart';
import 'package:rxpro_mobile/features/appointments/presentation/pages/customer_appointments_page.dart';
import 'package:rxpro_mobile/features/business/pages/business_profile_edit_entry_page.dart';
import 'package:rxpro_mobile/features/businesses/business_pos_page.dart';
import 'package:rxpro_mobile/features/businesses/business_products_page.dart';
import 'package:rxpro_mobile/features/businesses/staff_tasks_entry_page.dart';
import 'package:rxpro_mobile/features/campaigns/campaign_ai_create_safe_page.dart';
import 'package:rxpro_mobile/features/notifications/notification_center_page.dart';
import 'package:rxpro_mobile/features/public_home/presentation/models/account_entry_context.dart';
import 'package:rxpro_mobile/features/public_home/presentation/pages/account_entry_lite_pages.dart';
import 'package:rxpro_mobile/features/public_home/presentation/widgets/account_entry_cards.dart';
import 'package:rxpro_mobile/features/staff_invites/staff_invite_code_page.dart';

class AccountEntryMenu extends StatelessWidget {
  const AccountEntryMenu({
    required this.account,
    required this.openSections,
    required this.onToggle,
    required this.onOpenPage,
    required this.onRequireLogin,
    required this.onOpenBusinessModule,
    required this.onInfo,
    required this.onSignOut,
    super.key,
  });

  final AccountEntryContext account;
  final Set<int> openSections;
  final ValueChanged<int> onToggle;
  final Future<void> Function(BuildContext context, Widget page) onOpenPage;
  final Future<void> Function(BuildContext context, User? user, Widget page)
  onRequireLogin;
  final Future<void> Function(
    BuildContext context,
    AccountEntryContext account,
    String target,
  )
  onOpenBusinessModule;
  final void Function(BuildContext context, String text) onInfo;
  final Future<void> Function(BuildContext context) onSignOut;

  List<Widget> _corporateSections(
    BuildContext context,
    AccountEntryContext ctx,
  ) {
    return [
      AccountActionGridSection(
        title: 'Müşteri ilişkileri',
        subtitle: 'Müşteri kayıtları, randevu, mesaj ve toplu gönderimler.',
        icon: Icons.support_agent_outlined,
        items: [
          AccountActionGridItem(
            icon: Icons.groups_2_outlined,
            title: 'Müşteri kayıtları',
            subtitle: 'Defter ve segment',
            color: const Color(0xFF0F766E),
            onTap: () => onOpenBusinessModule(context, ctx, 'customers'),
          ),
          AccountActionGridItem(
            icon: Icons.calendar_month_outlined,
            title: 'Randevular',
            subtitle: 'Bugün ve talepler',
            color: const Color(0xFF2563EB),
            onTap: () => onOpenBusinessModule(
              context,
              ctx,
              'appointmentManagement',
            ),
          ),
          AccountActionGridItem(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Mesajlar',
            subtitle: 'Gelen kutusu',
            color: const Color(0xFF0891B2),
            onTap: () => onOpenBusinessModule(context, ctx, 'messages'),
          ),
          AccountActionGridItem(
            icon: Icons.sms_outlined,
            title: 'Toplu mesaj',
            subtitle: 'Filtreli gönderim',
            color: const Color(0xFFEA580C),
            onTap: () => onOpenBusinessModule(context, ctx, 'bulkMessage'),
          ),
        ],
      ),
      AccountActionGridSection(
        title: 'İşletme yönetimi',
        subtitle: 'Hizmet, ekip, finans, satış, stok ve operasyon kontrolü.',
        icon: Icons.business_center_outlined,
        items: [
          AccountActionGridItem(
            icon: Icons.room_service_outlined,
            title: 'Hizmetler',
            subtitle: 'Paket ve fiyat',
            color: const Color(0xFF2563EB),
            onTap: () => onOpenBusinessModule(context, ctx, 'services'),
          ),
          AccountActionGridItem(
            icon: Icons.groups_outlined,
            title: 'Personel',
            subtitle: 'Yetki ve davet',
            color: const Color(0xFF7C3AED),
            onTap: () => onOpenBusinessModule(context, ctx, 'staff'),
          ),
          AccountActionGridItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Finans',
            subtitle: 'Gelir ve gider',
            color: const Color(0xFF0F766E),
            onTap: () => onOpenBusinessModule(context, ctx, 'finance'),
          ),
          AccountActionGridItem(
            icon: Icons.receipt_long_rounded,
            title: 'Adisyon',
            subtitle: 'Satış ve ödeme',
            color: const Color(0xFF2563EB),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BusinessPosPage()),
            ),
          ),
          AccountActionGridItem(
            icon: Icons.inventory_2_outlined,
            title: 'Stok',
            subtitle: 'Ürün hareketi',
            color: const Color(0xFF059669),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BusinessProductsPage()),
            ),
          ),
          AccountActionGridItem(
            icon: Icons.timer_outlined,
            title: 'Süre analizi',
            subtitle: 'Hizmet süresi',
            color: const Color(0xFFEA580C),
            onTap: () => onOpenBusinessModule(context, ctx, 'duration'),
          ),
          AccountActionGridItem(
            icon: Icons.manage_history_outlined,
            title: 'Hareketler',
            subtitle: 'İşlem geçmişi',
            color: const Color(0xFF334155),
            onTap: () => onOpenBusinessModule(context, ctx, 'logs'),
          ),
        ],
      ),
      AccountActionGridSection(
        title: 'Vitrin ve yayın',
        subtitle: 'Profil düzenleme, ön izleme, paylaşım ve kampanya işleri.',
        icon: Icons.storefront_outlined,
        items: [
          AccountActionGridItem(
            icon: Icons.edit_note_rounded,
            title: 'Profil düzenle',
            subtitle: 'Vitrin bilgileri',
            color: const Color(0xFF7C3AED),
            onTap: () => onRequireLogin(
              context,
              ctx.user,
              const BusinessProfileEditEntryPage(),
            ),
          ),
          AccountActionGridItem(
            icon: Icons.visibility_outlined,
            title: 'Ön izleme',
            subtitle: 'Profil ekranı',
            color: const Color(0xFF0EA5E9),
            onTap: () => onOpenBusinessModule(context, ctx, 'preview'),
          ),
          AccountActionGridItem(
            icon: Icons.dynamic_feed_outlined,
            title: 'Paylaşımlar',
            subtitle: 'Tanıtım vitrini',
            color: const Color(0xFF0F766E),
            onTap: () => onOpenBusinessModule(context, ctx, 'stories'),
          ),
          AccountActionGridItem(
            icon: Icons.local_offer_outlined,
            title: 'Kampanyalar',
            subtitle: 'Yayın ve indirim',
            color: const Color(0xFF10B981),
            onTap: () => onOpenBusinessModule(context, ctx, 'campaigns'),
          ),
          AccountActionGridItem(
            icon: Icons.auto_awesome_outlined,
            title: 'AI kampanya',
            subtitle: 'Metin oluştur',
            color: const Color(0xFF9333EA),
            onTap: () => onRequireLogin(
              context,
              ctx.user,
              const CampaignAiCreateSafePage(),
            ),
          ),
        ],
      ),
      AccountActionGridSection(
        title: 'Hesap ve sistem',
        subtitle: 'Bildirimler, uygulama ayarları ve hesap bağlantısı.',
        icon: Icons.settings_outlined,
        items: [
          AccountActionGridItem(
            icon: Icons.notifications_none_rounded,
            title: 'Bildirimler',
            subtitle: 'Sistem uyarıları',
            color: const Color(0xFFF59E0B),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
            ),
          ),
          AccountActionGridItem(
            icon: Icons.settings_outlined,
            title: 'Ayarlar',
            subtitle: 'Bildirim ve görünüm',
            color: const Color(0xFF64748B),
            onTap: () => onOpenPage(
              context,
              const AccountAppSettingsLitePage(),
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
                  : 'Firebase bağlantısı aktif. Oturum: ${ctx.user?.email ?? ctx.user?.uid}',
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _individualSections(
    BuildContext context,
    AccountEntryContext ctx,
  ) {
    final user = ctx.user;

    return [
      AccountActionGridSection(
        title: 'Bireysel alan',
        subtitle: 'Randevu, bildirim, takip ve kampanya kısayolları.',
        icon: Icons.person_search_outlined,
        items: [
          AccountActionGridItem(
            icon: Icons.calendar_month_outlined,
            title: 'Randevularım',
            subtitle: 'Aktif ve geçmiş',
            color: const Color(0xFF2563EB),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CustomerAppointmentsPage(),
              ),
            ),
          ),
          AccountActionGridItem(
            icon: Icons.notifications_none_rounded,
            title: 'Bildirimler',
            subtitle: 'Talepler ve uyarı',
            color: const Color(0xFFF59E0B),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
            ),
          ),
          AccountActionGridItem(
            icon: Icons.favorite_border_rounded,
            title: 'Takipler',
            subtitle: 'Favori işletmeler',
            color: const Color(0xFFEF4444),
            onTap: () => FixShellNavState.setIndividualIndex(1),
          ),
          AccountActionGridItem(
            icon: Icons.sell_outlined,
            title: 'Kampanyalar',
            subtitle: 'Bana uygun',
            color: const Color(0xFF0EA5E9),
            onTap: () => FixShellNavState.setIndividualIndex(3),
          ),
        ],
      ),
      AccountActionGridSection(
        title: 'Hesap ve ayarlar',
        subtitle: 'Profil, davet kodu ve uygulama tercihleri.',
        icon: Icons.settings_outlined,
        items: [
          AccountActionGridItem(
            icon: Icons.badge_outlined,
            title: 'Davet kodu',
            subtitle: 'Kurumsal role bağlan',
            color: const Color(0xFF16A34A),
            onTap: () => onOpenPage(context, const StaffInviteCodePage()),
          ),
          AccountActionGridItem(
            icon: Icons.person_outline_rounded,
            title: 'Profilim',
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
            icon: Icons.settings_outlined,
            title: 'Ayarlar',
            subtitle: 'Bildirim ve görünüm',
            color: const Color(0xFF64748B),
            onTap: () => onOpenPage(
              context,
              const AccountAppSettingsLitePage(),
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
                  : 'Firebase bağlantısı aktif. Oturum: ${ctx.user?.email ?? ctx.user?.uid}',
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ctx = account;
    final loggedIn = ctx.user != null;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
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
          if (loggedIn && ctx.shouldShowStaffTasks) ...[
            _LiveFlowActionTile(
              onTap: () {
                if (ctx.canOpenOwnerManagement) {
                  onOpenBusinessModule(context, ctx, 'live');
                  return;
                }

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StaffTasksEntryPage(),
                  ),
                );
              },
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

String _displayNameOf(User? user) {
  final name = user?.displayName?.trim() ?? '';
  if (name.isNotEmpty) return name;

  final email = user?.email?.trim() ?? '';
  if (email.isNotEmpty) return email;

  final phone = user?.phoneNumber?.trim() ?? '';
  if (phone.isNotEmpty) return phone;

  return 'fi Hesabı';
}

String _profilePhotoOf(AccountEntryContext ctx) {
  final candidates = <Object?>[
    ctx.user?.photoURL,
    ctx.userData['photoUrl'],
    ctx.userData['imageUrl'],
    ctx.userData['avatarUrl'],
    ctx.business?.data['logoUrl'],
    ctx.business?.data['photoUrl'],
    ctx.business?.data['imageUrl'],
  ];

  for (final candidate in candidates) {
    final value = candidate?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }

  return '';
}

class _LiveFlowActionTile extends StatelessWidget {
  const _LiveFlowActionTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.026),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9FFF4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Canlı Akış',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Günlük operasyon, ekip durumu ve aktif işler.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
