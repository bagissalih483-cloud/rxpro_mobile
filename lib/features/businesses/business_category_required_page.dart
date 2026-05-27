import 'package:flutter/material.dart';

import '../../core/businesses/business_category.dart';
import 'data/registered_business_gateway_repository.dart';

class BusinessCategoryRequiredPage extends StatefulWidget {
  const BusinessCategoryRequiredPage({
    super.key,
    required this.businessId,
    required this.sourceCollection,
    required this.businessName,
  });

  final String businessId;
  final String sourceCollection;
  final String businessName;

  @override
  State<BusinessCategoryRequiredPage> createState() =>
      _BusinessCategoryRequiredPageState();
}

class _BusinessCategoryRequiredPageState
    extends State<BusinessCategoryRequiredPage> {
  BusinessCategoryOption? selected;
  bool saving = false;
  final RegisteredBusinessGatewayRepository _gatewayRepository =
      RegisteredBusinessGatewayRepository();

  Future<void> _save() async {
    final category = selected;

    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kayıt işlemine devam etmek için kurumsal kategori seçmelisiniz.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.businessId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kurumsal kayıt bulunamadı. Önce kurumsal profilinizi oluşturun.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final collection = widget.sourceCollection.trim().isEmpty
          ? RegisteredBusinessGatewayCollections.businesses
          : widget.sourceCollection.trim();

      await _gatewayRepository.updateBusinessCategory(
        collection: collection,
        businessId: widget.businessId,
        category: category,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kategori kaydedildi: ${category.label}'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kategori kaydedilemedi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessName = widget.businessName.trim().isEmpty
        ? 'Kurumsal Profiliniz'
        : widget.businessName.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Kurumsal Kategori')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    color: Color(0xFF216A6D),
                    size: 34,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$businessName için kategori seçin',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kategori bilgisi Keşfet filtreleri, sıralama, kampanya hedefleme ve ileride eklenecek öneri sistemleri için zorunludur.',
                    style: TextStyle(color: Color(0xFF60727A), height: 1.35),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...BusinessCategories.values.map((item) {
            final active = selected?.id == item.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                color: active ? const Color(0xFFE8FAF4) : null,
                child: RadioListTile<BusinessCategoryOption>(
                  value: item,
                  // ignore: deprecated_member_use
                  groupValue: selected,
                  // ignore: deprecated_member_use
                  onChanged: saving
                      ? null
                      : (value) {
                          setState(() => selected = value);
                        },
                  title: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(item.keywords.take(4).join(' • ')),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(saving ? 'Kaydediliyor' : 'Kategoriyi Kaydet'),
          ),
        ],
      ),
    );
  }
}
