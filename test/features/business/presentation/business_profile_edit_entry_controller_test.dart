import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/business/presentation/business_profile_edit_entry_controller.dart';

void main() {
  group('BusinessProfileEditEntryController', () {
    test('owns lookup result states', () {
      final controller = BusinessProfileEditEntryController();

      expect(controller.loading, isTrue);

      controller.setNeedsLogin();
      expect(controller.loading, isFalse);
      expect(controller.businessId, isNull);
      expect(controller.errorMessage, contains('giriş'));

      controller.setResolvedBusiness('business-1');
      expect(controller.businessId, 'business-1');
      expect(controller.errorMessage, isNull);

      controller.setLookupError('boom');
      expect(controller.businessId, isNull);
      expect(controller.errorMessage, contains('boom'));

      controller.dispose();
    });
  });
}
