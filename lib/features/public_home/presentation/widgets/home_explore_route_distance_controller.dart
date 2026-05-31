import 'package:flutter/foundation.dart';
import 'package:rxpro_mobile/core/businesses/business_route_distance_service.dart';

class HomeExploreRouteDistanceController extends ChangeNotifier {
  BusinessRouteInfo? _info;
  bool _loading = false;
  bool _attempted = false;
  String _activeKey = '';

  BusinessRouteInfo? get info => _info;
  bool get loading => _loading;
  bool get attempted => _attempted;
  String get activeKey => _activeKey;

  void resetForKey(String key) {
    if (key == _activeKey) return;
    _info = null;
    _loading = false;
    _attempted = false;
    _activeKey = '';
    notifyListeners();
  }

  bool beginAttempt(String key) {
    if (_loading || _attempted) return false;
    _activeKey = key;
    _attempted = true;
    _loading = true;
    notifyListeners();
    return true;
  }

  void markSkipped() {
    if (!_loading) return;
    _loading = false;
    notifyListeners();
  }

  void complete(BusinessRouteInfo? info) {
    _info = info;
    _loading = false;
    notifyListeners();
  }
}
