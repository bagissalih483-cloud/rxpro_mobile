import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/registered_businesses_controller.dart';

void main() {
  group('RegisteredBusinessesController', () {
    test('refreshes gateway future and owns staff opening state', () async {
      var loadCount = 0;
      final controller = RegisteredBusinessesController<int>(
        load: () async {
          loadCount += 1;
          return <int>[loadCount];
        },
      );

      expect(await controller.future, <int>[1]);
      expect(controller.openingStaff, isFalse);

      controller.setOpeningStaff(true);
      expect(controller.openingStaff, isTrue);

      await controller.refresh();

      expect(await controller.future, <int>[2]);
      expect(loadCount, 2);

      controller.dispose();
    });
  });
}
