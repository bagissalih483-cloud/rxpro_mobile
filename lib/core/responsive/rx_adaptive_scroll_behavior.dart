import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class RxAdaptiveScrollBehavior extends MaterialScrollBehavior {
  const RxAdaptiveScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices {
    return const <PointerDeviceKind>{
      PointerDeviceKind.touch,
      PointerDeviceKind.mouse,
      PointerDeviceKind.stylus,
      PointerDeviceKind.invertedStylus,
      PointerDeviceKind.trackpad,
    };
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final platform = getPlatform(context);
    final desktopLike = platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;

    if (!desktopLike) {
      return super.buildScrollbar(context, child, details);
    }

    return Scrollbar(
      controller: details.controller,
      thumbVisibility: false,
      child: child,
    );
  }
}
