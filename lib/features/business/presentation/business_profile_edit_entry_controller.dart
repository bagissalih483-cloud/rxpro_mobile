import 'package:flutter/foundation.dart';

class BusinessProfileEditEntryController extends ChangeNotifier {
  bool _loading = true;
  String? _businessId;
  String? _errorMessage;

  bool get loading => _loading;
  String? get businessId => _businessId;
  String? get errorMessage => _errorMessage;

  void setNeedsLogin() {
    _loading = false;
    _businessId = null;
    _errorMessage = 'Kurumsal profili düzenlemek için giriş yapmalısınız.';
    notifyListeners();
  }

  void setResolvedBusiness(String? businessId) {
    _loading = false;
    _businessId = businessId;
    _errorMessage = businessId == null
        ? 'Bu hesaba bağlı kurumsal kayıt otomatik bulunamadı.'
        : null;
    notifyListeners();
  }

  void setLookupError(Object error) {
    _loading = false;
    _businessId = null;
    _errorMessage = 'Kurumsal kayıt aranırken hata oluştu: $error';
    notifyListeners();
  }
}
