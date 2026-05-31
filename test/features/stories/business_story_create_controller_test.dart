import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxpro_mobile/features/stories/business_story_create_controller.dart';

void main() {
  group('BusinessStoryCreateController', () {
    test('owns selected image and publishing state', () {
      final controller = BusinessStoryCreateController();
      final file = XFile('story.jpg');

      expect(controller.selectedImage, isNull);
      expect(controller.publishing, isFalse);

      controller
        ..selectImage(file)
        ..setPublishing(true);

      expect(controller.selectedImage, same(file));
      expect(controller.publishing, isTrue);

      controller.dispose();
    });
  });
}
