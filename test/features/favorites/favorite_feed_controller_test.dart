import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/favorites/favorite_feed_controller.dart';

void main() {
  group('FavoriteFeedController', () {
    test('owns tab and loaded futures', () async {
      var feedLoads = 0;
      var savedLoads = 0;
      final controller = FavoriteFeedController<int, List<int>>(
        loadFeed: (uid) async {
          feedLoads += 1;
          return uid.length;
        },
        loadSaved: (uid) async {
          savedLoads += 1;
          return <int>[uid.length];
        },
        emptyFeed: () async => 0,
        emptySaved: () async => const <int>[],
      );

      controller.ensureLoaded('abc');
      expect(await controller.feedFuture, 3);
      expect(await controller.savedFuture, <int>[3]);
      expect(feedLoads, 1);
      expect(savedLoads, 1);

      controller.selectTab(2);
      expect(controller.selectedTab, 2);

      await controller.refresh('abcd');
      expect(await controller.feedFuture, 4);
      expect(await controller.savedFuture, <int>[4]);

      controller.dispose();
    });
  });
}
