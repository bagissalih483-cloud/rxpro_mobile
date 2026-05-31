part of 'fix_login_gate_page.dart';

extension _FixLoginGatePhoneAuthActions on _FixLoginGatePageState {
  Future<void> _sendRegisterSmsCode(String phone) async {
    if (phone.isEmpty) {
      _showMessage(
        'Telefonu 05xx xxx xx xx, 5xx xxx xx xx veya +90 5xx xxx xx xx formatında yazın.',
      );
      return;
    }

    _controller.setLoading(true);
    smsCodeController.clear();

    try {
      await authService.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _controller.resendToken,
        verificationCompleted: (credential) async {
          if (!mounted) return;
          await _completePhoneRegistrationWithCredential(credential);
        },
        verificationFailed: (error) {
          if (!mounted) return;
          _controller.setLoading(false);
          _showMessage(_firebaseErrorText(error));
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          _controller.setLoading(false);
          _controller.setSmsCodeSent(
            verificationId: verificationId,
            phone: phone,
            resendToken: resendToken,
          );
          _showMessage('SMS kodu gönderildi. Kodu girip kaydı tamamlayın.');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted) return;
          _controller.setSmsCodeSent(
            verificationId: verificationId,
            phone: phone,
            resendToken: _controller.resendToken,
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      _controller.setLoading(false);
      _showMessage('SMS doğrulama başlatılamadı: $error');
    }
  }

  Future<UserCredential> _completePhonePasswordRegistration({
    required String phone,
    required String password,
  }) async {
    final smsCode = smsCodeController.text.trim();
    if (smsCode.length < 4 || _controller.verificationId.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-sms-code',
        message: 'SMS doğrulama kodunu girin.',
      );
    }

    final credential = await authService.signInWithPhoneCode(
      verificationId: _controller.verificationId,
      smsCode: smsCode,
    );

    await _linkPhonePasswordCredential(phone: phone, password: password);
    return credential;
  }

  Future<void> _completePhoneRegistrationWithCredential(
    PhoneAuthCredential credential,
  ) async {
    final phone = _normalizeTurkishPhone(phoneController.text.trim());
    final password = passwordController.text.trim();
    if (phone.isEmpty || password.length < 6) return;

    _controller.setLoading(true);
    try {
      final userCredential = await authService.signInWithPhoneCredential(
        credential,
      );
      await _linkPhonePasswordCredential(phone: phone, password: password);

      final user = userCredential.user;
      if (user == null) return;

      final email = emailController.text.trim().contains('@')
          ? emailController.text.trim()
          : '';
      if (isCorporate) {
        await _completeCorporateAuth(user: user, email: email, phone: phone);
      } else {
        await _completeIndividualAuth(user: user, email: email, phone: phone);
      }

      await _saveRememberedLogin(phone);
      await user.reload();
      await authService.currentUser?.getIdToken(true);
      if (!mounted) return;
      FixSessionGate.refreshAfterAuthChange();
      _showMessage('$modeLabel kayıt tamamlandı.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (error) {
      _showMessage(_firebaseErrorText(error));
    } catch (error) {
      _showMessage('İşlem başarısız: $error');
    } finally {
      if (mounted) {
        _controller.setLoading(false);
      }
    }
  }

  Future<void> _linkPhonePasswordCredential({
    required String phone,
    required String password,
  }) async {
    try {
      await authService.linkEmailPasswordToCurrentUser(
        email: _phonePasswordEmail(phone),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'provider-already-linked') return;
      rethrow;
    }
  }
}
