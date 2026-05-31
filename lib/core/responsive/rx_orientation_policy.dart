import 'package:flutter/services.dart';

class RxOrientationPolicy {
  const RxOrientationPolicy._();

  static Future<void> applyStartupPolicy() {
    return SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}
