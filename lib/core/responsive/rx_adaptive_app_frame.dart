import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RxAdaptiveAppFrame extends StatelessWidget {
  const RxAdaptiveAppFrame({super.key, required this.child, this.onDismiss});

  final Widget child;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              if (onDismiss != null) {
                onDismiss!();
                return null;
              }

              final navigator = Navigator.maybeOf(context);
              if (navigator != null && navigator.canPop()) {
                navigator.maybePop();
              }
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: child,
        ),
      ),
    );
  }
}
