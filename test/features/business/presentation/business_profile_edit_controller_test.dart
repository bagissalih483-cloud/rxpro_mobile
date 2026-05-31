import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/businesses/business_category.dart';
import 'package:rxpro_mobile/features/business/presentation/business_profile_edit_controller.dart';

void main() {
  group('BusinessProfileEditController', () {
    test('owns profile edit loading, media, location, and saving state', () {
      final controller = BusinessProfileEditController();
      addTearDown(controller.dispose);

      expect(controller.loading, isTrue);

      controller.applyLoadedProfile(
        categoryId: BusinessCategories.values.last.id,
        logoUrl: ' https://logo.example ',
        coverUrl: '',
        businessLat: 37.19,
        businessLng: 38.79,
      );

      expect(controller.loading, isFalse);
      expect(controller.categoryId, BusinessCategories.values.last.id);
      expect(controller.logoUrl, 'https://logo.example');
      expect(controller.coverUrl, isNull);
      expect(controller.hasLocation, isTrue);
      expect(controller.hasLogo, isTrue);
      expect(controller.hasCover, isFalse);

      controller.setSaving(true);
      expect(controller.canStartMediaUpload, isFalse);

      controller.setSaving(false);
      controller.setLogoUploading(true);
      expect(controller.canStartMediaUpload, isFalse);

      controller.applyLogoUrl('https://new-logo.example');
      expect(controller.uploadingLogo, isFalse);
      expect(controller.logoUrl, 'https://new-logo.example');

      controller.setCoverUploading(true);
      controller.applyCoverUrl('https://cover.example');
      expect(controller.uploadingCover, isFalse);
      expect(controller.hasCover, isTrue);

      controller.applyLocation(latitude: 37.2, longitude: 38.8);
      expect(controller.businessLat, 37.2);
      expect(controller.businessLng, 38.8);
    });
  });
}
