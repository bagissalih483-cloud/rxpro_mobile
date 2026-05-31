import 'package:flutter/widgets.dart';

enum RxDeviceClass {
  phone,
  smallTablet,
  tablet,
  desktopWide;

  bool get isPhone => this == RxDeviceClass.phone;
  bool get isSmallTablet => this == RxDeviceClass.smallTablet;
  bool get isTablet => this == RxDeviceClass.tablet;
  bool get isDesktopWide => this == RxDeviceClass.desktopWide;
  bool get usesWideNavigation => isSmallTablet || isTablet || isDesktopWide;
}

class RxBreakpoints {
  const RxBreakpoints._();

  static const double phoneMax = 599;
  static const double smallTabletMin = 600;
  static const double tabletMin = 900;
  static const double desktopWideMin = 1200;

  static RxDeviceClass fromWidth(double width) {
    if (width >= desktopWideMin) return RxDeviceClass.desktopWide;
    if (width >= tabletMin) return RxDeviceClass.tablet;
    if (width >= smallTabletMin) return RxDeviceClass.smallTablet;
    return RxDeviceClass.phone;
  }

  static RxDeviceClass of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }
}
