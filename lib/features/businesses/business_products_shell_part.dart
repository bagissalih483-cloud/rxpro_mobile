part of 'business_products_page.dart';

class BusinessProductsPage extends StatefulWidget {
  const BusinessProductsPage({super.key});

  @override
  State<BusinessProductsPage> createState() => _BusinessProductsPageState();
}

class _BusinessProductsPageState extends State<BusinessProductsPage> {
  final BusinessProductsService _productsService = BusinessProductsService();
  late final BusinessProductsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BusinessProductsController(
      loadContext: _loadBusinessContext,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

    if (saved == true && mounted) _controller.refreshContext();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FutureBuilder<BusinessProductContext>(
          future: _controller.contextFuture,
          builder: (context, businessSnapshot) {
        final ctx =
            businessSnapshot.data ??
            const BusinessProductContext(
              businessId: '',
              businessName: 'Kurumsal Kullanıcı',
            );

        return RxKeyboardShortcutScope(
          onCreate: ctx.businessId.isEmpty
              ? null
              : () => _openProductForm(contextData: ctx),
          child: DefaultTabController(
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

                      docs.sort(
                        (a, b) => BusinessProductPolicy.sortKey(
                          a.data(),
                        ).compareTo(BusinessProductPolicy.sortKey(b.data())),
                      );

                      final active = docs
                          .where((d) {
                            return BusinessProductPolicy.isActive(d.data());
                          })
                          .toList(growable: false);

                      final lowStock = active
                          .where((d) {
                            return BusinessProductPolicy.isLowStock(d.data());
                          })
                          .toList(growable: false);

                      final publicProducts = active
                          .where((d) {
                            return BusinessProductPolicy.isPublic(d.data());
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
          ),
        );
          },
        );
      },
    );
  }
}
