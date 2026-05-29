import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/app/app_routes.dart';
import '../../core/firestore/firestore_fields.dart';
import 'package:flutter/material.dart';

import 'data/business_products_repository.dart';
import 'presentation/widgets/business_stock_ledger_list.dart';
import 'services/business_products_service.dart';

class BusinessProductsPage extends StatefulWidget {
  const BusinessProductsPage({super.key});

  @override
  State<BusinessProductsPage> createState() => _BusinessProductsPageState();
}

class _BusinessProductsPageState extends State<BusinessProductsPage> {
  late Future<BusinessProductContext> _contextFuture;
  final BusinessProductsService _productsService = BusinessProductsService();

  @override
  void initState() {
    super.initState();
    _contextFuture = _loadBusinessContext();
  }

  Future<BusinessProductContext> _loadBusinessContext() {
    return _productsService.resolveBusinessContext();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _products(String businessId) {
    return _productsService.watchProducts(businessId);
  }

  Future<void> _openProductForm({
    required BusinessProductContext contextData,
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final saved = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.businessProductForm,
      arguments: BusinessProductFormRouteArgs(
        businessId: contextData.businessId,
        businessName: contextData.businessName,
        doc: doc,
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        _contextFuture = _loadBusinessContext();
      });
    }
  }

  Future<void> _toggleActive(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool active,
  ) async {
    await _productsService.setProductActive(
      productRef: doc.reference,
      active: active,
    );
  }

  Future<void> _togglePublic(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool isPublic,
  ) async {
    await _productsService.setProductPublic(
      productRef: doc.reference,
      isPublic: isPublic,
    );
  }

  Future<void> _deleteProduct(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ürünü sil'),
          content: const Text('Bu ürün kaydı silinsin mi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _productsService.deleteProduct(doc.reference);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BusinessProductContext>(
      future: _contextFuture,
      builder: (context, businessSnapshot) {
        final ctx =
            businessSnapshot.data ??
            const BusinessProductContext(
              businessId: '',
              businessName: 'Kurumsal Kullanıcı',
            );

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: const Text('Stok ve Ürünler'),
              backgroundColor: const Color(0xFFF8FAFC),
              elevation: 0,
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Ürünler'),
                  Tab(text: 'Stok'),
                  Tab(text: 'Düşük Stok'),
                  Tab(text: 'Yayınlananlar'),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: ctx.businessId.isEmpty
                  ? null
                  : () => _openProductForm(contextData: ctx),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ürün Ekle'),
            ),
            body: ctx.businessId.isEmpty
                ? const _InfoState(
                    icon: Icons.store_mall_directory_outlined,
                    title: 'Kurumsal Kullanıcı bağlantısı bulunamadı',
                    text:
                        'Ürün eklemek için kurumsal kullanıcı hesabıyla giriş yapılmalı.',
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _products(ctx.businessId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _InfoState(
                          icon: Icons.warning_amber_rounded,
                          title: 'Ürünler okunamadı',
                          text: snapshot.error.toString(),
                        );
                      }

                      final docs =
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[
                            ...(snapshot.data?.docs ??
                                const <
                                  QueryDocumentSnapshot<Map<String, dynamic>>
                                >[]),
                          ];

                      docs.sort((a, b) {
                        final an = _clean(a.data()['name']).toLowerCase();
                        final bn = _clean(b.data()['name']).toLowerCase();
                        return an.compareTo(bn);
                      });

                      final active = docs
                          .where((d) {
                            final data = d.data();
                            return data[FirestoreFields.isActive] != false;
                          })
                          .toList(growable: false);

                      final lowStock = active
                          .where((d) {
                            final data = d.data();
                            final stock = _toDouble(
                              data[FirestoreFields.stockQuantity],
                            );
                            final min = _toDouble(
                              data[FirestoreFields.minStockQuantity],
                            );
                            return min > 0 && stock <= min;
                          })
                          .toList(growable: false);

                      final publicProducts = active
                          .where((d) {
                            final data = d.data();
                            return data[FirestoreFields.isPublic] == true;
                          })
                          .toList(growable: false);

                      return TabBarView(
                        children: [
                          _ProductsList(
                            docs: docs,
                            emptyTitle: 'Ürün yok',
                            emptyText:
                                'İlk ürününüzü ekleyerek stok takibine başlayın.',
                            onEdit: (doc) =>
                                _openProductForm(contextData: ctx, doc: doc),
                            onToggleActive: _toggleActive,
                            onTogglePublic: _togglePublic,
                            onDelete: _deleteProduct,
                          ),
                          _StockOverview(docs: active),
                          _ProductsList(
                            docs: lowStock,
                            emptyTitle: 'Düşük stok yok',
                            emptyText:
                                'Minimum stok seviyesinin altına düşen ürün yok.',
                            onEdit: (doc) =>
                                _openProductForm(contextData: ctx, doc: doc),
                            onToggleActive: _toggleActive,
                            onTogglePublic: _togglePublic,
                            onDelete: _deleteProduct,
                          ),
                          _ProductsList(
                            docs: publicProducts,
                            emptyTitle: 'Yayınlanan ürün yok',
                            emptyText:
                                'Halka açık işaretlenen ürünler burada görünür.',
                            onEdit: (doc) =>
                                _openProductForm(contextData: ctx, doc: doc),
                            onToggleActive: _toggleActive,
                            onTogglePublic: _togglePublic,
                            onDelete: _deleteProduct,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

class BusinessProductFormPage extends StatefulWidget {
  const BusinessProductFormPage({
    super.key,
    required this.businessId,
    required this.businessName,
    this.doc,
  });

  final String businessId;
  final String businessName;
  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;

  @override
  State<BusinessProductFormPage> createState() =>
      _BusinessProductFormPageState();
}

class _BusinessProductFormPageState extends State<BusinessProductFormPage> {
  final BusinessProductsService _productsService = BusinessProductsService();
  final _name = TextEditingController();
  final _barcode = TextEditingController();
  final _purchasePrice = TextEditingController();
  final _salePrice = TextEditingController();
  final _stock = TextEditingController();
  final _minStock = TextEditingController();

  String _category = 'Genel';
  bool _isPublic = false;
  bool _isActive = true;
  bool _saving = false;

  static const categories = [
    'Genel',
    'Şampuan',
    'Saç Bakım',
    'Cilt Bakım',
    'Kozmetik',
    'Manikür/Pedikür',
    'Sarf Malzeme',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();

    final data = widget.doc?.data();
    if (data != null) {
      _name.text = _clean(data[FirestoreFields.name]);
      _barcode.text = _clean(data[FirestoreFields.barcode]);
      _purchasePrice.text = _numberText(data[FirestoreFields.purchasePrice]);
      _salePrice.text = _numberText(data[FirestoreFields.salePrice]);
      _stock.text = _numberText(data[FirestoreFields.stockQuantity]);
      _minStock.text = _numberText(data[FirestoreFields.minStockQuantity]);
      _category = _clean(data[FirestoreFields.category]).isEmpty
          ? 'Genel'
          : _clean(data[FirestoreFields.category]);
      _isPublic = data[FirestoreFields.isPublic] == true;
      _isActive = data[FirestoreFields.isActive] != false;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _purchasePrice.dispose();
    _salePrice.dispose();
    _stock.dispose();
    _minStock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();

    if (name.isEmpty) {
      _snack('Ürün adı boş olamaz.');
      return;
    }

    setState(() => _saving = true);

    try {
      await _productsService.saveProduct(
        productRef: widget.doc?.reference,
        input: BusinessProductSaveInput(
          businessId: widget.businessId,
          businessName: widget.businessName,
          name: name,
          category: _category,
          barcode: _barcode.text.trim(),
          purchasePrice: _toDouble(_purchasePrice.text),
          salePrice: _toDouble(_salePrice.text),
          stockQuantity: _toDouble(_stock.text),
          minStockQuantity: _toDouble(_minStock.text),
          isPublic: _isPublic,
          isActive: _isActive,
          source: 'business_products_page_38B',
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Ürün kaydedilemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.doc != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(editing ? 'Ürünü Düzenle' : 'Ürün Ekle'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Ürün adı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: categories.contains(_category) ? _category : 'Genel',
            decoration: const InputDecoration(
              labelText: 'Kategori',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? 'Genel'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _barcode,
            decoration: const InputDecoration(
              labelText: 'Barkod / Ürün kodu',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _purchasePrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Alış fiyatı',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _salePrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Satış fiyatı',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stok adedi',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _minStock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum stok',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
            title: const Text('Halka açık ürün'),
            subtitle: const Text(
              'Açık olursa bireysel kullanıcı kurumsal profilde görebilir.',
            ),
          ),
          SwitchListTile(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Aktif ürün'),
            subtitle: const Text(
              'Pasif ürün satış ve adisyonda gizlenebilir.',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data();

        final name = _clean(
          data[FirestoreFields.name] ?? data[FirestoreFields.productName],
        );
        final category = _clean(data[FirestoreFields.category]).isEmpty
            ? 'Genel'
            : _clean(data[FirestoreFields.category]);
        final purchasePrice = _toDouble(data[FirestoreFields.purchasePrice]);
        final salePrice = _toDouble(data[FirestoreFields.salePrice]);
        final stock = _toDouble(data[FirestoreFields.stockQuantity]);
        final minStock = _toDouble(data[FirestoreFields.minStockQuantity]);
        final active = data[FirestoreFields.isActive] != false;
        final isPublic = data[FirestoreFields.isPublic] == true;
        final low = minStock > 0 && stock <= minStock;

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
                        name.isEmpty ? 'Ürün' : name,
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
                        value: _money(purchasePrice),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AmountBox(
                        label: 'Satış',
                        value: _money(salePrice),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AmountBox(label: 'Stok', value: _qty(stock)),
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
    );
  }
}

class _StockOverview extends StatelessWidget {
  const _StockOverview({required this.docs});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  Widget build(BuildContext context) {
    double totalCost = 0;
    double totalSale = 0;
    double totalStock = 0;

    for (final doc in docs) {
      final data = doc.data();
      final stock = _toDouble(data[FirestoreFields.stockQuantity]);
      totalStock += stock;
      totalCost += stock * _toDouble(data[FirestoreFields.purchasePrice]);
      totalSale += stock * _toDouble(data[FirestoreFields.salePrice]);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _SummaryCard(
          title: 'Stok Özeti',
          items: [
            _SummaryItem('Ürün çeşidi', docs.length.toString()),
            _SummaryItem('Toplam stok', _qty(totalStock)),
            _SummaryItem('Stok maliyeti', _money(totalCost)),
            _SummaryItem('Satış potansiyeli', _money(totalSale)),
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

class _InfoState extends StatelessWidget {
  const _InfoState({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
            child: Column(
              children: [
                Icon(icon, size: 40, color: const Color(0xFF64748B)),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _clean(dynamic value) => value?.toString().trim() ?? '';

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();

  final text = value?.toString().replaceAll(',', '.').trim() ?? '';
  return double.tryParse(text) ?? 0;
}

String _numberText(dynamic value) {
  final n = _toDouble(value);
  if (n == 0) return '';
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(2);
}

String _money(double value) {
  return '${value.toStringAsFixed(2).replaceAll('.', ',')} TL';
}

String _qty(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2).replaceAll('.', ',');
}
