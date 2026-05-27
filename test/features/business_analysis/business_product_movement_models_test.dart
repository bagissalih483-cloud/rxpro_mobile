import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/business_analysis/business_product_movement_models.dart';

void main() {
  group('BusinessProductMovementRecord', () {
    test('fromMap reads canonical movement fields', () {
      final record = BusinessProductMovementRecord.fromMap(
        id: 'movement_1',
        data: const {
          'productName': 'Serum',
          'quantity': 3,
          'totalAmount': 1250.5,
        },
      );

      expect(record.id, 'movement_1');
      expect(record.productName, 'Serum');
      expect(record.quantity, 3);
      expect(record.totalAmount, 1250.5);
    });

    test('fromMap supports legacy fallback field names and string amounts', () {
      final record = BusinessProductMovementRecord.fromMap(
        id: 'movement_2',
        data: const {'title': 'Krem', 'count': '2', 'amount': '750,25'},
      );

      expect(record.productName, 'Krem');
      expect(record.quantity, 2);
      expect(record.totalAmount, 750.25);
    });

    test('fromMap uses safe defaults for malformed values', () {
      final record = BusinessProductMovementRecord.fromMap(
        id: 'movement_3',
        data: const {'quantity': 'not-a-number', 'amount': 'not-a-number'},
      );

      expect(record.productName, 'Urun');
      expect(record.quantity, 1);
      expect(record.totalAmount, 0);
    });
  });
}
