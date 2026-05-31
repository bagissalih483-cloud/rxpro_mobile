part of 'business_finance_widgets.dart';

class FinanceAmountLine extends StatelessWidget {
  const FinanceAmountLine({
    super.key,
    required this.title,
    required this.amount,
    required this.negative,
  });

  final String title;
  final double amount;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final color = negative ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            financeMoney(amount),
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class FinanceExpenseLine extends StatelessWidget {
  const FinanceExpenseLine({super.key, required this.row});

  final FinanceExpenseRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${row.title}  -  ${row.category}  -  ${row.createdText}${row.recurring ? '  -  Tekrarli' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            financeMoney(row.amount),
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
