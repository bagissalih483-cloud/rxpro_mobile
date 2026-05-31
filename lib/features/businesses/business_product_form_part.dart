part of 'business_products_page.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _barcode = TextEditingController();
  final _purchasePrice = TextEditingController();
  final _salePrice = TextEditingController();
  final _stock = TextEditingController();
  final _minStock = TextEditingController();

  late final BusinessProductFormController _controller;

  @override
  void initState() {
    super.initState();

    final data = widget.doc?.data();
    _controller = BusinessProductFormController(initialData: data);
    if (data != null) {
      _name.text = BusinessProductPolicy.clean(data[FirestoreFields.name]);
      _barcode.text = BusinessProductPolicy.clean(
        data[FirestoreFields.barcode],
      );
      _purchasePrice.text = BusinessProductPolicy.numberText(
        data[FirestoreFields.purchasePrice],
      );
      _salePrice.text = BusinessProductPolicy.numberText(
        data[FirestoreFields.salePrice],
      );
      _stock.text = BusinessProductPolicy.numberText(
        data[FirestoreFields.stockQuantity],
      );
      _minStock.text = BusinessProductPolicy.numberText(
        data[FirestoreFields.minStockQuantity],
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _barcode.dispose();
    _purchasePrice.dispose();
    _salePrice.dispose();
    _stock.dispose();
    _minStock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _snack('Ürün bilgilerini kontrol edin.');
      return;
    }

    _controller.setSaving(true);

    try {
      final draft = BusinessProductPolicy.buildSaveDraft(
        name: _name.text,
        category: _controller.category,
        barcode: _barcode.text,
        purchasePrice: _purchasePrice.text,
        salePrice: _salePrice.text,
        stockQuantity: _stock.text,
        minStockQuantity: _minStock.text,
      );

      await _productsService.saveProduct(
        productRef: widget.doc?.reference,
        input: BusinessProductSaveInput(
          businessId: widget.businessId,
          businessName: widget.businessName,
          name: draft.name,
          category: draft.category,
          barcode: draft.barcode,
          purchasePrice: draft.purchasePrice,
          salePrice: draft.salePrice,
          stockQuantity: draft.stockQuantity,
          minStockQuantity: draft.minStockQuantity,
          isPublic: _controller.isPublic,
          isActive: _controller.isActive,
          source: 'business_products_page_38B',
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Ürün kaydedilemedi: $e');
    } finally {
      if (mounted) _controller.setSaving(false);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final editing = widget.doc != null;

        return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(editing ? 'Ürünü Düzenle' : 'Ürün Ekle'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Ürün adı',
                border: OutlineInputBorder(),
              ),
              validator: BusinessProductPolicy.validateName,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: BusinessProductPolicy.validCategory(
                _controller.category,
              ),
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: BusinessProductPolicy.categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => _controller.selectCategory(v ?? 'Genel'),
            ),
            const SizedBox(height: 12),
            TextFormField(
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
                  child: TextFormField(
                    controller: _purchasePrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Alış fiyatı',
                      border: OutlineInputBorder(),
                    ),
                    validator: BusinessProductPolicy.validateOptionalNumber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _salePrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Satış fiyatı',
                      border: OutlineInputBorder(),
                    ),
                    validator: BusinessProductPolicy.validateOptionalNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stok adedi',
                      border: OutlineInputBorder(),
                    ),
                    validator: BusinessProductPolicy.validateOptionalNumber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _minStock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minimum stok',
                      border: OutlineInputBorder(),
                    ),
                    validator: BusinessProductPolicy.validateOptionalNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _controller.isPublic,
              onChanged: _controller.setPublic,
              title: const Text('Halka açık ürün'),
              subtitle: const Text(
                'Açık olursa bireysel kullanıcı kurumsal profilde görebilir.',
              ),
            ),
            SwitchListTile(
              value: _controller.isActive,
              onChanged: _controller.setActive,
              title: const Text('Aktif ürün'),
              subtitle: const Text(
                'Pasif ürün satış ve adisyonda gizlenebilir.',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _controller.saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _controller.saving ? 'Kaydediliyor...' : 'Kaydet',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}
