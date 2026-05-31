import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/responsive/rx_breakpoints.dart';
import 'package:rxpro_mobile/core/responsive/rx_navigation_policy.dart';
import 'package:rxpro_mobile/core/responsive/rx_platform_profile.dart';

void main() {
  group('RxBreakpoints', () {
    test('classifies screen widths', () {
      expect(RxBreakpoints.fromWidth(375), RxDeviceClass.phone);
      expect(RxBreakpoints.fromWidth(600), RxDeviceClass.smallTablet);
      expect(RxBreakpoints.fromWidth(900), RxDeviceClass.tablet);
      expect(RxBreakpoints.fromWidth(1200), RxDeviceClass.desktopWide);
    });
  });

  group('RxNavigationPolicy', () {
    test('keeps bottom navigation on phone and small tablet', () {
      expect(RxNavigationPolicy.fromWidth(599).useSideNavigation, false);
      expect(RxNavigationPolicy.fromWidth(899).useSideNavigation, false);
    });

    test('uses rail navigation on tablet and desktop widths', () {
      final tablet = RxNavigationPolicy.fromWidth(900);
      final desktop = RxNavigationPolicy.fromWidth(1200);

      expect(tablet.useSideNavigation, true);
      expect(tablet.extendSideNavigation, false);
      expect(desktop.useSideNavigation, true);
      expect(desktop.extendSideNavigation, true);
    });
  });

  group('RxPlatformProfile', () {
    test('treats desktop and wide screens as dense business workspaces', () {
      const desktop = RxPlatformProfile(
        hostPlatform: RxHostPlatform.windows,
        deviceClass: RxDeviceClass.phone,
        logicalSize: Size(480, 900),
      );
      const tablet = RxPlatformProfile(
        hostPlatform: RxHostPlatform.android,
        deviceClass: RxDeviceClass.tablet,
        logicalSize: Size(900, 1200),
      );

      expect(desktop.isDesktop, true);
      expect(desktop.supportsDenseBusinessWorkspace, true);
      expect(tablet.supportsDenseBusinessWorkspace, true);
    });
  });
}
