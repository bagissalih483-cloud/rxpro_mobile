import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/businesses/domain/business_service_form_policy.dart';
import 'package:rxpro_mobile/features/businesses/presentation/business_service_form_controller.dart';

void main() {
  group('BusinessServiceFormController', () {
    test('starts from existing service data', () {
      final controller = BusinessServiceFormController(
        initialData: {
          FirestoreFields.serviceType:
              BusinessServiceFormPolicy.sessionPackage,
          FirestoreFields.bookingEnabled: false,
        },
      );

      expect(controller.type, BusinessServiceFormPolicy.sessionPackage);
      expect(controller.active, isFalse);
      expect(controller.saving, isFalse);

      controller.dispose();
    });

    test('owns service form mutations', () {
      final controller = BusinessServiceFormController();

      controller
        ..selectType(BusinessServiceFormPolicy.package)
        ..setActive(false)
        ..setSaving(true);

      expect(controller.type, BusinessServiceFormPolicy.package);
      expect(controller.active, isFalse);
      expect(controller.saving, isTrue);

      controller.dispose();
    });
  });
}
