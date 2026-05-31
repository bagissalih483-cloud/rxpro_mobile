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

  Stream<List<AccountingInstallment>> watchInstallments({
    required String businessId,
    required DateTime from,
    required DateTime to,
  });

  Future<void> createManualSale(AccountingSale sale);

  Future<void> processSale(AccountingSaleProcessingInput input);

  Future<void> cancelSale(AccountingSaleCancellationInput input);

  Future<void> refundSale(AccountingSaleRefundInput input);

  Future<void> collectPayment(AccountingPayment payment);

  Future<void> collectInstallmentPayment(
    AccountingInstallmentPaymentInput input,
  );

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
  Stream<List<AccountingInstallment>> watchInstallments({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) {
    return const Stream<List<AccountingInstallment>>.empty();
  }

  @override
  Future<void> createManualSale(AccountingSale sale) {
    throw UnsupportedError(
      'Muhasebe veri yazma 46L/Cloud Function sonrasında açılacak.',
    );
  }

  @override
  Future<void> processSale(AccountingSaleProcessingInput input) {
    throw UnsupportedError(
      'Adisyon işleme veri yazma 46L/Cloud Function sonrasında açılacak.',
    );
  }

  @override
  Future<void> cancelSale(AccountingSaleCancellationInput input) {
    throw UnsupportedError(
      'Adisyon iptal işlemi Cloud Function sonrasında açılacak.',
    );
  }

  @override
  Future<void> refundSale(AccountingSaleRefundInput input) {
    throw UnsupportedError(
      'Adisyon iade işlemi Cloud Function sonrasında açılacak.',
    );
  }

  @override
  Future<void> collectPayment(AccountingPayment payment) {
    throw UnsupportedError(
      'Tahsilat veri yazma 46L/Cloud Function sonrasında açılacak.',
    );
  }

  @override
  Future<void> collectInstallmentPayment(
    AccountingInstallmentPaymentInput input,
  ) {
    throw UnsupportedError(
      'Taksit tahsilatı Cloud Function sonrasında açılacak.',
    );
  }

  @override
  Future<void> createExpense(AccountingExpense expense) {
    throw UnsupportedError(
      'Gider veri yazma 46L/Cloud Function sonrasında açılacak.',
    );
  }
}

class AccountingSaleCancellationInput {
  const AccountingSaleCancellationInput({
    required this.businessId,
    required this.saleId,
    required this.cancelReason,
  });

  final String businessId;
  final String saleId;
  final String cancelReason;
}

class AccountingInstallmentPaymentInput {
  const AccountingInstallmentPaymentInput({
    required this.businessId,
    required this.saleId,
    required this.installmentId,
    required this.amountKurus,
    required this.method,
    this.note,
  });

  final String businessId;
  final String saleId;
  final String installmentId;
  final int amountKurus;
  final AccountingPaymentMethod method;
  final String? note;
}

class AccountingSaleRefundInput {
  const AccountingSaleRefundInput({
    required this.businessId,
    required this.saleId,
    required this.amountKurus,
    required this.refundReason,
    this.method = AccountingPaymentMethod.unknown,
  });

  final String businessId;
  final String saleId;
  final int amountKurus;
  final String refundReason;
  final AccountingPaymentMethod method;
}

class AccountingSaleProcessingInput {
  const AccountingSaleProcessingInput({
    required this.sale,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paidAmountKurus,
    this.dueDate,
    this.installmentCount = 0,
    this.installmentPeriod = 'monthly',
    this.note,
  });

  final AccountingSale sale;
  final AccountingPaymentStatus paymentStatus;
  final AccountingPaymentMethod paymentMethod;
  final int paidAmountKurus;
  final DateTime? dueDate;
  final int installmentCount;
  final String installmentPeriod;
  final String? note;

  int get normalizedPaidAmountKurus {
    final total = sale.totalAmountKurus;
    return paidAmountKurus.clamp(0, total).toInt();
  }

  int get remainingAmountKurus {
    if (paymentStatus == AccountingPaymentStatus.free) return 0;
    final remaining = sale.totalAmountKurus - normalizedPaidAmountKurus;
    return remaining > 0 ? remaining : 0;
  }
}
