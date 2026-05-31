import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/responsive/rx_adaptive_modal.dart';
import 'package:rxpro_mobile/core/session/app_session_scope.dart';
import 'package:rxpro_mobile/features/accounting/data/accounting_repository.dart';
import 'package:rxpro_mobile/features/accounting/data/callable_accounting_repository.dart';
import 'package:rxpro_mobile/features/accounting/models/accounting_models.dart';
import 'package:rxpro_mobile/features/accounting/presentation/widgets/accounting_sale_processing_sheet.dart';
part 'accounting_sales_summary_part.dart';
part 'accounting_sales_list_part.dart';
part 'accounting_sales_primitives_part.dart';

class AccountingSalesPage extends StatefulWidget {
  AccountingSalesPage({
    super.key,
    required this.from,
    required this.to,
    AccountingRepository? repository,
  }) : _repository = repository ?? CallableAccountingRepository();

  final DateTime from;
  final DateTime to;
  final AccountingRepository _repository;

  @override
  State<AccountingSalesPage> createState() => _AccountingSalesPageState();
}

class _AccountingSalesPageState extends State<AccountingSalesPage>
    with AutomaticKeepAliveClientMixin {
  String? _salesStreamKey;
  Stream<List<AccountingSale>>? _salesStream;
  final ValueNotifier<AccountingProcessStatus> _selectedStatus =
      ValueNotifier<AccountingProcessStatus>(AccountingProcessStatus.pending);

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _selectedStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final session = AppSessionScope.maybeOf(context);
    final businessId = session?.businessId ?? '';

    return ValueListenableBuilder<AccountingProcessStatus>(
      valueListenable: _selectedStatus,
      builder: (context, selectedStatus, _) {
        return StreamBuilder<List<AccountingSale>>(
          stream: _watchSalesFor(businessId),
          builder: (context, snapshot) {
        final sales = snapshot.data ?? const <AccountingSale>[];
        final canProcessSales =
            session?.hasPermission('adisyon.edit') == true ||
            session?.hasPermission('adisyon.collectPayment') == true;
        final canCancelSales =
            session?.hasPermission('adisyon.cancel') == true ||
            session?.hasPermission('saleCancel') == true;
        final canRefundSales =
            session?.hasPermission('adisyon.refund') == true ||
            session?.hasPermission('paymentRefund') == true;
        final pendingSales = _byProcessStatus(
          sales,
          AccountingProcessStatus.pending,
        );
        final processedSales = _byProcessStatus(
          sales,
          AccountingProcessStatus.processed,
        );
        final cancelledSales = _byProcessStatus(
          sales,
          AccountingProcessStatus.cancelled,
        );
        final visibleSales = _byProcessStatus(sales, selectedStatus);
        final serviceTotal = _sumByType(sales, AccountingSaleType.service);
        final productTotal = _sumByType(sales, AccountingSaleType.product);
        final mixedTotal = _sumByType(sales, AccountingSaleType.mixed);
        final collected = sales.fold<int>(
          0,
          (total, sale) => total + sale.paidAmountKurus,
        );
        final openAmountKurus = sales
            .where(
              (sale) =>
                  sale.processStatus != AccountingProcessStatus.cancelled &&
                  sale.paymentStatus != AccountingPaymentStatus.refunded,
            )
            .fold<int>(
              0,
              (total, sale) => total + sale.remainingAmountKurus,
            );

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
          children: [
            _AdisyonCommandHeader(
              pendingCount: pendingSales.length,
              openAmountKurus: openAmountKurus,
            ),
            const SizedBox(height: 10),
            _SalesInsightPanel(
              serviceTotal: serviceTotal,
              productTotal: productTotal,
              mixedTotal: mixedTotal,
              collected: collected,
              count: sales.length,
              pendingCount: pendingSales.length,
              processedCount: processedSales.length,
              cancelledCount: cancelledSales.length,
              openAmountKurus: openAmountKurus,
            ),
            const SizedBox(height: 10),
            _AdisyonStatusTabs(
              selected: selectedStatus,
              pendingCount: pendingSales.length,
              processedCount: processedSales.length,
              cancelledCount: cancelledSales.length,
              onSelected: (status) => _selectedStatus.value = status,
            ),
            const SizedBox(height: 10),
            _RecentSalesPanel(
              sales: visibleSales.take(24).toList(),
              status: selectedStatus,
              onProcessSale: _openProcessSaleSheet,
              onCancelSale: _confirmCancelSale,
              onRefundSale: _confirmRefundSale,
              canProcessSales: canProcessSales,
              canCancelSales: canCancelSales,
              canRefundSales: canRefundSales,
            ),
          ],
        );
          },
        );
      },
    );
  }

  Stream<List<AccountingSale>> _watchSalesFor(String businessId) {
    final key = [
      businessId,
      widget.from.millisecondsSinceEpoch,
      widget.to.millisecondsSinceEpoch,
    ].join('|');

    if (_salesStreamKey != key || _salesStream == null) {
      _salesStreamKey = key;
      _salesStream = widget._repository.watchSales(
        businessId: businessId,
        from: widget.from,
        to: widget.to,
      );
    }

    return _salesStream!;
  }

  int _sumByType(List<AccountingSale> sales, AccountingSaleType type) {
    return sales
        .where((sale) => sale.saleType == type)
        .fold<int>(0, (total, sale) => total + sale.totalAmountKurus);
  }

  List<AccountingSale> _byProcessStatus(
    List<AccountingSale> sales,
    AccountingProcessStatus status,
  ) {
    return sales.where((sale) => sale.processStatus == status).toList();
  }

  Future<void> _openProcessSaleSheet(AccountingSale sale) async {
    await showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 620,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: AccountingSaleProcessingSheet(
            sale: sale,
            repository: widget._repository,
          ),
        );
      },
    );
  }

  Future<void> _confirmCancelSale(AccountingSale sale) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adisyonu iptal et'),
          content: TextField(
            controller: reasonController,
            autofocus: true,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'İptal nedeni',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final text = reasonController.text.trim();
                if (text.isEmpty) return;
                Navigator.of(context).pop(text);
              },
              child: const Text('İptal et'),
            ),
          ],
        );
      },
    );
    reasonController.dispose();
    if (reason == null || reason.trim().isEmpty) return;

    try {
      await widget._repository.cancelSale(
        AccountingSaleCancellationInput(
          businessId: sale.businessId,
          saleId: sale.saleId,
          cancelReason: reason.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adisyon iptal edildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adisyon iptal edilemedi: $error')),
      );
    }
  }

  Future<void> _confirmRefundSale(AccountingSale sale) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adisyonu iade et'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'İlk güvenli fazda sadece tam iade yapılır: ${_money(sale.paidAmountKurus)}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                autofocus: true,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'İade nedeni',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final text = reasonController.text.trim();
                if (text.isEmpty) return;
                Navigator.of(context).pop(text);
              },
              child: const Text('Tam iade et'),
            ),
          ],
        );
      },
    );
    reasonController.dispose();
    if (reason == null || reason.trim().isEmpty) return;

    try {
      await widget._repository.refundSale(
        AccountingSaleRefundInput(
          businessId: sale.businessId,
          saleId: sale.saleId,
          amountKurus: sale.paidAmountKurus,
          refundReason: reason.trim(),
          method: sale.paymentMethod,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adisyon için tam iade kaydedildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İade kaydedilemedi: $error')),
      );
    }
  }
}


String _typeLabel(AccountingSaleType type) {
  switch (type) {
    case AccountingSaleType.product:
      return 'Ürün satışı';
    case AccountingSaleType.mixed:
      return 'Karma satış';
    case AccountingSaleType.service:
      return 'Hizmet satışı';
  }
}

IconData _typeIcon(AccountingSaleType type) {
  switch (type) {
    case AccountingSaleType.product:
      return Icons.inventory_2_rounded;
    case AccountingSaleType.mixed:
      return Icons.all_inclusive_rounded;
    case AccountingSaleType.service:
      return Icons.spa_rounded;
  }
}

Color _typeColor(AccountingSaleType type) {
  switch (type) {
    case AccountingSaleType.product:
      return const Color(0xFF2563EB);
    case AccountingSaleType.mixed:
      return const Color(0xFF7C3AED);
    case AccountingSaleType.service:
      return const Color(0xFF10B981);
  }
}

String _statusLabel(AccountingPaymentStatus status) {
  switch (status) {
    case AccountingPaymentStatus.paid:
    case AccountingPaymentStatus.collected:
      return 'Tahsil edildi';
    case AccountingPaymentStatus.partial:
      return 'Kısmi';
    case AccountingPaymentStatus.openAccount:
      return 'Açık hesap';
    case AccountingPaymentStatus.installment:
      return 'Taksitli';
    case AccountingPaymentStatus.free:
      return 'Ücretsiz';
    case AccountingPaymentStatus.overdue:
      return 'Gecikmiş';
    case AccountingPaymentStatus.refunded:
      return 'İade';
    case AccountingPaymentStatus.cancelled:
      return 'İptal';
    case AccountingPaymentStatus.unpaid:
      return 'Bekliyor';
  }
}
