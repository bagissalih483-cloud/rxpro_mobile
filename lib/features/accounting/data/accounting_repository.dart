import '../models/accounting_models.dart';

abstract class AccountingRepository {
  Stream<AccountingSummary> watchSummary({
    required String businessId,
    required String periodKey,
    DateTime? from,
    DateTime? to,
  });

  Stream<List<AccountingSale>> watchSales({
    required String businessId,
    required DateTime from,
    required DateTime to,
  });

  Stream<List<AccountingExpense>> watchExpenses({
    required String businessId,
    required DateTime from,
    required DateTime to,
  });

  Future<void> createManualSale(AccountingSale sale);

  Future<void> collectPayment(AccountingPayment payment);

  Future<void> createExpense(AccountingExpense expense);
}

class DisabledAccountingRepository implements AccountingRepository {
  const DisabledAccountingRepository();

  @override
  Stream<AccountingSummary> watchSummary({
    required String businessId,
    required String periodKey,
    DateTime? from,
    DateTime? to,
  }) {
    return Stream<AccountingSummary>.value(
      AccountingSummary(businessId: businessId, periodLabel: periodKey),
    );
  }

  @override
  Stream<List<AccountingSale>> watchSales({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) {
    return const Stream<List<AccountingSale>>.empty();
  }

  @override
  Stream<List<AccountingExpense>> watchExpenses({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) {
    return const Stream<List<AccountingExpense>>.empty();
  }

  @override
  Future<void> createManualSale(AccountingSale sale) {
    throw UnsupportedError(
      'Muhasebe veri yazma 46L/Cloud Function sonrasında açılacak.',
    );
  }

  @override
  Future<void> collectPayment(AccountingPayment payment) {
    throw UnsupportedError(
      'Tahsilat veri yazma 46L/Cloud Function sonrasında açılacak.',
    );
  }

  @override
  Future<void> createExpense(AccountingExpense expense) {
    throw UnsupportedError(
      'Gider veri yazma 46L/Cloud Function sonrasında açılacak.',
    );
  }
}
