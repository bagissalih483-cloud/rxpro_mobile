import 'package:flutter/material.dart';

import '../theme/rx_ui.dart';
import 'rx_breakpoints.dart';

class RxDesktopCommandBar extends StatelessWidget {
  const RxDesktopCommandBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 16),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RxColors.surface,
      child: Container(
        padding: padding,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: RxColors.line)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: RxText.pageTitle),
                  if (subtitle?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: RxText.body,
                    ),
                  ],
                ],
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 16),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class RxDesktopWorkArea extends StatelessWidget {
  const RxDesktopWorkArea({
    super.key,
    required this.child,
    this.maxWidth = 1320,
    this.padding = const EdgeInsets.all(24),
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class RxAdaptiveContentWidth extends StatelessWidget {
  const RxAdaptiveContentWidth({
    super.key,
    required this.child,
    this.desktopMaxWidth = 1320,
    this.tabletMaxWidth = 980,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  });

  final Widget child;
  final double desktopMaxWidth;
  final double tabletMaxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceClass = RxBreakpoints.fromWidth(constraints.maxWidth);
        final maxWidth = deviceClass.isDesktopWide
            ? desktopMaxWidth
            : deviceClass.usesWideNavigation
                ? tabletMaxWidth
                : double.infinity;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(padding: padding, child: child),
          ),
        );
      },
    );
  }
}

class RxDesktopPanel extends StatelessWidget {
  const RxDesktopPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: RxColors.surface,
        border: Border.all(color: RxColors.line),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: RxColors.navy.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
