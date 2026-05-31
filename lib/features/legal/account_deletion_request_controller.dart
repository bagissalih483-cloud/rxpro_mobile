import 'package:flutter/foundation.dart';

class AccountDeletionRequestController extends ChangeNotifier {
  bool _confirmed = false;
  bool _submitting = false;

  bool get confirmed => _confirmed;
  bool get submitting => _submitting;
  bool get canSubmit => _confirmed && !_submitting;

  void setConfirmed(bool value) {
    if (value == _confirmed) return;
    _confirmed = value;
    notifyListeners();
  }

  void setSubmitting(bool value) {
    if (value == _submitting) return;
    _submitting = value;
    notifyListeners();
  }
}
