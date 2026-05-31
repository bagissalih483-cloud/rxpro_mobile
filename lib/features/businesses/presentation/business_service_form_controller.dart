import 'package:flutter/foundation.dart';

import '../domain/business_service_form_policy.dart';

class BusinessServiceFormController extends ChangeNotifier {
  BusinessServiceFormController({Map<String, dynamic> initialData = const {}})
    : _type = BusinessServiceFormPolicy.typeOf(initialData),
      _active = BusinessServiceFormPolicy.isActive(initialData);

  String _type;
  bool _active;
  bool _saving = false;

  String get type => _type;
  bool get active => _active;
  bool get saving => _saving;

  void selectType(String value) {
    if (_type == value) return;
    _type = value;
    notifyListeners();
  }

  void setActive(bool value) {
    if (_active == value) return;
    _active = value;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    _saving = value;
    notifyListeners();
  }
}
