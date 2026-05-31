part of 'accounting_sales_widgets.dart';

class AccountingSalesHeaderCard extends StatelessWidget {
  const AccountingSalesHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.add_business_rounded,
              color: Color(0xFF10B981),
              size: 34,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Seçim yaptıkça form otomatik ilerler. Telefon eşleştirme, katalog ve kayıt adımları hazır olduğunda bu akıştan yönetilecek.',
                style: TextStyle(
                  color: Color(0xFF475569),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: selected ? Colors.white : const Color(0xFF334155),
      ),
      selectedColor: const Color(0xFF10B981),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class AccountingPreviewRow extends StatelessWidget {
  const AccountingPreviewRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
