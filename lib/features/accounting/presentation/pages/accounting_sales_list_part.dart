part of 'accounting_sales_page.dart';

class _RecentSalesPanel extends StatelessWidget {
  const _RecentSalesPanel({
    required this.sales,
    required this.status,
    required this.onProcessSale,
    required this.onCancelSale,
    required this.onRefundSale,
    required this.canProcessSales,
    required this.canCancelSales,
    required this.canRefundSales,
  });

  final List<AccountingSale> sales;
  final AccountingProcessStatus status;
  final ValueChanged<AccountingSale> onProcessSale;
  final ValueChanged<AccountingSale> onCancelSale;
  final ValueChanged<AccountingSale> onRefundSale;
  final bool canProcessSales;
  final bool canCancelSales;
  final bool canRefundSales;

  @override
  Widget build(BuildContext context) {
    return _SalesSurface(
      title: _panelTitle(status),
      trailing: _MiniBadge(label: '${sales.length} kayıt'),
      child: sales.isEmpty
          ? _EmptySalesState(status: status)
          : Column(
              children: [
                for (var i = 0; i < sales.length; i++) ...[
                  _SaleRow(
                    sale: sales[i],
                    onProcessSale: onProcessSale,
                    onCancelSale: onCancelSale,
                    onRefundSale: onRefundSale,
                    canProcessSale: canProcessSales,
                    canCancelSale: canCancelSales,
                    canRefundSale: canRefundSales,
                  ),
                  if (i != sales.length - 1) const Divider(height: 14),
                ],
              ],
            ),
    );
  }

  String _panelTitle(AccountingProcessStatus status) {
    switch (status) {
      case AccountingProcessStatus.processed:
        return 'İşlenen adisyonlar';
      case AccountingProcessStatus.cancelled:
        return 'İptal edilen adisyonlar';
      case AccountingProcessStatus.pending:
        return 'Bekleyen adisyonlar';
    }
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({
    required this.sale,
    required this.onProcessSale,
    required this.onCancelSale,
    required this.onRefundSale,
    required this.canProcessSale,
    required this.canCancelSale,
    required this.canRefundSale,
  });

  final AccountingSale sale;
  final ValueChanged<AccountingSale> onProcessSale;
  final ValueChanged<AccountingSale> onCancelSale;
  final ValueChanged<AccountingSale> onRefundSale;
  final bool canProcessSale;
  final bool canCancelSale;
  final bool canRefundSale;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(sale.saleType);
    final itemText = sale.items.map((item) => item.name).take(2).join(' + ');
    final customer = sale.customerName?.trim().isNotEmpty == true
        ? sale.customerName!.trim()
        : 'Misafir müşteri';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_typeIcon(sale.saleType), color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemText.isEmpty ? _typeLabel(sale.saleType) : itemText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$customer · ${_dateLabel(sale.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (sale.remainingAmountKurus > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Kalan: ${_money(sale.remainingAmountKurus)}',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _money(sale.totalAmountKurus),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _statusLabel(sale.paymentStatus),
              style: TextStyle(
                color: sale.remainingAmountKurus > 0
                    ? const Color(0xFFF97316)
                    : const Color(0xFF10B981),
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (sale.processStatus == AccountingProcessStatus.pending &&
                (canProcessSale || canCancelSale)) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: [
                  if (canProcessSale)
                    TextButton(
                      onPressed: () => onProcessSale(sale),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'İşle',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  if (canCancelSale)
                    TextButton(
                      onPressed: () => onCancelSale(sale),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB91C1C),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                ],
              ),
            ],
            if (sale.processStatus == AccountingProcessStatus.processed &&
                sale.paidAmountKurus > 0 &&
                sale.paymentStatus != AccountingPaymentStatus.refunded &&
                canRefundSale) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => onRefundSale(sale),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'İade',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

