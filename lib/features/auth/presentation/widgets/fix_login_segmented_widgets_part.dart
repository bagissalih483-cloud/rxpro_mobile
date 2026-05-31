part of 'fix_login_form_widgets.dart';

class FixSegmentedOption<T> {
  const FixSegmentedOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class FixSegmentedTabs<T> extends StatelessWidget {
  const FixSegmentedTabs({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.compact = false,
  });

  final T value;
  final List<FixSegmentedOption<T>> options;
  final ValueChanged<T>? onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 40 : 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: compact ? const Color(0xFFEFF4F3) : Colors.white,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: compact ? null : Border.all(color: const Color(0xFFE1ECEB)),
        boxShadow: compact
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF17384A).withValues(alpha: 0.035),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        children: options
            .map(
              (option) => Expanded(
                child: _FixSegmentButton<T>(
                  option: option,
                  selected: option.value == value,
                  compact: compact,
                  onTap: onChanged == null
                      ? null
                      : () => onChanged!(option.value),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _FixSegmentButton<T> extends StatelessWidget {
  const _FixSegmentButton({
    required this.option,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final FixSegmentedOption<T> option;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: selected
            ? const Color(0xFF1DB954)
            : Colors.transparent,
        foregroundColor: selected ? Colors.white : const Color(0xFF60727A),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (option.icon != null) ...[
            Icon(option.icon, size: compact ? 15 : 16),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
