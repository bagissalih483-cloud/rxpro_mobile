import 'package:flutter/foundation.dart';

class BusinessProfileController extends ChangeNotifier {
  int _selectedTab = 0;

  int get selectedTab => _selectedTab;

  void selectTab(int index) {
    if (index == _selectedTab) return;
    _selectedTab = index;
    notifyListeners();
  }
}
