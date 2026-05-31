import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/businesses/business_category.dart';

enum FixAuthMode { individual, corporate }

enum FixAuthAction { login, register }

class FixLoginGateController extends ChangeNotifier {
  FixAuthMode mode = FixAuthMode.individual;
  FixAuthAction action = FixAuthAction.login;
  BusinessCategoryOption selectedCategory = BusinessCategories.values.first;
  bool obscure = true;
  bool loading = false;
  bool rememberMe = false;
  bool legalAccepted = false;
  bool smsCodeSent = false;
  bool noticeIsError = true;
  bool googleTemporarilyUnavailable = false;
  String verificationId = '';
  String pendingPhone = '';
  String? noticeText;
  int? resendToken;

  bool get isCorporate => mode == FixAuthMode.corporate;
  bool get isRegister => action == FixAuthAction.register;
  String get modeLabel => isCorporate ? 'Kurumsal' : 'Bireysel';

  void applyInitialMode(FixAuthMode value) {
    mode = value;
  }

  void applyRememberedMode(FixAuthMode value) {
    if (mode == value) return;
    mode = value;
    notifyListeners();
  }

  void changeMode(FixAuthMode value) {
    if (mode == value) return;
    mode = value;
    action = FixAuthAction.login;
    rememberMe = false;
    notifyListeners();
  }

  void applySavedCredentials({required bool rememberPassword}) {
    rememberMe = rememberPassword;
    notifyListeners();
  }

  void setLoading(bool value) {
    if (loading == value) return;
    loading = value;
    notifyListeners();
  }

  void setAction(FixAuthAction value) {
    if (action == value) return;
    action = value;
    if (value == FixAuthAction.login) {
      legalAccepted = false;
    }
    notifyListeners();
  }

  void setSelectedCategory(BusinessCategoryOption value) {
    if (selectedCategory == value) return;
    selectedCategory = value;
    notifyListeners();
  }

  void toggleObscure() {
    obscure = !obscure;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    if (rememberMe == value) return;
    rememberMe = value;
    notifyListeners();
  }

  void setLegalAccepted(bool value) {
    if (legalAccepted == value) return;
    legalAccepted = value;
    notifyListeners();
  }

  void setSmsCodeSent({
    required String verificationId,
    required String phone,
    int? resendToken,
  }) {
    smsCodeSent = true;
    this.verificationId = verificationId;
    pendingPhone = phone;
    this.resendToken = resendToken;
    notifyListeners();
  }

  void resetSmsVerification() {
    smsCodeSent = false;
    verificationId = '';
    pendingPhone = '';
    resendToken = null;
    notifyListeners();
  }

  void setNotice(String text, {required bool isError}) {
    noticeText = text;
    noticeIsError = isError;
    notifyListeners();
  }

  void clearNotice() {
    if (noticeText == null && noticeIsError) return;
    noticeText = null;
    noticeIsError = true;
    notifyListeners();
  }

  void markGoogleTemporarilyUnavailable() {
    if (googleTemporarilyUnavailable) return;
    googleTemporarilyUnavailable = true;
    notifyListeners();
  }
}
