part of 'accounting_sales_page.dart';

class _AdisyonCommandHeader extends StatelessWidget {
  const _AdisyonCommandHeader({
    required this.pendingCount,
    required this.openAmountKurus,
  });

  final int pendingCount;
  final int openAmountKurus;

  @override
  Widget build(BuildContext context) {
    final hasWork = pendingCount > 0 || openAmountKurus > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Adisyon Yönetimi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasWork
                      ? 'Bekleyen adisyonları işle, ödemeyi tahsilat/alacak/taksit akışına bağla.'
                      : 'Bu dönem için işlem bekleyen adisyon görünmüyor.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _DarkBadge(label: '$pendingCount bekleyen'),
              const SizedBox(height: 6),
              _DarkBadge(label: 'Açık ${_money(openAmountKurus)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DarkBadge extends StatelessWidget {
  const _DarkBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SalesInsightPanel extends StatelessWidget {
  const _SalesInsightPanel({
    required this.serviceTotal,
    required this.productTotal,
    required this.mixedTotal,
    required this.collected,
    required this.count,
    required this.pendingCount,
    required this.processedCount,
    required this.cancelledCount,
    required this.openAmountKurus,
  });

  final int serviceTotal;
  final int productTotal;
  final int mixedTotal;
  final int collected;
  final int count;
  final int pendingCount;
  final int processedCount;
  final int cancelledCount;
  final int openAmountKurus;

  @override
  Widget build(BuildContext context) {
    return _SalesSurface(
      title: 'Adisyon özeti',
      trailing: _MiniBadge(label: '$count kayıt / $cancelledCount iptal'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 560 ? 4 : 2;
          const spacing = 8.0;
          final width =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          final items = [
            _SalesMetric(
              'Hizmet',
              _money(serviceTotal),
              Icons.spa_rounded,
              const Color(0xFF10B981),
            ),
            _SalesMetric(
              'Ürün',
              _money(productTotal),
              Icons.inventory_2_rounded,
              const Color(0xFF2563EB),
            ),
            _SalesMetric(
              'Karma',
              _money(mixedTotal),
              Icons.all_inclusive_rounded,
              const Color(0xFF7C3AED),
            ),
            _SalesMetric(
              'Tahsilat',
              _money(collected),
              Icons.payments_rounded,
              const Color(0xFFF97316),
            ),
            _SalesMetric(
              'Bekleyen',
              '$pendingCount / $processedCount',
              Icons.pending_actions_rounded,
              const Color(0xFF0F766E),
            ),
            _SalesMetric(
              'Açık',
              _money(openAmountKurus),
              Icons.schedule_rounded,
              const Color(0xFFB45309),
            ),
          ];

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final item in items)
                SizedBox(
                  width: width,
                  child: _SalesMetricTile(item: item),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdisyonStatusTabs extends StatelessWidget {
  const _AdisyonStatusTabs({
    required this.selected,
    required this.pendingCount,
    required this.processedCount,
    required this.cancelledCount,
    required this.onSelected,
  });

  final AccountingProcessStatus selected;
  final int pendingCount;
  final int processedCount;
  final int cancelledCount;
  final ValueChanged<AccountingProcessStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (AccountingProcessStatus.pending, 'Bekleyen', pendingCount),
      (AccountingProcessStatus.processed, 'İşlenen', processedCount),
      (AccountingProcessStatus.cancelled, 'İptal', cancelledCount),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tab in tabs)
          ChoiceChip(
            selected: selected == tab.$1,
            label: Text('${tab.$2} (${tab.$3})'),
            onSelected: (_) => onSelected(tab.$1),
          ),
      ],
    );
  }
}

