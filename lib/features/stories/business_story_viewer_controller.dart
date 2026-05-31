import 'package:flutter/foundation.dart';

class BusinessStoryViewerController extends ChangeNotifier {
  BusinessStoryViewerController({required int initialIndex})
    : _index = initialIndex;

  int _index;

  int get index => _index;

  void setIndex(int value) {
    if (value == _index) return;
    _index = value;
    notifyListeners();
  }
}
