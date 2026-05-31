import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/stories/business_story_viewer_controller.dart';

void main() {
  group('BusinessStoryViewerController', () {
    test('owns current story index', () {
      final controller = BusinessStoryViewerController(initialIndex: 1);
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      expect(controller.index, 1);

      controller.setIndex(2);
      expect(controller.index, 2);
      expect(notifications, 1);

      controller.setIndex(2);
      expect(notifications, 1);

      controller.dispose();
    });
  });
}
