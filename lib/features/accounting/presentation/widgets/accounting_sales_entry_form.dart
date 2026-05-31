import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/responsive/rx_adaptive_modal.dart';
import 'package:rxpro_mobile/features/accounting/data/accounting_validators.dart';
import 'package:rxpro_mobile/features/accounting/presentation/accounting_sales_entry_controller.dart';
import 'package:rxpro_mobile/features/accounting/presentation/models/accounting_sales_models.dart';
import 'package:rxpro_mobile/features/accounting/presentation/widgets/accounting_sales_widgets.dart';
part 'accounting_sales_entry_form_logic_part.dart';
part 'accounting_sales_entry_form_actions_part.dart';
part 'accounting_sales_entry_form_view_part.dart';

class AccountingSalesEntryForm extends StatefulWidget {
  const AccountingSalesEntryForm({super.key});

  @override
  State<AccountingSalesEntryForm> createState() =>
      _AccountingSalesEntryFormState();
}

class _AccountingSalesEntryFormState extends State<AccountingSalesEntryForm> {
  final AccountingSalesEntryController _controller =
      AccountingSalesEntryController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _manualItemController = TextEditingController();
  final _amountController = TextEditingController(text: '1000');
  final _paidAmountController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _manualItemController.text = _catalogLabel(_controller.selectedCatalogItem);
    _amountController.text = _catalogAmount(_controller.selectedCatalogItem);
  }

  @override
  void dispose() {
    _controller.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _manualItemController.dispose();
    _amountController.dispose();
    _paidAmountController.dispose();
    _dueDateController.dispose();
    _noteController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) => _buildEntryFormContent(context);
}
