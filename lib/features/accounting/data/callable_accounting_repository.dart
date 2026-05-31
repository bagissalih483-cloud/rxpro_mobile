import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/services/app_observability_service.dart';

import '../models/accounting_models.dart';
import 'accounting_firestore_paths.dart';
import 'accounting_functions_client.dart';
import 'accounting_repository.dart';

class CallableAccountingRepository implements AccountingRepository {
  CallableAccountingRepository({
    AccountingFunctionsClient? client,
    FirebaseFirestore? firestore,
  }) : _client = client ?? AccountingFunctionsClient(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  static const _periodQueryLimit = 600;

  final AccountingFunctionsClient _client;
  final FirebaseFirestore _firestore;

  Query<Map<String, dynamic>> _salesPeriodQuery({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) {
    return _firestore
        .collection(AccountingFirestorePaths.sales(businessId))
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThan: Timestamp.fromDate(to))
        .orderBy('createdAt', descending: true)
        .limit(_periodQueryLimit);
  }

  Query<Map<String, dynamic>> _expensesPeriodQuery({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) {
    return _firestore
        .collection(AccountingFirestorePaths.expenses(businessId))
        .where('expenseDate', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('expenseDate', isLessThan: Timestamp.fromDate(to))
        .orderBy('expenseDate', descending: true)
        .limit(_periodQueryLimit);
  }

  Query<Map<String, dynamic>> _installmentsPeriodQuery({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) {
    return _firestore
        .collection(AccountingFirestorePaths.installments(businessId))
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('dueDate', isLessThan: Timestamp.fromDate(to))
        .orderBy('dueDate')
        .limit(_periodQueryLimit);
  }

  @override
  Stream<AccountingSummary> watchSummary({
    required String businessId,
    required String periodKey,
    DateTime? from,
    DateTime? to,
  }) {
    if (businessId.trim().isEmpty) {
      return Stream<AccountingSummary>.value(
        AccountingSummary(businessId: businessId, periodLabel: periodKey),
      );
    }

    final controller = StreamController<AccountingSummary>();
    final now = DateTime.now();
    final periodStart = from ?? DateTime(now.year, now.month);
    final periodEnd = to ?? DateTime(now.year, now.month + 1);
    var salesReady = false;
    var expensesReady = false;
    var sales = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    var expenses = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    void emit() {
      if (!salesReady || !expensesReady || controller.isClosed) return;

      controller.add(
        _buildSummary(
          businessId: businessId,
          periodLabel: periodKey,
          sales: sales,
          expenses: expenses,
          periodStart: periodStart,
          periodEnd: periodEnd,
        ),
      );
    }

    final salesSubscription =
        _salesPeriodQuery(
          businessId: businessId,
          from: periodStart,
          to: periodEnd,
        ).snapshots().listen(
          (snapshot) {
            sales = snapshot.docs;
            salesReady = true;
            emit();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) controller.addError(error, stackTrace);
          },
        );

    final expensesSubscription =
        _expensesPeriodQuery(
          businessId: businessId,
          from: periodStart,
          to: periodEnd,
        ).snapshots().listen(
          (snapshot) {
            expenses = snapshot.docs;
            expensesReady = true;
            emit();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) controller.addError(error, stackTrace);
          },
        );

    controller.onCancel = () async {
      await salesSubscription.cancel();
      await expensesSubscription.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<AccountingSale>> watchSales({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) {
    if (businessId.trim().isEmpty) {
      return const Stream<List<AccountingSale>>.empty();
    }

    return _salesPeriodQuery(
      businessId: businessId,
      from: from,
      to: to,
    ).snapshots().map((snapshot) {
      final sales = snapshot.docs.map(_saleFromDoc).where((sale) {
        return !sale.createdAt.isBefore(from) && sale.createdAt.isBefore(to);
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return sales;
    });
  }

  @override
  Stream<List<AccountingExpense>> watchExpenses({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) {
    if (businessId.trim().isEmpty) {
      return const Stream<List<AccountingExpense>>.empty();
    }

    return _expensesPeriodQuery(
      businessId: businessId,
      from: from,
      to: to,
    ).snapshots().map((snapshot) {
      final expenses = snapshot.docs.map(_expenseFromDoc).where((expense) {
        if (expense.status == AccountingExpenseStatus.cancelled) {
          return false;
        }

        final date = expense.expenseDate;
        return !date.isBefore(from) && date.isBefore(to);
      }).toList()..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

      return expenses;
    });
  }

  @override
  Stream<List<AccountingInstallment>> watchInstallments({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) {
    if (businessId.trim().isEmpty) {
      return const Stream<List<AccountingInstallment>>.empty();
    }

    return _installmentsPeriodQuery(
      businessId: businessId,
      from: from,
      to: to,
    ).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(_installmentFromDoc)
          .where((item) => item.isOpen)
          .toList()
        ..sort((a, b) {
          final aDate = a.dueDate ?? DateTime(9999);
          final bDate = b.dueDate ?? DateTime(9999);
          return aDate.compareTo(bDate);
        });

      return items;
    });
  }

  @override
  Future<void> createManualSale(AccountingSale sale) async {
    await _client.createManualSale(sale);
    await AppObservabilityService.instance.logFinanceActionCompleted(
      actionType: 'manual_sale_created',
      businessId: sale.businessId,
      amountKurus: sale.totalAmountKurus,
    );
  }

  @override
  Future<void> processSale(AccountingSaleProcessingInput input) async {
    if (input.sale.businessId.trim().isEmpty ||
        input.sale.saleId.trim().isEmpty) {
      throw ArgumentError(
        'Adisyon işlemek için geçerli işletme ve adisyon gerekir.',
      );
    }

    await _client.processSale(input);
    await AppObservabilityService.instance.logFinanceActionCompleted(
      actionType: 'sale_processed_${input.paymentStatus.name}',
      businessId: input.sale.businessId,
      amountKurus: input.sale.totalAmountKurus,
    );
  }

  @override
  Future<void> cancelSale(AccountingSaleCancellationInput input) async {
    if (input.businessId.trim().isEmpty ||
        input.saleId.trim().isEmpty ||
        input.cancelReason.trim().isEmpty) {
      throw ArgumentError(
        'Adisyon iptali için işletme, adisyon ve iptal nedeni gerekir.',
      );
    }

    await _client.cancelSale(input);
    await AppObservabilityService.instance.logFinanceActionCompleted(
      actionType: 'sale_cancelled',
      businessId: input.businessId,
    );
  }

  @override
  Future<void> refundSale(AccountingSaleRefundInput input) async {
    if (input.businessId.trim().isEmpty ||
        input.saleId.trim().isEmpty ||
        input.refundReason.trim().isEmpty ||
        input.amountKurus <= 0) {
      throw ArgumentError(
        'Adisyon iadesi için geçerli adisyon, tutar ve iade nedeni gerekir.',
      );
    }

    await _client.refundSale(input);
    await AppObservabilityService.instance.logFinanceActionCompleted(
      actionType: 'sale_refunded',
      businessId: input.businessId,
      amountKurus: input.amountKurus,
    );
  }

  @override
  Future<void> collectPayment(AccountingPayment payment) async {
    await _client.collectPayment(payment);
    await AppObservabilityService.instance.logFinanceActionCompleted(
      actionType: 'payment_collected',
      businessId: payment.businessId,
      amountKurus: payment.amountKurus,
    );
  }

  @override
  Future<void> collectInstallmentPayment(
    AccountingInstallmentPaymentInput input,
  ) async {
    if (input.businessId.trim().isEmpty ||
        input.saleId.trim().isEmpty ||
        input.installmentId.trim().isEmpty ||
        input.amountKurus <= 0) {
      throw ArgumentError(
        'Taksit tahsilatı için geçerli adisyon, taksit ve tutar gerekir.',
      );
    }

    await _client.collectInstallmentPayment(input);
    await AppObservabilityService.instance.logFinanceActionCompleted(
      actionType: 'installment_payment_collected',
      businessId: input.businessId,
      amountKurus: input.amountKurus,
    );
  }

  @override
  Future<void> createExpense(AccountingExpense expense) async {
    await _client.createExpense(expense);
    await AppObservabilityService.instance.logFinanceActionCompleted(
      actionType: 'expense_created',
      businessId: expense.businessId,
      amountKurus: expense.amountKurus,
    );
  }

  AccountingSummary _buildSummary({
    required String businessId,
    required String periodLabel,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> sales,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> expenses,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    var totalSalesKurus = 0;
    var collectedKurus = 0;
    var pendingKurus = 0;
    var overdueKurus = 0;
    var expenseKurus = 0;
    var serviceRevenueKurus = 0;
    var productRevenueKurus = 0;
    var transactionCount = 0;
    final now = DateTime.now();

    for (final doc in sales) {
      final data = doc.data();
      final createdAt = _date(data['createdAt']);
      if (!_inPeriod(createdAt, periodStart, periodEnd)) continue;
      final paymentStatus = _text(data['paymentStatus']);
      if (paymentStatus == AccountingPaymentStatus.cancelled.name ||
          paymentStatus == AccountingPaymentStatus.refunded.name) {
        continue;
      }

      final total = _int(data['totalAmountKurus']);
      final paid = _int(data['paidAmountKurus']);
      final remaining = _int(data['remainingAmountKurus']);
      final saleType = _text(data['saleType']);
      final dueDate = _date(data['dueDate']);

      if (paymentStatus != AccountingPaymentStatus.free.name) {
        totalSalesKurus += total;
      }
      collectedKurus += paid;
      pendingKurus += remaining;
      transactionCount += 1;

      if (remaining > 0 && dueDate != null && dueDate.isBefore(now)) {
        overdueKurus += remaining;
      }

      if (paymentStatus == AccountingPaymentStatus.free.name) {
        continue;
      } else if (saleType == AccountingSaleType.product.name) {
        productRevenueKurus += total;
      } else if (saleType == AccountingSaleType.mixed.name) {
        serviceRevenueKurus += total;
        productRevenueKurus += total;
      } else {
        serviceRevenueKurus += total;
      }
    }

    for (final doc in expenses) {
      final data = doc.data();
      final expenseDate =
          _date(data['expenseDate']) ?? _date(data['createdAt']);
      if (!_inPeriod(expenseDate, periodStart, periodEnd)) continue;
      if (_text(data['status']) == AccountingExpenseStatus.cancelled.name) {
        continue;
      }

      expenseKurus += _int(data['amountKurus']);
      transactionCount += 1;
    }

    return AccountingSummary(
      businessId: businessId,
      periodLabel: periodLabel,
      totalSalesKurus: totalSalesKurus,
      collectedKurus: collectedKurus,
      pendingKurus: pendingKurus,
      overdueKurus: overdueKurus,
      expenseKurus: expenseKurus,
      serviceRevenueKurus: serviceRevenueKurus,
      productRevenueKurus: productRevenueKurus,
      transactionCount: transactionCount,
    );
  }

  bool _inPeriod(DateTime? date, DateTime start, DateTime end) {
    if (date == null) return false;
    return !date.isBefore(start) && date.isBefore(end);
  }

  int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _text(Object? value) {
    return value?.toString().trim() ?? '';
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.round());
    }

    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  AccountingSale _saleFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final saleType = _enumByName(
      AccountingSaleType.values,
      _text(data['saleType']),
      AccountingSaleType.service,
    );
    final total = _int(data['totalAmountKurus']);
    final itemFallback = _text(
      data['itemName'] ??
          data['title'] ??
          data['serviceName'] ??
          data['productName'],
    );

    return AccountingSale(
      saleId: doc.id,
      businessId: _text(data['businessId']).isEmpty
          ? doc.reference.parent.parent?.id ?? ''
          : _text(data['businessId']),
      customerId: _nullableText(data['customerId']),
      customerName: _nullableText(data['customerName']),
      customerPhone: _nullableText(data['customerPhone']),
      appointmentId: _nullableText(data['appointmentId']),
      source: _enumByName(
        AccountingSaleSource.values,
        _text(data['source']),
        AccountingSaleSource.manualWalkIn,
      ),
      saleType: saleType,
      items: _saleItems(data['items'], saleType, itemFallback, total),
      totalAmountKurus: total,
      paidAmountKurus: _int(data['paidAmountKurus']),
      remainingAmountKurus: _int(data['remainingAmountKurus']),
      discountAmountKurus: _int(data['discountAmountKurus']),
      depositAmountKurus: _int(data['depositAmountKurus']),
      processStatus: _processStatusOf(data),
      paymentStatus: _enumByName(
        AccountingPaymentStatus.values,
        _text(data['paymentStatus']),
        AccountingPaymentStatus.unpaid,
      ),
      paymentMethod: _enumByName(
        AccountingPaymentMethod.values,
        _text(data['paymentMethod']),
        AccountingPaymentMethod.unknown,
      ),
      dueDate: _date(data['dueDate']),
      note: _nullableText(data['note']),
      createdByUid: _nullableText(data['createdByUid']),
      createdByName: _nullableText(data['createdByName']),
      createdAt:
          _date(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  AccountingProcessStatus _processStatusOf(Map<String, dynamic> data) {
    final explicit = _enumByName(
      AccountingProcessStatus.values,
      _text(data['processStatus']),
      AccountingProcessStatus.pending,
    );
    if (_text(data['processStatus']).trim().isNotEmpty) return explicit;

    final paymentStatus = _text(data['paymentStatus']).toLowerCase();
    if (paymentStatus == AccountingPaymentStatus.cancelled.name) {
      return AccountingProcessStatus.cancelled;
    }

    final remaining = _int(data['remainingAmountKurus']);
    final paid = _int(data['paidAmountKurus']);
    if (paid > 0 || remaining > 0) return AccountingProcessStatus.processed;

    return AccountingProcessStatus.pending;
  }

  AccountingExpense _expenseFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt =
        _date(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final expenseDate = _date(data['expenseDate']) ?? createdAt;

    return AccountingExpense(
      expenseId: doc.id,
      businessId: _text(data['businessId']).isEmpty
          ? doc.reference.parent.parent?.id ?? ''
          : _text(data['businessId']),
      category: _text(data['category']).isEmpty
          ? 'other'
          : _text(data['category']),
      title: _text(data['title']).isEmpty
          ? 'Gider kaydı'
          : _text(data['title']),
      amountKurus: _int(data['amountKurus']),
      paymentMethod: _enumByName(
        AccountingPaymentMethod.values,
        _text(data['paymentMethod']),
        AccountingPaymentMethod.unknown,
      ),
      status: _enumByName(
        AccountingExpenseStatus.values,
        _text(data['status']),
        AccountingExpenseStatus.unpaid,
      ),
      expenseDate: expenseDate,
      createdAt: createdAt,
      vendorName: _nullableText(data['vendorName']),
      note: _nullableText(data['note']),
      createdByUid: _nullableText(data['createdByUid']),
    );
  }

  AccountingInstallment _installmentFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return AccountingInstallment(
      installmentId: _text(data['installmentId']).isEmpty
          ? doc.id
          : _text(data['installmentId']),
      businessId: _text(data['businessId']),
      saleId: _text(data['saleId']),
      customerId: _nullableText(data['customerId']),
      customerName: _nullableText(data['customerName']),
      installmentNo: _int(data['installmentNo']),
      amountKurus: _int(data['amountKurus']),
      paidAmountKurus: _int(data['paidAmountKurus']),
      dueDate: _date(data['dueDate']),
      status: _enumByName(
        AccountingInstallmentStatus.values,
        _text(data['status']),
        AccountingInstallmentStatus.pending,
      ),
    );
  }

  List<AccountingSaleItem> _saleItems(
    Object? value,
    AccountingSaleType fallbackType,
    String fallbackName,
    int fallbackTotal,
  ) {
    if (value is Iterable) {
      final items = value.whereType<Map>().map((raw) {
        final data = raw.cast<String, dynamic>();
        final itemType = _enumByName(
          AccountingSaleType.values,
          _text(data['itemType'] ?? data['type']),
          fallbackType,
        );
        final total = _int(data['lineTotalKurus']);
        final unit = _int(data['unitPriceKurus']);

        return AccountingSaleItem(
          itemType: itemType,
          refId: _nullableText(data['refId']),
          name: _text(data['name']).isEmpty
              ? 'Satış kalemi'
              : _text(data['name']),
          quantity: _int(data['quantity']).clamp(1, 999).toInt(),
          unitPriceKurus: unit == 0 ? total : unit,
          lineTotalKurus: total == 0 ? unit : total,
        );
      }).toList();

      if (items.isNotEmpty) return items;
    }

    return [
      AccountingSaleItem(
        itemType: fallbackType,
        refId: null,
        name: fallbackName.isEmpty ? 'Satış kalemi' : fallbackName,
        quantity: 1,
        unitPriceKurus: fallbackTotal,
        lineTotalKurus: fallbackTotal,
      ),
    ];
  }

  T _enumByName<T extends Enum>(List<T> values, String name, T fallback) {
    final normalized = name.trim();
    if (normalized.isEmpty) return fallback;

    for (final value in values) {
      if (value.name == normalized) return value;
    }

    return fallback;
  }

  String? _nullableText(Object? value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }
}
