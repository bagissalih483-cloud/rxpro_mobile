import 'package:flutter/foundation.dart';

class AccountingReportsController extends ChangeNotifier {
  String _reportType = 'summary';

  String get reportType => _reportType;

  void setReportType(String value) {
    if (value == _reportType) return;
    _reportType = value;
    notifyListeners();
  }
}
