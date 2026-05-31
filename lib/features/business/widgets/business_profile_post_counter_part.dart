part of 'business_profile_post_interactive_card.dart';

class _RoundIconCounter extends StatelessWidget {
  const _RoundIconCounter({
    required this.icon,
    required this.count,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF18B7C9) : const Color(0xFF6B7280);
    final bg = active ? const Color(0xFFE0F7FA) : const Color(0xFFF9FAFB);
    final border = active ? const Color(0xFF18B7C9) : const Color(0xFFE5E7EB);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
