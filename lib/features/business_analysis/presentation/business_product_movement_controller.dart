import 'package:flutter/foundation.dart';

import '../business_product_movement_models.dart';

class BusinessProductMovementController extends ChangeNotifier {
  int _mode = 0;
  bool _saving = false;
  String _productName = '';

  int get mode => _mode;
  bool get saving => _saving;

  bool get canSave => _productName.trim().isNotEmpty && !_saving;

  BusinessProductMovementType get movementType {
    return _mode == 0
        ? BusinessProductMovementType.sale
        : BusinessProductMovementType.purchase;
  }

  String get formTitle {
    return _mode == 0 ? 'Ürün Satışı Kaydet' : 'Ürün Alımı Kaydet';
  }

  String get recentTitle {
    return _mode == 0 ? 'Son Ürün Satışları' : 'Son Ürün Alımları';
  }

  String get successMessage {
    return _mode == 0 ? 'Ürün satışı kaydedildi.' : 'Ürün alımı kaydedildi.';
  }

  void selectMode(int value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }

  void setProductName(String value) {
    if (_productName == value) return;
    _productName = value;
    notifyListeners();
  }

  void clearProductName() {
    if (_productName.isEmpty) return;
    _productName = '';
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    _saving = value;
    notifyListeners();
  }
}
