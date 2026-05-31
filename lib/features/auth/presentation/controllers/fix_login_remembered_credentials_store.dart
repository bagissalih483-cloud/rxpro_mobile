import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxpro_mobile/features/auth/presentation/controllers/fix_login_gate_controller.dart';

const String _rememberModeKey = 'fix_remember_mode';

const String _individualSavedEmailKey = 'fix_individual_saved_email';
const String _corporateSavedEmailKey = 'fix_corporate_saved_email';
const String _individualRememberPasswordKey =
    'fix_individual_remember_password';
const String _corporateRememberPasswordKey = 'fix_corporate_remember_password';
const String _individualSecurePasswordKey = 'fix_individual_secure_password';
const String _corporateSecurePasswordKey = 'fix_corporate_secure_password';

const FlutterSecureStorage _fixSecureStorage = FlutterSecureStorage();

class FixLoginSavedCredentials {
  const FixLoginSavedCredentials({
    required this.loginValue,
    required this.password,
    required this.rememberPassword,
  });

  final String loginValue;
  final String password;
  final bool rememberPassword;
}

class FixLoginRememberedCredentialsStore {
  const FixLoginRememberedCredentialsStore();

  Future<FixAuthMode> resolveInitialMode({
    required bool startCorporate,
    required FixAuthMode fallback,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedMode = prefs.getString(_rememberModeKey) ?? '';

    if (rememberedMode == 'corporate') return FixAuthMode.corporate;
    if (rememberedMode == 'individual') return FixAuthMode.individual;
    if (startCorporate) return FixAuthMode.corporate;
    return fallback;
  }

  Future<FixLoginSavedCredentials> loadForMode(FixAuthMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = _keysForMode(mode);

    final savedEmail = prefs.getString(keys.emailKey) ?? '';
    final shouldRememberPassword =
        prefs.getBool(keys.rememberPasswordKey) ?? false;
    final savedPassword = shouldRememberPassword
        ? await _safeReadRememberedPassword(
            prefs: prefs,
            rememberPasswordKey: keys.rememberPasswordKey,
            securePasswordKey: keys.securePasswordKey,
          )
        : '';

    return FixLoginSavedCredentials(
      loginValue: savedEmail,
      password: savedPassword,
      rememberPassword: shouldRememberPassword && savedPassword.isNotEmpty,
    );
  }

  Future<void> save({
    required FixAuthMode mode,
    required String loginValue,
    required String password,
    required bool rememberPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = _keysForMode(mode);

    await prefs.setString(
      _rememberModeKey,
      mode == FixAuthMode.corporate ? 'corporate' : 'individual',
    );

    await prefs.setString(keys.emailKey, loginValue);

    if (rememberPassword) {
      await prefs.setBool(keys.rememberPasswordKey, true);
      await _fixSecureStorage.write(
        key: keys.securePasswordKey,
        value: password,
      );
    } else {
      await prefs.setBool(keys.rememberPasswordKey, false);
      await _fixSecureStorage.delete(key: keys.securePasswordKey);
    }
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
        // Android Keystore may reject both read and delete after key rotation.
      }
      debugPrint('FIX_REMEMBERED_PASSWORD_RESET $error');
      return '';
    }
  }

  _RememberedCredentialKeys _keysForMode(FixAuthMode mode) {
    final corporate = mode == FixAuthMode.corporate;
    return _RememberedCredentialKeys(
      emailKey: corporate ? _corporateSavedEmailKey : _individualSavedEmailKey,
      rememberPasswordKey: corporate
          ? _corporateRememberPasswordKey
          : _individualRememberPasswordKey,
      securePasswordKey: corporate
          ? _corporateSecurePasswordKey
          : _individualSecurePasswordKey,
    );
  }
}

class _RememberedCredentialKeys {
  const _RememberedCredentialKeys({
    required this.emailKey,
    required this.rememberPasswordKey,
    required this.securePasswordKey,
  });

  final String emailKey;
  final String rememberPasswordKey;
  final String securePasswordKey;
}
