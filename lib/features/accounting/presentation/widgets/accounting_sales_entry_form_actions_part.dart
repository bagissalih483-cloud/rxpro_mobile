part of 'accounting_sales_entry_form.dart';

extension _AccountingSalesEntryFormActions on _AccountingSalesEntryFormState {
void _showPreview() {
    final customer = _customerNameController.text.trim().isEmpty
        ? (_controller.customerType == 'registered'
              ? 'Telefonla eşleştirilecek kayıtlı müşteri'
              : 'Misafir müşteri')
        : _customerNameController.text.trim();

    final item = _manualItemController.text.trim().isEmpty
        ? _catalogLabel(_controller.selectedCatalogItem)
        : _manualItemController.text.trim();

    showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 560,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Satış ön izlemesi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              AccountingPreviewRow(label: 'Kaynak', value: _saleTypeLabel),
              AccountingPreviewRow(label: 'Müşteri', value: customer),
              AccountingPreviewRow(label: 'Kalem', value: item),
              AccountingPreviewRow(
                label: 'Satış tutarı',
                value: _formatTlFromKurus(_amountKurus),
              ),
              AccountingPreviewRow(
                label: 'Ödenen',
                value: _formatTlFromKurus(_paidKurus),
              ),
              AccountingPreviewRow(
                label: 'Kalan',
                value: _formatTlFromKurus(_remainingKurus),
              ),
              AccountingPreviewRow(label: 'Durum', value: _paymentStatusLabel),
              if (_controller.hasDueDate)
                AccountingPreviewRow(
                  label: 'Vade',
                  value: _dueDateController.text.trim().isEmpty
                      ? 'Girilecek'
                      : _dueDateController.text.trim(),
                ),
              if (_controller.isInstallment)
                AccountingPreviewRow(
                  label: 'Taksit',
                  value:
                      '${_controller.installmentCount} taksit / $_installmentPeriodLabel',
                ),
              const SizedBox(height: 12),
              const Text(
                'Bu ön izleme kayda gönderilmeden önce işletmecinin kontrol etmesi için hazırlanır.',
                style: TextStyle(color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        );
      },
    );
  }

  void _validateDraft() {
    final item = _manualItemController.text.trim().isEmpty
        ? _catalogLabel(_controller.selectedCatalogItem)
        : _manualItemController.text.trim();

    final result = AccountingDraftValidator.validateManualSale(
      saleType: _controller.saleType,
      customerType: _controller.customerType == 'registered'
          ? 'registered'
          : 'manual',
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      itemName: item,
      totalKurus: _amountKurus,
      paidKurus: _paidKurus,
      hasDueDate: _controller.hasDueDate,
      isInstallment: _controller.isInstallment,
      closeAtCollectedAmount: _controller.finalizeAtCollectedAmount,
    );

    if (!result.ok) {
      _showSnack(result.message ?? 'Satış taslağı eksik.');
      return;
    }

    _showSnack(
      'Satış taslağı kayda hazır. Kayıt bağlantısı hazır olduğunda doğrudan gönderilecek.',
    );
  }
}
