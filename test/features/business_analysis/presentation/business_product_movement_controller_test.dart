import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/business_analysis/business_product_movement_models.dart';
import 'package:rxpro_mobile/features/business_analysis/presentation/business_product_movement_controller.dart';

void main() {
  group('BusinessProductMovementController', () {
    test('owns mode and movement type', () {
      final controller = BusinessProductMovementController();

      expect(controller.mode, 0);
      expect(controller.movementType, BusinessProductMovementType.sale);

      controller.selectMode(1);

      expect(controller.mode, 1);
      expect(controller.movementType, BusinessProductMovementType.purchase);

      controller.dispose();
    });

    test('guards save availability with product text and saving state', () {
      final controller = BusinessProductMovementController();

      expect(controller.canSave, isFalse);

      controller.setProductName(' Serum ');
      expect(controller.canSave, isTrue);

      controller.setSaving(true);
      expect(controller.canSave, isFalse);

      controller
        ..setSaving(false)
        ..clearProductName();
      expect(controller.canSave, isFalse);

      controller.dispose();
    });
  });
}
