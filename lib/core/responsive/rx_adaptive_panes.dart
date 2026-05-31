import 'package:flutter/material.dart';

import 'rx_breakpoints.dart';

class RxAdaptivePanes extends StatelessWidget {
  const RxAdaptivePanes({
    super.key,
    required this.primary,
    this.secondary,
    this.tertiary,
    this.spacing = 16,
    this.primaryFlex = 5,
    this.secondaryFlex = 3,
    this.tertiaryWidth = 360,
  });

  final Widget primary;
  final Widget? secondary;
  final Widget? tertiary;
  final double spacing;
  final int primaryFlex;
  final int secondaryFlex;
  final double tertiaryWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceClass = RxBreakpoints.fromWidth(constraints.maxWidth);

        if (deviceClass.isDesktopWide && tertiary != null) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: primaryFlex, child: primary),
              SizedBox(width: spacing),
              if (secondary != null)
                Expanded(flex: secondaryFlex, child: secondary!)
              else
                SizedBox(width: tertiaryWidth, child: tertiary!),
              if (secondary != null) ...[
                SizedBox(width: spacing),
                SizedBox(width: tertiaryWidth, child: tertiary!),
              ],
            ],
          );
        }

        if ((deviceClass.isTablet || deviceClass.isDesktopWide) &&
            secondary != null) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: primaryFlex, child: primary),
              SizedBox(width: spacing),
              Expanded(flex: secondaryFlex, child: secondary!),
            ],
          );
        }

        return primary;
      },
    );
  }
}
