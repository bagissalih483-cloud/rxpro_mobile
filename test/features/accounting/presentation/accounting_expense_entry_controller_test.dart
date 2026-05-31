import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/accounting/presentation/accounting_expense_entry_controller.dart';

void main() {
  group('AccountingExpenseEntryController', () {
    test('owns expense category payment and switch state', () {
      final controller = AccountingExpenseEntryController();

      expect(controller.category, 'supplies');
      expect(controller.paymentMethod, 'cash');
      expect(controller.isPaid, isTrue);
      expect(controller.isRecurring, isFalse);

      controller
        ..selectCategory('rent')
        ..selectPaymentMethod('bank')
        ..setPaid(false)
        ..setRecurring(true);

      expect(controller.category, 'rent');
      expect(controller.paymentMethod, 'bank');
      expect(controller.isPaid, isFalse);
      expect(controller.isRecurring, isTrue);

      controller.dispose();
    });

    test('does not notify for unchanged values', () {
      final controller = AccountingExpenseEntryController();
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      controller
        ..selectCategory('supplies')
        ..selectPaymentMethod('cash')
        ..setPaid(true)
        ..setRecurring(false);

      expect(notifications, 0);

      controller.dispose();
    });
  });
}
