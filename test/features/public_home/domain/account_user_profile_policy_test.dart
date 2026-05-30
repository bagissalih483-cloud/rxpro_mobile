import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/public_home/domain/account_user_profile_policy.dart';

void main() {
  group('AccountUserProfilePolicy', () {
    test('validates display name length after trimming', () {
      expect(AccountUserProfilePolicy.validateDisplayName(' A '), isNotNull);
      expect(AccountUserProfilePolicy.validateDisplayName(' Ayse '), isNull);
    });

    test('normalizes profile update input before repository writes', () {
      final input = AccountUserProfilePolicy.normalizeUpdate(
        displayName: '  Ayse Demir ',
        phone: '  05xx xxx xx xx ',
        city: ' Sanliurfa ',
        district: ' Karakopru ',
        photoUrl: ' https://cdn.example/avatar.jpg ',
      );

      expect(input.displayName, 'Ayse Demir');
      expect(input.phone, '05xx xxx xx xx');
      expect(input.city, 'Sanliurfa');
      expect(input.district, 'Karakopru');
      expect(input.photoUrl, 'https://cdn.example/avatar.jpg');
    });

    test('builds verification text with auth phone preferred', () {
      expect(
        AccountUserProfilePolicy.verificationText(
          email: ' user@example.com ',
          authPhoneNumber: '+905551112233',
          profilePhone: '0555 111 22 33',
        ),
        'E-posta: user@example.com\nTelefon: +905551112233',
      );
    });

    test('builds verification text with profile phone fallback', () {
      expect(
        AccountUserProfilePolicy.verificationText(
          email: '',
          authPhoneNumber: null,
          profilePhone: ' 0555 111 22 33 ',
        ),
        'E-posta: -\nTelefon: 0555 111 22 33',
      );
    });
  });
}
