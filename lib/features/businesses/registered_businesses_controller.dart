import 'package:flutter/foundation.dart';

class RegisteredBusinessesController<T> extends ChangeNotifier {
  RegisteredBusinessesController({required Future<List<T>> Function() load})
    : _load = load {
    _future = _load();
  }

  final Future<List<T>> Function() _load;
  late Future<List<T>> _future;
  bool _openingStaff = false;

  Future<List<T>> get future => _future;
  bool get openingStaff => _openingStaff;

  Future<void> refresh() async {
    final next = _load();
    _future = next;
    notifyListeners();
    await next;
  }

  void setOpeningStaff(bool value) {
    if (value == _openingStaff) return;
    _openingStaff = value;
    notifyListeners();
  }
}
