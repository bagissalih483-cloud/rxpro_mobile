import 'package:flutter/material.dart';

import '../theme/rx_ui.dart';
import 'rx_breakpoints.dart';

class RxAdaptiveWorkSurface extends StatelessWidget {
  const RxAdaptiveWorkSurface({
    super.key,
    required this.primary,
    this.secondary,
    this.header,
    this.padding = const EdgeInsets.all(16),
    this.maxWidth = 1440,
    this.secondaryWidth = 360,
    this.gap = 16,
    this.desktopBreakpoint = RxBreakpoints.smallTabletMin,
  });

  final Widget primary;
  final Widget? secondary;
  final Widget? header;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final double secondaryWidth;
  final double gap;
  final double desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = secondary != null &&
            constraints.maxWidth >= desktopBreakpoint + secondaryWidth;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (header != null) ...[
                    header!,
                    SizedBox(height: gap),
                  ],
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: primary),
                              SizedBox(width: gap),
                              SizedBox(width: secondaryWidth, child: secondary),
                            ],
                          )
                        : ListView(
                            children: [
                              primary,
                              if (secondary != null) ...[
                                SizedBox(height: gap),
                                secondary!,
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class RxWorkPanel extends StatelessWidget {
  const RxWorkPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: RxColors.surface,
        border: Border.all(color: RxColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
