import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/business_analysis/business_product_movement_models.dart';
import 'package:rxpro_mobile/features/business_analysis/presentation/business_product_movement_controller.dart';
import 'package:rxpro_mobile/features/business_analysis/services/business_product_movement_service.dart';

class BusinessProductMovementPage extends StatefulWidget {
  const BusinessProductMovementPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  State<BusinessProductMovementPage> createState() =>
      _BusinessProductMovementPageState();
}

class _BusinessProductMovementPageState
    extends State<BusinessProductMovementPage> {
  final BusinessProductMovementService _movementService =
      BusinessProductMovementService();
  late final BusinessProductMovementController _controller;

  final productController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = BusinessProductMovementController();
  }

  @override
  void dispose() {
    _controller.dispose();
    productController.dispose();
    quantityController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  int get quantity {
    final parsed = int.tryParse(quantityController.text.trim());
    if (parsed == null || parsed <= 0) return 1;
    return parsed;
  }

  double get amount {
    final raw = amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }

  bool get canSave {
    return _controller.canSave;
  }

  BusinessProductMovementType get movementType {
    return _controller.movementType;
  }

  Future<void> _save() async {
    if (!canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ürün adı zorunludur.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _controller.setSaving(true);

    try {
      await _movementService.createMovement(
        BusinessProductMovementCreateInput(
          businessId: widget.businessId,
          businessName: widget.businessName,
          productName: productController.text,
          quantity: quantity,
          amount: amount,
          note: noteController.text,
          type: movementType,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.successMessage,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      productController.clear();
      _controller.clearProductName();
      quantityController.text = '1';
      amountController.clear();
      noteController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt başarısız: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) _controller.setSaving(false);
    }
  }

  Stream<List<BusinessProductMovementRecord>> _recentStream() {
    return _movementService.watchRecentMovements(
      businessId: widget.businessId,
      type: movementType,
    );
  }

  String _money(dynamic value) {
    double amount = 0;

    if (value is num) {
      amount = value.toDouble();
    } else {
      amount =
          double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
    }

    final raw = amount.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} TL';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final mode = _controller.mode;
        final saving = _controller.saving;

        return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ürün Hareketi'),
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
          children: [
            Center(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Satış'),
                    icon: Icon(Icons.shopping_bag_outlined),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Alım'),
                    icon: Icon(Icons.inventory_2_outlined),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (value) {
                  _controller.selectMode(value.first);
                },
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              title: mode == 0 ? 'Ürün Satışı Kaydet' : 'Ürün Alımı Kaydet',
              child: Column(
                children: [
                  TextField(
                    controller: productController,
                    onChanged: _controller.setProductName,
                    decoration: const InputDecoration(
                      labelText: 'Ürün adı',
                      hintText: 'Örn. Şampuan, krem, serum',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Adet',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tutar',
                            hintText: 'Örn. 750',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Not',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              title: mode == 0 ? 'Son Ürün Satışları' : 'Son Ürün Alımları',
              child: StreamBuilder<List<BusinessProductMovementRecord>>(
                stream: _recentStream(),
                builder: (context, snapshot) {
                  final records =
                      snapshot.data ?? <BusinessProductMovementRecord>[];

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator(minHeight: 2);
                  }

                  if (records.isEmpty) {
                    return const Text(
                      'Henüz kayıt yok.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    );
                  }

                  return Column(
                    children: records.map((record) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              mode == 0
                                  ? Icons.shopping_bag_outlined
                                  : Icons.inventory_2_outlined,
                              color: const Color(0xFF0F766E),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${record.productName}\n${record.quantity} adet',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              _money(record.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: canSave ? _save : null,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(saving ? 'Kaydediliyor...' : 'Kaydet'),
        ),
      ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
