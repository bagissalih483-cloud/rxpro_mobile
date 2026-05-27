import 'package:flutter/material.dart';

class RxColors {
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF18B7C9);
  static const Color navy = Color(0xFF0B1F3A);
  static const Color green = Color(0xFF10B981);
  static const Color success = Color(0xFF1D9E75);
  static const Color warning = Color(0xFFBA7517);
  static const Color danger = Color(0xFFA32D2D);
  static const Color premium = Color(0xFF534AB7);
  static const Color red = Color(0xFFEF4444);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color orange = Color(0xFFF59E0B);
  static const Color text = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color line = Color(0xFFE5E7EB);
}

class RxSpace {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
}

class RxRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 26;
}

class RxText {
  static const TextStyle pageTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: RxColors.text,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w900,
    color: RxColors.text,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: RxColors.text,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    color: RxColors.muted,
    height: 1.25,
  );

  static const TextStyle tiny = TextStyle(
    fontSize: 11,
    color: RxColors.muted,
    fontWeight: FontWeight.w700,
  );
}

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
        if (trailing != null) trailing!,
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
