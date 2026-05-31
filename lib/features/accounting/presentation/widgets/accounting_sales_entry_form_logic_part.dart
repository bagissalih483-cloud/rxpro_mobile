part of 'accounting_sales_entry_form.dart';

extension _AccountingSalesEntryFormLogic on _AccountingSalesEntryFormState {
  void _goToStep(int index) {
    _controller.goToStep(index);
  }

  void _next() => _controller.next();

  void _selectSaleType(String value) {
    final selectedCatalogItem = _controller.selectSaleType(value);
    _manualItemController.text = _catalogLabel(selectedCatalogItem);
    _amountController.text = _catalogAmount(selectedCatalogItem);
  }

  void _selectCustomerType(String value) {
    _controller.selectCustomerType(value);
  }

  void _selectCatalogItem(String value) {
    _controller.selectCatalogItem(value);
    if (value != 'manual') {
      _manualItemController.text = _catalogLabel(value);
      _amountController.text = _catalogAmount(value);
    } else {
      _manualItemController.clear();
      _amountController.text = '0';
    }
  }

  void _selectPaymentStatus(String value) {
    _controller.selectPaymentStatus(value);
    if (value == 'paid') {
      _paidAmountController.text = _amountController.text.trim();
    } else if (value == 'openAccount' ||
        value == 'installment' ||
        value == 'free') {
      _paidAmountController.text = '0';
    }
  }

  void _mockPhoneLookup() {
    final phone = _customerPhoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Telefon numarası girilmeden sorgulama yapılamaz.');
      return;
    }

    _showSnack(
      'Telefon eşleştirme hazır olduğunda müşteri adı otomatik doldurulacak.',
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    final day = picked.day.toString().padLeft(2, '0');
    final month = picked.month.toString().padLeft(2, '0');
    controller.text = '$day.$month.${picked.year}';
  }

  String _catalogLabel(String id) {
    switch (id) {
      case 'service_1':
        return 'Standart hizmet';
      case 'service_2':
        return 'Paket / seans hizmeti';
      case 'product_1':
        return 'Perakende ürün';
      case 'product_2':
        return 'Bakım ürünü';
      case 'mixed_1':
        return 'Hizmet + ürün';
      case 'mixed_2':
        return 'Paket + ürün';
      default:
        return 'Manuel kalem';
    }
  }

  String _catalogAmount(String id) {
    switch (id) {
      case 'service_1':
        return '1000';
      case 'service_2':
        return '4500';
      case 'product_1':
        return '750';
      case 'product_2':
        return '1250';
      case 'mixed_1':
        return '1750';
      case 'mixed_2':
        return '5250';
      default:
        return '0';
    }
  }

  int _parseKurus(TextEditingController controller) {
    final raw = controller.text.trim().replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null) return 0;
    return (value * 100).round();
  }

  String _formatTlFromKurus(int kurus) {
    final value = (kurus / 100.0).toStringAsFixed(2).replaceAll('.', ',');
    return '$value TL';
  }

  int get _amountKurus => _parseKurus(_amountController);
  int get _paidKurus => _parseKurus(_paidAmountController);

  int get _remainingKurus {
    if (_controller.finalizeAtCollectedAmount && !_controller.hasDueDate) {
      return 0;
    }
    final remaining = _amountKurus - _paidKurus;
    return remaining > 0 ? remaining : 0;
  }

  String get _saleTypeLabel {
    switch (_controller.saleType) {
      case 'product':
        return 'Ürün';
      case 'mixed':
        return 'Karma';
      default:
        return 'Hizmet';
    }
  }

  String get _paymentStatusLabel {
    switch (_controller.paymentStatus) {
      case 'partial':
        return 'Kısmi ödendi';
      case 'paid':
        return 'Ödendi';
      case 'openAccount':
        return 'Açık hesap';
      case 'installment':
        return 'Taksitli';
      case 'free':
        return 'Ücretsiz';
      default:
        return 'Bekliyor';
    }
  }

  String get _installmentPeriodLabel {
    switch (_controller.installmentPeriod) {
      case 'weekly':
        return 'Haftalık';
      case 'custom':
        return 'Özel not';
      default:
        return 'Aylık';
    }
  }

  List<AccountingCatalogOption> get _catalogOptions {
    if (_controller.saleType == 'product') {
      return const [
        AccountingCatalogOption('product_1', 'Perakende ürün', '750 TL'),
        AccountingCatalogOption('product_2', 'Bakım ürünü', '1250 TL'),
        AccountingCatalogOption('manual', 'Manuel ürün gir', ''),
      ];
    }

    if (_controller.saleType == 'mixed') {
      return const [
        AccountingCatalogOption('mixed_1', 'Hizmet + ürün', '1750 TL'),
        AccountingCatalogOption('mixed_2', 'Paket + ürün', '5250 TL'),
        AccountingCatalogOption('manual', 'Manuel karma kalem gir', ''),
      ];
    }

    return const [
      AccountingCatalogOption('service_1', 'Standart hizmet', '1000 TL'),
      AccountingCatalogOption('service_2', 'Paket / seans hizmeti', '4500 TL'),
      AccountingCatalogOption('manual', 'Manuel hizmet gir', ''),
    ];
  }

}
