part of '../../staff_workspace_page.dart';

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
        Navigator.of(context).pushNamed(AppRoutes.registeredBusinesses);
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
