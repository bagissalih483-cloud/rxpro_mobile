import 'package:flutter/foundation.dart';

class AccountingSalesEntryController extends ChangeNotifier {
  int _step = 0;
  String _saleType = 'service';
  String _customerType = 'walkIn';
  String _selectedCatalogItem = 'service_1';
  String _paymentStatus = 'openAccount';
  String _paymentMethod = 'cash';
  String _installmentCount = '3';
  String _installmentPeriod = 'monthly';
  bool _hasDueDate = false;
  bool _isInstallment = false;
  bool _finalizeAtCollectedAmount = false;

  int get step => _step;
  String get saleType => _saleType;
  String get customerType => _customerType;
  String get selectedCatalogItem => _selectedCatalogItem;
  String get paymentStatus => _paymentStatus;
  String get paymentMethod => _paymentMethod;
  String get installmentCount => _installmentCount;
  String get installmentPeriod => _installmentPeriod;
  bool get hasDueDate => _hasDueDate;
  bool get isInstallment => _isInstallment;
  bool get finalizeAtCollectedAmount => _finalizeAtCollectedAmount;

  void goToStep(int index) {
    _step = index.clamp(0, 4);
    notifyListeners();
  }

  void next() => goToStep(_step + 1);

  String selectSaleType(String value) {
    _saleType = value;
    _selectedCatalogItem = _defaultCatalogForSaleType(value);
    _step = 1;
    notifyListeners();
    return _selectedCatalogItem;
  }

  void selectCustomerType(String value) {
    _customerType = value;
    _step = 2;
    notifyListeners();
  }

  void selectCatalogItem(String value) {
    _selectedCatalogItem = value;
    _step = 3;
    notifyListeners();
  }

  void selectPaymentStatus(String value) {
    _paymentStatus = value;
    if (value == 'installment') {
      _isInstallment = true;
      _hasDueDate = true;
      _finalizeAtCollectedAmount = false;
    } else if (value == 'free') {
      _isInstallment = false;
      _hasDueDate = false;
      _finalizeAtCollectedAmount = true;
    } else if (value == 'paid') {
      _isInstallment = false;
      _hasDueDate = false;
      _finalizeAtCollectedAmount = true;
    }
    _step = 4;
    notifyListeners();
  }

  void selectPaymentMethod(String value) {
    if (_paymentMethod == value) return;
    _paymentMethod = value;
    notifyListeners();
  }

  void setHasDueDate(bool value) {
    if (_hasDueDate == value) return;
    _hasDueDate = value;
    notifyListeners();
  }

  void setInstallment(bool value) {
    _isInstallment = value;
    if (value) {
      _hasDueDate = true;
      _finalizeAtCollectedAmount = false;
    }
    notifyListeners();
  }

  void setInstallmentCount(String value) {
    if (_installmentCount == value) return;
    _installmentCount = value;
    notifyListeners();
  }

  void setInstallmentPeriod(String value) {
    if (_installmentPeriod == value) return;
    _installmentPeriod = value;
    notifyListeners();
  }

  void setFinalizeAtCollectedAmount(bool value) {
    _finalizeAtCollectedAmount = value;
    if (value) {
      _hasDueDate = false;
      _isInstallment = false;
    }
    notifyListeners();
  }

  static String _defaultCatalogForSaleType(String type) {
    switch (type) {
      case 'product':
        return 'product_1';
      case 'mixed':
        return 'mixed_1';
      default:
        return 'service_1';
    }
  }
}
