import 'package:flutter/foundation.dart';

class CustomerCampaignsController<T> extends ChangeNotifier {
  CustomerCampaignsController({required Future<List<T>> Function() load})
    : _load = load {
    _future = _load();
  }

  final Future<List<T>> Function() _load;
  late Future<List<T>> _future;
  int _selectedTab = 0;
  String _selectedCategory = 'T\u00fcm\u00fc';

  Future<List<T>> get future => _future;
  int get selectedTab => _selectedTab;
  String get selectedCategory => _selectedCategory;

  Future<void> refresh() async {
    final next = _load();
    _future = next;
    notifyListeners();
    await next;
  }

  void selectTab(int value) {
    if (value == _selectedTab) return;
    _selectedTab = value;
    notifyListeners();
  }

  void selectCategory(String value) {
    if (value == _selectedCategory) return;
    _selectedCategory = value;
    notifyListeners();
  }
}
