part of 'fix_login_gate_page.dart';

extension _FixLoginGateAuthActions on _FixLoginGatePageState {
  Future<void> _submit() async {
    if (_controller.loading) return;

    final loginInput = emailController.text.trim();
    final email = loginInput.contains('@') ? loginInput : '';
    final password = passwordController.text.trim();
    final phone = _normalizeTurkishPhone(phoneController.text.trim());

    if (password.length < 6) {
      _showMessage('En az 6 haneli şifre zorunludur.');
      return;
    }

    if (isRegister && phone.isEmpty) {
      _showMessage(
        'Kayıt için geçerli GSM numarası zorunludur. 05xx, 5xx veya +90 formatını kullanabilirsiniz.',
      );
      return;
    }

    if (!isRegister && loginInput.isEmpty) {
      _showMessage('E-posta veya telefon numarası zorunludur.');
      return;
    }

    if (!isRegister &&
        email.isEmpty &&
        _normalizeTurkishPhone(loginInput).isEmpty) {
      _showMessage(
        'Telefonu 05xx xxx xx xx, 5xx xxx xx xx veya +90 5xx xxx xx xx formatında yazın.',
      );
      return;
    }

    if (isRegister && !_controller.legalAccepted) {
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

    if (isRegister && !_controller.smsCodeSent) {
      await _sendRegisterSmsCode(phone);
      return;
    }

    _controller.setLoading(true);

    try {
      UserCredential credential;

      if (isRegister) {
        credential = await _completePhonePasswordRegistration(
          phone: phone,
          password: password,
        );
      } else {
        credential = await authService.signInWithEmail(
          email: _loginEmailForInput(loginInput),
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

      await _saveRememberedLogin(isRegister ? phone : loginInput);
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
        _controller.setLoading(false);
      }
    }
  }
}
