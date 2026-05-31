part of 'accounting_receivables_page.dart';

class _ReceivableItem {
  const _ReceivableItem({
    required this.saleId,
    required this.businessId,
    required this.customerId,
    required this.installmentId,
    required this.customerName,
    required this.itemName,
    required this.totalLabel,
    required this.paidLabel,
    required this.remainingLabel,
    required this.remainingKurus,
    required this.dueLabel,
    required this.status,
    required this.source,
  });

  final String saleId;
  final String businessId;
  final String? customerId;
  final String? installmentId;
  final String customerName;
  final String itemName;
  final String totalLabel;
  final String paidLabel;
  final String remainingLabel;
  final int remainingKurus;
  final String dueLabel;
  final String status;
  final String source;

  factory _ReceivableItem.fromSale(AccountingSale sale) {
    final now = DateTime.now();
    final due = sale.dueDate;
    final itemName = sale.items.map((item) => item.name).take(2).join(' + ');
    final overdue =
        due != null && sale.remainingAmountKurus > 0 && due.isBefore(now);

    return _ReceivableItem(
      saleId: sale.saleId,
      businessId: sale.businessId,
      customerId: sale.customerId,
      installmentId: null,
      customerName: sale.customerName?.trim().isNotEmpty == true
          ? sale.customerName!.trim()
          : 'Misafir müşteri',
      itemName: itemName.isEmpty ? _saleTypeLabel(sale.saleType) : itemName,
      totalLabel: _money(sale.totalAmountKurus),
      paidLabel: _money(sale.paidAmountKurus),
      remainingLabel: _money(sale.remainingAmountKurus),
      remainingKurus: sale.remainingAmountKurus,
      dueLabel: due == null ? 'Vade yok' : 'Vade: ${_dateLabel(due)}',
      status: overdue
          ? 'overdue'
          : sale.paidAmountKurus > 0
          ? 'partial'
          : 'unpaid',
      source: _saleTypeLabel(sale.saleType),
    );
  }

  factory _ReceivableItem.fromInstallment(AccountingInstallment installment) {
    final now = DateTime.now();
    final due = installment.dueDate;
    final overdue =
        due != null && installment.remainingAmountKurus > 0 && due.isBefore(now);

    return _ReceivableItem(
      saleId: installment.saleId,
      businessId: installment.businessId,
      customerId: installment.customerId,
      installmentId: installment.installmentId,
      customerName: installment.customerName?.trim().isNotEmpty == true
          ? installment.customerName!.trim()
          : 'Misafir müşteri',
      itemName: '${installment.installmentNo}. taksit',
      totalLabel: _money(installment.amountKurus),
      paidLabel: _money(installment.paidAmountKurus),
      remainingLabel: _money(installment.remainingAmountKurus),
      remainingKurus: installment.remainingAmountKurus,
      dueLabel: due == null ? 'Vade yok' : 'Vade: ${_dateLabel(due)}',
      status: overdue ? 'overdue' : 'installment',
      source: 'Taksit',
    );
  }

  String get statusLabel {
    switch (status) {
      case 'partial':
        return 'K\u0131smi';
      case 'overdue':
        return 'Geciken';
      case 'installment':
        return 'Taksit';
      default:
        return 'Bekleyen';
    }
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

String _saleTypeLabel(AccountingSaleType type) {
  switch (type) {
    case AccountingSaleType.product:
      return 'Ürün satışı';
    case AccountingSaleType.mixed:
      return 'Karma satış';
    case AccountingSaleType.service:
      return 'Hizmet satışı';
  }
}
