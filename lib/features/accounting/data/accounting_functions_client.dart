import 'package:cloud_functions/cloud_functions.dart';

import '../models/accounting_models.dart';
import 'accounting_dto.dart';
import 'accounting_repository.dart';

class AccountingFunctionsClient {
  AccountingFunctionsClient({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<void> createManualSale(AccountingSale sale) async {
    final callable = _functions.httpsCallable('accountingCreateManualSale');
    await callable.call(AccountingDtoCodec.saleToMap(sale));
  }

  Future<void> collectPayment(AccountingPayment payment) async {
    final callable = _functions.httpsCallable('accountingCollectPayment');
    await callable.call(AccountingDtoCodec.paymentToMap(payment));
  }

  Future<void> processSale(AccountingSaleProcessingInput input) async {
    final callable = _functions.httpsCallable('accountingProcessSale');
    await callable.call(<String, dynamic>{
      'businessId': input.sale.businessId,
      'saleId': input.sale.saleId,
      'paymentStatus': input.paymentStatus.name,
      'paymentMethod': input.paymentMethod.name,
      'paidAmountKurus': input.normalizedPaidAmountKurus,
      'dueDate': input.dueDate?.toIso8601String(),
      'installmentCount': input.installmentCount,
      'installmentPeriod': input.installmentPeriod,
      'note': input.note,
    });
  }

  Future<void> cancelSale(AccountingSaleCancellationInput input) async {
    final callable = _functions.httpsCallable('accountingCancelSale');
    await callable.call(<String, dynamic>{
      'businessId': input.businessId,
      'saleId': input.saleId,
      'cancelReason': input.cancelReason,
    });
  }

  Future<void> refundSale(AccountingSaleRefundInput input) async {
    final callable = _functions.httpsCallable('accountingRefundSale');
    await callable.call(<String, dynamic>{
      'businessId': input.businessId,
      'saleId': input.saleId,
      'amountKurus': input.amountKurus,
      'refundReason': input.refundReason,
      'method': input.method.name,
    });
  }

  Future<void> collectInstallmentPayment(
    AccountingInstallmentPaymentInput input,
  ) async {
    final callable = _functions.httpsCallable(
      'accountingCollectInstallmentPayment',
    );
    await callable.call(<String, dynamic>{
      'businessId': input.businessId,
      'saleId': input.saleId,
      'installmentId': input.installmentId,
      'amountKurus': input.amountKurus,
      'method': input.method.name,
      'note': input.note,
    });
  }

  Future<void> createExpense(AccountingExpense expense) async {
    final callable = _functions.httpsCallable('accountingCreateExpense');
    await callable.call(AccountingDtoCodec.expenseToMap(expense));
  }
}
