import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RxSearchIntent extends Intent {
  const RxSearchIntent();
}

class RxCreateIntent extends Intent {
  const RxCreateIntent();
}

class RxRefreshIntent extends Intent {
  const RxRefreshIntent();
}

class RxKeyboardShortcutScope extends StatelessWidget {
  const RxKeyboardShortcutScope({
    super.key,
    required this.child,
    this.onSearch,
    this.onCreate,
    this.onRefresh,
  });

  final Widget child;
  final VoidCallback? onSearch;
  final VoidCallback? onCreate;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final shortcuts = <ShortcutActivator, Intent>{};
    final actions = <Type, Action<Intent>>{};

    if (onSearch != null) {
      shortcuts[const SingleActivator(LogicalKeyboardKey.keyF, control: true)] =
          const RxSearchIntent();
      shortcuts[const SingleActivator(LogicalKeyboardKey.keyF, meta: true)] =
          const RxSearchIntent();
      actions[RxSearchIntent] = CallbackAction<RxSearchIntent>(
        onInvoke: (_) {
          onSearch?.call();
          return null;
        },
      );
    }

    if (onCreate != null) {
      shortcuts[const SingleActivator(LogicalKeyboardKey.keyN, control: true)] =
          const RxCreateIntent();
      shortcuts[const SingleActivator(LogicalKeyboardKey.keyN, meta: true)] =
          const RxCreateIntent();
      actions[RxCreateIntent] = CallbackAction<RxCreateIntent>(
        onInvoke: (_) {
          onCreate?.call();
          return null;
        },
      );
    }

    if (onRefresh != null) {
      shortcuts[const SingleActivator(LogicalKeyboardKey.keyR, control: true)] =
          const RxRefreshIntent();
      shortcuts[const SingleActivator(LogicalKeyboardKey.keyR, meta: true)] =
          const RxRefreshIntent();
      actions[RxRefreshIntent] = CallbackAction<RxRefreshIntent>(
        onInvoke: (_) {
          onRefresh?.call();
          return null;
        },
      );
    }

    if (shortcuts.isEmpty) return child;

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(actions: actions, child: child),
    );
  }
}
