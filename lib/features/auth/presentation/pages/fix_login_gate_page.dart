import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxpro_mobile/app/app_routes.dart';
import 'package:rxpro_mobile/core/app_state/fix_session_gate.dart';
import 'package:rxpro_mobile/core/businesses/business_category.dart';
import 'package:rxpro_mobile/core/models/app_user_model.dart';
import 'package:rxpro_mobile/core/models/auth_status_model.dart';
import 'package:rxpro_mobile/core/models/business_account_model.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';
import 'package:rxpro_mobile/core/services/firestore_service.dart';
import 'package:rxpro_mobile/core/services/app_observability_service.dart';
import 'package:rxpro_mobile/features/auth/data/fix_login_gate_repository.dart';
import 'package:rxpro_mobile/features/auth/presentation/widgets/fix_login_form_widgets.dart';
import 'package:rxpro_mobile/features/auth/presentation/widgets/fix_login_gate_actions.dart';
import 'package:rxpro_mobile/features/auth/presentation/widgets/fix_login_brand.dart';

enum _FixAuthMode { individual, corporate }

enum _FixAuthAction { login, register }

const String _rememberModeKey = 'fix_remember_mode';

const String _individualSavedEmailKey = 'fix_individual_saved_email';
const String _corporateSavedEmailKey = 'fix_corporate_saved_email';
const String _individualRememberPasswordKey =
    'fix_individual_remember_password';
const String _corporateRememberPasswordKey = 'fix_corporate_remember_password';
const String _individualSecurePasswordKey = 'fix_individual_secure_password';
const String _corporateSecurePasswordKey = 'fix_corporate_secure_password';

const FlutterSecureStorage _fixSecureStorage = FlutterSecureStorage();

/// 50C-G1: Login/signup behavior is unchanged.
class FixLoginGatePage extends StatefulWidget {
  const FixLoginGatePage({super.key, this.startCorporate = false});

  final bool startCorporate;

  @override
  State<FixLoginGatePage> createState() => _FixLoginGatePageState();
}

class _FixLoginGatePageState extends State<FixLoginGatePage> {
  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();
  final FixLoginGateRepository _loginGateRepository = FixLoginGateRepository();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final fullNameController = TextEditingController();
  final corporateNameController = TextEditingController();
  final corporateOwnerController = TextEditingController();
  final cityController = TextEditingController();
  final districtController = TextEditingController();
  final corporateAddressController = TextEditingController();

  _FixAuthMode mode = _FixAuthMode.individual;
  _FixAuthAction action = _FixAuthAction.login;
  BusinessCategoryOption selectedCategory = BusinessCategories.values.first;

  bool obscure = true;
  bool loading = false;
  bool rememberMe = false;
  bool legalAccepted = false;

  bool get isCorporate => mode == _FixAuthMode.corporate;
  bool get isRegister => action == _FixAuthAction.register;
  String get modeLabel => isCorporate ? 'Kurumsal' : 'Bireysel';

  @override
  void initState() {
    super.initState();
    if (widget.startCorporate) {
      mode = _FixAuthMode.corporate;
    }
    _loadRememberedLogin();
  }

  Future<void> _loadRememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final rememberedMode = prefs.getString(_rememberModeKey) ?? '';

    if (!mounted) return;

    if (rememberedMode == 'corporate') {
      mode = _FixAuthMode.corporate;
    } else if (rememberedMode == 'individual') {
      mode = _FixAuthMode.individual;
    } else if (widget.startCorporate) {
      mode = _FixAuthMode.corporate;
    }

    await _applySavedCredentialsForMode(mode);
  }

  Future<void> _changeMode(_FixAuthMode value) async {
    if (loading || mode == value) return;

    setState(() {
      mode = value;
      action = _FixAuthAction.login;
      emailController.clear();
      passwordController.clear();
      cityController.clear();
      districtController.clear();
      rememberMe = false;
    });

    await _applySavedCredentialsForMode(value);
  }

  Future<void> _applySavedCredentialsForMode(_FixAuthMode targetMode) async {
    final prefs = await SharedPreferences.getInstance();
    final targetCorporate = targetMode == _FixAuthMode.corporate;

    final emailKey = targetCorporate
        ? _corporateSavedEmailKey
        : _individualSavedEmailKey;
    final rememberPasswordKey = targetCorporate
        ? _corporateRememberPasswordKey
        : _individualRememberPasswordKey;
    final securePasswordKey = targetCorporate
        ? _corporateSecurePasswordKey
        : _individualSecurePasswordKey;

    final savedEmail = prefs.getString(emailKey) ?? '';
    final shouldRememberPassword = prefs.getBool(rememberPasswordKey) ?? false;
    final savedPassword = shouldRememberPassword
        ? await _safeReadRememberedPassword(
            prefs: prefs,
            rememberPasswordKey: rememberPasswordKey,
            securePasswordKey: securePasswordKey,
          )
        : '';
    final rememberPassword = shouldRememberPassword && savedPassword.isNotEmpty;

    if (!mounted) return;

    setState(() {
      emailController.text = savedEmail;
      rememberMe = rememberPassword;
      passwordController.text = savedPassword;
    });
  }

  Future<String> _safeReadRememberedPassword({
    required SharedPreferences prefs,
    required String rememberPasswordKey,
    required String securePasswordKey,
  }) async {
    try {
      return await _fixSecureStorage.read(key: securePasswordKey) ?? '';
    } catch (error) {
      await prefs.setBool(rememberPasswordKey, false);
      try {
        await _fixSecureStorage.delete(key: securePasswordKey);
      } catch (_) {
        // If Android Keystore data is corrupted, reading and deleting can both fail.
      }
      debugPrint('FIX_REMEMBERED_PASSWORD_RESET $error');
      return '';
    }
  }

  Future<void> _saveRememberedLogin(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCorporate = isCorporate;

    final emailKey = currentCorporate
        ? _corporateSavedEmailKey
        : _individualSavedEmailKey;
    final rememberPasswordKey = currentCorporate
        ? _corporateRememberPasswordKey
        : _individualRememberPasswordKey;
    final securePasswordKey = currentCorporate
        ? _corporateSecurePasswordKey
        : _individualSecurePasswordKey;

    await prefs.setString(
      _rememberModeKey,
      currentCorporate ? 'corporate' : 'individual',
    );

    // E-posta başarılı giriş/kayıt sonrasında role-specific otomatik tutulur.
    await prefs.setString(emailKey, email);

    // Checkbox yalnızca şifreyi güvenli depolamada saklamak içindir.
    if (rememberMe) {
      await prefs.setBool(rememberPasswordKey, true);
      await _fixSecureStorage.write(
        key: securePasswordKey,
        value: passwordController.text,
      );
    } else {
      await prefs.setBool(rememberPasswordKey, false);
      await _fixSecureStorage.delete(key: securePasswordKey);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    fullNameController.dispose();
    corporateNameController.dispose();
    corporateOwnerController.dispose();
    cityController.dispose();
    districtController.dispose();
    corporateAddressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (loading) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = _normalizeTurkishPhone(phoneController.text.trim());

    if (email.isEmpty || password.length < 6) {
      _showMessage('E-posta ve en az 6 haneli şifre zorunludur.');
      return;
    }

    if (isRegister && phone.isEmpty) {
      _showMessage('Kayıt için geçerli GSM numarası zorunludur.');
      return;
    }

    if (isRegister && !legalAccepted) {
      _showMessage(
        'Devam etmek için yasal metinleri ve veri işleme bilgilendirmesini onaylamalısınız.',
      );
      return;
    }

    if (isRegister && !isCorporate && fullNameController.text.trim().isEmpty) {
      _showMessage('Bireysel kayıt için ad soyad zorunludur.');
      return;
    }

    if (isRegister && isCorporate) {
      if (corporateNameController.text.trim().isEmpty ||
          corporateOwnerController.text.trim().isEmpty) {
        _showMessage(
          'Kurumsal kayıt için kurum adı ve yetkili kişi zorunludur.',
        );
        return;
      }
    }

    setState(() => loading = true);

    try {
      UserCredential credential;

      if (isRegister) {
        credential = await authService.registerWithEmail(
          email: email,
          password: password,
        );
      } else {
        credential = await authService.signInWithEmail(
          email: email,
          password: password,
        );
      }

      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase kullanıcısı alınamadı.');
      }

      if (isCorporate) {
        await _completeCorporateAuth(user: user, email: email, phone: phone);
      } else {
        await _completeIndividualAuth(user: user, email: email, phone: phone);
      }

      await _saveRememberedLogin(email);
      await user.reload();
      await authService.currentUser?.getIdToken(true);

      if (!mounted) return;

      FixSessionGate.refreshAfterAuthChange();

      _showMessage(
        isRegister
            ? '$modeLabel kayıt tamamlandı.'
            : '$modeLabel giriş başarılı.',
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      _showMessage(_firebaseErrorText(e));
    } catch (e) {
      _showMessage('İşlem başarısız: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _completeIndividualAuth({
    required User user,
    required String email,
    required String phone,
  }) async {
    final displayName = isRegister
        ? fullNameController.text.trim()
        : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Bireysel Kullanıcı');

    await user.updateDisplayName(displayName);

    await firestoreService.saveUser(
      AppUserModel(
        uid: user.uid,
        email: email,
        phone: phone.isEmpty ? phoneController.text.trim() : phone,
        displayName: displayName,
        role: UserRole.customer,
        accountStatus: AccountStatus.active,
        emailVerified: user.emailVerified,
        phoneVerified: phone.isNotEmpty,
      ),
    );

    // Bireysel kullanıcı rolü kesin yazılır; eski kurumsal alanlar temizlenir.
    await _loginGateRepository.ensureIndividualUserDocument(
      user: user,
      email: email,
      phone: phone.isEmpty ? phoneController.text.trim() : phone,
      displayName: displayName,
      city: cityController.text,
      district: districtController.text,
      phoneVerified: phone.isNotEmpty,
      recordLegalAcceptance: isRegister,
    );

    if (isRegister) {
      unawaited(
        AppObservabilityService.instance.logRegistrationCompleted(
          accountType: 'individual',
        ),
      );
    }
  }

  Future<void> _completeCorporateAuth({
    required User user,
    required String email,
    required String phone,
  }) async {
    final ownerName = isRegister
        ? corporateOwnerController.text.trim()
        : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Kurumsal Yetkili');

    await user.updateDisplayName(ownerName);

    final finalPhone = phone.isEmpty ? phoneController.text.trim() : phone;
    final businessContext = await _resolveCorporateBusinessContext(user);
    final businessId = isRegister
        ? 'business_${user.uid}'
        : businessContext['businessId']!;
    final businessName = isRegister
        ? corporateNameController.text.trim()
        : businessContext['businessName']!;

    await firestoreService.saveUser(
      AppUserModel(
        uid: user.uid,
        email: email,
        phone: finalPhone,
        displayName: ownerName,
        role: UserRole.businessOwner,
        accountStatus: AccountStatus.active,
        emailVerified: user.emailVerified,
        phoneVerified: phone.isNotEmpty,
      ),
    );

    if (isRegister) {
      final address = corporateAddressController.text.trim();

      await firestoreService.saveBusiness(
        BusinessAccountModel(
          id: businessId,
          ownerUid: user.uid,
          businessName: businessName,
          category: selectedCategory.label,
          phone: finalPhone,
          address: address.isEmpty
              ? 'Adres bilgisi daha sonra tamamlanacak'
              : address,
          businessStatus: BusinessStatus.active,
          ownerEmailVerified: user.emailVerified,
          ownerPhoneVerified: phone.isNotEmpty,
          adminApproved: true,
        ),
      );

      await _loginGateRepository.ensureCorporateBusinessDocument(
        user: user,
        businessId: businessId,
        businessName: businessName,
        city: cityController.text,
        district: districtController.text,
        categoryData: selectedCategory.toFirestore(),
      );
    }

    // Kurumsal rol kesin yazılır; AppGate artık bu alanlara göre shell seçer.
    await _loginGateRepository.ensureCorporateOwnerUserDocument(
      user: user,
      email: email,
      phone: phone.isEmpty ? phoneController.text.trim() : phone,
      businessId: businessId,
      businessName: businessName,
      ownerName: ownerName,
      city: cityController.text,
      district: districtController.text,
      phoneVerified: phone.isNotEmpty,
      recordLegalAcceptance: isRegister,
    );

    if (isRegister) {
      unawaited(
        AppObservabilityService.instance.logRegistrationCompleted(
          accountType: 'corporate',
        ),
      );
    }
  }

  Future<Map<String, String>> _resolveCorporateBusinessContext(
    User user,
  ) async {
    final context = await _loginGateRepository.resolveCorporateBusinessContext(
      user: user,
      fallbackBusinessName: corporateNameController.text.trim(),
    );

    return <String, String>{
      'businessId': context.businessId,
      'businessName': context.businessName,
    };
  }

  void _continueAsGuest() {
    FixSessionGate.continueAsGuest();
  }

  void _showForgotPassword() {
    Navigator.of(context).pushNamed(AppRoutes.phonePasswordReset);
  }

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  String _normalizeTurkishPhone(String raw) {
    var value = raw.trim();

    value = value
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');

    if (value.startsWith('+90') && value.length == 13) return value;
    if (value.startsWith('90') && value.length == 12) return '+$value';
    if (value.startsWith('0') && value.length == 11) {
      return '+90${value.substring(1)}';
    }
    if (value.length == 10 && value.startsWith('5')) return '+90$value';

    return '';
  }

  String _firebaseErrorText(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Bu e-posta zaten kayıtlı. Giriş sekmesinden devam edin.';
      case 'invalid-email':
        return 'E-posta formatı geçersiz.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'user-not-found':
        return 'Bu e-posta ile kayıt bulunamadı. Kaydol sekmesini kullanın.';
      case 'network-request-failed':
        return 'İnternet bağlantısı veya Firebase erişimi başarısız.';
      case 'operation-not-allowed':
        return 'Firebase Console’da Email/Password giriş yöntemi açık değil.';
      default:
        return e.message ?? 'Firebase Auth hatası: ${e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            22,
            20,
            22,
            18 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            const FixLoginBrandArea(),
            const SizedBox(height: 22),
            FixSegmentedTabs<_FixAuthMode>(
              value: mode,
              onChanged: loading ? null : _changeMode,
              options: const [
                FixSegmentedOption(
                  value: _FixAuthMode.individual,
                  label: 'Bireysel',
                  icon: Icons.person_outline_rounded,
                ),
                FixSegmentedOption(
                  value: _FixAuthMode.corporate,
                  label: 'Kurumsal',
                  icon: Icons.storefront_outlined,
                ),
              ],
            ),
            const SizedBox(height: 14),
            FixSegmentedTabs<_FixAuthAction>(
              value: action,
              compact: true,
              onChanged: loading
                  ? null
                  : (value) => setState(() {
                      action = value;
                      if (value == _FixAuthAction.login) {
                        legalAccepted = false;
                      }
                    }),
              options: const [
                FixSegmentedOption(
                  value: _FixAuthAction.login,
                  label: 'Giriş',
                  icon: Icons.login_rounded,
                ),
                FixSegmentedOption(
                  value: _FixAuthAction.register,
                  label: 'Kaydol',
                  icon: Icons.person_add_alt_1_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            FixLoginPanel(
              title: isRegister
                  ? '$modeLabel Hesap Oluştur'
                  : '$modeLabel Giriş Yap',
              subtitle: isCorporate
                  ? 'Kurumsal hesabınızla randevu, kampanya ve operasyon süreçlerini yönetin.'
                  : 'Bireysel hesabınızla kurumsal kullanıcıları keşfedin, randevu alın ve işlemlerinizi takip edin.',
              child: _buildForm(),
            ),
            const SizedBox(height: 16),
            FixLoginGuestActions(
              loading: loading,
              onGuest: _continueAsGuest,
              onForgot: _showForgotPassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isRegister && !isCorporate) ...[
          FixInput(
            controller: fullNameController,
            label: 'Ad Soyad',
            icon: Icons.person_outline_rounded,
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
        ],
        if (isRegister && isCorporate) ...[
          FixInput(
            controller: corporateNameController,
            label: 'Kurum Adı',
            icon: Icons.storefront_outlined,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          FixInput(
            controller: corporateOwnerController,
            label: 'Yetkili Kişi',
            icon: Icons.badge_outlined,
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<BusinessCategoryOption>(
            initialValue: selectedCategory,
            isExpanded: true,
            decoration: fixInputDecoration(
              label: 'Faaliyet Kategorisi',
              icon: Icons.category_outlined,
            ),
            items: BusinessCategories.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(),
            onChanged: loading
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
          ),
          const SizedBox(height: 14),
          FixInput(
            controller: corporateAddressController,
            label: 'Adres / Bölge',
            icon: Icons.location_on_outlined,
            autofillHints: const [AutofillHints.fullStreetAddress],
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
        ],
        if (isRegister) ...[
          FixInput(
            controller: phoneController,
            label: 'GSM',
            hint: '05xx xxx xx xx',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
          const SizedBox(height: 6),
          const Text(
            'Telefon doğrulama altyapısı hazırdır. SMS doğrulama bu aşamada aktif değildir.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6C757D),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FixInput(
                  controller: cityController,
                  label: 'İl',
                  hint: 'İstanbul',
                  icon: Icons.location_city_outlined,
                  autofillHints: const [AutofillHints.addressCity],
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FixInput(
                  controller: districtController,
                  label: 'İlçe',
                  hint: 'Kadıköy',
                  icon: Icons.place_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        FixInput(
          controller: emailController,
          label: 'E-posta',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: passwordController,
          autofillHints: [
            isRegister ? AutofillHints.newPassword : AutofillHints.password,
          ],
          obscureText: obscure,
          decoration:
              fixInputDecoration(
                label: 'Şifre',
                icon: Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
        ),
        const SizedBox(height: 14),
        FixRememberPasswordTile(
          value: rememberMe,
          onChanged: loading
              ? null
              : (value) => setState(() => rememberMe = value ?? false),
        ),
        if (isRegister) ...[
          const SizedBox(height: 10),
          _LegalAcceptanceTile(
            value: legalAccepted,
            isCorporate: isCorporate,
            onChanged: loading
                ? null
                : (value) => setState(() => legalAccepted = value ?? false),
            onOpenLegal: () =>
                Navigator.of(context).pushNamed(AppRoutes.legalDocuments),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isRegister ? '$modeLabel Kaydol' : '$modeLabel Giriş Yap',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _LegalAcceptanceTile extends StatelessWidget {
  const _LegalAcceptanceTile({
    required this.value,
    required this.isCorporate,
    required this.onChanged,
    required this.onOpenLegal,
  });

  final bool value;
  final bool isCorporate;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback onOpenLegal;

  @override
  Widget build(BuildContext context) {
    final scope = isCorporate
        ? 'İşletme kullanım şartlarını, KVKK aydınlatmasını, gizlilik politikasını ve açık rıza bilgilendirmesini okudum.'
        : 'Kullanıcı sözleşmesini, KVKK aydınlatmasını, gizlilik politikasını ve açık rıza bilgilendirmesini okudum.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: value, onChanged: onChanged),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scope,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: onOpenLegal,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Yasal metinleri incele'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
