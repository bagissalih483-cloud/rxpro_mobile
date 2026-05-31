part of 'messages_ui_widgets.dart';

class MessagesRoleHeader extends StatelessWidget {
  const MessagesRoleHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isBusinessOwner,
    required this.threadCount,
    this.onNewMessage,
  });

  final String title;
  final String subtitle;
  final bool isBusinessOwner;
  final int threadCount;
  final VoidCallback? onNewMessage;

  @override
  Widget build(BuildContext context) {
    final roleColor = isBusinessOwner ? RxColors.navy : RxColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RxSpace.lg),
      decoration: BoxDecoration(
        color: RxColors.surface,
        borderRadius: BorderRadius.circular(RxRadius.lg),
        border: Border.all(color: RxColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: RxText.pageTitle),
          const SizedBox(height: RxSpace.xs),
          RxStatusChip(
            label: MessageUiPolicy.inboxRoleLabel(
              isBusinessOwner: isBusinessOwner,
            ),
            icon: isBusinessOwner
                ? Icons.business_center_outlined
                : Icons.person_outline,
            color: roleColor,
          ),
          const SizedBox(height: RxSpace.xs),
          Text(subtitle, style: RxText.body),
          const SizedBox(height: RxSpace.md),
          Wrap(
            spacing: RxSpace.sm,
            runSpacing: RxSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RxStatusChip(
                label: '$threadCount görüşme',
                icon: Icons.forum_outlined,
                color: RxColors.success,
              ),
              if (!isBusinessOwner && onNewMessage != null)
                FilledButton.icon(
                  onPressed: onNewMessage,
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('Yeni Mesaj'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class MessagesLoadingList extends StatelessWidget {
  const MessagesLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        RxSkeletonCard(height: 112),
        SizedBox(height: RxSpace.sm),
        RxSkeletonCard(height: 86),
        SizedBox(height: RxSpace.sm),
        RxSkeletonCard(height: 86),
        SizedBox(height: RxSpace.sm),
        RxSkeletonCard(height: 86),
      ],
    );
  }
}
