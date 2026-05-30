import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/businesses/domain/business_product_policy.dart';

void main() {
  group('BusinessProductPolicy', () {
    test('normalizes product display fields and status flags', () {
      final row = {
        FirestoreFields.name: '  Şampuan ',
        FirestoreFields.category: ' Saç Bakım ',
        FirestoreFields.isActive: true,
        FirestoreFields.isPublic: true,
      };

      expect(BusinessProductPolicy.nameOf(row), 'Şampuan');
      expect(BusinessProductPolicy.categoryOf(row), 'Saç Bakım');
      expect(BusinessProductPolicy.isActive(row), isTrue);
      expect(BusinessProductPolicy.isPublic(row), isTrue);
      expect(BusinessProductPolicy.sortKey(row), 'şampuan');
      expect(BusinessProductPolicy.validCategory('Bilinmeyen'), 'Genel');
    });

    test('parses and formats numeric values', () {
      expect(BusinessProductPolicy.numberOf('12,50'), 12.5);
      expect(BusinessProductPolicy.numberText(12), '12');
      expect(BusinessProductPolicy.numberText(12.5), '12.50');
      expect(BusinessProductPolicy.money(12.5), '12,50 TL');
      expect(BusinessProductPolicy.quantity(3), '3');
      expect(BusinessProductPolicy.quantity(3.25), '3,25');
    });

    test('detects low stock and summarizes inventory value', () {
      final rows = [
        {
          FirestoreFields.stockQuantity: 3,
          FirestoreFields.minStockQuantity: 5,
          FirestoreFields.purchasePrice: 10,
          FirestoreFields.salePrice: 20,
        },
        {
          FirestoreFields.stockQuantity: 2,
          FirestoreFields.minStockQuantity: 0,
          FirestoreFields.purchasePrice: 4,
          FirestoreFields.salePrice: 8,
        },
      ];

      expect(BusinessProductPolicy.isLowStock(rows.first), isTrue);
      expect(BusinessProductPolicy.isLowStock(rows.last), isFalse);

      final summary = BusinessProductPolicy.stockSummary(rows);
      expect(summary.productCount, 2);
      expect(summary.totalStock, 5);
      expect(summary.totalCost, 38);
      expect(summary.totalSale, 76);
    });

    test('validates form fields and builds a save draft', () {
      expect(BusinessProductPolicy.validateName(' '), isNotNull);
      expect(BusinessProductPolicy.validateName('Krem'), isNull);
      expect(BusinessProductPolicy.validateOptionalNumber('bad'), isNotNull);
      expect(BusinessProductPolicy.validateOptionalNumber('12,50'), isNull);

      final draft = BusinessProductPolicy.buildSaveDraft(
        name: '  Krem ',
        category: '',
        barcode: '  ABC123 ',
        purchasePrice: '10,25',
        salePrice: '20',
        stockQuantity: '5',
        minStockQuantity: '2',
      );

      expect(draft.name, 'Krem');
      expect(draft.category, 'Genel');
      expect(draft.barcode, 'ABC123');
      expect(draft.purchasePrice, 10.25);
      expect(draft.salePrice, 20);
      expect(draft.stockQuantity, 5);
      expect(draft.minStockQuantity, 2);
    });
  });
}
