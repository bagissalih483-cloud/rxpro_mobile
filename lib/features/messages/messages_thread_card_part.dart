part of 'messages_inbox_page.dart';

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({
    required this.thread,
    required this.isBusinessOwner,
    required this.onTap,
  });

  final MessageThreadItem thread;
  final bool isBusinessOwner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = MessageUiPolicy.threadUnread(
      isBusinessOwner: isBusinessOwner,
      unreadForCustomer: thread.unreadForCustomer,
      unreadForBusiness: thread.unreadForBusiness,
    );
    final title = isBusinessOwner ? thread.customerName : thread.businessName;
    final statusColor = MessageUiPolicy.isClosed(thread.status)
        ? RxColors.muted
        : RxColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: RxSpace.sm),
      child: Material(
        color: RxColors.surface,
        borderRadius: BorderRadius.circular(RxRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(RxRadius.md),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(RxSpace.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RxRadius.md),
              border: Border.all(
                color: unread
                    ? RxColors.primary.withValues(alpha: 0.45)
                    : RxColors.line,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: unread
                          ? RxColors.primary.withValues(alpha: 0.12)
                          : const Color(0xFFF3F4F6),
                      child: Icon(
                        unread
                            ? Icons.mark_chat_unread_outlined
                            : Icons.chat_bubble_outline,
                        color: unread ? RxColors.primary : RxColors.muted,
                      ),
                    ),
                    if (unread)
                      const Positioned(
                        right: -1,
                        top: -1,
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: RxColors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: RxSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? 'Görüşme' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: RxColors.text,
                          fontSize: 15,
                          fontWeight: unread
                              ? FontWeight.w900
                              : FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thread.lastMessage.isEmpty
                            ? 'Mesaj yok'
                            : thread.lastMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: RxText.body,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          RxStatusChip(
                            label: MessageUiPolicy.topicLabel(thread.topic),
                            icon: Icons.sell_outlined,
                            color: RxColors.premium,
                            compact: true,
                          ),
                          RxStatusChip(
                            label: MessageUiPolicy.statusLabel(thread.status),
                            icon: MessageUiPolicy.isClosed(thread.status)
                                ? Icons.lock_outline
                                : Icons.lock_open_outlined,
                            color: statusColor,
                            compact: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: RxSpace.sm),
                const Icon(Icons.chevron_right, color: RxColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
