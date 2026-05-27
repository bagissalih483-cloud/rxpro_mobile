import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/accounting/presentation/models/accounting_sales_models.dart';

class AccountingSaleTypeStep extends StatelessWidget {
  const AccountingSaleTypeStep({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ChoicePill(
          selected: selected == 'service',
          label: 'Hizmet',
          onTap: () => onSelected('service'),
        ),
        _ChoicePill(
          selected: selected == 'product',
          label: '\u00dcr\u00fcn',
          onTap: () => onSelected('product'),
        ),
        _ChoicePill(
          selected: selected == 'mixed',
          label: 'Karma',
          onTap: () => onSelected('mixed'),
        ),
      ],
    );
  }
}

class AccountingCustomerStep extends StatelessWidget {
  const AccountingCustomerStep({
    super.key,
    required this.customerType,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.onSelectType,
    required this.onLookup,
    required this.onContinue,
  });

  final String customerType;
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final ValueChanged<String> onSelectType;
  final VoidCallback onLookup;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ChoicePill(
              selected: customerType == 'walkIn',
              label: 'Misafir / randevusuz',
              onTap: () => onSelectType('walkIn'),
            ),
            _ChoicePill(
              selected: customerType == 'registered',
              label: 'Kay\u0131tl\u0131 bireysel',
              onTap: () => onSelectType('registered'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: customerPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Telefon',
            helperText: customerType == 'registered'
                ? 'Telefon numarasıyla kayıtlı bireysel müşteri eşleştirilecek.'
                : 'Misafir m\u00fc\u015fteri i\u00e7in iste\u011fe ba\u011fl\u0131.',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: onLookup,
              icon: const Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: customerNameController,
          decoration: const InputDecoration(
            labelText: 'M\u00fc\u015fteri ad\u0131',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: onContinue,
            child: const Text('Devam'),
          ),
        ),
      ],
    );
  }
}

class AccountingCatalogStep extends StatelessWidget {
  const AccountingCatalogStep({
    super.key,
    required this.options,
    required this.selected,
    required this.manualItemController,
    required this.onSelected,
    required this.onContinue,
  });

  final List<AccountingCatalogOption> options;
  final String selected;
  final TextEditingController manualItemController;
  final ValueChanged<String> onSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CatalogTile(
              option: option,
              selected: selected == option.id,
              onTap: () => onSelected(option.id),
            ),
          ),
        if (selected == 'manual') ...[
          const SizedBox(height: 6),
          TextField(
            controller: manualItemController,
            decoration: const InputDecoration(
              labelText: 'Manuel kalem ad\u0131',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onContinue,
              child: const Text('Devam'),
            ),
          ),
        ],
      ],
    );
  }
}

class AccountingPricingStep extends StatelessWidget {
  const AccountingPricingStep({
    super.key,
    required this.amountController,
    required this.selectedCatalogItem,
    required this.onContinue,
  });

  final TextEditingController amountController;
  final String selectedCatalogItem;
  final VoidCallback onContinue;

  bool get _manual => selectedCatalogItem == 'manual';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: amountController,
          enabled: _manual,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _manual
                ? 'Sat\u0131\u015f tutar\u0131'
                : 'Sabit sat\u0131\u015f tutar\u0131',
            suffixText: 'TL',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _manual
              ? 'Manuel kalem i\u00e7in tutar girilebilir.'
              : 'Se\u00e7ilen kalemin sabit tutar\u0131 kullan\u0131l\u0131r.',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: onContinue,
            child: const Text('Devam'),
          ),
        ),
      ],
    );
  }
}

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
              selected: paymentStatus == 'unpaid',
              label: 'Bekliyor',
              onTap: () => onStatusSelected('unpaid'),
            ),
            _ChoicePill(
              selected: paymentStatus == 'partial',
              label: 'K\u0131smi',
              onTap: () => onStatusSelected('partial'),
            ),
            _ChoicePill(
              selected: paymentStatus == 'collected',
              label: 'Tahsil edildi',
              onTap: () => onStatusSelected('collected'),
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

class AccountingWizardStepCard extends StatelessWidget {
  const AccountingWizardStepCard({
    super.key,
    required this.index,
    required this.currentStep,
    required this.data,
    required this.onTap,
  });

  final int index;
  final int currentStep;
  final AccountingWizardStep data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = index == currentStep;
    final done = index < currentStep;

    return Card(
      elevation: 0,
      color: active ? Colors.white : const Color(0xFFF8FAFC),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: active || done
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE2E8F0),
                    child: Icon(
                      done
                          ? Icons.check_rounded
                          : active
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: active || done
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      data.subtitle,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (active) ...[const SizedBox(height: 14), data.child],
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AccountingCatalogOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor: const Color(0xFFEFFBF4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
        ),
      ),
      title: Text(
        option.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: option.amountLabel.isEmpty ? null : Text(option.amountLabel),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
          : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class AccountingSalesHeaderCard extends StatelessWidget {
  const AccountingSalesHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.add_business_rounded,
              color: Color(0xFF10B981),
              size: 34,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Se\u00e7im yapt\u0131k\u00e7a form otomatik ilerler. Telefon e\u015fle\u015ftirme, katalog ve kay\u0131t i\u015flemleri veri katman\u0131ndan sonra aktif edilecek.',
                style: TextStyle(
                  color: Color(0xFF475569),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: selected ? Colors.white : const Color(0xFF334155),
      ),
      selectedColor: const Color(0xFF10B981),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class AccountingPreviewRow extends StatelessWidget {
  const AccountingPreviewRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
