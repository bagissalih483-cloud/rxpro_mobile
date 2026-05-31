part of 'fix_login_gate_page.dart';

extension _FixLoginGateGoogleAuthActions on _FixLoginGatePageState {
  Future<void> _signInWithGoogle() async {
    if (_controller.loading) return;

    if (isRegister && !_controller.legalAccepted) {
      _showMessage(
        'Devam etmek için yasal metinleri ve veri işleme bilgilendirmesini onaylamalısınız.',
      );
      return;
    }

    if (isRegister && isCorporate) {
      if (corporateNameController.text.trim().isEmpty ||
          corporateOwnerController.text.trim().isEmpty) {
        _showMessage(
          'Kurumsal Google kaydı için kurum adı ve yetkili kişi zorunludur.',
        );
        return;
      }
    }

    _controller.setLoading(true);

    try {
      final credential = await authService.signInWithGoogle();
      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase kullanicisi alinamadi.');
      }

      final email = user.email?.trim() ?? '';
      final phone = user.phoneNumber?.trim() ?? '';

      if (isCorporate) {
        await _completeCorporateAuth(user: user, email: email, phone: phone);
      } else {
        await _completeIndividualAuth(user: user, email: email, phone: phone);
      }

      await _saveRememberedLogin(email.isNotEmpty ? email : phone);
      await user.reload();
      await authService.currentUser?.getIdToken(true);

      if (!mounted) return;

      FixSessionGate.refreshAfterAuthChange();
      _showMessage('Google ile $modeLabel giriş başarılı.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (error) {
      _showMessage(_firebaseErrorText(error));
    } catch (error) {
      _showMessage(_googleSignInErrorText(error));
      if (_isGoogleConfigurationError(error)) {
        _controller.markGoogleTemporarilyUnavailable();
      }
    } finally {
      if (mounted) {
        _controller.setLoading(false);
      }
    }
  }

  String _googleSignInErrorText(Object error) {
    final text = error.toString();
    if (text.contains('clientConfigurationError') ||
        text.contains('serverClientId must be provided')) {
      return 'Google ile giriş yapılandırması tamamlanmamış. Şimdilik telefon veya e-posta ile devam edin.';
    }

    return 'Google ile giriş şu anda tamamlanamadı. Lütfen telefon veya e-posta ile devam edin.';
  }

  bool _isGoogleConfigurationError(Object error) {
    final text = error.toString();
    return text.contains('clientConfigurationError') ||
        text.contains('serverClientId must be provided');
  }
}
