import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/public_home/domain/account_owner_overview_model.dart';

void main() {
  group('AccountOwnerOverviewModel', () {
    test('computes profile completion from business fields', () {
      final model =
          AccountOwnerOverviewModel.fromBusinessData(<String, dynamic>{
            FirestoreFields.businessName: 'Fix Beauty',
            FirestoreFields.categoryLabel: 'Güzellik & Bakım',
            FirestoreFields.phone: '0500 000 00 00',
            FirestoreFields.address: 'Karaköprü',
            FirestoreFields.lat: 37.1,
            'logoUrl': 'https://example.com/logo.png',
            FirestoreFields.openingHour: '09:00',
          });

      expect(model.profileCompletionPercent, 100);
    });

    test('reads active business status from common fields', () {
      final model = AccountOwnerOverviewModel.fromBusinessData(
        <String, dynamic>{FirestoreFields.status: 'active'},
      );

      expect(model.isActive, isTrue);
      expect(model.statusLabel, 'Aktif');
    });

    test('marks sparse business data as needing review', () {
      final model = AccountOwnerOverviewModel.fromBusinessData(
        <String, dynamic>{FirestoreFields.businessName: 'Fix'},
      );

      expect(model.profileCompletionPercent, lessThan(30));
      expect(model.isActive, isFalse);
      expect(model.statusLabel, 'Kontrol et');
    });
  });
}
