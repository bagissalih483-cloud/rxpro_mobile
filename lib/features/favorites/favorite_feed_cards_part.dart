part of 'favorite_feed_page.dart';

class _FavoriteInfoCard extends StatelessWidget {
  const _FavoriteInfoCard({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF7C3AED), size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  if (actionText != null && onAction != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.explore_outlined),
                      label: Text(actionText!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritePostCard extends StatelessWidget {
  const _FavoritePostCard({required this.post, required this.onOpenBusiness});

  final _FavoritePostItem post;
  final VoidCallback onOpenBusiness;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F7FA),
              child: Icon(Icons.storefront_outlined, color: Color(0xFF18B7C9)),
            ),
            title: Text(
              post.businessName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(post.businessCategory),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: onOpenBusiness,
          ),
        ),
        BusinessProfilePostInteractiveCard(
          postId: post.id,
          text: post.text,
          imageUrl: post.imageUrl,
          createdAt: post.createdAt,
          likeCount: post.likeCount,
          saveCount: post.saveCount,
          reportCount: post.reportCount,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
