import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

abstract final class FirebaseAppCheckBootstrap {
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

    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug,
      appleProvider: kReleaseMode
          ? AppleProvider.appAttestWithDeviceCheckFallback
          : AppleProvider.debug,
    );

    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    debugPrint('RX_APP_CHECK_ACTIVE release=$kReleaseMode');
  }
}
