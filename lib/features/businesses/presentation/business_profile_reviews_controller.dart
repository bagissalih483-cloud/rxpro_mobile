import 'package:flutter/foundation.dart';

class BusinessProfileReviewsController extends ChangeNotifier {
  int _selectedRating = 5;
  bool _sending = false;

  int get selectedRating => _selectedRating;
  bool get sending => _sending;

  void selectRating(int value) {
    final safeValue = value.clamp(1, 5).toInt();
    if (_selectedRating == safeValue) return;
    _selectedRating = safeValue;
    notifyListeners();
  }

  void setSending(bool value) {
    if (_sending == value) return;
    _sending = value;
    notifyListeners();
  }
}

class BusinessProfileFollowController extends ChangeNotifier {
  bool _following = false;
  bool _busy = false;

  bool get following => _following;
  bool get busy => _busy;

  void applyFollowing(bool value) {
    if (_following == value) return;
    _following = value;
    notifyListeners();
  }

  void startToggle(bool value) {
    _following = value;
    _busy = true;
    notifyListeners();
  }

  void setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }
}
