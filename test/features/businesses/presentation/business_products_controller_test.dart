import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/businesses/data/business_products_repository.dart';
import 'package:rxpro_mobile/features/businesses/presentation/business_products_controller.dart';

void main() {
  group('BusinessProductsController', () {
    test('refreshes business context through its loader', () async {
      var loadCount = 0;
      final controller = BusinessProductsController(
        loadContext: () async {
          loadCount += 1;
          return BusinessProductContext(
            businessId: 'business-$loadCount',
            businessName: 'Business $loadCount',
          );
        },
      );

      expect((await controller.contextFuture).businessId, 'business-1');

      var notifications = 0;
      controller.addListener(() => notifications += 1);
      controller.refreshContext();

      expect((await controller.contextFuture).businessId, 'business-2');
      expect(loadCount, 2);
      expect(notifications, 1);

      controller.dispose();
    });
  });

  group('BusinessProductFormController', () {
    test('owns product form state from an existing product', () {
      final controller = BusinessProductFormController(
        initialData: {
          FirestoreFields.category: 'Kozmetik',
          FirestoreFields.isPublic: true,
          FirestoreFields.isActive: false,
        },
      );

      expect(controller.category, 'Kozmetik');
      expect(controller.isPublic, isTrue);
      expect(controller.isActive, isFalse);
      expect(controller.saving, isFalse);

      controller
        ..selectCategory('Genel')
        ..setPublic(false)
        ..setActive(true)
        ..setSaving(true);

      expect(controller.category, 'Genel');
      expect(controller.isPublic, isFalse);
      expect(controller.isActive, isTrue);
      expect(controller.saving, isTrue);

      controller.dispose();
    });
  });
}
