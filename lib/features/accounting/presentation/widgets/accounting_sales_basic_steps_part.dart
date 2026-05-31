part of 'accounting_sales_widgets.dart';

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
