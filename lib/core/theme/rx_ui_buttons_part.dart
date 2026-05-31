part of 'rx_ui.dart';

class RxBadge extends StatelessWidget {
  const RxBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: RxColors.red,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class RxMiniActionButton extends StatelessWidget {
  const RxMiniActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = RxColors.primary,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(RxRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : RxColors.surface,
          borderRadius: BorderRadius.circular(RxRadius.md),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.45) : RxColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : RxColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RxPrimaryActionButton extends StatelessWidget {
  const RxPrimaryActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = RxColors.green,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RxRadius.sm),
        ),
      ),
    );
  }
}

class RxSecondaryActionButton extends StatelessWidget {
  const RxSecondaryActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = RxColors.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        side: BorderSide(color: color.withValues(alpha: 0.45)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RxRadius.sm),
        ),
      ),
    );
  }
}
