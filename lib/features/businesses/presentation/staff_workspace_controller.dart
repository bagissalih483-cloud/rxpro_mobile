import 'package:flutter/foundation.dart';

class StaffWorkspaceController extends ChangeNotifier {
  StaffWorkspaceController({Set<int>? initialExpanded})
    : _expanded = {...?initialExpanded};

  final Set<int> _expanded;

  bool isExpanded(int index) => _expanded.contains(index);

  void toggle(int index) {
    if (_expanded.contains(index)) {
      _expanded.remove(index);
    } else {
      _expanded.add(index);
    }
    notifyListeners();
  }
}
