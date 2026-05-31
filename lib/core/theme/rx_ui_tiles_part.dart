part of 'rx_ui.dart';

class RxCompactTile extends StatelessWidget {
  const RxCompactTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = RxColors.primary,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: color.withValues(alpha: 0.10),
              child: Icon(icon, color: color, size: 20),
            ),
            if (badgeCount > 0)
              Positioned(right: -5, top: -6, child: RxBadge(count: badgeCount)),
          ],
        ),
        title: Text(title, style: RxText.cardTitle),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: RxText.body,
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}

class RxSectionHeader extends StatelessWidget {
  const RxSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: RxText.sectionTitle),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RxText.tiny,
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class RxStatusChip extends StatelessWidget {
  const RxStatusChip({
    super.key,
    required this.label,
    this.icon,
    this.color = RxColors.primary,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 13 : 15, color: color),
            SizedBox(width: compact ? 3 : 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
