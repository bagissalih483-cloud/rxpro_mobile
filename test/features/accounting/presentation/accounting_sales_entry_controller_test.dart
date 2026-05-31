import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/accounting/presentation/accounting_sales_entry_controller.dart';

void main() {
  group('AccountingSalesEntryController', () {
    test('owns wizard step, sale type, and catalog selection', () {
      final controller = AccountingSalesEntryController();
      addTearDown(controller.dispose);

      expect(controller.step, 0);
      expect(controller.saleType, 'service');
      expect(controller.selectedCatalogItem, 'service_1');

      final catalogItem = controller.selectSaleType('product');

      expect(controller.saleType, 'product');
      expect(catalogItem, 'product_1');
      expect(controller.selectedCatalogItem, 'product_1');
      expect(controller.step, 1);

      controller.selectCatalogItem('manual');
      expect(controller.selectedCatalogItem, 'manual');
      expect(controller.step, 3);
    });

    test('owns payment, due date, installment, and finalize state', () {
      final controller = AccountingSalesEntryController();
      addTearDown(controller.dispose);

      controller.selectPaymentStatus('partial');
      controller.selectPaymentMethod('card');
      controller.setHasDueDate(true);

      expect(controller.paymentStatus, 'partial');
      expect(controller.paymentMethod, 'card');
      expect(controller.hasDueDate, isTrue);
      expect(controller.step, 4);

      controller.setInstallment(true);
      controller.setInstallmentCount('6');
      controller.setInstallmentPeriod('weekly');

      expect(controller.isInstallment, isTrue);
      expect(controller.hasDueDate, isTrue);
      expect(controller.finalizeAtCollectedAmount, isFalse);
      expect(controller.installmentCount, '6');
      expect(controller.installmentPeriod, 'weekly');

      controller.setFinalizeAtCollectedAmount(true);

      expect(controller.finalizeAtCollectedAmount, isTrue);
      expect(controller.hasDueDate, isFalse);
      expect(controller.isInstallment, isFalse);
    });

    test('normalizes professional payment result shortcuts', () {
      final controller = AccountingSalesEntryController();
      addTearDown(controller.dispose);

      controller.selectPaymentStatus('installment');

      expect(controller.paymentStatus, 'installment');
      expect(controller.isInstallment, isTrue);
      expect(controller.hasDueDate, isTrue);
      expect(controller.finalizeAtCollectedAmount, isFalse);

      controller.selectPaymentStatus('free');

      expect(controller.paymentStatus, 'free');
      expect(controller.isInstallment, isFalse);
      expect(controller.hasDueDate, isFalse);
      expect(controller.finalizeAtCollectedAmount, isTrue);
    });

    test('clamps wizard step range', () {
      final controller = AccountingSalesEntryController();
      addTearDown(controller.dispose);

      controller.goToStep(99);
      expect(controller.step, 4);

      controller.goToStep(-4);
      expect(controller.step, 0);
    });
  });
}
