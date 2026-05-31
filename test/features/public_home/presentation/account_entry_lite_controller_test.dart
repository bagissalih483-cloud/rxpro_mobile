import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/public_home/data/account_user_profile_repository.dart';
import 'package:rxpro_mobile/features/public_home/presentation/account_entry_lite_controller.dart';

void main() {
  group('AccountUserProfileLiteController', () {
    test('applies loaded user profile state', () {
      final controller = AccountUserProfileLiteController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.applyLoaded(
        const AccountUserProfileData(
          displayName: 'Ayse Demir',
          email: 'ayse@example.com',
          phone: '05000000000',
          city: 'Sanliurfa',
          district: 'Karakopru',
          photoUrl: 'https://example.com/avatar.jpg',
        ),
      );

      expect(controller.loading, isFalse);
      expect(controller.email, 'ayse@example.com');
      expect(controller.photoUrl, 'https://example.com/avatar.jpg');
      expect(notifications, 1);
    });

    test('tracks save and avatar upload state', () {
      final controller = AccountUserProfileLiteController();

      controller.setSaving(true);
      controller.setUploadingAvatar(true);
      controller.applyAvatarUrl('  https://example.com/new.jpg  ');

      expect(controller.saving, isTrue);
      expect(controller.uploadingAvatar, isFalse);
      expect(controller.photoUrl, 'https://example.com/new.jpg');
    });
  });

  group('AccountAppSettingsLiteController', () {
    test('applies loaded settings and updates switches', () {
      final controller = AccountAppSettingsLiteController();

      controller.applyLoaded(
        notifications: false,
        campaigns: true,
        routeDistance: false,
      );
      controller.setNotifications(true);
      controller.setCampaigns(false);
      controller.setRouteDistance(true);

      expect(controller.loading, isFalse);
      expect(controller.notifications, isTrue);
      expect(controller.campaigns, isFalse);
      expect(controller.routeDistance, isTrue);
    });
  });
}
