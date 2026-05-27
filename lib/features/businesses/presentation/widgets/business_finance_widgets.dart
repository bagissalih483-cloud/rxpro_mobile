import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/businesses/presentation/models/business_finance_models.dart';
import 'package:rxpro_mobile/features/businesses/presentation/utils/business_finance_formatters.dart';

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

class FinancePeriodCard extends StatelessWidget {
  const FinancePeriodCard({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class FinanceMetricCard extends StatelessWidget {
  const FinanceMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FinanceSectionCard extends StatelessWidget {
  const FinanceSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

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
  const FinanceExpenseLine({
    super.key,
    required this.row,
  });

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

class FinanceInfoCard extends StatelessWidget {
  const FinanceInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2563EB)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(text),
      ),
    );
  }
}

class FinanceWarningCard extends StatelessWidget {
  const FinanceWarningCard({
    super.key,
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFF7ED),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFB45309),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(text),
      ),
    );
  }
}

class FinanceEmptyText extends StatelessWidget {
  const FinanceEmptyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
