import 'package:flutter/foundation.dart';
import 'package:rxpro_mobile/core/businesses/business_category.dart';

class BusinessProfileEditController extends ChangeNotifier {
  bool _loading = true;
  bool _saving = false;
  bool _uploadingLogo = false;
  bool _uploadingCover = false;
  bool _locatingBusiness = false;
  String? _logoUrl;
  String? _coverUrl;
  double? _businessLat;
  double? _businessLng;
  String _categoryId = BusinessCategories.values.first.id;

  bool get loading => _loading;
  bool get saving => _saving;
  bool get uploadingLogo => _uploadingLogo;
  bool get uploadingCover => _uploadingCover;
  bool get locatingBusiness => _locatingBusiness;
  String? get logoUrl => _logoUrl;
  String? get coverUrl => _coverUrl;
  double? get businessLat => _businessLat;
  double? get businessLng => _businessLng;
  String get categoryId => _categoryId;

  bool get canStartMediaUpload {
    return !_saving && !_uploadingLogo && !_uploadingCover;
  }

  bool get hasLocation => _businessLat != null && _businessLng != null;
  bool get hasLogo => _logoUrl != null && _logoUrl!.isNotEmpty;
  bool get hasCover => _coverUrl != null && _coverUrl!.isNotEmpty;

  void applyLoadedProfile({
    required String categoryId,
    required String? logoUrl,
    required String? coverUrl,
    required double? businessLat,
    required double? businessLng,
  }) {
    _categoryId = categoryId;
    _logoUrl = _emptyToNull(logoUrl);
    _coverUrl = _emptyToNull(coverUrl);
    _businessLat = businessLat;
    _businessLng = businessLng;
    _loading = false;
    notifyListeners();
  }

  void finishLoading() {
    if (!_loading) return;
    _loading = false;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    _saving = value;
    notifyListeners();
  }

  void setLogoUploading(bool value) {
    if (_uploadingLogo == value) return;
    _uploadingLogo = value;
    notifyListeners();
  }

  void setCoverUploading(bool value) {
    if (_uploadingCover == value) return;
    _uploadingCover = value;
    notifyListeners();
  }

  void applyLogoUrl(String value) {
    _logoUrl = _emptyToNull(value);
    _uploadingLogo = false;
    notifyListeners();
  }

  void applyCoverUrl(String value) {
    _coverUrl = _emptyToNull(value);
    _uploadingCover = false;
    notifyListeners();
  }

  void setLocatingBusiness(bool value) {
    if (_locatingBusiness == value) return;
    _locatingBusiness = value;
    notifyListeners();
  }

  void applyLocation({required double latitude, required double longitude}) {
    _businessLat = latitude;
    _businessLng = longitude;
    notifyListeners();
  }

  void setCategoryId(String value) {
    if (_categoryId == value) return;
    _categoryId = value;
    notifyListeners();
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
