part of 'messages_ui_widgets.dart';

class MessageThreadContextPanel extends StatelessWidget {
  const MessageThreadContextPanel({
    super.key,
    required this.name,
    required this.topic,
    required this.status,
    required this.isBusinessOwner,
  });

  final String name;
  final String topic;
  final String status;
  final bool isBusinessOwner;

  @override
  Widget build(BuildContext context) {
    final closed = MessageUiPolicy.isClosed(status);
    final roleColor = isBusinessOwner ? RxColors.navy : RxColors.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(RxSpace.md, RxSpace.sm, RxSpace.md, 0),
      padding: const EdgeInsets.all(RxSpace.md),
      decoration: BoxDecoration(
        color: RxColors.surface,
        borderRadius: BorderRadius.circular(RxRadius.md),
        border: Border.all(color: RxColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: roleColor.withValues(alpha: 0.10),
            child: Icon(
              isBusinessOwner
                  ? Icons.person_search_outlined
                  : Icons.storefront_outlined,
              color: roleColor,
            ),
          ),
          const SizedBox(width: RxSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MessageUiPolicy.threadContextTitle(
                    isBusinessOwner: isBusinessOwner,
                  ),
                  style: RxText.tiny,
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RxText.cardTitle,
                ),
                const SizedBox(height: 5),
                Text(
                  MessageUiPolicy.threadContextText(
                    isBusinessOwner: isBusinessOwner,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: RxText.body,
                ),
              ],
            ),
          ),
          const SizedBox(width: RxSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RxStatusChip(
                label: MessageUiPolicy.topicLabel(topic),
                icon: Icons.sell_outlined,
                color: RxColors.premium,
                compact: true,
              ),
              const SizedBox(height: 6),
              RxStatusChip(
                label: MessageUiPolicy.statusLabel(status),
                icon: closed ? Icons.lock_outline : Icons.lock_open_outlined,
                color: closed ? RxColors.muted : RxColors.success,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
