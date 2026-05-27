import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/session/app_role.dart';
import 'package:rxpro_mobile/core/session/session_role_policy.dart';

void main() {
  group('SessionRolePolicy pure helpers', () {
    test('truthy recognizes common true-like values', () {
      expect(SessionRolePolicy.truthy(true), isTrue);
      expect(SessionRolePolicy.truthy('true'), isTrue);
      expect(SessionRolePolicy.truthy('1'), isTrue);
      expect(SessionRolePolicy.truthy(1), isTrue);
    });

    test('truthy rejects false-like and empty values', () {
      expect(SessionRolePolicy.truthy(false), isFalse);
      expect(SessionRolePolicy.truthy('false'), isFalse);
      expect(SessionRolePolicy.truthy(''), isFalse);
      expect(SessionRolePolicy.truthy(null), isFalse);
      expect(SessionRolePolicy.truthy(0), isFalse);
    });

    test('uidMatches trims and compares normalized uid values', () {
      expect(SessionRolePolicy.uidMatches(' user_123 ', 'user_123'), isTrue);
      expect(SessionRolePolicy.uidMatches('user_123', ' USER_123 '), isTrue);
      expect(SessionRolePolicy.uidMatches('', 'user_123'), isFalse);
      expect(SessionRolePolicy.uidMatches('user_123', null), isFalse);
    });

    test('text and norm provide stable normalization', () {
      expect(SessionRolePolicy.text('  Owner  '), 'Owner');
      expect(SessionRolePolicy.text(null), '');
      expect(SessionRolePolicy.norm('  Owner Role  '), 'ownerrole');
    });
  });

  group('SessionRolePolicy role resolution', () {
    test('accountKind individual wins over legacy business leftovers', () {
      final role = SessionRolePolicy.resolveCanonicalRole({
        FirestoreFields.accountKind: 'individual',
        FirestoreFields.businessId: 'legacy_business',
        FirestoreFields.isBusinessOwner: true,
      });

      expect(role, AppRole.individual);
    });

    test('corporate linked staff resolves to staff when session is active', () {
      final role = SessionRolePolicy.resolveCanonicalRole({
        FirestoreFields.accountKind: 'corporate',
        FirestoreFields.role: 'linkedStaff',
        FirestoreFields.businessStaffId: 'staff_1',
        FirestoreFields.activeWorkSession: true,
      });

      expect(role, AppRole.corporateStaff);
    });

    test('inactive linked staff falls back to individual mode', () {
      final role = SessionRolePolicy.resolveCanonicalRole({
        FirestoreFields.role: 'linkedStaff',
        FirestoreFields.businessStaffId: 'staff_1',
        FirestoreFields.staffWorkStatus: 'inactive',
      });

      expect(role, AppRole.individual);
    });

    test('owner authority accepts business owner uid fields', () {
      final hasAuthority = SessionRolePolicy.hasOwnerAuthority(
        uid: 'owner_1',
        userData: const <String, dynamic>{},
        businessData: const <String, dynamic>{'ownerUid': ' OWNER_1 '},
      );

      expect(hasAuthority, isTrue);
    });
  });
}
