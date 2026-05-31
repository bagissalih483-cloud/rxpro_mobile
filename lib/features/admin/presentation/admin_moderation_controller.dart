import 'package:flutter/foundation.dart';

class AdminModerationController extends ChangeNotifier {
  String _query = '';
  String _statusFilter = 'all';

  String get query => _query;
  String get statusFilter => _statusFilter;

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void setStatusFilter(String value) {
    if (value == _statusFilter) return;
    _statusFilter = value;
    notifyListeners();
  }
}
