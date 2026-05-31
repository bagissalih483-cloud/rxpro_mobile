import 'package:flutter/foundation.dart';

import '../data/business_products_repository.dart';
import '../domain/business_product_policy.dart';

class BusinessProductsController extends ChangeNotifier {
  BusinessProductsController({
    required Future<BusinessProductContext> Function() loadContext,
  }) : _loadContext = loadContext {
    _contextFuture = _loadContext();
  }

  final Future<BusinessProductContext> Function() _loadContext;
  late Future<BusinessProductContext> _contextFuture;

  Future<BusinessProductContext> get contextFuture => _contextFuture;

  void refreshContext() {
    _contextFuture = _loadContext();
    notifyListeners();
  }
}

class BusinessProductFormController extends ChangeNotifier {
  BusinessProductFormController({Map<String, dynamic>? initialData}) {
    if (initialData != null) {
      _category = BusinessProductPolicy.categoryOf(initialData);
      _isPublic = BusinessProductPolicy.isPublic(initialData);
      _isActive = BusinessProductPolicy.isActive(initialData);
    }
  }

  String _category = 'Genel';
  bool _isPublic = false;
  bool _isActive = true;
  bool _saving = false;

  String get category => _category;
  bool get isPublic => _isPublic;
  bool get isActive => _isActive;
  bool get saving => _saving;

  void selectCategory(String value) {
    final next = value.trim().isEmpty ? 'Genel' : value.trim();
    if (_category == next) return;
    _category = next;
    notifyListeners();
  }

  void setPublic(bool value) {
    if (_isPublic == value) return;
    _isPublic = value;
    notifyListeners();
  }

  void setActive(bool value) {
    if (_isActive == value) return;
    _isActive = value;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    _saving = value;
    notifyListeners();
  }
}
