part of 'accounting_sales_widgets.dart';

class AccountingPaymentStep extends StatelessWidget {
  const AccountingPaymentStep({
    super.key,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paidAmountController,
    required this.dueDateController,
    required this.noteController,
    required this.hasDueDate,
    required this.isInstallment,
    required this.installmentCount,
    required this.installmentPeriod,
    required this.finalizeAtCollectedAmount,
    required this.onStatusSelected,
    required this.onMethodSelected,
    required this.onDueDateChanged,
    required this.onPickDueDate,
    required this.onInstallmentChanged,
    required this.onInstallmentCountChanged,
    required this.onInstallmentPeriodChanged,
    required this.onFinalizeChanged,
    required this.onPreview,
    required this.onValidateDraft,
  });

  final String paymentStatus;
  final String paymentMethod;
  final TextEditingController paidAmountController;
  final TextEditingController dueDateController;
  final TextEditingController noteController;
  final bool hasDueDate;
  final bool isInstallment;
  final String installmentCount;
  final String installmentPeriod;
  final bool finalizeAtCollectedAmount;
  final ValueChanged<String> onStatusSelected;
  final ValueChanged<String> onMethodSelected;
  final ValueChanged<bool> onDueDateChanged;
  final VoidCallback onPickDueDate;
  final ValueChanged<bool> onInstallmentChanged;
  final ValueChanged<String?> onInstallmentCountChanged;
  final ValueChanged<String?> onInstallmentPeriodChanged;
  final ValueChanged<bool> onFinalizeChanged;
  final VoidCallback onPreview;
  final VoidCallback onValidateDraft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ChoicePill(
              selected: paymentStatus == 'openAccount',
              label: 'Açık hesap',
              onTap: () => onStatusSelected('openAccount'),
            ),
            _ChoicePill(
              selected: paymentStatus == 'partial',
              label: 'K\u0131smi',
              onTap: () => onStatusSelected('partial'),
            ),
            _ChoicePill(
              selected: paymentStatus == 'paid',
              label: 'Ödendi',
              onTap: () => onStatusSelected('paid'),
            ),
            _ChoicePill(
              selected: paymentStatus == 'installment',
              label: 'Taksitli',
              onTap: () => onStatusSelected('installment'),
            ),
            _ChoicePill(
              selected: paymentStatus == 'free',
              label: 'Ücretsiz',
              onTap: () => onStatusSelected('free'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: paidAmountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '\u00d6denen tutar',
            suffixText: 'TL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ChoicePill(
              selected: paymentMethod == 'cash',
              label: 'Nakit',
              onTap: () => onMethodSelected('cash'),
            ),
            _ChoicePill(
              selected: paymentMethod == 'bank',
              label: 'Havale',
              onTap: () => onMethodSelected('bank'),
            ),
            _ChoicePill(
              selected: paymentMethod == 'card',
              label: 'Kart',
              onTap: () => onMethodSelected('card'),
            ),
            _ChoicePill(
              selected: paymentMethod == 'nfc',
              label: 'NFC',
              onTap: () => onMethodSelected('nfc'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: hasDueDate,
          title: const Text('Kalan tutar i\u00e7in vade gir'),
          onChanged: onDueDateChanged,
        ),
        if (hasDueDate)
          TextField(
            controller: dueDateController,
            readOnly: true,
            onTap: onPickDueDate,
            decoration: InputDecoration(
              labelText: 'Vade tarihi',
              hintText: 'Takvimden se\u00e7',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: onPickDueDate,
                icon: const Icon(Icons.calendar_month_rounded),
              ),
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: isInstallment,
          title: const Text('Taksitli sat\u0131\u015f'),
          subtitle: const Text(
            'Kalan tutar taksitlere b\u00f6l\u00fcnecekse i\u015faretle.',
          ),
          onChanged: onInstallmentChanged,
        ),
        if (isInstallment) ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: installmentCount,
                  decoration: const InputDecoration(
                    labelText: 'Taksit say\u0131s\u0131',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '2', child: Text('2 taksit')),
                    DropdownMenuItem(value: '3', child: Text('3 taksit')),
                    DropdownMenuItem(value: '4', child: Text('4 taksit')),
                    DropdownMenuItem(value: '6', child: Text('6 taksit')),
                    DropdownMenuItem(value: '12', child: Text('12 taksit')),
                  ],
                  onChanged: onInstallmentCountChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: installmentPeriod,
                  decoration: const InputDecoration(
                    labelText: '\u00d6deme periyodu',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text('Haftal\u0131k'),
                    ),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text('Ayl\u0131k'),
                    ),
                    DropdownMenuItem(
                      value: 'custom',
                      child: Text('\u00d6zel not'),
                    ),
                  ],
                  onChanged: onInstallmentPeriodChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Taksit planı satış kaydıyla birlikte alacak takibine bağlanacak.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: finalizeAtCollectedAmount,
          title: const Text('Vadeli de\u011fil; al\u0131nan tutardan kapat'),
          subtitle: const Text(
            'Eksik \u00f6deme alacak say\u0131lmayacaksa bu se\u00e7enek kullan\u0131l\u0131r.',
          ),
          onChanged: onFinalizeChanged,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: noteController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'A\u00e7\u0131klama',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onPreview,
          icon: const Icon(Icons.visibility_rounded),
          label: const Text('\u00d6n izleme'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onValidateDraft,
          icon: const Icon(Icons.fact_check_rounded),
          label: const Text('Kayda uygunlu\u011fu kontrol et'),
        ),
      ],
    );
  }
}
