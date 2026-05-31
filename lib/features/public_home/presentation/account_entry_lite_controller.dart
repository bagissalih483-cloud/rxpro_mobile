import 'package:flutter/foundation.dart';
import 'package:rxpro_mobile/features/public_home/data/account_user_profile_repository.dart';

class AccountUserProfileLiteController extends ChangeNotifier {
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String _email = '';
  String _photoUrl = '';

  bool get loading => _loading;
  bool get saving => _saving;
  bool get uploadingAvatar => _uploadingAvatar;
  String get email => _email;
  String get photoUrl => _photoUrl;

  void applyLoaded(AccountUserProfileData data) {
    _email = data.email;
    _photoUrl = data.photoUrl;
    _loading = false;
    notifyListeners();
  }

  void completeLoading() {
    if (!_loading) return;
    _loading = false;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    _saving = value;
    notifyListeners();
  }

  void setUploadingAvatar(bool value) {
    if (_uploadingAvatar == value) return;
    _uploadingAvatar = value;
    notifyListeners();
  }

  void applyAvatarUrl(String value) {
    _photoUrl = value.trim();
    _uploadingAvatar = false;
    notifyListeners();
  }
}

class AccountAppSettingsLiteController extends ChangeNotifier {
  bool _loading = true;
  bool _notifications = true;
  bool _campaigns = true;
  bool _routeDistance = true;

  bool get loading => _loading;
  bool get notifications => _notifications;
  bool get campaigns => _campaigns;
  bool get routeDistance => _routeDistance;

  void applyLoaded({
    required bool notifications,
    required bool campaigns,
    required bool routeDistance,
  }) {
    _notifications = notifications;
    _campaigns = campaigns;
    _routeDistance = routeDistance;
    _loading = false;
    notifyListeners();
  }

  void setNotifications(bool value) {
    if (_notifications == value) return;
    _notifications = value;
    notifyListeners();
  }

  void setCampaigns(bool value) {
    if (_campaigns == value) return;
    _campaigns = value;
    notifyListeners();
  }

  void setRouteDistance(bool value) {
    if (_routeDistance == value) return;
    _routeDistance = value;
    notifyListeners();
  }
}
