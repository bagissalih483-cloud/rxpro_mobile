import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/responsive/rx_adaptive_modal.dart';
import 'package:rxpro_mobile/core/session/app_session_scope.dart';

import '../data/accounting_repository.dart';
import '../data/callable_accounting_repository.dart';
import '../models/accounting_models.dart';
import '../presentation/accounting_receivables_controller.dart';

part 'accounting_receivables_filters_part.dart';
part 'accounting_receivables_card_part.dart';
part 'accounting_receivables_empty_part.dart';
part 'accounting_receivables_model_part.dart';

class AccountingReceivablesPage extends StatefulWidget {
  AccountingReceivablesPage({
    super.key,
    required this.from,
    required this.to,
    AccountingRepository? repository,
  }) : _repository = repository ?? CallableAccountingRepository();

  final DateTime from;
  final DateTime to;
  final AccountingRepository _repository;

  @override
  State<AccountingReceivablesPage> createState() =>
      _AccountingReceivablesPageState();
}

class _AccountingReceivablesPageState extends State<AccountingReceivablesPage>
    with AutomaticKeepAliveClientMixin {
  final AccountingReceivablesController _controller =
      AccountingReceivablesController();
  String? _salesStreamKey;
  Stream<List<AccountingSale>>? _salesStream;
  String? _installmentsStreamKey;
  Stream<List<AccountingInstallment>>? _installmentsStream;
  var _collecting = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_ReceivableItem> _visibleItems(List<_ReceivableItem> items) {
    if (_controller.filter == 'all') return items;
    return items
        .where((item) => item.status == _controller.filter)
        .toList();
  }

  Future<void> _showCollectionSheet(_ReceivableItem item) async {
    final amountController = TextEditingController(
      text: (item.remainingKurus / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    var method = AccountingPaymentMethod.cash;

    await showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 560,
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              if (_collecting) return;
              final amount = _parseMoneyKurus(amountController.text);
              if (amount <= 0 || amount > item.remainingKurus) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tahsilat tutarı kalan bakiyeden büyük olamaz.',
                    ),
                  ),
                );
                return;
              }

              setSheetState(() => _collecting = true);
              try {
                final installmentId = item.installmentId;
                if (installmentId == null) {
                  await widget._repository.collectPayment(
                    AccountingPayment(
                      paymentId: '',
                      saleId: item.saleId,
                      businessId: item.businessId,
                      customerId: item.customerId,
                      amountKurus: amount,
                      method: method,
                      collectedAt: DateTime.now(),
                      source: 'receivable_collection',
                    ),
                  );
                } else {
                  await widget._repository.collectInstallmentPayment(
                    AccountingInstallmentPaymentInput(
                      businessId: item.businessId,
                      saleId: item.saleId,
                      installmentId: installmentId,
                      amountKurus: amount,
                      method: method,
                    ),
                  );
                }
                if (!mounted || !context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                setSheetState(() => _collecting = false);
                Navigator.of(context).pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Tahsilat kaydedildi.')),
                );
              } catch (error) {
                if (!mounted || !context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tahsilat kaydedilemedi: $error')),
                );
              } finally {
                if (mounted && context.mounted) {
                  setSheetState(() => _collecting = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, bottomInset + 24),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Tahsilat al',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Müşteri', value: item.customerName),
                  _InfoRow(label: 'Kalem', value: item.itemName),
                  _InfoRow(label: 'Toplam', value: item.totalLabel),
                  _InfoRow(label: 'Ödenen', value: item.paidLabel),
                  _InfoRow(label: 'Kalan', value: item.remainingLabel),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tahsil edilen tutar',
                      suffixText: 'TL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<AccountingPaymentMethod>(
                    initialValue: method,
                    decoration: const InputDecoration(
                      labelText: 'Ödeme yöntemi',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AccountingPaymentMethod.cash,
                        child: Text('Nakit'),
                      ),
                      DropdownMenuItem(
                        value: AccountingPaymentMethod.card,
                        child: Text('Kart'),
                      ),
                      DropdownMenuItem(
                        value: AccountingPaymentMethod.bank,
                        child: Text('Havale'),
                      ),
                      DropdownMenuItem(
                        value: AccountingPaymentMethod.nfc,
                        child: Text('NFC'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheetState(() => method = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _collecting ? null : submit,
                    icon: _collecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payments_rounded),
                    label: const Text('Tahsilatı kaydet'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _collecting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Vazgeç'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
  }

  void _showReminderPreview(_ReceivableItem item) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hat\u0131rlatma tasla\u011f\u0131'),
          content: Text(
            '${item.customerName} i\u00e7in ${item.remainingLabel} kalan alacak hat\u0131rlatmas\u0131 olu\u015fturulacak. Bildirim altyap\u0131s\u0131 46H a\u015famas\u0131nda ba\u011flanacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final session = AppSessionScope.maybeOf(context);
    final businessId = session?.businessId ?? '';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return StreamBuilder<List<AccountingSale>>(
          stream: _watchSalesFor(businessId),
          builder: (context, snapshot) {
            return StreamBuilder<List<AccountingInstallment>>(
              stream: _watchInstallmentsFor(businessId),
              builder: (context, installmentSnapshot) {
                final sales = snapshot.data ?? const <AccountingSale>[];
                final installmentItems =
                    (installmentSnapshot.data ??
                            const <AccountingInstallment>[])
                        .map(_ReceivableItem.fromInstallment)
                        .toList();
                final saleItems = sales
                    .where(
                      (sale) =>
                          sale.remainingAmountKurus > 0 &&
                          sale.paymentStatus !=
                              AccountingPaymentStatus.installment,
                    )
                    .map(_ReceivableItem.fromSale)
                    .toList();
                final allItems = [...saleItems, ...installmentItems];
                final items = _visibleItems(allItems);
                final canCollect =
                    session?.hasPermission('adisyon.collectPayment') == true ||
                    session?.hasPermission('paymentCollect') == true ||
                    session?.hasPermission('financeWrite') == true;

                return ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    _FilterChips(
                      filter: _controller.filter,
                      onChanged: _controller.setFilter,
                    ),
                    const SizedBox(height: 10),
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        installmentSnapshot.connectionState ==
                            ConnectionState.waiting)
                      const LinearProgressIndicator(minHeight: 3),
                    if (items.isEmpty)
                      const _EmptyReceivables()
                    else
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ReceivableCard(
                            item: item,
                            onCollect: canCollect
                                ? () => _showCollectionSheet(item)
                                : null,
                            onReminder: () => _showReminderPreview(item),
                          ),
                        ),
                  ],
                );
              },
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

  Stream<List<AccountingInstallment>> _watchInstallmentsFor(String businessId) {
    final key = [
      businessId,
      widget.from.millisecondsSinceEpoch,
      widget.to.millisecondsSinceEpoch,
    ].join('|');

    if (_installmentsStreamKey != key || _installmentsStream == null) {
      _installmentsStreamKey = key;
      _installmentsStream = widget._repository.watchInstallments(
        businessId: businessId,
        from: widget.from,
        to: widget.to,
      );
    }

    return _installmentsStream!;
  }
}
