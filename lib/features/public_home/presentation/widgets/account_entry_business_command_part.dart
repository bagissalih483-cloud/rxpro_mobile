part of 'account_entry_cards.dart';

class AccountBusinessCommandPanel extends StatelessWidget {
  const AccountBusinessCommandPanel({
    super.key,
    required this.businessLabel,
    required this.onAppointments,
    required this.onCustomers,
    required this.onBulkMessage,
    required this.onMessages,
    required this.onProfile,
    required this.onOperations,
  });

  final String businessLabel;
  final VoidCallback onAppointments;
  final VoidCallback onCustomers;
  final VoidCallback onBulkMessage;
  final VoidCallback onMessages;
  final VoidCallback onProfile;
  final VoidCallback onOperations;

  @override
  Widget build(BuildContext context) {
    final title = businessLabel.trim().isEmpty
        ? 'Kurumsal kontrol merkezi'
        : businessLabel.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7EDEA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9FFF4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'En sık kullanılan işletme işlemleri tek ekranda.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AccountCommandAction(
                    width: tileWidth,
                    icon: Icons.calendar_month_outlined,
                    title: 'Randevular',
                    subtitle: 'Bugün ve talepler',
                    color: const Color(0xFF2563EB),
                    onTap: onAppointments,
                  ),
                  _AccountCommandAction(
                    width: tileWidth,
                    icon: Icons.groups_2_outlined,
                    title: 'Müşteriler',
                    subtitle: 'Defter ve segment',
                    color: const Color(0xFF0F766E),
                    onTap: onCustomers,
                  ),
                  _AccountCommandAction(
                    width: tileWidth,
                    icon: Icons.sms_outlined,
                    title: 'Toplu mesaj',
                    subtitle: 'Filtreli gönderim',
                    color: const Color(0xFFEA580C),
                    onTap: onBulkMessage,
                  ),
                  _AccountCommandAction(
                    width: tileWidth,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Mesajlar',
                    subtitle: 'Gelen kutusu',
                    color: const Color(0xFF0891B2),
                    onTap: onMessages,
                  ),
                  _AccountCommandAction(
                    width: tileWidth,
                    icon: Icons.storefront_outlined,
                    title: 'Profil',
                    subtitle: 'Vitrin bilgileri',
                    color: const Color(0xFF7C3AED),
                    onTap: onProfile,
                  ),
                  _AccountCommandAction(
                    width: tileWidth,
                    icon: Icons.tune_outlined,
                    title: 'Operasyon',
                    subtitle: 'Hizmet ve ekip',
                    color: const Color(0xFF16A34A),
                    onTap: onOperations,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AccountCommandAction extends StatelessWidget {
  const _AccountCommandAction({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 92,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const Spacer(),
                    Icon(Icons.arrow_forward_rounded, color: color, size: 18),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
