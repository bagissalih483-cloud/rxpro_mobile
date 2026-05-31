import 'package:flutter/foundation.dart';

class AccountingReceivablesController extends ChangeNotifier {
  String _filter = 'all';

  String get filter => _filter;

  void setFilter(String value) {
    if (value == _filter) return;
    _filter = value;
    notifyListeners();
  }
}
