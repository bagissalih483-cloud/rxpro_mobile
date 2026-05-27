enum BusinessProductMovementType {
  sale,
  purchase;

  String get firestoreValue => switch (this) {
    BusinessProductMovementType.sale => 'sale',
    BusinessProductMovementType.purchase => 'purchase',
  };
}

class BusinessProductMovementCreateInput {
  const BusinessProductMovementCreateInput({
    required this.businessId,
    required this.businessName,
    required this.productName,
    required this.quantity,
    required this.amount,
    required this.note,
    required this.type,
  });

  final String businessId;
  final String businessName;
  final String productName;
  final int quantity;
  final double amount;
  final String note;
  final BusinessProductMovementType type;
}

class BusinessProductMovementRecord {
  const BusinessProductMovementRecord({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.totalAmount,
  });

  final String id;
  final String productName;
  final int quantity;
  final double totalAmount;

  factory BusinessProductMovementRecord.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return BusinessProductMovementRecord(
      id: id,
      productName:
          (data['productName'] ?? data['name'] ?? data['title'] ?? 'Urun')
              .toString(),
      quantity: _intValue(data['quantity'] ?? data['count']) ?? 1,
      totalAmount: _doubleValue(data['totalAmount'] ?? data['amount']) ?? 0,
    );
  }

  static int? _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '');
  }
}
