import 'package:cloud_functions/cloud_functions.dart';

import '../models/accounting_models.dart';
import 'accounting_dto.dart';

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

  Future<void> createExpense(AccountingExpense expense) async {
    final callable = _functions.httpsCallable('accountingCreateExpense');
    await callable.call(AccountingDtoCodec.expenseToMap(expense));
  }
}
