import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/responsive/rx_adaptive_modal.dart';
import 'package:rxpro_mobile/core/session/app_session_scope.dart';

import '../data/accounting_repository.dart';
import '../data/accounting_validators.dart';
import '../data/callable_accounting_repository.dart';
import '../models/accounting_models.dart';
import '../presentation/accounting_expense_entry_controller.dart';

class AccountingExpenseEntryForm extends StatefulWidget {
  const AccountingExpenseEntryForm({super.key});

  @override
  State<AccountingExpenseEntryForm> createState() =>
      _AccountingExpenseEntryFormState();
}

class _AccountingExpenseEntryFormState
    extends State<AccountingExpenseEntryForm> {
  final AccountingExpenseEntryController _controller =
      AccountingExpenseEntryController();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;

    _dateController.text = _dateLabel(picked);
  }

  void _validateDraft() {
    final title = _titleController.text.trim().isEmpty
        ? _categoryLabelForExpense(_controller.category)
        : _titleController.text.trim();

    final result = AccountingDraftValidator.validateExpense(
      category: _controller.category,
      title: title,
      amountKurus: AccountingMoneyParser.parseKurus(_amountController.text),
      recurring: _controller.isRecurring,
      recurrencePeriod: 'monthly',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.ok
              ? 'Gider taslağı kayda hazır. Canlı kayıt yetkisi açılınca gönderilecek.'
              : result.message ?? 'Gider taslağı eksik.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
        const Text(
          'Gider ekle',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _controller.category,
          decoration: const InputDecoration(
            labelText: 'Kategori',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'supplies', child: Text('Sarf malzeme')),
            DropdownMenuItem(value: 'rent', child: Text('Kira')),
            DropdownMenuItem(value: 'staff', child: Text('Personel')),
            DropdownMenuItem(value: 'product', child: Text('Ürün alımı')),
            DropdownMenuItem(value: 'commission', child: Text('Komisyon')),
            DropdownMenuItem(value: 'tax', child: Text('Vergi / resmi gider')),
            DropdownMenuItem(value: 'other', child: Text('Diğer')),
          ],
          onChanged: (value) {
            if (value != null) _controller.selectCategory(value);
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Gider başlığı',
            hintText: _categoryLabelForExpense(_controller.category),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Tutar',
            suffixText: 'TL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _vendorController,
          decoration: const InputDecoration(
            labelText: 'Tedarikçi / açıklama',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _dateController,
          readOnly: true,
          onTap: _pickDate,
          decoration: InputDecoration(
            labelText: 'Gider tarihi',
            hintText: 'Bugün',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ChoicePill(
              selected: _controller.paymentMethod == 'cash',
              label: 'Nakit',
              onTap: () => _controller.selectPaymentMethod('cash'),
            ),
            _ChoicePill(
              selected: _controller.paymentMethod == 'bank',
              label: 'Havale',
              onTap: () => _controller.selectPaymentMethod('bank'),
            ),
            _ChoicePill(
              selected: _controller.paymentMethod == 'card',
              label: 'Kart',
              onTap: () => _controller.selectPaymentMethod('card'),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _controller.isPaid,
          title: const Text('Bu gider ödendi'),
          onChanged: _controller.setPaid,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _controller.isRecurring,
          title: const Text('Tekrarlayan gider'),
          subtitle: const Text('Kira, abonelik veya düzenli giderler için.'),
          onChanged: _controller.setRecurring,
        ),
        TextField(
          controller: _noteController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Not',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _validateDraft,
          icon: const Icon(Icons.fact_check_rounded),
          label: const Text('Kayda uygunluğu kontrol et'),
        ),
          ],
        );
      },
    );
  }
}

class AccountingExpensesPage extends StatefulWidget {
  AccountingExpensesPage({
    super.key,
    required this.from,
    required this.to,
    AccountingRepository? repository,
  }) : _repository = repository ?? CallableAccountingRepository();

  final DateTime from;
  final DateTime to;
  final AccountingRepository _repository;

  @override
  State<AccountingExpensesPage> createState() => _AccountingExpensesPageState();
}

class _AccountingExpensesPageState extends State<AccountingExpensesPage>
    with AutomaticKeepAliveClientMixin {
  String? _expensesStreamKey;
  Stream<List<AccountingExpense>>? _expensesStream;

  @override
  bool get wantKeepAlive => true;

  void _showEditPreview(_ExpenseDemo expense) {
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
                'Gider d\u00fczenleme tasla\u011f\u0131',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _InfoRow(label: 'Ba\u015fl\u0131k', value: expense.title),
              _InfoRow(label: 'Kategori', value: expense.categoryLabel),
              _InfoRow(label: 'Tutar', value: expense.amountLabel),
              _InfoRow(label: 'Tekrar', value: expense.recurringLabel),
              const SizedBox(height: 12),
              const TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Yeni tutar / not / periyot',
                  hintText: 'Düzenleme hazır olduğunda aktif olacak',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Düzenleme hazır olduğunda tek kayıt veya sonraki tekrarlar ayrı seçenek olarak yönetilecek.',
                style: TextStyle(color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final session = AppSessionScope.maybeOf(context);
    final businessId = session?.businessId ?? '';

    return StreamBuilder<List<AccountingExpense>>(
      stream: _watchExpensesFor(businessId),
      builder: (context, snapshot) {
        final expenses = (snapshot.data ?? const <AccountingExpense>[])
            .map(_ExpenseDemo.fromExpense)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            const _SectionTitle('Son giderler'),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(minHeight: 3),
            if (expenses.isEmpty)
              const _EmptyExpenses()
            else
              for (final expense in expenses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExpenseCard(
                    expense: expense,
                    onEdit: () => _showEditPreview(expense),
                  ),
                ),
          ],
        );
      },
    );
  }

  Stream<List<AccountingExpense>> _watchExpensesFor(String businessId) {
    final key = [
      businessId,
      widget.from.millisecondsSinceEpoch,
      widget.to.millisecondsSinceEpoch,
    ].join('|');

    if (_expensesStreamKey != key || _expensesStream == null) {
      _expensesStreamKey = key;
      _expensesStream = widget._repository.watchExpenses(
        businessId: businessId,
        from: widget.from,
        to: widget.to,
      );
    }

    return _expensesStream!;
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expense, required this.onEdit});

  final _ExpenseDemo expense;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final paid = expense.statusLabel == '\u00d6dendi';
    final color = paid ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.receipt_long_rounded, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${expense.categoryLabel} • ${expense.methodLabel} • ${expense.dateLabel}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    expense.recurringLabel,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  expense.amountLabel,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  expense.statusLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'D\u00fczenle',
                ),
              ],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: Color(0xFF0F172A),
        fontSize: 15,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 96,
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

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF10B981),
              size: 38,
            ),
            SizedBox(height: 10),
            Text(
              'Seçili dönemde gider yok',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseDemo {
  const _ExpenseDemo({
    required this.title,
    required this.categoryLabel,
    required this.amountLabel,
    required this.methodLabel,
    required this.statusLabel,
    required this.dateLabel,
    required this.recurringLabel,
  });

  final String title;
  final String categoryLabel;
  final String amountLabel;
  final String methodLabel;
  final String statusLabel;
  final String dateLabel;
  final String recurringLabel;

  factory _ExpenseDemo.fromExpense(AccountingExpense expense) {
    return _ExpenseDemo(
      title: expense.title,
      categoryLabel: _categoryLabelForExpense(expense.category),
      amountLabel: _money(expense.amountKurus),
      methodLabel: _methodLabelForExpense(expense.paymentMethod),
      statusLabel: expense.status == AccountingExpenseStatus.paid
          ? 'Ödendi'
          : 'Bekliyor',
      dateLabel: _dateLabel(expense.expenseDate),
      recurringLabel: 'Tek seferlik',
    );
  }
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

String _categoryLabelForExpense(String value) {
  switch (value) {
    case 'rent':
      return 'Kira';
    case 'staff':
      return 'Personel';
    case 'product':
      return 'Ürün alımı';
    case 'commission':
      return 'Komisyon';
    case 'tax':
      return 'Vergi / resmi gider';
    case 'supplies':
      return 'Sarf malzeme';
    default:
      return 'Diğer';
  }
}

String _methodLabelForExpense(AccountingPaymentMethod method) {
  switch (method) {
    case AccountingPaymentMethod.bank:
      return 'Havale';
    case AccountingPaymentMethod.card:
      return 'Kart';
    case AccountingPaymentMethod.cash:
      return 'Nakit';
    case AccountingPaymentMethod.nfc:
      return 'NFC';
    case AccountingPaymentMethod.mixed:
      return 'Karma';
    case AccountingPaymentMethod.unknown:
      return 'Belirsiz';
  }
}
