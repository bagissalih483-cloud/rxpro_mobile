import 'package:flutter/foundation.dart';

class BusinessCustomerDirectMessageController extends ChangeNotifier {
  bool _sending = false;

  bool get sending => _sending;

  void setSending(bool value) {
    if (value == _sending) return;
    _sending = value;
    notifyListeners();
  }
}
