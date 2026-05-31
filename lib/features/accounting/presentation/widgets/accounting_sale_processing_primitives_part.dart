part of 'accounting_sale_processing_sheet.dart';

class _ProcessingChoice extends StatelessWidget {
  const _ProcessingChoice({
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
      onSelected: (_) => onTap(),
    );
  }
}

class _ProcessingSummary extends StatelessWidget {
  const _ProcessingSummary({
    required this.paid,
    required this.remaining,
    required this.status,
  });

  final int paid;
  final int remaining;
  final AccountingPaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final note = switch (status) {
      AccountingPaymentStatus.paid => 'Tahsilat kaydı oluşur, alacak kapanır.',
      AccountingPaymentStatus.partial => 'Tahsilat ve kalan alacak oluşur.',
      AccountingPaymentStatus.openAccount =>
        'Para girişi yoksa açık alacak oluşur.',
      AccountingPaymentStatus.installment =>
        'Kalan tutar taksit planına bölünür.',
      AccountingPaymentStatus.free => 'Tahsilat veya alacak oluşmaz.',
      _ => 'Adisyon sonucu muhasebe kayıtlarına yansıtılır.',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alınan: ${_money(paid)} · Kalan: ${_money(remaining)}',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

String _money(int kurus) {
  final sign = kurus < 0 ? '-' : '';
  final value = (kurus.abs() / 100).toStringAsFixed(2).replaceAll('.', ',');
  return '$sign$value TL';
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
