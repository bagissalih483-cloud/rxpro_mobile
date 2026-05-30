import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

abstract final class FirebaseAppCheckBootstrap {
  static const bool _forceDebugProvider = bool.fromEnvironment(
    'RXPRO_APP_CHECK_DEBUG',
  );

  static bool get supportsCurrentPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static Future<void> activate() async {
    if (!supportsCurrentPlatform) {
      debugPrint(
        'RX_APP_CHECK_SKIPPED platform=$defaultTargetPlatform web=$kIsWeb',
      );
      return;
    }

    final useDebugProvider = _forceDebugProvider || !kReleaseMode;

    await FirebaseAppCheck.instance.activate(
      providerAndroid: useDebugProvider
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: useDebugProvider
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );

    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    debugPrint(
      'RX_APP_CHECK_ACTIVE release=$kReleaseMode debugProvider=$useDebugProvider',
    );
  }
}
