import 'package:flutter/foundation.dart';

class CustomerAppointmentsController extends ChangeNotifier {
  int _selectedTab = 0;
  int _refreshVersion = 0;

  int get selectedTab => _selectedTab;
  int get refreshVersion => _refreshVersion;

  void selectTab(int value) {
    if (value == _selectedTab) return;
    _selectedTab = value;
    notifyListeners();
  }

  Future<void> refresh() async {
    _refreshVersion += 1;
    notifyListeners();
  }
}
