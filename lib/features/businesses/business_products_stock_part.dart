part of 'business_products_page.dart';

class _StockOverview extends StatelessWidget {
  const _StockOverview({required this.docs});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  Widget build(BuildContext context) {
    final summary = BusinessProductPolicy.stockSummary(
      docs.map((doc) => doc.data()),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _SummaryCard(
          title: 'Stok Özeti',
          items: [
            _SummaryItem('Ürün çeşidi', summary.productCount.toString()),
            _SummaryItem(
              'Toplam stok',
              BusinessProductPolicy.quantity(summary.totalStock),
            ),
            _SummaryItem(
              'Stok maliyeti',
              BusinessProductPolicy.money(summary.totalCost),
            ),
            _SummaryItem(
              'Satış potansiyeli',
              BusinessProductPolicy.money(summary.totalSale),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BusinessStockLedgerList(docs: docs),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.items});

  final String title;
  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...items.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.label,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      e.value,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value);
  final String label;
  final String value;
}

class _AmountBox extends StatelessWidget {
  const _AmountBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      visualDensity: VisualDensity.compact,
      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
    );
  }
}
