part of 'business_finance_page.dart';

class ExpenseFormPage extends StatefulWidget {
  const ExpenseFormPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final ExpenseFormController _controller = ExpenseFormController();

  static const _categories = [
    'Genel',
    'Kira',
    'Personel',
    'Malzeme',
    'Reklam',
    'Fatura',
    'Bakim',
    'Diger',
  ];

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    _controller.dispose();
    super.dispose();
  }

  double _parseAmount() {
    return double.tryParse(_amount.text.replaceAll(',', '.').trim()) ?? 0;
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final amount = _parseAmount();

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masraf adi ve gecerli tutar girin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _controller.setSaving(true);

    final now = DateTime.now();

    try {
      await BusinessFinanceRepository().addBusinessExpense(
        businessId: widget.businessId,
        businessName: widget.businessName,
        title: title,
        amount: amount,
        category: _controller.category,
        note: _note.text.trim(),
        isRecurring: _controller.isRecurring,
        recurringPeriod: _controller.recurringPeriod,
        now: now,
        source: 'business_finance_page_37M_B',
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _controller.setSaving(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masraf kaydedilemedi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Masraf Ekle'),
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Masraf adi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _controller.category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => _controller.setCategory(v ?? 'Genel'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Not',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _controller.isRecurring,
                onChanged: _controller.setRecurring,
                title: const Text('Tekrar eden masraf'),
                subtitle: const Text(
                  'Aylik veya donemsel sabit gider olarak isaretle.',
                ),
              ),
              if (_controller.isRecurring) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _controller.recurringPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Periyot',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Aylik')),
                    DropdownMenuItem(value: 'weekly', child: Text('Haftalik')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yillik')),
                  ],
                  onChanged: (v) =>
                      _controller.setRecurringPeriod(v ?? 'monthly'),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _controller.saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_controller.saving ? 'Kaydediliyor...' : 'Kaydet'),
              ),
            ],
          ),
        );
      },
    );
  }
}
