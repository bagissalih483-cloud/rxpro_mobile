import 'package:flutter/foundation.dart';

class AccountingOverviewPanelController extends ChangeNotifier {
  bool _summaryExpanded = false;

  bool get summaryExpanded => _summaryExpanded;

  void toggleSummary() {
    _summaryExpanded = !_summaryExpanded;
    notifyListeners();
  }
}
