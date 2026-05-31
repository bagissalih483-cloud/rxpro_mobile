part of 'business_products_page.dart';

class _ProductsList extends StatelessWidget {
  const _ProductsList({
    required this.docs,
    required this.emptyTitle,
    required this.emptyText,
    required this.onEdit,
    required this.onToggleActive,
    required this.onTogglePublic,
    required this.onDelete,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final String emptyTitle;
  final String emptyText;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>> onEdit;
  final Future<void> Function(QueryDocumentSnapshot<Map<String, dynamic>>, bool)
  onToggleActive;
  final Future<void> Function(QueryDocumentSnapshot<Map<String, dynamic>>, bool)
  onTogglePublic;
  final Future<void> Function(QueryDocumentSnapshot<Map<String, dynamic>>)
  onDelete;

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return _InfoState(
        icon: Icons.inventory_2_outlined,
        title: emptyTitle,
        text: emptyText,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        RxResponsiveGrid(
          itemCount: docs.length,
          maxColumns: 2,
          itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data();

        final name = BusinessProductPolicy.nameOf(data);
        final category = BusinessProductPolicy.categoryOf(data);
        final purchasePrice = BusinessProductPolicy.numberOf(
          data[FirestoreFields.purchasePrice],
        );
        final salePrice = BusinessProductPolicy.numberOf(
          data[FirestoreFields.salePrice],
        );
        final stock = BusinessProductPolicy.numberOf(
          data[FirestoreFields.stockQuantity],
        );
        final active = BusinessProductPolicy.isActive(data);
        final isPublic = BusinessProductPolicy.isPublic(data);
        final low = BusinessProductPolicy.isLowStock(data);

        return Card(
          elevation: 0,
          color: active ? Colors.white : const Color(0xFFF1F5F9),
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: low ? const Color(0xFFF97316) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isPublic
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC),
                      child: Icon(
                        isPublic
                            ? Icons.storefront_rounded
                            : Icons.inventory_2_outlined,
                        color: isPublic
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') onEdit(doc);
                        if (v == 'delete') onDelete(doc);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                        PopupMenuItem(value: 'delete', child: Text('Sil')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniChip(text: category),
                    _MiniChip(text: isPublic ? 'Halka açık' : 'Gizli'),
                    _MiniChip(text: active ? 'Aktif' : 'Pasif'),
                    if (low) const _MiniChip(text: 'Düşük stok'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _AmountBox(
                        label: 'Alış',
                        value: BusinessProductPolicy.money(purchasePrice),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AmountBox(
                        label: 'Satış',
                        value: BusinessProductPolicy.money(salePrice),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AmountBox(
                        label: 'Stok',
                        value: BusinessProductPolicy.quantity(stock),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: active,
                        onChanged: (v) => onToggleActive(doc, v),
                        title: const Text('Aktif'),
                      ),
                    ),
                    Expanded(
                      child: SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: isPublic,
                        onChanged: (v) => onTogglePublic(doc, v),
                        title: const Text('Yayında'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
          },
        ),
      ],
    );
  }
}
