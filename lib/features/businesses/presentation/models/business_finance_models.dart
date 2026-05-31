class FinanceLoadResult {
  const FinanceLoadResult({
    required this.expenses,
    required this.incomes,
    required this.rawExpenseCount,
    required this.rawIncomeCount,
    required this.filteredExpenseCount,
    required this.filteredIncomeCount,
    required this.expenseReadError,
    required this.incomeReadError,
  });

  final List<FinanceExpenseRow> expenses;
  final List<FinanceIncomeRow> incomes;
  final int rawExpenseCount;
  final int rawIncomeCount;
  final int filteredExpenseCount;
  final int filteredIncomeCount;
  final String? expenseReadError;
  final String? incomeReadError;
}

class FinanceExpenseRow {
  const FinanceExpenseRow({
    required this.id,
    required this.title,
    required this.category,
    required this.note,
    required this.amount,
    required this.recurring,
    required this.createdText,
  });

  final String id;
  final String title;
  final String category;
  final String note;
  final double amount;
  final bool recurring;
  final String createdText;
}

class FinanceIncomeRow {
  const FinanceIncomeRow({
    required this.id,
    required this.title,
    required this.amount,
    required this.createdText,
    this.paymentStatus = '',
    this.staffName = '',
  });

  final String id;
  final String title;
  final double amount;
  final String createdText;
  final String paymentStatus;
  final String staffName;

  String get paymentStatusLabel {
    final normalized = paymentStatus.trim().toLowerCase();

    if (normalized == 'paid' ||
        normalized == 'odendi' ||
        normalized == 'ödendi') {
      return 'Ödendi';
    }

    if (normalized == 'paymentpending' ||
        normalized == 'payment_pending' ||
        normalized == 'pending' ||
        normalized == 'tahsilatbekliyor') {
      return 'Tahsilat bekliyor';
    }

    if (normalized == 'receivable' || normalized == 'alacak') {
      return 'Alacak';
    }

    return '';
  }

  String get detailLabel {
    final parts = <String>[
      if (createdText.trim().isNotEmpty) createdText.trim(),
      if (paymentStatusLabel.isNotEmpty) paymentStatusLabel,
      if (staffName.trim().isNotEmpty) staffName.trim(),
    ];

    return parts.join('  -  ');
  }
}
