import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/accounting/data/accounting_repository.dart';
import 'package:rxpro_mobile/features/accounting/models/accounting_models.dart';
part 'accounting_sale_processing_logic_part.dart';
part 'accounting_sale_processing_view_part.dart';
part 'accounting_sale_processing_primitives_part.dart';

class AccountingSaleProcessingSheet extends StatefulWidget {
  const AccountingSaleProcessingSheet({
    super.key,
    required this.sale,
    required this.repository,
  });

  final AccountingSale sale;
  final AccountingRepository repository;

  @override
  State<AccountingSaleProcessingSheet> createState() =>
      _AccountingSaleProcessingSheetState();
}

class _AccountingSaleProcessingSheetState
    extends State<AccountingSaleProcessingSheet> {
  final _paidAmountController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _noteController = TextEditingController();
  final ValueNotifier<int> _processingRevision = ValueNotifier<int>(0);
  AccountingPaymentStatus _status = AccountingPaymentStatus.paid;
  AccountingPaymentMethod _method = AccountingPaymentMethod.cash;
  int _installmentCount = 3;
  String _installmentPeriod = 'monthly';
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _paidAmountController.text = (widget.sale.totalAmountKurus / 100)
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  @override
  void dispose() {
    _processingRevision.dispose();
    _paidAmountController.dispose();
    _dueDateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _notifyProcessingChanged() {
    _processingRevision.value++;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _processingRevision,
      builder: (context, _, __) => _buildProcessingContent(context),
    );
  }
}
