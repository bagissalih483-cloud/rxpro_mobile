class AccountingInstallmentPlan {
  const AccountingInstallmentPlan({
    required this.totalKurus,
    required this.count,
    required this.period,
    required this.firstDueDate,
    required this.items,
  });

  final int totalKurus;
  final int count;
  final String period;
  final DateTime firstDueDate;
  final List<AccountingInstallmentItem> items;

  int get plannedTotalKurus {
    return items.fold<int>(0, (total, item) => total + item.amountKurus);
  }
}

class AccountingInstallmentItem {
  const AccountingInstallmentItem({
    required this.index,
    required this.amountKurus,
    required this.dueDate,
  });

  final int index;
  final int amountKurus;
  final DateTime dueDate;
}

class AccountingInstallmentPlanner {
  const AccountingInstallmentPlanner._();

  static AccountingInstallmentPlan create({
    required int totalKurus,
    required int count,
    required String period,
    required DateTime firstDueDate,
  }) {
    if (count <= 0) {
      throw ArgumentError.value(
        count,
        'count',
        'Taksit sayısı sıfırdan büyük olmalıdır.',
      );
    }

    if (totalKurus <= 0) {
      throw ArgumentError.value(
        totalKurus,
        'totalKurus',
        'Taksit toplamı sıfırdan büyük olmalıdır.',
      );
    }

    final base = totalKurus ~/ count;
    final remainder = totalKurus % count;

    final items = <AccountingInstallmentItem>[];
    for (var i = 0; i < count; i++) {
      final amount = base + (i == 0 ? remainder : 0);
      items.add(
        AccountingInstallmentItem(
          index: i + 1,
          amountKurus: amount,
          dueDate: _addPeriod(firstDueDate, period, i),
        ),
      );
    }

    return AccountingInstallmentPlan(
      totalKurus: totalKurus,
      count: count,
      period: period,
      firstDueDate: firstDueDate,
      items: items,
    );
  }

  static DateTime _addPeriod(DateTime start, String period, int step) {
    switch (period) {
      case 'weekly':
        return start.add(Duration(days: 7 * step));
      case 'custom':
        return start.add(Duration(days: 30 * step));
      case 'monthly':
      default:
        return DateTime(start.year, start.month + step, start.day);
    }
  }
}
