import '../models/accounting_models.dart';

class AccountingDtoCodec {
  const AccountingDtoCodec._();

  static Map<String, Object?> saleToMap(AccountingSale sale) {
    return {
      'saleId': sale.saleId,
      'businessId': sale.businessId,
      'customerId': sale.customerId,
      'customerName': sale.customerName,
      'customerPhone': sale.customerPhone,
      'appointmentId': sale.appointmentId,
      'source': sale.source.name,
      'saleType': sale.saleType.name,
      'totalAmountKurus': sale.totalAmountKurus,
      'paidAmountKurus': sale.paidAmountKurus,
      'remainingAmountKurus': sale.remainingAmountKurus,
      'discountAmountKurus': sale.discountAmountKurus,
      'depositAmountKurus': sale.depositAmountKurus,
      'processStatus': sale.processStatus.name,
      'paymentStatus': sale.paymentStatus.name,
      'paymentMethod': sale.paymentMethod.name,
      'dueDate': sale.dueDate?.toIso8601String(),
      'note': sale.note,
      'createdByUid': sale.createdByUid,
      'createdByName': sale.createdByName,
      'createdAt': sale.createdAt.toIso8601String(),
      'items': sale.items.map(saleItemToMap).toList(),
      'schemaVersion': 1,
    };
  }

  static Map<String, Object?> saleItemToMap(AccountingSaleItem item) {
    return {
      'itemType': item.itemType.name,
      'refId': item.refId,
      'name': item.name,
      'quantity': item.quantity,
      'unitPriceKurus': item.unitPriceKurus,
      'lineTotalKurus': item.lineTotalKurus,
    };
  }

  static Map<String, Object?> paymentToMap(AccountingPayment payment) {
    return {
      'paymentId': payment.paymentId,
      'saleId': payment.saleId,
      'businessId': payment.businessId,
      'customerId': payment.customerId,
      'amountKurus': payment.amountKurus,
      'method': payment.method.name,
      'collectedAt': payment.collectedAt.toIso8601String(),
      'collectedByUid': payment.collectedByUid,
      'note': payment.note,
      'source': payment.source,
      'schemaVersion': 1,
    };
  }

  static Map<String, Object?> expenseToMap(AccountingExpense expense) {
    return {
      'expenseId': expense.expenseId,
      'businessId': expense.businessId,
      'category': expense.category,
      'title': expense.title,
      'amountKurus': expense.amountKurus,
      'paymentMethod': expense.paymentMethod.name,
      'status': expense.status.name,
      'expenseDate': expense.expenseDate.toIso8601String(),
      'vendorName': expense.vendorName,
      'note': expense.note,
      'createdByUid': expense.createdByUid,
      'createdAt': expense.createdAt.toIso8601String(),
      'schemaVersion': 1,
    };
  }
}
