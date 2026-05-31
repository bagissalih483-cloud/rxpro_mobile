part of 'fix_login_gate_page.dart';

extension _FixLoginGateMessageUtils on _FixLoginGatePageState {
  void _continueAsGuest() {
    FixSessionGate.continueAsGuest();
  }

  void _showForgotPassword() {
    Navigator.of(context).pushNamed(AppRoutes.phonePasswordReset);
  }

  void _showMessage(String text) {
    if (!mounted) return;

    final isError = _isErrorMessage(text);
    _controller.setNotice(text, isError: isError);

    final background = isError
        ? const Color(0xFFFFF1F2)
        : const Color(0xFFEFFAF4);
    final foreground = isError
        ? const Color(0xFFB91C1C)
        : const Color(0xFF166534);
    final width = MediaQuery.sizeOf(context).width;
    final useDesktopToast = width >= 900;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: foreground,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        elevation: 0,
        width: useDesktopToast ? 420 : null,
        margin: useDesktopToast ? null : const EdgeInsets.fromLTRB(16, 0, 16, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _clearNotice() {
    _controller.clearNotice();
  }

  bool _isErrorMessage(String text) {
    final lower = text.toLowerCase();
    return lower.contains('hata') ||
        lower.contains('hatalı') ||
        lower.contains('başarısız') ||
        lower.contains('zorunlu') ||
        lower.contains('geçersiz') ||
        lower.contains('tamamlanamadı') ||
        lower.contains('bulunamadı') ||
        lower.contains('kullanılamıyor') ||
        lower.contains('yapılandırması');
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

  String _loginEmailForInput(String raw) {
    final value = raw.trim();
    if (value.contains('@')) return value;

    final phone = _normalizeTurkishPhone(value);
    if (phone.isEmpty) return value;
    return _phonePasswordEmail(phone);
  }

  String _phonePasswordEmail(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return 'tr_$digits@phone.rxpro.local';
  }

  String _firebaseErrorText(FirebaseAuthException e) {
    switch (e.code) {
      case 'missing-sms-code':
        return e.message ?? 'SMS doğrulama kodunu girin.';
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
        return 'Firebase Console’da gerekli giriş yöntemi açık değil.';
      case 'google-sign-in-unavailable':
        return e.message ?? 'Google ile giriş bu cihazda kullanılamıyor.';
      default:
        return e.message ?? 'Firebase Auth hatası: ${e.code}';
    }
  }
}
