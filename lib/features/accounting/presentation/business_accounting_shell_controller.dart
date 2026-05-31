import 'package:flutter/foundation.dart';

import '../models/accounting_models.dart';

class BusinessAccountingShellController extends ChangeNotifier {
  BusinessAccountingShellController({DateTime? now})
    : _periodAnchor = normalizeAnchor(
        now ?? DateTime.now(),
        AccountingPeriodMode.month,
      );

  int _index = 0;
  AccountingPeriodMode _periodMode = AccountingPeriodMode.month;
  DateTime _periodAnchor;

  int get index => _index;
  AccountingPeriodMode get periodMode => _periodMode;
  DateTime get periodAnchor => _periodAnchor;

  void selectTab(int index, int tabCount) {
    if (tabCount <= 0) return;
    final nextIndex = index.clamp(0, tabCount - 1).toInt();
    if (nextIndex == _index) return;
    _index = nextIndex;
    notifyListeners();
  }

  void setPeriodMode(AccountingPeriodMode mode) {
    if (mode == _periodMode) return;
    _periodMode = mode;
    _periodAnchor = normalizeAnchor(_periodAnchor, mode);
    notifyListeners();
  }

  void shiftPeriod(int direction) {
    switch (_periodMode) {
      case AccountingPeriodMode.day:
        _periodAnchor = _periodAnchor.add(Duration(days: direction));
        break;
      case AccountingPeriodMode.year:
        _periodAnchor = DateTime(_periodAnchor.year + direction);
        break;
      case AccountingPeriodMode.month:
        _periodAnchor = DateTime(
          _periodAnchor.year,
          _periodAnchor.month + direction,
        );
        break;
    }
    notifyListeners();
  }

  void goToCurrentPeriod({DateTime? now}) {
    _periodAnchor = normalizeAnchor(now ?? DateTime.now(), _periodMode);
    notifyListeners();
  }

  static DateTime normalizeAnchor(DateTime date, AccountingPeriodMode mode) {
    switch (mode) {
      case AccountingPeriodMode.day:
        return DateTime(date.year, date.month, date.day);
      case AccountingPeriodMode.year:
        return DateTime(date.year);
      case AccountingPeriodMode.month:
        return DateTime(date.year, date.month);
    }
  }
}
