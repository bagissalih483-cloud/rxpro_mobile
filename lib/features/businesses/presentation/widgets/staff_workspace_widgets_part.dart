part of '../../staff_workspace_page.dart';

class _StaffPanelHeader extends StatelessWidget {
  const _StaffPanelHeader({
    required this.businessName,
    required this.staffName,
    required this.roleLabel,
  });

  final String businessName;
  final String staffName;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF7C2D12)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.badge_outlined, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  staffName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffAccordion extends StatelessWidget {
  const _StaffAccordion({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFFF7ED),
                    child: Icon(icon, color: const Color(0xFFC2410C)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFF7ED),
          child: Icon(icon, color: const Color(0xFFC2410C)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _AppointmentWorkTile extends StatelessWidget {
  const _AppointmentWorkTile({
    required this.title,
    required this.time,
    required this.status,
    required this.statusLabel,
    required this.isOverdue,
    required this.readOnly,
    required this.onStart,
    required this.onComplete,
    this.onCreateReminder,
    this.onCancelNoShow,
  });

  final String title;
  final String time;
  final String status;
  final String statusLabel;
  final bool isOverdue;
  final bool readOnly;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback? onCreateReminder;
  final VoidCallback? onCancelNoShow;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final inProgress =
        normalized == 'inprogress' || normalized == 'in_progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOverdue ? const Color(0xFFF97316) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isOverdue
                    ? const Color(0xFFFFEDD5)
                    : inProgress
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFEFF6FF),
                child: Icon(
                  isOverdue
                      ? Icons.warning_amber_rounded
                      : inProgress
                      ? Icons.timelapse_rounded
                      : Icons.event_available_outlined,
                  color: isOverdue
                      ? const Color(0xFFEA580C)
                      : inProgress
                      ? const Color(0xFFD97706)
                      : const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$time • $statusLabel',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!readOnly) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: inProgress ? null : onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('İşleme Başladım'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('İşlemi Bitirdim'),
                  ),
                ),
              ],
            ),
            if (isOverdue) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCreateReminder,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Uyarı oluştur'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancelNoShow,
                      icon: const Icon(Icons.event_busy_outlined),
                      label: const Text('İptal / gelmedi'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF7C2D12),
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

// RXPRO_MANAGEMENT_CENTER_QUICK_ACTION_35K
Widget rxproManagementCenterQuickAction35K(BuildContext context) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.admin_panel_settings_outlined,
          color: Color(0xFF2563EB),
        ),
      ),
      title: const Text(
        'Kurumsal Kullanıcı Yönetim Merkezi',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
      ),
      subtitle: const Text(
        'Hizmetler, çalışanlar, finans, süre analizi ve yetkiler',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Color(0xFF64748B),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RegisteredBusinessesPage()),
        );
      },
    ),
  );
}

// FIX_47D_FINANCE_STAFF_NAV_CARD
// Mali yetkili personel navigasyon karari:
// financeRead/financeWrite/expenseWrite/receivableManage/reportExport izni olan personelde
// Gorevlerim > Yetkili Hizli Islemler altinda "Mali Isler" karti gosterilecek.
// Personel bireysel 5'li navigasyonda kalacak; owner kurumsal paneliyle karistirilmayacak.
// Bu marker sonraki derin patch icin sabit arama noktasi olarak eklendi.
