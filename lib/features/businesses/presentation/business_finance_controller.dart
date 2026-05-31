import 'package:flutter/foundation.dart';
import 'package:rxpro_mobile/features/businesses/presentation/models/business_finance_models.dart';
import 'package:rxpro_mobile/features/businesses/presentation/utils/business_finance_formatters.dart';

class BusinessFinanceController extends ChangeNotifier {
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

  DateTime get period => _period;
  bool get loading => _loading;
  bool get generatingPdf => _generatingPdf;
  String? get mainError => _mainError;
  String? get expenseReadError => _expenseReadError;
  String? get incomeReadError => _incomeReadError;
  List<FinanceExpenseRow> get expenses => List.unmodifiable(_expenses);
  List<FinanceIncomeRow> get incomes => List.unmodifiable(_incomes);
  int get rawExpenseCount => _rawExpenseCount;
  int get rawIncomeCount => _rawIncomeCount;
  int get filteredExpenseCount => _filteredExpenseCount;
  int get filteredIncomeCount => _filteredIncomeCount;
  String get periodLabel => financeMonthLabel(_period);
  String get monthKey => financeFilePeriod(_period);

  double get incomeTotal {
    return _incomes.fold(0, (total, item) => total + item.amount);
  }

  double get expenseTotal {
    return _expenses.fold(0, (total, item) => total + item.amount);
  }

  double get net => incomeTotal - expenseTotal;

  Map<String, double> get expenseByCategory {
    final map = <String, double>{};
    for (final item in _expenses) {
      map[item.category] = (map[item.category] ?? 0) + item.amount;
    }
    return map;
  }

  void beginReload() {
    _loading = true;
    _mainError = null;
    _expenseReadError = null;
    _incomeReadError = null;
    notifyListeners();
  }

  void applyLoaded(FinanceLoadResult loaded) {
    _expenses = loaded.expenses;
    _incomes = loaded.incomes;
    _rawExpenseCount = loaded.rawExpenseCount;
    _rawIncomeCount = loaded.rawIncomeCount;
    _filteredExpenseCount = loaded.filteredExpenseCount;
    _filteredIncomeCount = loaded.filteredIncomeCount;
    _expenseReadError = loaded.expenseReadError;
    _incomeReadError = loaded.incomeReadError;
    _loading = false;
    notifyListeners();
  }

  void applyLoadError(Object error) {
    _mainError = error.toString();
    _loading = false;
    notifyListeners();
  }

  void previousMonth() {
    _period = DateTime(_period.year, _period.month - 1, 1);
    notifyListeners();
  }

  void nextMonth() {
    _period = DateTime(_period.year, _period.month + 1, 1);
    notifyListeners();
  }

  void setGeneratingPdf(bool value) {
    if (_generatingPdf == value) return;
    _generatingPdf = value;
    notifyListeners();
  }
}

class ExpenseFormController extends ChangeNotifier {
  String _category = 'Genel';
  bool _isRecurring = false;
  String _recurringPeriod = 'monthly';
  bool _saving = false;

  String get category => _category;
  bool get isRecurring => _isRecurring;
  String get recurringPeriod => _recurringPeriod;
  bool get saving => _saving;

  void setCategory(String value) {
    final next = value.trim().isEmpty ? 'Genel' : value;
    if (_category == next) return;
    _category = next;
    notifyListeners();
  }

  void setRecurring(bool value) {
    if (_isRecurring == value) return;
    _isRecurring = value;
    notifyListeners();
  }

  void setRecurringPeriod(String value) {
    final next = value.trim().isEmpty ? 'monthly' : value;
    if (_recurringPeriod == next) return;
    _recurringPeriod = next;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    _saving = value;
    notifyListeners();
  }
}
