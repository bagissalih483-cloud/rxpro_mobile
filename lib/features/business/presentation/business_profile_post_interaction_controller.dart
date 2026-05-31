import 'package:flutter/foundation.dart';

class BusinessProfilePostInteractionController extends ChangeNotifier {
  bool _busy = false;

  bool get busy => _busy;

  bool beginAction() {
    if (_busy) return false;
    _busy = true;
    notifyListeners();
    return true;
  }

  void finishAction() {
    if (!_busy) return;
    _busy = false;
    notifyListeners();
  }
}
