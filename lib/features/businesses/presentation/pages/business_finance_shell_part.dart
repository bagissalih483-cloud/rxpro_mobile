part of 'business_finance_page.dart';

class BusinessFinancePage extends StatefulWidget {
  const BusinessFinancePage({
    super.key,
    required this.businessId,
    this.businessName = 'İşletme',
  });

  final String businessId;
  final String businessName;

  @override
  State<BusinessFinancePage> createState() => _BusinessFinancePageState();
}

class _BusinessFinancePageState extends State<BusinessFinancePage> {
  final BusinessFinanceRepository _financeRepository =
      BusinessFinanceRepository();
  final BusinessFinanceController _controller = BusinessFinanceController();

  @override
  void initState() {
    super.initState();
    _safeReload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _safeReload() async {
    if (!mounted) return;

    _controller.beginReload();

    try {
      final loaded = await _loadFinance();

      if (!mounted) return;

      _controller.applyLoaded(loaded);
    } catch (e, st) {
      debugPrint('BusinessFinancePage reload error: $e');
      debugPrint(st.toString());

      if (!mounted) return;

      _controller.applyLoadError(e);
    }
  }

  Future<FinanceLoadResult> _loadFinance() async {
    final expenses = <FinanceExpenseRow>[];
    final incomes = <FinanceIncomeRow>[];

    int rawExpenseCount = 0;
    int rawIncomeCount = 0;
    int filteredExpenseCount = 0;
    int filteredIncomeCount = 0;

    String? expenseReadError;
    String? incomeReadError;

    final businessId = widget.businessId.trim();

    try {
      final snap = await _financeRepository.fetchBusinessExpensesSnapshot(
        businessId: businessId,
        limit: 500,
      );
      rawExpenseCount = snap.docs.length;

      for (final doc in snap.docs) {
        final data = doc.data();

        if (!_isInSelectedMonth(data)) continue;

        filteredExpenseCount++;

        final amount = _toDouble(
          data[FirestoreFields.amount] ??
              data[FirestoreFields.price] ??
              data[FirestoreFields.total],
        );

        if (amount <= 0) continue;

        expenses.add(
          FinanceExpenseRow(
            id: doc.id,
            title:
                (data[FirestoreFields.title] ??
                        data[FirestoreFields.expenseName] ??
                        data[FirestoreFields.name] ??
                        'Masraf')
                    .toString(),
            category: (data[FirestoreFields.category] ?? 'Genel').toString(),
            note: (data[FirestoreFields.note] ?? '').toString(),
            amount: amount,
            recurring: data[FirestoreFields.isRecurring] == true,
            createdText: _dateLabelOf(data),
          ),
        );
      }
    } catch (e) {
      expenseReadError = e.toString();
    }

    try {
      final financeRecordIncomes = <FinanceIncomeRow>[];
      int financeRecordRawCount = 0;
      int financeRecordFilteredCount = 0;
      final financeSnap = await _financeRepository
          .fetchIncomeFinanceRecordsSnapshot(
            businessId: businessId,
            limit: 500,
          );
      financeRecordRawCount = financeSnap.docs.length;

      for (final doc in financeSnap.docs) {
        final data = doc.data();

        if (!_isInSelectedMonth(data)) continue;
        if (data[FirestoreFields.isDeleted] == true) continue;

        financeRecordFilteredCount++;

        final amount = _toDouble(
          data[FirestoreFields.amount] ??
              data[FirestoreFields.total] ??
              data[FirestoreFields.price],
        );

        if (amount <= 0) continue;

        financeRecordIncomes.add(
          FinanceIncomeRow(
            id: doc.id,
            title:
                (data[FirestoreFields.serviceName] ??
                        data[FirestoreFields.title] ??
                        data[FirestoreFields.sourceAppointmentId] ??
                        'Randevu geliri')
                    .toString(),
            amount: amount,
            createdText: _dateLabelOf(data),
            paymentStatus: (data[FirestoreFields.paymentStatus] ?? '')
                .toString(),
            staffName: (data[FirestoreFields.staffName] ?? '').toString(),
          ),
        );
      }

      if (financeRecordIncomes.isNotEmpty) {
        rawIncomeCount = financeRecordRawCount;
        filteredIncomeCount = financeRecordFilteredCount;
        incomes.addAll(financeRecordIncomes);
      } else {
        final snap = await _financeRepository.fetchBusinessAppointmentsSnapshot(
          businessId: businessId,
          limit: 500,
        );
        rawIncomeCount = snap.docs.length;

        for (final doc in snap.docs) {
          final data = doc.data();

          if (!_isInSelectedMonth(data)) continue;
          if (_isCancelled(data)) continue;

          filteredIncomeCount++;

          final amount = _toDouble(
            data[FirestoreFields.paidAmount] ??
                data[FirestoreFields.amount] ??
                data[FirestoreFields.price] ??
                data[FirestoreFields.servicePrice],
          );

          if (amount <= 0) continue;

          incomes.add(
            FinanceIncomeRow(
              id: doc.id,
              title:
                  (data[FirestoreFields.serviceName] ??
                          data[FirestoreFields.title] ??
                          data[FirestoreFields.appointmentNo] ??
                          'Randevu geliri')
                      .toString(),
              amount: amount,
              createdText: _dateLabelOf(data),
              paymentStatus: (data[FirestoreFields.paymentStatus] ?? '')
                  .toString(),
              staffName: (data[FirestoreFields.staffName] ?? '').toString(),
            ),
          );
        }
      }
    } catch (e) {
      incomeReadError = e.toString();
    }
    expenses.sort((a, b) => b.amount.compareTo(a.amount));
    incomes.sort((a, b) => b.amount.compareTo(a.amount));

    return FinanceLoadResult(
      expenses: expenses,
      incomes: incomes,
      rawExpenseCount: rawExpenseCount,
      rawIncomeCount: rawIncomeCount,
      filteredExpenseCount: filteredExpenseCount,
      filteredIncomeCount: filteredIncomeCount,
      expenseReadError: expenseReadError,
      incomeReadError: incomeReadError,
    );
  }

  bool _isCancelled(Map<String, dynamic> data) {
    final status =
        (data[FirestoreFields.status] ??
                data['appointmentStatus'] ??
                data['state'] ??
                data[FirestoreFields.bookingStatus] ??
                '')
            .toString()
            .toLowerCase();

    return status.contains('cancel') ||
        status.contains('iptal') ||
        data['isCancelled'] == true;
  }

  bool _isInSelectedMonth(Map<String, dynamic> data) {
    final monthKey = (data[FirestoreFields.monthKey] ?? '').toString().trim();

    if (monthKey.isNotEmpty) {
      return monthKey == _controller.monthKey;
    }

    final date = _parseDate(
      data[FirestoreFields.expenseDateIso] ??
          data[FirestoreFields.createdAtLocalIso] ??
          data[FirestoreFields.expenseDate] ??
          data['startAtIso'] ??
          data['startAt'] ??
          data['appointmentDate'] ??
          data['dateText'] ??
          data[FirestoreFields.createdAt],
    );

    if (date == null) return false;

    return date.year == _controller.period.year &&
        date.month == _controller.period.month;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;

    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    final direct = DateTime.tryParse(text);
    if (direct != null) return direct;

    final parts = text.split(RegExp(r'[./-]'));
    if (parts.length >= 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);

      if (a != null && b != null && c != null) {
        if (a > 1900) {
          return DateTime(a, b, c);
        }
        if (c > 1900) {
          return DateTime(c, b, a);
        }
      }
    }

    return null;
  }

  String _dateLabelOf(Map<String, dynamic> data) {
    final date = _parseDate(
      data[FirestoreFields.expenseDateIso] ??
          data[FirestoreFields.createdAtLocalIso] ??
          data[FirestoreFields.expenseDate] ??
          data['startAtIso'] ??
          data['startAt'] ??
          data['appointmentDate'] ??
          data['dateText'] ??
          data[FirestoreFields.createdAt],
    );

    if (date == null) return '-';

    return financeDateText(date);
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    if (value is String) {
      final normalized = value.replaceAll('.', '').replaceAll(',', '.').trim();
      return double.tryParse(normalized) ?? 0;
    }

    return 0;
  }

  void _previousMonth() {
    _controller.previousMonth();
    _safeReload();
  }

  void _nextMonth() {
    _controller.nextMonth();
    _safeReload();
  }

  Future<void> _openAddExpense() async {
    final saved = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.businessExpenseForm,
      arguments: BusinessExpenseFormRouteArgs(
        businessId: widget.businessId,
        businessName: widget.businessName,
      ),
    );

    if (saved == true) {
      await _safeReload();
    }
  }

  Future<void> _createPdf() async {
    if (_controller.generatingPdf) return;

    _controller.setGeneratingPdf(true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text('fi Finans Raporu'),
            pw.SizedBox(height: 8),
            pw.Text('İşletme: ${widget.businessName}'),
            pw.Text('İşletme ID: ${widget.businessId}'),
            pw.Text('Dönem: ${_controller.periodLabel}'),
            pw.SizedBox(height: 12),
            pw.Text('Ciro: ${financeMoney(_controller.incomeTotal)}'),
            pw.Text('Masraf: ${financeMoney(_controller.expenseTotal)}'),
            pw.Text('Net: ${financeMoney(_controller.net)}'),
            pw.SizedBox(height: 18),
            pw.Text('Masraf Detayları'),
            ..._controller.expenses.map(
              (e) => pw.Text(
                '${e.title} - ${e.category} - ${financeMoney(e.amount)}',
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Text('Gelir Detayları'),
            ..._controller.incomes.map(
              (e) => pw.Text('${e.title} - ${financeMoney(e.amount)}'),
            ),
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/rxpro_finans_${_controller.monthKey}.pdf');
      await file.writeAsBytes(await pdf.save());

      await OpenFilex.open(file.path);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF oluşturulamadi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        _controller.setGeneratingPdf(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final expenseByCategory = _controller.expenseByCategory;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Finans ve Masraf'),
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
            actions: [
              IconButton(
                onPressed: _controller.loading ? null : _safeReload,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Yenile',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddExpense,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Masraf Ekle'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
            children: [
              FinancePeriodCard(
                label: _controller.periodLabel,
                onPrevious: _previousMonth,
                onNext: _nextMonth,
              ),
              const SizedBox(height: 12),
              FinanceDebugCard(
                businessId: widget.businessId,
                businessName: widget.businessName,
                monthKey: _controller.monthKey,
                loading: _controller.loading,
                rawExpenseCount: _controller.rawExpenseCount,
                filteredExpenseCount: _controller.filteredExpenseCount,
                rawIncomeCount: _controller.rawIncomeCount,
                filteredIncomeCount: _controller.filteredIncomeCount,
                mainError: _controller.mainError,
                expenseError: _controller.expenseReadError,
                incomeError: _controller.incomeReadError,
              ),
              const SizedBox(height: 12),
              if (_controller.loading)
                const FinanceInfoCard(
                  icon: Icons.sync_rounded,
                  title: 'Finans verisi yukleniyor',
                  text: 'Masraf ve randevu gelirleri guvenli sekilde okunuyor.',
                ),
              if (_controller.mainError != null)
                FinanceWarningCard(
                  title: 'Finans sayfasi hata yakaladi',
                  text: _controller.mainError!,
                ),
              if (_controller.expenseReadError != null)
                FinanceWarningCard(
                  title: 'Masraf verisi okunamadi',
                  text: _controller.expenseReadError!,
                ),
              if (_controller.incomeReadError != null)
                FinanceWarningCard(
                  title: 'Ciro verisi okunamadi',
                  text: _controller.incomeReadError!,
                ),
              Row(
                children: [
                  Expanded(
                    child: FinanceMetricCard(
                      title: 'Bu Ay Ciro',
                      value: financeMoney(_controller.incomeTotal),
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FinanceMetricCard(
                      title: 'Bu Ay Masraf',
                      value: financeMoney(_controller.expenseTotal),
                      icon: Icons.trending_down_rounded,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FinanceMetricCard(
                title: _controller.net >= 0 ? 'Net Kar' : 'Net Zarar',
                value: financeMoney(_controller.net),
                icon: _controller.net >= 0
                    ? Icons.account_balance_wallet_outlined
                    : Icons.warning_amber_rounded,
                color: _controller.net >= 0
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFB45309),
              ),
              const SizedBox(height: 12),
              FinanceSectionCard(
                title: 'Masraf Kategorileri',
                child: expenseByCategory.isEmpty
                    ? const FinanceEmptyText('Bu ay kategori masrafı yok.')
                    : Column(
                        children: expenseByCategory.entries
                            .map(
                              (e) => FinanceAmountLine(
                                title: e.key,
                                amount: e.value,
                                negative: true,
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 12),
              FinanceSectionCard(
                title: 'Gelir Kalemleri',
                child: _controller.incomes.isEmpty
                    ? const FinanceEmptyText('Bu ay randevu geliri yok.')
                    : Column(
                        children: _controller.incomes
                            .map(
                              (e) => FinanceAmountLine(
                                title: '${e.title}  -  ${e.createdText}',
                                amount: e.amount,
                                negative: false,
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 12),
              FinanceSectionCard(
                title: 'Masraf Detayları',
                child: _controller.expenses.isEmpty
                    ? const FinanceEmptyText('Bu ay masraf kaydı yok.')
                    : Column(
                        children: _controller.expenses
                            .map((e) => FinanceExpenseLine(row: e))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _controller.generatingPdf ? null : _createPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(
                  _controller.generatingPdf
                      ? 'PDF hazirlaniyor...'
                      : 'PDF Rapor Al',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
