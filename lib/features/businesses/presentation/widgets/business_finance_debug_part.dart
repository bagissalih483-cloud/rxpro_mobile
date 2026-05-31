part of 'business_finance_widgets.dart';

class FinanceDebugCard extends StatelessWidget {
  const FinanceDebugCard({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.monthKey,
    required this.loading,
    required this.rawExpenseCount,
    required this.filteredExpenseCount,
    required this.rawIncomeCount,
    required this.filteredIncomeCount,
    required this.mainError,
    required this.expenseError,
    required this.incomeError,
  });

  final String businessId;
  final String businessName;
  final String monthKey;
  final bool loading;
  final int rawExpenseCount;
  final int filteredExpenseCount;
  final int rawIncomeCount;
  final int filteredIncomeCount;
  final String? mainError;
  final String? expenseError;
  final String? incomeError;

  bool get hasProblem =>
      mainError != null || expenseError != null || incomeError != null;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: hasProblem ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: hasProblem ? const Color(0xFFF97316) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasProblem
                      ? Icons.warning_amber_rounded
                      : Icons.fact_check_outlined,
                  color: hasProblem
                      ? const Color(0xFFB45309)
                      : const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasProblem ? 'Finans kontrol kartı' : 'Finans veri durumu',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'İşletme: $businessName',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              'businessId: ${businessId.isEmpty ? '-' : businessId}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            Text(
              'Ay: $monthKey  -  Masraf: $filteredExpenseCount/$rawExpenseCount  -  Gelir: $filteredIncomeCount/$rawIncomeCount',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            if (mainError != null) _debugError('Genel hata', mainError!),
            if (expenseError != null)
              _debugError('Masraf okuma', expenseError!),
            if (incomeError != null) _debugError('Gelir okuma', incomeError!),
          ],
        ),
      ),
    );
  }

  Widget _debugError(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '$title: $text',
        style: const TextStyle(
          color: Color(0xFFB45309),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
