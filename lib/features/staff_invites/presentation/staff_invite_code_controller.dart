import 'package:flutter/foundation.dart';
import 'package:rxpro_mobile/features/staff_invites/staff_invite_service.dart';

class StaffInviteCodeController extends ChangeNotifier {
  bool _loading = false;
  bool _statusLoading = true;
  bool _initialStatusLoaded = false;
  StaffInviteAcceptResult? _result;
  StaffLinkedAccountSummary? _linked;

  bool get loading => _loading;
  bool get statusLoading => _statusLoading;
  bool get initialStatusLoaded => _initialStatusLoaded;
  StaffInviteAcceptResult? get result => _result;
  StaffLinkedAccountSummary? get linked => _linked;

  void beginStatusLoad() {
    _statusLoading = true;
    notifyListeners();
  }

  void applyLinkedStatus(StaffLinkedAccountSummary? linked) {
    _linked = linked;
    _initialStatusLoaded = true;
    notifyListeners();
  }

  void finishStatusLoad() {
    if (!_statusLoading) return;
    _statusLoading = false;
    notifyListeners();
  }

  void beginWorkStatusMutation() {
    _statusLoading = true;
    _result = null;
    notifyListeners();
  }

  void beginSubmit() {
    _loading = true;
    _result = null;
    notifyListeners();
  }

  void applyResult(StaffInviteAcceptResult result) {
    _result = result;
    notifyListeners();
  }

  void applyError(String message) {
    _result = StaffInviteAcceptResult(success: false, message: message);
    _initialStatusLoaded = true;
    notifyListeners();
  }

  void finishSubmit() {
    if (!_loading) return;
    _loading = false;
    notifyListeners();
  }
}
