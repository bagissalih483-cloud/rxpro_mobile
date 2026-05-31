import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/accounting/data/accounting_permissions.dart';
import 'package:rxpro_mobile/features/businesses/presentation/business_staff_form_controller.dart';

void main() {
  group('BusinessStaffFormController', () {
    test('owns role, service matching, and saving state', () {
      final controller = BusinessStaffFormController(staffId: null);
      addTearDown(controller.dispose);

      expect(controller.role, 'staff');
      expect(controller.canWorkAssignedAppointments, isTrue);
      expect(controller.requiresServiceMatchWarning, isTrue);

      controller.setServiceAssigned('svc-b', true);
      controller.setServiceAssigned('svc-a', true);

      expect(controller.sortedAssignedServiceIds, ['svc-a', 'svc-b']);
      expect(controller.serviceMatchMode, 'selected');
      expect(controller.requiresServiceMatchWarning, isFalse);

      controller.setSaving(true);
      expect(controller.saving, isTrue);
    });

    test('applies finance defaults when role changes to finance', () {
      final controller = BusinessStaffFormController(
        staffId: 'staff-1',
        initialData: const <String, dynamic>{FirestoreFields.role: 'staff'},
      );
      addTearDown(controller.dispose);

      expect(controller.financeRead, isFalse);

      controller.setRole('finance');

      expect(controller.role, 'finance');
      expect(controller.financeRead, isTrue);
      expect(controller.financeWrite, isTrue);
      expect(controller.expenseWrite, isTrue);
      expect(controller.receivableManage, isTrue);
      expect(controller.reportExport, isTrue);
    });

    test('keeps legacy appointment and accounting permissions readable', () {
      final controller = BusinessStaffFormController(
        staffId: 'staff-1',
        initialData: const <String, dynamic>{
          'canManageAppointments': true,
          FirestoreFields.permissions: <String, dynamic>{
            'viewFinance': true,
            'paymentCollect': true,
          },
        },
      );
      addTearDown(controller.dispose);

      expect(controller.canWorkAssignedAppointments, isTrue);
      expect(controller.canManageAppointmentChanges, isTrue);
      expect(controller.financeRead, isTrue);
      expect(controller.financeWrite, isTrue);
      expect(controller.receivableManage, isTrue);

      final permissions = controller.permissionsPayload(const <String, dynamic>{
        'legacyFlag': true,
      });

      expect(permissions['legacyFlag'], isTrue);
      expect(permissions['canManageAppointments'], isTrue);
      expect(permissions[AccountingPermissionKeys.receivableManage], isTrue);
    });
  });
}
