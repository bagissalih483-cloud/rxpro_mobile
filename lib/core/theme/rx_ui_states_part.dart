part of 'rx_ui.dart';

class RxEmptyState extends StatelessWidget {
  const RxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.actionText,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final contentWidth = maxWidth < 360 ? maxWidth : 360.0;

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: contentWidth,
            child: Padding(
              padding: const EdgeInsets.all(RxSpace.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 38, color: RxColors.muted),
                  const SizedBox(height: RxSpace.sm),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: RxText.cardTitle,
                  ),
                  const SizedBox(height: RxSpace.xs),
                  Text(text, textAlign: TextAlign.center, style: RxText.body),
                  if (actionText != null && onAction != null) ...[
                    const SizedBox(height: RxSpace.md),
                    OutlinedButton(
                      onPressed: onAction,
                      child: Text(actionText!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class RxSkeletonCard extends StatelessWidget {
  const RxSkeletonCard({super.key, this.height = 98});

  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.35, end: 0.75),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        final color = Color.lerp(
          const Color(0xFFE9EEF2),
          const Color(0xFFF6F8FA),
          value,
        )!;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: RxColors.surface,
            borderRadius: BorderRadius.circular(RxRadius.md),
            border: Border.all(color: RxColors.line),
          ),
          padding: const EdgeInsets.all(RxSpace.md),
          child: Row(
            children: [
              _SkeletonBlock(color: color, width: 50, height: 50, radius: 16),
              const SizedBox(width: RxSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SkeletonBlock(color: color, width: 160, height: 14),
                    const SizedBox(height: 9),
                    _SkeletonBlock(color: color, width: 220, height: 11),
                    const SizedBox(height: 9),
                    _SkeletonBlock(color: color, width: 120, height: 11),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.color,
    required this.width,
    required this.height,
    this.radius = 99,
  });

  final Color color;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
