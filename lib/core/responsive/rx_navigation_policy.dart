import 'rx_breakpoints.dart';

class RxNavigationPolicy {
  const RxNavigationPolicy({
    required this.deviceClass,
    required this.useSideNavigation,
    required this.extendSideNavigation,
    required this.contentMaxWidth,
  });

  factory RxNavigationPolicy.fromWidth(double width) {
    final deviceClass = RxBreakpoints.fromWidth(width);
    return RxNavigationPolicy(
      deviceClass: deviceClass,
      useSideNavigation: deviceClass.usesWideNavigation,
      extendSideNavigation: deviceClass.isDesktopWide,
      contentMaxWidth: deviceClass.isDesktopWide
          ? 1440
          : deviceClass.isTablet
              ? 1180
              : 760,
    );
  }

  final RxDeviceClass deviceClass;
  final bool useSideNavigation;
  final bool extendSideNavigation;
  final double contentMaxWidth;

  double get horizontalPadding {
    switch (deviceClass) {
      case RxDeviceClass.phone:
        return 0;
      case RxDeviceClass.smallTablet:
        return 10;
      case RxDeviceClass.tablet:
        return 14;
      case RxDeviceClass.desktopWide:
        return 20;
    }
  }
}
