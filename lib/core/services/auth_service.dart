import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../app_cache/app_cache_service.dart';
import '../diagnostics/rx_runtime_diagnostics.dart';
import '../realtime/rx_push_notification_service.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _googleSignInInitialized = false;

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

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;

    await GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'google-sign-in-unavailable',
        message: 'Google ile giriş bu cihazda kullanılamıyor.',
      );
    }

    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  Future<UserCredential> signInWithPhoneCode({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) {
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> linkEmailPasswordToCurrentUser({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Giriş yapan kullanıcı yok.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    return user.linkWithCredential(credential);
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

    try {
      await _ensureGoogleSignInInitialized();
      await GoogleSignIn.instance.signOut().timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint('FIX_AUTH_GOOGLE_SIGN_OUT_SKIPPED $error');
    }

    await _auth.signOut().timeout(const Duration(seconds: 6));
    await AppCacheService().clearUserSnapshot();
    debugPrint('FIX_AUTH_SIGN_OUT_DONE reason=$reason');
  }
}
