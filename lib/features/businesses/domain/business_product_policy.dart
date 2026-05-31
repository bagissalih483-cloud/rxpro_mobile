import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

class BusinessProductSaveDraft {
  const BusinessProductSaveDraft({
    required this.name,
    required this.category,
    required this.barcode,
    required this.purchasePrice,
    required this.salePrice,
    required this.stockQuantity,
    required this.minStockQuantity,
  });

  final String name;
  final String category;
  final String barcode;
  final double purchasePrice;
  final double salePrice;
  final double stockQuantity;
  final double minStockQuantity;
}

class BusinessProductStockSummary {
  const BusinessProductStockSummary({
    required this.productCount,
    required this.totalStock,
    required this.totalCost,
    required this.totalSale,
  });

  final int productCount;
  final double totalStock;
  final double totalCost;
  final double totalSale;
}

class BusinessProductPolicy {
  const BusinessProductPolicy._();

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

  static String clean(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static double numberOf(Object? value) {
    if (value is num) return value.toDouble();

    final text = value?.toString().replaceAll(',', '.').trim() ?? '';
    return double.tryParse(text) ?? 0;
  }

  static String numberText(Object? value) {
    final number = numberOf(value);
    if (number == 0) return '';
    if (number == number.roundToDouble()) return number.toInt().toString();
    return number.toStringAsFixed(2);
  }

  static String money(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} TL';
  }

  static String quantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String nameOf(Map<String, dynamic> data) {
    final name = clean(
      data[FirestoreFields.name] ?? data[FirestoreFields.productName],
    );
    return name.isEmpty ? 'Ürün' : name;
  }

  static String categoryOf(Map<String, dynamic> data) {
    final category = clean(data[FirestoreFields.category]);
    return category.isEmpty ? 'Genel' : category;
  }

  static String validCategory(String value) {
    final cleanValue = clean(value);
    return categories.contains(cleanValue) ? cleanValue : 'Genel';
  }

  static bool isActive(Map<String, dynamic> data) {
    return data[FirestoreFields.isActive] != false;
  }

  static bool isPublic(Map<String, dynamic> data) {
    return data[FirestoreFields.isPublic] == true;
  }

  static bool isLowStock(Map<String, dynamic> data) {
    final stock = numberOf(data[FirestoreFields.stockQuantity]);
    final min = numberOf(data[FirestoreFields.minStockQuantity]);
    return min > 0 && stock <= min;
  }

  static String sortKey(Map<String, dynamic> data) {
    return nameOf(data).toLowerCase();
  }

  static BusinessProductStockSummary stockSummary(
    Iterable<Map<String, dynamic>> rows,
  ) {
    var totalStock = 0.0;
    var totalCost = 0.0;
    var totalSale = 0.0;
    var count = 0;

    for (final data in rows) {
      count++;
      final stock = numberOf(data[FirestoreFields.stockQuantity]);
      totalStock += stock;
      totalCost += stock * numberOf(data[FirestoreFields.purchasePrice]);
      totalSale += stock * numberOf(data[FirestoreFields.salePrice]);
    }

    return BusinessProductStockSummary(
      productCount: count,
      totalStock: totalStock,
      totalCost: totalCost,
      totalSale: totalSale,
    );
  }

  static String? validateName(String? value) {
    if (clean(value).isEmpty) return 'Ürün adı boş olamaz.';
    return null;
  }

  static String? validateOptionalNumber(String? value) {
    final text = clean(value);
    if (text.isEmpty) return null;

    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return 'Geçerli sayı girin.';
    return null;
  }

  static BusinessProductSaveDraft buildSaveDraft({
    required String name,
    required String category,
    required String barcode,
    required String purchasePrice,
    required String salePrice,
    required String stockQuantity,
    required String minStockQuantity,
  }) {
    return BusinessProductSaveDraft(
      name: clean(name),
      category: clean(category).isEmpty ? 'Genel' : clean(category),
      barcode: clean(barcode),
      purchasePrice: numberOf(purchasePrice),
      salePrice: numberOf(salePrice),
      stockQuantity: numberOf(stockQuantity),
      minStockQuantity: numberOf(minStockQuantity),
    );
  }
}
