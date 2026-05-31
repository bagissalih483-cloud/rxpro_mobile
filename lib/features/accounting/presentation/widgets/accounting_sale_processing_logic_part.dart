part of 'accounting_sale_processing_sheet.dart';

extension _AccountingSaleProcessingLogic on _AccountingSaleProcessingSheetState {
  int get _paidKurus {
    final raw = _paidAmountController.text
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null) return 0;
    return (value * 100).round().clamp(0, widget.sale.totalAmountKurus).toInt();
  }

  int get _effectivePaidKurus {
    if (_status == AccountingPaymentStatus.paid) {
      return widget.sale.totalAmountKurus;
    }
    if (_status == AccountingPaymentStatus.free ||
        _status == AccountingPaymentStatus.openAccount ||
        _status == AccountingPaymentStatus.installment) {
      return _paidKurus;
    }
    return _paidKurus;
  }

  int get _remainingKurus {
    if (_status == AccountingPaymentStatus.paid ||
        _status == AccountingPaymentStatus.free) {
      return 0;
    }
    final remaining = widget.sale.totalAmountKurus - _effectivePaidKurus;
    return remaining > 0 ? remaining : 0;
  }

  bool get _needsDueDate {
    return _status == AccountingPaymentStatus.openAccount ||
        _status == AccountingPaymentStatus.installment;
  }

  void _selectStatus(AccountingPaymentStatus status) {
    _status = status;
    if (status == AccountingPaymentStatus.paid) {
      _paidAmountController.text = (widget.sale.totalAmountKurus / 100)
          .toStringAsFixed(2)
          .replaceAll('.', ',');
    } else if (status == AccountingPaymentStatus.openAccount ||
        status == AccountingPaymentStatus.installment ||
        status == AccountingPaymentStatus.free) {
      _paidAmountController.text = '0';
    }
    _notifyProcessingChanged();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    _dueDate = picked;
    _dueDateController.text = _dateLabel(picked);
    _notifyProcessingChanged();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_status == AccountingPaymentStatus.partial && _paidKurus <= 0) {
      _showMessage('Kısmi ödeme için alınan tutarı girin.');
      return;
    }
    if (_status == AccountingPaymentStatus.partial &&
        _paidKurus >= widget.sale.totalAmountKurus) {
      _showMessage('Tam ödeme için "Ödendi" sonucunu seçin.');
      return;
    }
    if (_needsDueDate && _dueDate == null) {
      _showMessage('Açık hesap veya taksit için vade tarihi seçin.');
      return;
    }
    if ((_status == AccountingPaymentStatus.openAccount ||
            _status == AccountingPaymentStatus.installment) &&
        _remainingKurus <= 0) {
      _showMessage('Açık hesap veya taksit için kalan tutar olmalıdır.');
      return;
    }
    if (_status == AccountingPaymentStatus.installment &&
        _installmentCount <= 1) {
      _showMessage('Taksitli satış için en az 2 taksit seçin.');
      return;
    }

    _saving = true;
    _notifyProcessingChanged();
    try {
      await widget.repository.processSale(
        AccountingSaleProcessingInput(
          sale: widget.sale,
          paymentStatus: _status,
          paymentMethod: _status == AccountingPaymentStatus.free
              ? AccountingPaymentMethod.unknown
              : _method,
          paidAmountKurus: _effectivePaidKurus,
          dueDate: _dueDate,
          installmentCount: _status == AccountingPaymentStatus.installment
              ? _installmentCount
              : 0,
          installmentPeriod: _installmentPeriod,
          note: _noteController.text,
        ),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Adisyon işlendi. Tahsilat ve alacak kayıtları güncellendi.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Adisyon işlenemedi: $error');
    } finally {
      if (mounted) {
        _saving = false;
        _notifyProcessingChanged();
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

}
