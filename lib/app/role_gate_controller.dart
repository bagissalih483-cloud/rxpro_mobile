import 'package:flutter/foundation.dart';

class RoleGateController extends ChangeNotifier {
  bool _allowRoleRepair = false;
  bool _startupTimedOut = false;

  bool get allowRoleRepair => _allowRoleRepair;
  bool get startupTimedOut => _startupTimedOut;

  void setAllowRoleRepair(bool value, {bool notify = true}) {
    if (value == _allowRoleRepair) return;
    _allowRoleRepair = value;
    if (notify) notifyListeners();
  }

  void setStartupTimedOut(bool value, {bool notify = true}) {
    if (value == _startupTimedOut) return;
    _startupTimedOut = value;
    if (notify) notifyListeners();
  }

  void requestRefresh() {
    notifyListeners();
  }
}
