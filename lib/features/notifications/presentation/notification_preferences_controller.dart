import 'package:flutter/foundation.dart';

class NotificationPreferencesController extends ChangeNotifier {
  String _savingKey = '';

  String get savingKey => _savingKey;

  void setSavingKey(String value) {
    if (value == _savingKey) return;
    _savingKey = value;
    notifyListeners();
  }
}
