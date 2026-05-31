import 'package:flutter/foundation.dart';

class PhonePasswordResetFlowController extends ChangeNotifier {
  int _step = 0;
  bool _obscure = true;

  int get step => _step;
  bool get obscure => _obscure;

  void goToCodeStep() {
    _setStep(1);
  }

  void goToPasswordStep() {
    _setStep(2);
  }

  void toggleObscure() {
    _obscure = !_obscure;
    notifyListeners();
  }

  void _setStep(int value) {
    if (value == _step) return;
    _step = value.clamp(0, 2).toInt();
    notifyListeners();
  }
}
