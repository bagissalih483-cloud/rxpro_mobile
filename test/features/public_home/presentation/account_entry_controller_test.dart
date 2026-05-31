import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/public_home/presentation/account_entry_controller.dart';
import 'package:rxpro_mobile/features/public_home/presentation/models/account_entry_context.dart';

void main() {
  group('AccountEntryController', () {
    test('owns opened account menu sections', () {
      final controller = AccountEntryController();

      expect(controller.openSections, isEmpty);

      controller.toggleSection(2);
      expect(controller.openSections, contains(2));

      controller.toggleSection(2);
      expect(controller.openSections, isEmpty);

      controller.dispose();
    });

    test('owns context future and loaded key', () async {
      final controller = AccountEntryController();

      expect(controller.needsContext('u1'), isTrue);

      controller.setContextFuture(
        loadedKey: 'u1',
        future: Future<AccountEntryContext>.value(AccountEntryContext.guest()),
      );

      expect(controller.loadedKey, 'u1');
      expect(controller.needsContext('u1'), isFalse);
      expect(await controller.contextFuture, isA<AccountEntryContext>());

      controller
        ..toggleSection(1)
        ..clearContext(clearOpenSections: true);

      expect(controller.loadedKey, isNull);
      expect(controller.contextFuture, isNull);
      expect(controller.openSections, isEmpty);

      controller.dispose();
    });
  });
}
