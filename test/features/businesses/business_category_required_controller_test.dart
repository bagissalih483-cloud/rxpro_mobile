import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/businesses/business_category.dart';
import 'package:rxpro_mobile/features/businesses/business_category_required_controller.dart';

void main() {
  group('BusinessCategoryRequiredController', () {
    test('owns selected category and saving state', () {
      final controller = BusinessCategoryRequiredController();
      final category = BusinessCategories.values.first;

      expect(controller.selected, isNull);
      expect(controller.saving, isFalse);

      controller
        ..select(category)
        ..setSaving(true);

      expect(controller.selected, same(category));
      expect(controller.saving, isTrue);

      controller.dispose();
    });
  });
}
