import 'package:flutter/foundation.dart';

import '../../core/businesses/business_category.dart';

class BusinessCategoryRequiredController extends ChangeNotifier {
  BusinessCategoryOption? _selected;
  bool _saving = false;

  BusinessCategoryOption? get selected => _selected;
  bool get saving => _saving;

  void select(BusinessCategoryOption? value) {
    if (value == _selected) return;
    _selected = value;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (value == _saving) return;
    _saving = value;
    notifyListeners();
  }
}
