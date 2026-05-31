import 'package:flutter/foundation.dart';

class MainShellController extends ChangeNotifier {
  MainShellController(int initialIndex) : _selectedIndex = initialIndex;

  int _selectedIndex;

  int get selectedIndex => _selectedIndex;

  void selectIndex(int index) {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }
}
