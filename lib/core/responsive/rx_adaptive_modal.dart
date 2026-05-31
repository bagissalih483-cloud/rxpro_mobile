import 'package:flutter/material.dart';

import '../theme/rx_ui.dart';
import 'rx_breakpoints.dart';

Future<T?> showRxAdaptiveModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool showDragHandle = true,
  double desktopMaxWidth = 560,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final deviceClass = RxBreakpoints.fromWidth(width);
  final desktopLike = !deviceClass.isPhone;

  if (!desktopLike) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      showDragHandle: showDragHandle,
      useSafeArea: true,
      backgroundColor: RxColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: builder,
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      return Dialog(
        insetPadding: const EdgeInsets.all(28),
        backgroundColor: RxColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: desktopMaxWidth,
            maxHeight: size.height - 56,
          ),
          child: builder(dialogContext),
        ),
      );
    },
  );
}
