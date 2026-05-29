import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/app/app_routes.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/finance/data/business_finance_repository.dart';
import 'package:rxpro_mobile/features/businesses/presentation/models/business_finance_models.dart';
import 'package:rxpro_mobile/features/businesses/presentation/utils/business_finance_formatters.dart';
import 'package:rxpro_mobile/features/businesses/presentation/widgets/business_finance_widgets.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

/// 51B-E: Business finance page Firestore collection/field literals use
/// FirestoreCollections/FirestoreFields constants. Behavior is unchanged.
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
  DateTime _period = DateTime(DateTime.now().year, DateTime.now().month, 1);

  bool _loading = true;
  bool _generatingPdf = false;

  String? _mainError;
  String? _expenseReadError;
  String? _incomeReadError;

  List<FinanceExpenseRow> _expenses = const [];
  List<FinanceIncomeRow> _incomes = const [];

  int _rawExpenseCount = 0;
  int _rawIncomeCount = 0;
  int _filteredExpenseCount = 0;
  int _filteredIncomeCount = 0;

  String get _periodLabel => financeMonthLabel(_period);
  String get _monthKey => financeFilePeriod(_period);

  double get _incomeTotal =>
      _incomes.fold(0, (total, item) => total + item.amount);

  double get _expenseTotal =>
      _expenses.fold(0, (total, item) => total + item.amount);

  double get _net => _incomeTotal - _expenseTotal;

  @override
  void initState() {
    super.initState();
    _safeReload();
  }

  Future<void> _safeReload() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _mainError = null;
      _expenseReadError = null;
      _incomeReadError = null;
    });

    try {
      final loaded = await _loadFinance();

      if (!mounted) return;

      setState(() {
        _expenses = loaded.expenses;
        _incomes = loaded.incomes;
        _rawExpenseCount = loaded.rawExpenseCount;
        _rawIncomeCount = loaded.rawIncomeCount;
        _filteredExpenseCount = loaded.filteredExpenseCount;
        _filteredIncomeCount = loaded.filteredIncomeCount;
        _expenseReadError = loaded.expenseReadError;
        _incomeReadError = loaded.incomeReadError;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('BusinessFinancePage reload error: $e');
      debugPrint(st.toString());

      if (!mounted) return;

      setState(() {
        _mainError = e.toString();
        _loading = false;
      });
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
      return monthKey == _monthKey;
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

    return date.year == _period.year && date.month == _period.month;
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
    setState(() {
      _period = DateTime(_period.year, _period.month - 1, 1);
    });
    _safeReload();
  }

  void _nextMonth() {
    setState(() {
      _period = DateTime(_period.year, _period.month + 1, 1);
    });
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
    if (_generatingPdf) return;

    setState(() => _generatingPdf = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text('fi Finans Raporu'),
            pw.SizedBox(height: 8),
            pw.Text('İşletme: ${widget.businessName}'),
            pw.Text('İşletme ID: ${widget.businessId}'),
            pw.Text('Donem: $_periodLabel'),
            pw.SizedBox(height: 12),
            pw.Text('Ciro: ${financeMoney(_incomeTotal)}'),
            pw.Text('Masraf: ${financeMoney(_expenseTotal)}'),
            pw.Text('Net: ${financeMoney(_net)}'),
            pw.SizedBox(height: 18),
            pw.Text('Masraf Detaylari'),
            ..._expenses.map(
              (e) => pw.Text('${e.title} - ${e.category} - ${financeMoney(e.amount)}'),
            ),
            pw.SizedBox(height: 18),
            pw.Text('Gelir Detayları'),
            ..._incomes.map((e) => pw.Text('${e.title} - ${financeMoney(e.amount)}')),
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/rxpro_finans_$_monthKey.pdf');
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
        setState(() => _generatingPdf = false);
      }
    }
  }

  Map<String, double> _expenseByCategory() {
    final map = <String, double>{};

    for (final item in _expenses) {
      map[item.category] = (map[item.category] ?? 0) + item.amount;
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final expenseByCategory = _expenseByCategory();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Finans ve Masraf'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _safeReload,
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
            label: _periodLabel,
            onPrevious: _previousMonth,
            onNext: _nextMonth,
          ),
          const SizedBox(height: 12),
          FinanceDebugCard(
            businessId: widget.businessId,
            businessName: widget.businessName,
            monthKey: _monthKey,
            loading: _loading,
            rawExpenseCount: _rawExpenseCount,
            filteredExpenseCount: _filteredExpenseCount,
            rawIncomeCount: _rawIncomeCount,
            filteredIncomeCount: _filteredIncomeCount,
            mainError: _mainError,
            expenseError: _expenseReadError,
            incomeError: _incomeReadError,
          ),
          const SizedBox(height: 12),
          if (_loading)
            const FinanceInfoCard(
              icon: Icons.sync_rounded,
              title: 'Finans verisi yukleniyor',
              text: 'Masraf ve randevu gelirleri guvenli sekilde okunuyor.',
            ),
          if (_mainError != null)
            FinanceWarningCard(
              title: 'Finans sayfasi hata yakaladi',
              text: _mainError!,
            ),
          if (_expenseReadError != null)
            FinanceWarningCard(
              title: 'Masraf verisi okunamadi',
              text: _expenseReadError!,
            ),
          if (_incomeReadError != null)
            FinanceWarningCard(
              title: 'Ciro verisi okunamadi',
              text: _incomeReadError!,
            ),
          Row(
            children: [
              Expanded(
                child: FinanceMetricCard(
                  title: 'Bu Ay Ciro',
                  value: financeMoney(_incomeTotal),
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FinanceMetricCard(
                  title: 'Bu Ay Masraf',
                  value: financeMoney(_expenseTotal),
                  icon: Icons.trending_down_rounded,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FinanceMetricCard(
            title: _net >= 0 ? 'Net Kar' : 'Net Zarar',
            value: financeMoney(_net),
            icon: _net >= 0
                ? Icons.account_balance_wallet_outlined
                : Icons.warning_amber_rounded,
            color: _net >= 0
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
            child: _incomes.isEmpty
                ? const FinanceEmptyText('Bu ay randevu geliri yok.')
                : Column(
                    children: _incomes
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
            title: 'Masraf Detaylari',
            child: _expenses.isEmpty
                ? const FinanceEmptyText('Bu ay masraf kaydi yok.')
                : Column(
                    children: _expenses
                        .map((e) => FinanceExpenseLine(row: e))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _generatingPdf ? null : _createPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(
              _generatingPdf ? 'PDF hazirlaniyor...' : 'PDF Rapor Al',
            ),
          ),
        ],
      ),
    );
  }
}

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

  String _category = 'Genel';
  bool _isRecurring = false;
  String _recurringPeriod = 'monthly';
  bool _saving = false;

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

    setState(() => _saving = true);

    final now = DateTime.now();

    try {
      await BusinessFinanceRepository().addBusinessExpense(
        businessId: widget.businessId,
        businessName: widget.businessName,
        title: title,
        amount: amount,
        category: _category,
        note: _note.text.trim(),
        isRecurring: _isRecurring,
        recurringPeriod: _recurringPeriod,
        now: now,
        source: 'business_finance_page_37M_B',
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

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
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? 'Genel'),
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
            value: _isRecurring,
            onChanged: (v) => setState(() => _isRecurring = v),
            title: const Text('Tekrar eden masraf'),
            subtitle: const Text(
              'Aylik veya donemsel sabit gider olarak isaretle.',
            ),
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _recurringPeriod,
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
                  setState(() => _recurringPeriod = v ?? 'monthly'),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
          ),
        ],
      ),
    );
  }
}
