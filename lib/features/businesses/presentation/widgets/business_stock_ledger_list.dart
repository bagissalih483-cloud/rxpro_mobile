import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

class BusinessStockLedgerList extends StatelessWidget {
  const BusinessStockLedgerList({super.key, required this.docs});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  Widget build(BuildContext context) {
    final sorted = [...docs]
      ..sort((a, b) {
        final aStock = _toDouble(a.data()[FirestoreFields.stockQuantity]);
        final bStock = _toDouble(b.data()[FirestoreFields.stockQuantity]);
        return aStock.compareTo(bStock);
      });

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stok Defteri',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mevcut ürün kayıtlarına göre anlık stok ve değer özeti.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              const Text(
                'Stokta izlenecek ürün yok.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              ...sorted.take(20).map((doc) => _StockLedgerRow(doc)),
          ],
        ),
      ),
    );
  }
}

class _StockLedgerRow extends StatelessWidget {
  const _StockLedgerRow(this.doc);

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final name = _clean(
      data[FirestoreFields.name] ?? data[FirestoreFields.productName],
    );
    final stock = _toDouble(data[FirestoreFields.stockQuantity]);
    final minStock = _toDouble(data[FirestoreFields.minStockQuantity]);
    final salePrice = _toDouble(data[FirestoreFields.salePrice]);
    final low = minStock > 0 && stock <= minStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: low ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: low ? const Color(0xFFF97316) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            low ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
            color: low ? const Color(0xFFF97316) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Ürün' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  low ? 'Düşük stok uyarısı' : 'Stok dengesi normal',
                  style: TextStyle(
                    color: low
                        ? const Color(0xFFC2410C)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_qty(stock)} adet',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                _money(stock * salePrice),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _clean(dynamic value) => value?.toString().trim() ?? '';

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();

  final text = value?.toString().replaceAll(',', '.').trim() ?? '';
  return double.tryParse(text) ?? 0;
}

String _money(double value) {
  return '${value.toStringAsFixed(2).replaceAll('.', ',')} TL';
}

String _qty(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2).replaceAll('.', ',');
}
