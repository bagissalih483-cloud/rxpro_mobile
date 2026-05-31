import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'rx_breakpoints.dart';

enum RxHostPlatform {
  android,
  ios,
  windows,
  macos,
  linux,
  web,
  fuchsia,
  unknown,
}

class RxPlatformProfile {
  const RxPlatformProfile({
    required this.hostPlatform,
    required this.deviceClass,
    required this.logicalSize,
  });

  final RxHostPlatform hostPlatform;
  final RxDeviceClass deviceClass;
  final Size logicalSize;

  bool get isDesktop {
    return hostPlatform == RxHostPlatform.windows ||
        hostPlatform == RxHostPlatform.macos ||
        hostPlatform == RxHostPlatform.linux;
  }

  bool get isAppleMobile => hostPlatform == RxHostPlatform.ios;
  bool get isAppleDesktop => hostPlatform == RxHostPlatform.macos;
  bool get isWeb => hostPlatform == RxHostPlatform.web;

  bool get prefersPointerUi {
    return isDesktop || isWeb || deviceClass.index >= RxDeviceClass.tablet.index;
  }

  bool get prefersCompactNavigation {
    return deviceClass == RxDeviceClass.phone ||
        deviceClass == RxDeviceClass.smallTablet;
  }

  bool get supportsDenseBusinessWorkspace {
    return deviceClass == RxDeviceClass.tablet ||
        deviceClass == RxDeviceClass.desktopWide ||
        isDesktop ||
        isWeb;
  }

  static RxPlatformProfile of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return RxPlatformProfile(
      hostPlatform: currentHostPlatform,
      deviceClass: RxBreakpoints.fromWidth(size.width),
      logicalSize: size,
    );
  }

  static RxHostPlatform get currentHostPlatform {
    if (kIsWeb) return RxHostPlatform.web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return RxHostPlatform.android;
      case TargetPlatform.iOS:
        return RxHostPlatform.ios;
      case TargetPlatform.windows:
        return RxHostPlatform.windows;
      case TargetPlatform.macOS:
        return RxHostPlatform.macos;
      case TargetPlatform.linux:
        return RxHostPlatform.linux;
      case TargetPlatform.fuchsia:
        return RxHostPlatform.fuchsia;
    }
  }
}
