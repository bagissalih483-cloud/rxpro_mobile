part of 'accounting_sale_processing_sheet.dart';

extension _AccountingSaleProcessingView on _AccountingSaleProcessingSheetState {
  Widget _buildProcessingContent(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, bottomInset + 18),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            'Adisyonu işle',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.sale.customerName ?? 'Misafir müşteri'} · ${_money(widget.sale.totalAmountKurus)}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProcessingChoice(
                selected: _status == AccountingPaymentStatus.paid,
                label: 'Ödendi',
                onTap: () => _selectStatus(AccountingPaymentStatus.paid),
              ),
              _ProcessingChoice(
                selected: _status == AccountingPaymentStatus.partial,
                label: 'Kısmi',
                onTap: () => _selectStatus(AccountingPaymentStatus.partial),
              ),
              _ProcessingChoice(
                selected: _status == AccountingPaymentStatus.openAccount,
                label: 'Açık hesap',
                onTap: () => _selectStatus(AccountingPaymentStatus.openAccount),
              ),
              _ProcessingChoice(
                selected: _status == AccountingPaymentStatus.installment,
                label: 'Taksitli',
                onTap: () => _selectStatus(AccountingPaymentStatus.installment),
              ),
              _ProcessingChoice(
                selected: _status == AccountingPaymentStatus.free,
                label: 'Ücretsiz',
                onTap: () => _selectStatus(AccountingPaymentStatus.free),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paidAmountController,
            enabled: _status != AccountingPaymentStatus.paid &&
                _status != AccountingPaymentStatus.free,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Alınan tutar',
              suffixText: 'TL',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _notifyProcessingChanged(),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<AccountingPaymentMethod>(
            initialValue: _method,
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
            onChanged: _status == AccountingPaymentStatus.free
                ? null
                : (value) {
                    if (value != null) {
                      _method = value;
                      _notifyProcessingChanged();
                    }
                  },
          ),
          if (_needsDueDate) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _dueDateController,
              readOnly: true,
              onTap: _pickDueDate,
              decoration: InputDecoration(
                labelText: _status == AccountingPaymentStatus.installment
                    ? 'İlk taksit tarihi'
                    : 'Vade tarihi',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.calendar_month_rounded),
                ),
              ),
            ),
          ],
          if (_status == AccountingPaymentStatus.installment) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _installmentCount,
                    decoration: const InputDecoration(
                      labelText: 'Taksit',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 2, child: Text('2 taksit')),
                      DropdownMenuItem(value: 3, child: Text('3 taksit')),
                      DropdownMenuItem(value: 4, child: Text('4 taksit')),
                      DropdownMenuItem(value: 6, child: Text('6 taksit')),
                      DropdownMenuItem(value: 12, child: Text('12 taksit')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _installmentCount = value;
                        _notifyProcessingChanged();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _installmentPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Periyot',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('Haftalık'),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Aylık'),
                      ),
                      DropdownMenuItem(value: 'custom', child: Text('Özel')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _installmentPeriod = value;
                        _notifyProcessingChanged();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Not',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _ProcessingSummary(
            paid: _effectivePaidKurus,
            remaining: _remainingKurus,
            status: _status,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: const Text('Adisyonu işle'),
          ),
        ],
      ),
    );
  }
}
