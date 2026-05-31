import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
import 'package:rxpro_mobile/features/auth/presentation/controllers/fix_login_gate_controller.dart';
import 'package:rxpro_mobile/features/auth/presentation/controllers/fix_login_remembered_credentials_store.dart';
import 'package:rxpro_mobile/features/auth/presentation/widgets/fix_login_form_widgets.dart';
import 'package:rxpro_mobile/features/auth/presentation/widgets/fix_login_gate_actions.dart';
import 'package:rxpro_mobile/features/auth/presentation/widgets/fix_login_brand.dart';
part 'fix_login_gate_auth_part.dart';
part 'fix_login_gate_google_auth_part.dart';
part 'fix_login_gate_phone_auth_part.dart';
part 'fix_login_gate_completion_part.dart';
part 'fix_login_gate_message_utils_part.dart';
part 'fix_login_gate_layout_part.dart';

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
  final FixLoginRememberedCredentialsStore _rememberedCredentialsStore =
      const FixLoginRememberedCredentialsStore();
  final FixLoginGateController _controller = FixLoginGateController();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final smsCodeController = TextEditingController();
  final fullNameController = TextEditingController();
  final corporateNameController = TextEditingController();
  final corporateOwnerController = TextEditingController();
  final cityController = TextEditingController();
  final districtController = TextEditingController();
  final corporateAddressController = TextEditingController();

  bool get isCorporate => _controller.isCorporate;
  bool get isRegister => _controller.isRegister;
  String get modeLabel => _controller.modeLabel;

  @override
  void initState() {
    super.initState();
    if (widget.startCorporate) {
      _controller.applyInitialMode(FixAuthMode.corporate);
    }
    _loadRememberedLogin();
  }

  Future<void> _loadRememberedLogin() async {
    final targetMode = await _rememberedCredentialsStore.resolveInitialMode(
      startCorporate: widget.startCorporate,
      fallback: _controller.mode,
    );

    if (!mounted) return;
    _controller.applyRememberedMode(targetMode);
    await _applySavedCredentialsForMode(targetMode);
  }

  Future<void> _changeMode(FixAuthMode value) async {
    if (_controller.loading || _controller.mode == value) return;

    _controller.changeMode(value);
    _clearNotice();
    emailController.clear();
    passwordController.clear();
    smsCodeController.clear();
    cityController.clear();
    districtController.clear();
    _controller.resetSmsVerification();

    await _applySavedCredentialsForMode(value);
  }

  void _changeAction(FixAuthAction value) {
    if (_controller.loading) return;
    _clearNotice();
    _controller.setAction(value);
  }

  Future<void> _applySavedCredentialsForMode(FixAuthMode targetMode) async {
    final saved = await _rememberedCredentialsStore.loadForMode(targetMode);

    if (!mounted) return;

    emailController.text = saved.loginValue;
    passwordController.text = saved.password;
    _controller.applySavedCredentials(
      rememberPassword: saved.rememberPassword,
    );
  }

  Future<void> _saveRememberedLogin(String email) async {
    await _rememberedCredentialsStore.save(
      mode: _controller.mode,
      loginValue: email,
      password: passwordController.text,
      rememberPassword: _controller.rememberMe,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    smsCodeController.dispose();
    fullNameController.dispose();
    corporateNameController.dispose();
    corporateOwnerController.dispose();
    cityController.dispose();
    districtController.dispose();
    corporateAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 900) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFFF4F7F8),
          body: SafeArea(child: _buildDesktopAuthLayout(context)),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width >= 600
                    ? 560
                    : double.infinity,
              ),
              child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              10 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              const FixLoginBrandArea(),
              const SizedBox(height: 12),
              FixSegmentedTabs<FixAuthMode>(
                value: _controller.mode,
                onChanged: _controller.loading ? null : _changeMode,
                options: const [
                  FixSegmentedOption(
                    value: FixAuthMode.individual,
                    label: 'Bireysel',
                    icon: Icons.person_outline_rounded,
                  ),
                  FixSegmentedOption(
                    value: FixAuthMode.corporate,
                    label: 'Kurumsal',
                    icon: Icons.storefront_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FixModeHint(isCorporate: isCorporate),
              const SizedBox(height: 9),
              FixSegmentedTabs<FixAuthAction>(
                value: _controller.action,
                compact: true,
                onChanged: _controller.loading ? null : _changeAction,
                options: const [
                  FixSegmentedOption(
                    value: FixAuthAction.login,
                    label: 'Giriş',
                    icon: Icons.login_rounded,
                  ),
                  FixSegmentedOption(
                    value: FixAuthAction.register,
                    label: 'Kaydol',
                    icon: Icons.person_add_alt_1_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FixLoginPanel(
                title: _panelTitle(),
                subtitle: _loginSubtitle(),
                bullets: _loginBullets(),
                notice: _controller.noticeText,
                noticeIsError: _controller.noticeIsError,
                child: _buildForm(),
              ),
              const SizedBox(height: 10),
              FixLoginGuestActions(
                loading: _controller.loading,
                onGuest: _continueAsGuest,
              ),
            ],
              ),
            ),
          ),
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
          const SizedBox(height: 10),
        ],
        if (isRegister && isCorporate) ...[
          FixInput(
            controller: corporateNameController,
            label: 'Kurum Adı',
            icon: Icons.storefront_outlined,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 10),
          FixInput(
            controller: corporateOwnerController,
            label: 'Yetkili Kişi',
            icon: Icons.badge_outlined,
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<BusinessCategoryOption>(
            initialValue: _controller.selectedCategory,
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
            onChanged: _controller.loading
                ? null
                : (value) {
                    if (value != null) {
                      _controller.setSelectedCategory(value);
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
            label: 'Telefon',
            hint: '05xx xxx xx xx, 5xx veya +90 5xx',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
          const SizedBox(height: 6),
          const Text(
            'Telefon numaran randevu bilgilendirmeleri ve hesap güvenliği için doğrulanacaktır.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6C757D),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          if (_controller.smsCodeSent) ...[
            FixInput(
              controller: smsCodeController,
              label: 'SMS doğrulama kodu',
              hint: '6 haneli kod',
              icon: Icons.sms_outlined,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _controller.loading
                  ? null
                  : () => _sendRegisterSmsCode(
                      _normalizeTurkishPhone(phoneController.text.trim()),
                    ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Kodu tekrar gönder'),
            ),
            const SizedBox(height: 14),
          ],
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
          label: isRegister ? 'E-posta (isteğe bağlı)' : 'E-posta veya telefon',
          hint: isRegister
              ? 'Hesap kurtarma ve bilgilendirme için'
              : 'E-posta, 05xx, 5xx veya +90 5xx',
          icon: isRegister ? Icons.mail_outline_rounded : Icons.person_search_outlined,
          keyboardType: isRegister
              ? TextInputType.emailAddress
              : TextInputType.emailAddress,
          autofillHints: isRegister
              ? const [AutofillHints.email]
              : const [AutofillHints.username],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: passwordController,
          autofillHints: [
            isRegister ? AutofillHints.newPassword : AutofillHints.password,
          ],
          obscureText: _controller.obscure,
          style: const TextStyle(
            color: Color(0xFF17384A),
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          decoration: fixInputDecoration(
            label: 'Şifre',
            icon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              onPressed: _controller.toggleObscure,
              icon: Icon(
                _controller.obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FixRememberPasswordTile(
                value: _controller.rememberMe,
                onChanged: _controller.loading
                    ? null
                    : (value) => _controller.setRememberMe(value ?? false),
              ),
            ),
            TextButton(
              onPressed: _controller.loading ? null : _showForgotPassword,
              child: const Text(
                'Şifremi unuttum',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        if (isRegister) ...[
          const SizedBox(height: 10),
          _LegalAcceptanceTile(
            value: _controller.legalAccepted,
            isCorporate: isCorporate,
            onChanged: _controller.loading
                ? null
                : (value) => _controller.setLegalAccepted(value ?? false),
            onOpenLegal: () =>
                Navigator.of(context).pushNamed(AppRoutes.legalDocuments),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _controller.loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _controller.loading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _primaryLoadingLabel(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : Text(
                    isRegister
                        ? (_controller.smsCodeSent
                              ? '$modeLabel Kaydı Tamamla'
                              : 'SMS Kodu Gönder')
                        : isCorporate
                        ? 'Kurumsal Giriş Yap'
                        : 'Bireysel Giriş Yap',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  )
          ),
        ),
        if (!isCorporate && !_controller.googleTemporarilyUnavailable) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _controller.loading ? null : _signInWithGoogle,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF17384A),
                side: const BorderSide(color: Color(0xFFDCE7E6)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
              label: const Text(
                'Google ile devam et',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _panelTitle() {
    if (isRegister) return '$modeLabel Hesap Oluştur';
    return isCorporate ? 'İşletme Paneline Giriş' : 'Bireysel Hesaba Giriş';
  }

  String _primaryLoadingLabel() {
    if (!isRegister) return 'Giriş yapılıyor...';
    return _controller.smsCodeSent
        ? 'Kayıt tamamlanıyor...'
        : 'Kod gönderiliyor...';
  }

  String _loginSubtitle() {
    if (isCorporate) {
      return isRegister
          ? 'İşletme hesabınızı güvenli şekilde oluşturun.'
          : 'Randevu, müşteri ve operasyon yönetiminize güvenli erişim sağlayın.';
    }

    return isRegister
        ? 'Randevu almak ve favorilerinizi takip etmek için hesabınızı oluşturun.'
        : 'Yakındaki işletmeleri keşfedin ve randevularınızı yönetin.';
  }

  List<String> _loginBullets() => const [];

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
