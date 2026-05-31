import 'package:flutter/foundation.dart';

enum AccountingSaleSource {
  appointment,
  manualWalkIn,
  manualRegisteredCustomer,
  productSale,
  mixed,
}

enum AccountingSaleType { service, product, mixed }

enum AccountingPeriodMode { day, month, year }

enum AccountingPaymentStatus {
  unpaid,
  partial,
  collected,
  paid,
  openAccount,
  installment,
  free,
  overdue,
  refunded,
  cancelled,
}

enum AccountingProcessStatus { pending, processed, cancelled }

enum AccountingPaymentMethod { cash, card, bank, nfc, mixed, unknown }

enum AccountingExpenseStatus { unpaid, paid, cancelled }

enum AccountingInstallmentStatus { pending, partial, paid, overdue, cancelled }

@immutable
class AccountingMoney {
  const AccountingMoney(this.kurus);

  final int kurus;

  double get tl => kurus / 100.0;

  String get displayTl {
    final value = tl.toStringAsFixed(2).replaceAll('.', ',');
    return '$value TL';
  }

  AccountingMoney operator +(AccountingMoney other) {
    return AccountingMoney(kurus + other.kurus);
  }

  AccountingMoney operator -(AccountingMoney other) {
    return AccountingMoney(kurus - other.kurus);
  }
}

@immutable
class AccountingSaleItem {
  const AccountingSaleItem({
    required this.itemType,
    required this.refId,
    required this.name,
    required this.quantity,
    required this.unitPriceKurus,
    required this.lineTotalKurus,
  });

  final AccountingSaleType itemType;
  final String? refId;
  final String name;
  final int quantity;
  final int unitPriceKurus;
  final int lineTotalKurus;
}

@immutable
class AccountingSale {
  const AccountingSale({
    required this.saleId,
    required this.businessId,
    required this.source,
    required this.saleType,
    required this.items,
    required this.totalAmountKurus,
    required this.paidAmountKurus,
    required this.remainingAmountKurus,
    required this.processStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.createdAt,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.appointmentId,
    this.discountAmountKurus = 0,
    this.depositAmountKurus = 0,
    this.dueDate,
    this.note,
    this.createdByUid,
    this.createdByName,
  });

  final String saleId;
  final String businessId;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? appointmentId;
  final AccountingSaleSource source;
  final AccountingSaleType saleType;
  final List<AccountingSaleItem> items;
  final int totalAmountKurus;
  final int paidAmountKurus;
  final int remainingAmountKurus;
  final int discountAmountKurus;
  final int depositAmountKurus;
  final AccountingProcessStatus processStatus;
  final AccountingPaymentStatus paymentStatus;
  final AccountingPaymentMethod paymentMethod;
  final DateTime? dueDate;
  final String? note;
  final String? createdByUid;
  final String? createdByName;
  final DateTime createdAt;

  bool get hasReceivable => remainingAmountKurus > 0;
  bool get isOverdue {
    final due = dueDate;
    if (due == null || remainingAmountKurus <= 0) return false;
    return DateTime.now().isAfter(due);
  }
}

@immutable
class AccountingPayment {
  const AccountingPayment({
    required this.paymentId,
    required this.saleId,
    required this.businessId,
    required this.amountKurus,
    required this.method,
    required this.collectedAt,
    this.customerId,
    this.collectedByUid,
    this.note,
    this.source = 'manual_collection',
  });

  final String paymentId;
  final String saleId;
  final String businessId;
  final String? customerId;
  final int amountKurus;
  final AccountingPaymentMethod method;
  final DateTime collectedAt;
  final String? collectedByUid;
  final String? note;
  final String source;
}

@immutable
class AccountingInstallment {
  const AccountingInstallment({
    required this.installmentId,
    required this.businessId,
    required this.saleId,
    required this.installmentNo,
    required this.amountKurus,
    required this.paidAmountKurus,
    required this.dueDate,
    required this.status,
    this.customerId,
    this.customerName,
  });

  final String installmentId;
  final String businessId;
  final String saleId;
  final String? customerId;
  final String? customerName;
  final int installmentNo;
  final int amountKurus;
  final int paidAmountKurus;
  final DateTime? dueDate;
  final AccountingInstallmentStatus status;

  int get remainingAmountKurus {
    final remaining = amountKurus - paidAmountKurus;
    return remaining > 0 ? remaining : 0;
  }

  bool get isOpen {
    return remainingAmountKurus > 0 &&
        status != AccountingInstallmentStatus.paid &&
        status != AccountingInstallmentStatus.cancelled;
  }
}

@immutable
class AccountingExpense {
  const AccountingExpense({
    required this.expenseId,
    required this.businessId,
    required this.category,
    required this.title,
    required this.amountKurus,
    required this.status,
    required this.expenseDate,
    required this.createdAt,
    this.paymentMethod = AccountingPaymentMethod.unknown,
    this.vendorName,
    this.note,
    this.createdByUid,
  });

  final String expenseId;
  final String businessId;
  final String category;
  final String title;
  final int amountKurus;
  final AccountingPaymentMethod paymentMethod;
  final AccountingExpenseStatus status;
  final DateTime expenseDate;
  final String? vendorName;
  final String? note;
  final String? createdByUid;
  final DateTime createdAt;
}

@immutable
class AccountingSummary {
  const AccountingSummary({
    required this.businessId,
    required this.periodLabel,
    this.totalSalesKurus = 0,
    this.collectedKurus = 0,
    this.pendingKurus = 0,
    this.overdueKurus = 0,
    this.expenseKurus = 0,
    this.serviceRevenueKurus = 0,
    this.productRevenueKurus = 0,
    this.transactionCount = 0,
  });

  final String businessId;
  final String periodLabel;
  final int totalSalesKurus;
  final int collectedKurus;
  final int pendingKurus;
  final int overdueKurus;
  final int expenseKurus;
  final int serviceRevenueKurus;
  final int productRevenueKurus;
  final int transactionCount;

  int get netKurus => collectedKurus - expenseKurus;
}
