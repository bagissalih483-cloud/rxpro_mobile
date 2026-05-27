import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/session/app_session_scope.dart';
import 'package:rxpro_mobile/features/accounting/data/accounting_repository.dart';
import 'package:rxpro_mobile/features/accounting/data/accounting_validators.dart';
import 'package:rxpro_mobile/features/accounting/data/callable_accounting_repository.dart';
import 'package:rxpro_mobile/features/accounting/models/accounting_models.dart';
import 'package:rxpro_mobile/features/accounting/presentation/models/accounting_sales_models.dart';
import 'package:rxpro_mobile/features/accounting/presentation/widgets/accounting_sales_widgets.dart';

class AccountingSalesPage extends StatefulWidget {
  AccountingSalesPage({
    super.key,
    required this.from,
    required this.to,
    AccountingRepository? repository,
  }) : _repository = repository ?? CallableAccountingRepository();

  final DateTime from;
  final DateTime to;
  final AccountingRepository _repository;

  @override
  State<AccountingSalesPage> createState() => _AccountingSalesPageState();
}

class _AccountingSalesPageState extends State<AccountingSalesPage>
    with AutomaticKeepAliveClientMixin {
  String? _salesStreamKey;
  Stream<List<AccountingSale>>? _salesStream;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final session = AppSessionScope.maybeOf(context);
    final businessId = session?.businessId ?? '';

    return StreamBuilder<List<AccountingSale>>(
      stream: _watchSalesFor(businessId),
      builder: (context, snapshot) {
        final sales = snapshot.data ?? const <AccountingSale>[];
        final serviceTotal = _sumByType(sales, AccountingSaleType.service);
        final productTotal = _sumByType(sales, AccountingSaleType.product);
        final mixedTotal = _sumByType(sales, AccountingSaleType.mixed);
        final collected = sales.fold<int>(
          0,
          (total, sale) => total + sale.paidAmountKurus,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
          children: [
            _SalesInsightPanel(
              serviceTotal: serviceTotal,
              productTotal: productTotal,
              mixedTotal: mixedTotal,
              collected: collected,
              count: sales.length,
            ),
            const SizedBox(height: 10),
            _RecentSalesPanel(sales: sales.take(12).toList()),
          ],
        );
      },
    );
  }

  Stream<List<AccountingSale>> _watchSalesFor(String businessId) {
    final key = [
      businessId,
      widget.from.millisecondsSinceEpoch,
      widget.to.millisecondsSinceEpoch,
    ].join('|');

    if (_salesStreamKey != key || _salesStream == null) {
      _salesStreamKey = key;
      _salesStream = widget._repository.watchSales(
        businessId: businessId,
        from: widget.from,
        to: widget.to,
      );
    }

    return _salesStream!;
  }

  int _sumByType(List<AccountingSale> sales, AccountingSaleType type) {
    return sales
        .where((sale) => sale.saleType == type)
        .fold<int>(0, (total, sale) => total + sale.totalAmountKurus);
  }
}

class _SalesInsightPanel extends StatelessWidget {
  const _SalesInsightPanel({
    required this.serviceTotal,
    required this.productTotal,
    required this.mixedTotal,
    required this.collected,
    required this.count,
  });

  final int serviceTotal;
  final int productTotal;
  final int mixedTotal;
  final int collected;
  final int count;

  @override
  Widget build(BuildContext context) {
    return _SalesSurface(
      title: 'Satış özeti',
      trailing: _MiniBadge(label: '$count satış'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 560 ? 4 : 2;
          const spacing = 8.0;
          final width =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          final items = [
            _SalesMetric(
              'Hizmet',
              _money(serviceTotal),
              Icons.spa_rounded,
              const Color(0xFF10B981),
            ),
            _SalesMetric(
              'Ürün',
              _money(productTotal),
              Icons.inventory_2_rounded,
              const Color(0xFF2563EB),
            ),
            _SalesMetric(
              'Karma',
              _money(mixedTotal),
              Icons.all_inclusive_rounded,
              const Color(0xFF7C3AED),
            ),
            _SalesMetric(
              'Tahsilat',
              _money(collected),
              Icons.payments_rounded,
              const Color(0xFFF97316),
            ),
          ];

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final item in items)
                SizedBox(width: width, child: _SalesMetricTile(item: item)),
            ],
          );
        },
      ),
    );
  }
}

class _RecentSalesPanel extends StatelessWidget {
  const _RecentSalesPanel({required this.sales});

  final List<AccountingSale> sales;

  @override
  Widget build(BuildContext context) {
    return _SalesSurface(
      title: 'Son satışlar',
      trailing: _MiniBadge(label: '${sales.length} kayıt'),
      child: sales.isEmpty
          ? const _EmptySalesState()
          : Column(
              children: [
                for (var i = 0; i < sales.length; i++) ...[
                  _SaleRow(sale: sales[i]),
                  if (i != sales.length - 1) const Divider(height: 14),
                ],
              ],
            ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.sale});

  final AccountingSale sale;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(sale.saleType);
    final itemText = sale.items.map((item) => item.name).take(2).join(' + ');
    final customer = sale.customerName?.trim().isNotEmpty == true
        ? sale.customerName!.trim()
        : 'Misafir müşteri';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_typeIcon(sale.saleType), color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemText.isEmpty ? _typeLabel(sale.saleType) : itemText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$customer · ${_dateLabel(sale.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (sale.remainingAmountKurus > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Kalan: ${_money(sale.remainingAmountKurus)}',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _money(sale.totalAmountKurus),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _statusLabel(sale.paymentStatus),
              style: TextStyle(
                color: sale.remainingAmountKurus > 0
                    ? const Color(0xFFF97316)
                    : const Color(0xFF10B981),
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptySalesState extends StatelessWidget {
  const _EmptySalesState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text(
        'Seçili dönemde satış görünmüyor. Yeni satış girişi üstteki hızlı işlemden yapılır; bu alan son satışları ve hizmet/ürün kırılımını takip etmek içindir.',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12.5,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SalesMetricTile extends StatelessWidget {
  const _SalesMetricTile({required this.item});

  final _SalesMetric item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 19),
          const Spacer(),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesSurface extends StatelessWidget {
  const _SalesSurface({
    required this.title,
    required this.trailing,
    required this.child,
  });

  final String title;
  final Widget trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SalesMetric {
  const _SalesMetric(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

String _money(int kurus) {
  final sign = kurus < 0 ? '-' : '';
  final value = (kurus.abs() / 100).toStringAsFixed(2).replaceAll('.', ',');
  return '$sign$value TL';
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String _typeLabel(AccountingSaleType type) {
  switch (type) {
    case AccountingSaleType.product:
      return 'Ürün satışı';
    case AccountingSaleType.mixed:
      return 'Karma satış';
    case AccountingSaleType.service:
      return 'Hizmet satışı';
  }
}

IconData _typeIcon(AccountingSaleType type) {
  switch (type) {
    case AccountingSaleType.product:
      return Icons.inventory_2_rounded;
    case AccountingSaleType.mixed:
      return Icons.all_inclusive_rounded;
    case AccountingSaleType.service:
      return Icons.spa_rounded;
  }
}

Color _typeColor(AccountingSaleType type) {
  switch (type) {
    case AccountingSaleType.product:
      return const Color(0xFF2563EB);
    case AccountingSaleType.mixed:
      return const Color(0xFF7C3AED);
    case AccountingSaleType.service:
      return const Color(0xFF10B981);
  }
}

String _statusLabel(AccountingPaymentStatus status) {
  switch (status) {
    case AccountingPaymentStatus.collected:
      return 'Tahsil edildi';
    case AccountingPaymentStatus.partial:
      return 'Kısmi';
    case AccountingPaymentStatus.overdue:
      return 'Gecikmiş';
    case AccountingPaymentStatus.refunded:
      return 'İade';
    case AccountingPaymentStatus.cancelled:
      return 'İptal';
    case AccountingPaymentStatus.unpaid:
      return 'Bekliyor';
  }
}

class AccountingSalesEntryForm extends StatefulWidget {
  const AccountingSalesEntryForm({super.key});

  @override
  State<AccountingSalesEntryForm> createState() =>
      _AccountingSalesEntryFormState();
}

class _AccountingSalesEntryFormState extends State<AccountingSalesEntryForm> {
  int _step = 0;

  String _saleType = 'service';
  String _customerType = 'walkIn';
  String _selectedCatalogItem = 'service_1';
  String _paymentStatus = 'unpaid';
  String _paymentMethod = 'cash';
  String _installmentCount = '3';
  String _installmentPeriod = 'monthly';

  bool _hasDueDate = false;
  bool _isInstallment = false;
  bool _finalizeAtCollectedAmount = false;

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
    _manualItemController.text = _catalogLabel(_selectedCatalogItem);
    _amountController.text = _catalogAmount(_selectedCatalogItem);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _manualItemController.dispose();
    _amountController.dispose();
    _paidAmountController.dispose();
    _dueDateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _goToStep(int index) {
    setState(() => _step = index.clamp(0, 4));
  }

  void _next() => _goToStep(_step + 1);

  void _selectSaleType(String value) {
    setState(() {
      _saleType = value;
      _selectedCatalogItem = _defaultCatalogForSaleType(value);
      _manualItemController.text = _catalogLabel(_selectedCatalogItem);
      _amountController.text = _catalogAmount(_selectedCatalogItem);
      _step = 1;
    });
  }

  void _selectCustomerType(String value) {
    setState(() {
      _customerType = value;
      _step = 2;
    });
  }

  void _selectCatalogItem(String value) {
    setState(() {
      _selectedCatalogItem = value;
      if (value != 'manual') {
        _manualItemController.text = _catalogLabel(value);
        _amountController.text = _catalogAmount(value);
      } else {
        _manualItemController.clear();
        _amountController.text = '0';
      }
      _step = 3;
    });
  }

  void _selectPaymentStatus(String value) {
    setState(() {
      _paymentStatus = value;
      if (value == 'collected' && _paidAmountController.text.trim().isEmpty) {
        _paidAmountController.text = _amountController.text.trim();
      }
      _step = 4;
    });
  }

  void _mockPhoneLookup() {
    final phone = _customerPhoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Telefon numaras\u0131 girilmeden sorgulama yap\u0131lamaz.');
      return;
    }

    _showSnack(
      'Telefonla müşteri eşleştirme servisi açıldığında ad bilgisi otomatik gelecek.',
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

  String _defaultCatalogForSaleType(String type) {
    switch (type) {
      case 'product':
        return 'product_1';
      case 'mixed':
        return 'mixed_1';
      default:
        return 'service_1';
    }
  }

  String _catalogLabel(String id) {
    switch (id) {
      case 'service_1':
        return 'Standart hizmet';
      case 'service_2':
        return 'Paket / seans hizmeti';
      case 'product_1':
        return 'Perakende \u00fcr\u00fcn';
      case 'product_2':
        return 'Bak\u0131m \u00fcr\u00fcn\u00fc';
      case 'mixed_1':
        return 'Hizmet + \u00fcr\u00fcn';
      case 'mixed_2':
        return 'Paket + \u00fcr\u00fcn';
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
    if (_finalizeAtCollectedAmount && !_hasDueDate) return 0;
    final remaining = _amountKurus - _paidKurus;
    return remaining > 0 ? remaining : 0;
  }

  String get _saleTypeLabel {
    switch (_saleType) {
      case 'product':
        return '\u00dcr\u00fcn';
      case 'mixed':
        return 'Karma';
      default:
        return 'Hizmet';
    }
  }

  String get _paymentStatusLabel {
    switch (_paymentStatus) {
      case 'partial':
        return 'K\u0131smi \u00f6dendi';
      case 'collected':
        return 'Tahsil edildi';
      default:
        return 'Bekliyor';
    }
  }

  String get _installmentPeriodLabel {
    switch (_installmentPeriod) {
      case 'weekly':
        return 'Haftal\u0131k';
      case 'custom':
        return '\u00d6zel not';
      default:
        return 'Ayl\u0131k';
    }
  }

  List<AccountingCatalogOption> get _catalogOptions {
    if (_saleType == 'product') {
      return const [
        AccountingCatalogOption('product_1', 'Perakende \u00fcr\u00fcn', '750 TL'),
        AccountingCatalogOption(
          'product_2',
          'Bak\u0131m \u00fcr\u00fcn\u00fc',
          '1250 TL',
        ),
        AccountingCatalogOption('manual', 'Manuel \u00fcr\u00fcn gir', ''),
      ];
    }

    if (_saleType == 'mixed') {
      return const [
        AccountingCatalogOption('mixed_1', 'Hizmet + \u00fcr\u00fcn', '1750 TL'),
        AccountingCatalogOption('mixed_2', 'Paket + \u00fcr\u00fcn', '5250 TL'),
        AccountingCatalogOption('manual', 'Manuel karma kalem gir', ''),
      ];
    }

    return const [
      AccountingCatalogOption('service_1', 'Standart hizmet', '1000 TL'),
      AccountingCatalogOption('service_2', 'Paket / seans hizmeti', '4500 TL'),
      AccountingCatalogOption('manual', 'Manuel hizmet gir', ''),
    ];
  }

  void _showPreview() {
    final customer = _customerNameController.text.trim().isEmpty
        ? (_customerType == 'registered'
              ? 'Telefonla e\u015fle\u015ftirilecek kay\u0131tl\u0131 m\u00fc\u015fteri'
              : 'Misafir m\u00fc\u015fteri')
        : _customerNameController.text.trim();

    final item = _manualItemController.text.trim().isEmpty
        ? _catalogLabel(_selectedCatalogItem)
        : _manualItemController.text.trim();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Sat\u0131\u015f \u00f6n izlemesi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              AccountingPreviewRow(label: 'Kaynak', value: _saleTypeLabel),
              AccountingPreviewRow(label: 'M\u00fc\u015fteri', value: customer),
              AccountingPreviewRow(label: 'Kalem', value: item),
              AccountingPreviewRow(
                label: 'Sat\u0131\u015f tutar\u0131',
                value: _formatTlFromKurus(_amountKurus),
              ),
              AccountingPreviewRow(
                label: '\u00d6denen',
                value: _formatTlFromKurus(_paidKurus),
              ),
              AccountingPreviewRow(
                label: 'Kalan',
                value: _formatTlFromKurus(_remainingKurus),
              ),
              AccountingPreviewRow(label: 'Durum', value: _paymentStatusLabel),
              if (_hasDueDate)
                AccountingPreviewRow(
                  label: 'Vade',
                  value: _dueDateController.text.trim().isEmpty
                      ? 'Girilecek'
                      : _dueDateController.text.trim(),
                ),
              if (_isInstallment)
                AccountingPreviewRow(
                  label: 'Taksit',
                  value: '$_installmentCount taksit / $_installmentPeriodLabel',
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
        ? _catalogLabel(_selectedCatalogItem)
        : _manualItemController.text.trim();

    final result = AccountingDraftValidator.validateManualSale(
      saleType: _saleType,
      customerType: _customerType == 'registered' ? 'registered' : 'manual',
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      itemName: item,
      totalKurus: _amountKurus,
      paidKurus: _paidKurus,
      hasDueDate: _hasDueDate,
      isInstallment: _isInstallment,
      closeAtCollectedAmount: _finalizeAtCollectedAmount,
    );

    if (!result.ok) {
      _showSnack(result.message ?? 'Sat\u0131\u015f tasla\u011f\u0131 eksik.');
      return;
    }

    _showSnack(
      'Satış taslağı kayda hazır. Canlı kayıt servisi açıldığında doğrudan gönderilecek.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      AccountingWizardStep(
        title: 'Sat\u0131\u015f tipi',
        subtitle: _saleTypeLabel,
        child: AccountingSaleTypeStep(
          selected: _saleType,
          onSelected: _selectSaleType,
        ),
      ),
      AccountingWizardStep(
        title: 'M\u00fc\u015fteri',
        subtitle: _customerType == 'registered'
            ? 'Kay\u0131tl\u0131 bireysel'
            : 'Misafir / randevusuz',
        child: AccountingCustomerStep(
          customerType: _customerType,
          customerNameController: _customerNameController,
          customerPhoneController: _customerPhoneController,
          onSelectType: _selectCustomerType,
          onLookup: _mockPhoneLookup,
          onContinue: _next,
        ),
      ),
      AccountingWizardStep(
        title: 'Kalem',
        subtitle: _catalogLabel(_selectedCatalogItem),
        child: AccountingCatalogStep(
          options: _catalogOptions,
          selected: _selectedCatalogItem,
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
          selectedCatalogItem: _selectedCatalogItem,
          onContinue: _next,
        ),
      ),
      AccountingWizardStep(
        title: '\u00d6deme',
        subtitle: _paymentStatusLabel,
        child: AccountingPaymentStep(
          paymentStatus: _paymentStatus,
          paymentMethod: _paymentMethod,
          paidAmountController: _paidAmountController,
          dueDateController: _dueDateController,
          noteController: _noteController,
          hasDueDate: _hasDueDate,
          isInstallment: _isInstallment,
          installmentCount: _installmentCount,
          installmentPeriod: _installmentPeriod,
          finalizeAtCollectedAmount: _finalizeAtCollectedAmount,
          onStatusSelected: _selectPaymentStatus,
          onMethodSelected: (value) => setState(() => _paymentMethod = value),
          onDueDateChanged: (value) => setState(() => _hasDueDate = value),
          onPickDueDate: () => _pickDate(_dueDateController),
          onInstallmentChanged: (value) {
            setState(() {
              _isInstallment = value;
              if (value) {
                _hasDueDate = true;
                _finalizeAtCollectedAmount = false;
              }
            });
          },
          onInstallmentCountChanged: (value) {
            if (value != null) setState(() => _installmentCount = value);
          },
          onInstallmentPeriodChanged: (value) {
            if (value != null) setState(() => _installmentPeriod = value);
          },
          onFinalizeChanged: (value) {
            setState(() {
              _finalizeAtCollectedAmount = value;
              if (value) {
                _hasDueDate = false;
                _isInstallment = false;
              }
            });
          },
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
            currentStep: _step,
            data: steps[i],
            onTap: () => _goToStep(i),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
