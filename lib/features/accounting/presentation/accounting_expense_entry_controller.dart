import 'package:flutter/foundation.dart';

class AccountingExpenseEntryController extends ChangeNotifier {
  AccountingExpenseEntryController({
    String category = 'supplies',
    String paymentMethod = 'cash',
    bool isPaid = true,
    bool isRecurring = false,
  }) : _category = category,
       _paymentMethod = paymentMethod,
       _isPaid = isPaid,
       _isRecurring = isRecurring;

  String _category;
  String _paymentMethod;
  bool _isPaid;
  bool _isRecurring;

  String get category => _category;
  String get paymentMethod => _paymentMethod;
  bool get isPaid => _isPaid;
  bool get isRecurring => _isRecurring;

  void selectCategory(String value) {
    if (_category == value) return;
    _category = value;
    notifyListeners();
  }

  void selectPaymentMethod(String value) {
    if (_paymentMethod == value) return;
    _paymentMethod = value;
    notifyListeners();
  }

  void setPaid(bool value) {
    if (_isPaid == value) return;
    _isPaid = value;
    notifyListeners();
  }

  void setRecurring(bool value) {
    if (_isRecurring == value) return;
    _isRecurring = value;
    notifyListeners();
  }
}
