import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../app_cache/app_cache_service.dart';
import '../diagnostics/rx_runtime_diagnostics.dart';
import '../realtime/rx_push_notification_service.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Stream<User?> idTokenChanges() {
    return _auth.idTokenChanges();
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Giriş yapan kullanıcı yok.');
    }

    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut({String reason = 'unspecified'}) async {
    debugPrint('FIX_AUTH_SIGN_OUT_START reason=$reason');

    await AppCacheService().clearUserSnapshot();

    if (RxRuntimeDiagnostics.shouldSkipPushTokenCleanup) {
      debugPrint('FIX_AUTH_SIGN_OUT_TOKEN_CLEANUP_SKIPPED reason=$reason');
    } else {
      try {
        await RxPushNotificationService.instance
            .deactivateTokenForCurrentUser()
            .timeout(const Duration(seconds: 4));
      } catch (error) {
        debugPrint('FIX_AUTH_SIGN_OUT_TOKEN_CLEANUP_ERROR $error');
        // Push token cleanup is best-effort; it must not block sign-out.
      }
    }

    await _auth.signOut().timeout(const Duration(seconds: 6));
    await AppCacheService().clearUserSnapshot();
    debugPrint('FIX_AUTH_SIGN_OUT_DONE reason=$reason');
  }
}
