part of '../../staff_workspace_page.dart';

extension _StaffWorkspacePageStateExpenseSheet on _StaffWorkspacePageState {
  Future<void> _openExpenseSheet() async {
    if (!_can('enterExpenses')) {
      _show('Masraf girme yetkin yok.');
      return;
    }

    final title = TextEditingController();
    final amount = TextEditingController();
    final note = TextEditingController();

    String category = 'Malzeme';
    bool saving = false;

    await showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 620,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> save() async {
              final userUid = _currentUid;
              if (userUid.isEmpty) return;

              final titleText = title.text.trim();
              final amountValue =
                  double.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;

              if (titleText.isEmpty || amountValue <= 0) {
                _show('Masraf adı ve tutarı zorunlu.');
                return;
              }

              if (!_can('enterExpenses')) {
                _show('Gider / masraf işlemleri için yetkin yok.');
                return;
              }

              if (!_StaffWorkspacePageState._staffExpenseLiveWriteEnabled) {
                _show(
                  'Masraf kaydı geçici olarak kapalı. Yetki ve muhasebe bağlantısı tamamlanınca etkinleşecek.',
                );
                return;
              }

              setSheetState(() => saving = true);

              try {
                final expenseId = await _workspaceRepository.createExpense(
                  businessId: _businessId,
                  staffId: _staffId,
                  createdByName:
                      (widget.memberData[FirestoreFields.staffName] ??
                              _currentEmail)
                          .toString(),
                  title: titleText,
                  category: category,
                  amount: amountValue,
                  note: note.text.trim(),
                );

                await _writeActivityLog(
                  type: 'expense_created_by_staff',
                  title: 'Masraf girildi',
                  description:
                      '$titleText - ${amountValue.toStringAsFixed(2)} TL',
                  expenseId: expenseId,
                  extra: {
                    FirestoreFields.category: category,
                    FirestoreFields.amount: amountValue,
                  },
                );

                if (!context.mounted) return;
                Navigator.pop(context);
                _show('Masraf kaydı eklendi.');
              } finally {
                if (context.mounted) {
                  setSheetState(() => saving = false);
                }
              }
            }

            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Masraf Gir',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bu kayıt kurumsal kullanıcının finans ve masraf analizinde kullanılacak.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Masraf adı *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              const [
                                    'Malzeme',
                                    'Kira',
                                    'Personel',
                                    'Reklam',
                                    'Elektrik / Su',
                                    'Komisyon',
                                    'Bakım / Onarım',
                                    'Diğer',
                                  ]
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() => category = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Tutar *',
                            suffixText: 'TL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Not',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Kaydediliyor...' : 'Masrafı Kaydet'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    title.dispose();
    amount.dispose();
    note.dispose();
  }
  void _show(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
