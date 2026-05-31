part of 'accounting_overview_panel.dart';

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.onQuickAction});

  final ValueChanged<AccountingQuickAction> onQuickAction;

  @override
  Widget build(BuildContext context) {
    const actions = [
      _ActionData(
        title: 'Yeni adisyon',
        text: 'Hızlı kayıt',
        icon: Icons.add_shopping_cart_rounded,
        color: Color(0xFF10B981),
        action: AccountingQuickAction.addSale,
      ),
      _ActionData(
        title: 'Tahsilat al',
        text: 'Kalan ödeme',
        icon: Icons.payments_rounded,
        color: Color(0xFF2563EB),
        action: AccountingQuickAction.collectPayment,
      ),
      _ActionData(
        title: 'Gider ekle',
        text: 'Masraf takibi',
        icon: Icons.receipt_long_rounded,
        color: Color(0xFFF97316),
        action: AccountingQuickAction.addExpense,
      ),
      _ActionData(
        title: 'Raporlar',
        text: 'Dönem çıktısı',
        icon: Icons.picture_as_pdf_rounded,
        color: Color(0xFF7C3AED),
        action: AccountingQuickAction.openReports,
      ),
      _ActionData(
        title: 'Yetki',
        text: 'Personel erişimi',
        icon: Icons.admin_panel_settings_rounded,
        color: Color(0xFF0F766E),
        action: AccountingQuickAction.openPermissions,
      ),
    ];

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = actions[index];

          return SizedBox(
            width: 88,
            child: _ActionTile(
              data: action,
              onTap: () => onQuickAction(action.action),
            ),
          );
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.data, required this.onTap});

  final _ActionData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 74,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(data.icon, color: data.color, size: 19),
              const Spacer(),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                data.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
