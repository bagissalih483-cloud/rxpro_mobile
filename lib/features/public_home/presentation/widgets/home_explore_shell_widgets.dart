import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/theme/rx_ui.dart';
import 'package:rxpro_mobile/features/auth/presentation/widgets/fix_login_brand.dart';

class ExploreHomeHeader extends StatelessWidget {
  const ExploreHomeHeader({
    super.key,
    required this.displayName,
    required this.messagesButton,
    required this.notificationsButton,
    this.photoUrl = '',
    this.showName = true,
  });

  final String displayName;
  final Widget messagesButton;
  final Widget notificationsButton;
  final String photoUrl;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final cleanName = displayName.trim();
    final name = cleanName.isEmpty ? 'Misafir' : cleanName;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1ECEB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17384A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const FixAmblemMark(height: 38, width: 70),
          const SizedBox(width: 8),
          _ExploreProfileAvatar(name: name, photoUrl: photoUrl),
          if (showName) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF17384A),
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ),
          ] else
            const Spacer(),
          messagesButton,
          const SizedBox(width: 6),
          notificationsButton,
        ],
      ),
    );
  }
}

class _ExploreProfileAvatar extends StatelessWidget {
  const _ExploreProfileAvatar({required this.name, required this.photoUrl});

  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final cleanPhotoUrl = photoUrl.trim();
    if (cleanPhotoUrl.isEmpty) return FixUserInitialAvatar(name: name);

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17384A).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFE9FFF4),
        backgroundImage: NetworkImage(cleanPhotoUrl),
      ),
    );
  }
}

class ExploreHeaderIconButton extends StatelessWidget {
  const ExploreHeaderIconButton({
    super.key,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          onPressed: onTap,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF1F8F8),
            foregroundColor: const Color(0xFF365162),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ExploreInfoState extends StatelessWidget {
  const ExploreInfoState({
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
    return Center(
      child: RxEmptyState(
        icon: icon,
        title: title,
        text: text,
        actionText: actionText,
        onAction: onAction,
      ),
    );
  }
}
