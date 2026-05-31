import 'package:flutter/foundation.dart';

class FixBootstrapController extends ChangeNotifier {
  Future<void>? _bootstrapFuture;
  String _bootstrapMessage = 'fix baslatiliyor...';

  Future<void>? get bootstrapFuture => _bootstrapFuture;
  String get bootstrapMessage => _bootstrapMessage;

  void setBootstrapFuture(Future<void> future) {
    _bootstrapFuture = future;
    notifyListeners();
  }

  void setBootstrapMessage(String message) {
    if (message == _bootstrapMessage) return;
    _bootstrapMessage = message;
    notifyListeners();
  }
}
