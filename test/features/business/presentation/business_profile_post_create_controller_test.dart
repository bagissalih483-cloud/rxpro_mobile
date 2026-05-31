import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxpro_mobile/features/business/presentation/business_profile_post_create_controller.dart';

void main() {
  group('BusinessProfilePostCreateController', () {
    test('owns selected image and saving state', () {
      final controller = BusinessProfilePostCreateController();
      final file = XFile('post.jpg');

      expect(controller.selectedImage, isNull);
      expect(controller.hasImage, isFalse);
      expect(controller.saving, isFalse);

      controller
        ..selectImage(file)
        ..setSaving(true);

      expect(controller.selectedImage, same(file));
      expect(controller.hasImage, isTrue);
      expect(controller.saving, isTrue);

      controller.dispose();
    });
  });
}
