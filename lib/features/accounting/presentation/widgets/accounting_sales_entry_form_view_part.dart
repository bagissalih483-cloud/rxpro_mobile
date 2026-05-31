part of 'accounting_sales_entry_form.dart';

extension _AccountingSalesEntryFormView on _AccountingSalesEntryFormState {
  Widget _buildEntryFormContent(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final steps = [
          AccountingWizardStep(
            title: 'Satış tipi',
            subtitle: _saleTypeLabel,
            child: AccountingSaleTypeStep(
              selected: _controller.saleType,
              onSelected: _selectSaleType,
            ),
          ),
          AccountingWizardStep(
            title: 'Müşteri',
            subtitle: _controller.customerType == 'registered'
                ? 'Kayıtlı bireysel'
                : 'Misafir / randevusuz',
            child: AccountingCustomerStep(
              customerType: _controller.customerType,
              customerNameController: _customerNameController,
              customerPhoneController: _customerPhoneController,
              onSelectType: _selectCustomerType,
              onLookup: _mockPhoneLookup,
              onContinue: _next,
            ),
          ),
          AccountingWizardStep(
            title: 'Kalem',
            subtitle: _catalogLabel(_controller.selectedCatalogItem),
            child: AccountingCatalogStep(
              options: _catalogOptions,
              selected: _controller.selectedCatalogItem,
              manualItemController: _manualItemController,
              onSelected: _selectCatalogItem,
              onContinue: _next,
            ),
          ),
          AccountingWizardStep(
            title: 'Tutar',
            subtitle: _formatTlFromKurus(_amountKurus),
            child: AccountingPricingStep(
              amountController: _amountController,
              selectedCatalogItem: _controller.selectedCatalogItem,
              onContinue: _next,
            ),
          ),
          AccountingWizardStep(
            title: 'Ödeme',
            subtitle: _paymentStatusLabel,
            child: AccountingPaymentStep(
              paymentStatus: _controller.paymentStatus,
              paymentMethod: _controller.paymentMethod,
              paidAmountController: _paidAmountController,
              dueDateController: _dueDateController,
              noteController: _noteController,
              hasDueDate: _controller.hasDueDate,
              isInstallment: _controller.isInstallment,
              installmentCount: _controller.installmentCount,
              installmentPeriod: _controller.installmentPeriod,
              finalizeAtCollectedAmount: _controller.finalizeAtCollectedAmount,
              onStatusSelected: _selectPaymentStatus,
              onMethodSelected: _controller.selectPaymentMethod,
              onDueDateChanged: _controller.setHasDueDate,
              onPickDueDate: () => _pickDate(_dueDateController),
              onInstallmentChanged: _controller.setInstallment,
              onInstallmentCountChanged: (value) {
                if (value != null) _controller.setInstallmentCount(value);
              },
              onInstallmentPeriodChanged: (value) {
                if (value != null) _controller.setInstallmentPeriod(value);
              },
              onFinalizeChanged: _controller.setFinalizeAtCollectedAmount,
              onPreview: _showPreview,
              onValidateDraft: _validateDraft,
            ),
          ),
        ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AccountingSalesHeaderCard(),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++) ...[
              AccountingWizardStepCard(
                index: i,
                currentStep: _controller.step,
                data: steps[i],
                onTap: () => _goToStep(i),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}
