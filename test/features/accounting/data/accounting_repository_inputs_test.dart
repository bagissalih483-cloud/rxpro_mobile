import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/accounting/data/accounting_repository.dart';
import 'package:rxpro_mobile/features/accounting/models/accounting_models.dart';

void main() {
  group('AccountingSaleProcessingInput', () {
    test('clamps paid amount to sale total', () {
      final input = AccountingSaleProcessingInput(
        sale: _sale(totalAmountKurus: 100000),
        paymentStatus: AccountingPaymentStatus.paid,
        paymentMethod: AccountingPaymentMethod.cash,
        paidAmountKurus: 150000,
      );

      expect(input.normalizedPaidAmountKurus, 100000);
      expect(input.remainingAmountKurus, 0);
    });

    test('keeps remaining amount for partial payment', () {
      final input = AccountingSaleProcessingInput(
        sale: _sale(totalAmountKurus: 100000),
        paymentStatus: AccountingPaymentStatus.partial,
        paymentMethod: AccountingPaymentMethod.card,
        paidAmountKurus: 40000,
      );

      expect(input.normalizedPaidAmountKurus, 40000);
      expect(input.remainingAmountKurus, 60000);
    });

    test('free sale has no remaining amount', () {
      final input = AccountingSaleProcessingInput(
        sale: _sale(totalAmountKurus: 100000),
        paymentStatus: AccountingPaymentStatus.free,
        paymentMethod: AccountingPaymentMethod.unknown,
        paidAmountKurus: 0,
      );

      expect(input.normalizedPaidAmountKurus, 0);
      expect(input.remainingAmountKurus, 0);
    });
  });
}

AccountingSale _sale({required int totalAmountKurus}) {
  return AccountingSale(
    saleId: 'sale_1',
    businessId: 'business_1',
    source: AccountingSaleSource.manualWalkIn,
    saleType: AccountingSaleType.service,
    items: const [
      AccountingSaleItem(
        itemType: AccountingSaleType.service,
        refId: 'service_1',
        name: 'Hizmet',
        quantity: 1,
        unitPriceKurus: 100000,
        lineTotalKurus: 100000,
      ),
    ],
    totalAmountKurus: totalAmountKurus,
    paidAmountKurus: 0,
    remainingAmountKurus: totalAmountKurus,
    processStatus: AccountingProcessStatus.pending,
    paymentStatus: AccountingPaymentStatus.unpaid,
    paymentMethod: AccountingPaymentMethod.unknown,
    createdAt: DateTime(2026, 1, 1),
  );
}
