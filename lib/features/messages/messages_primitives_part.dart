part of 'messages_inbox_page.dart';

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.isBusinessOwner,
    required this.onRecall,
  });

  final MessageItem message;
  final bool mine;
  final bool isBusinessOwner;
  final VoidCallback onRecall;

  @override
  Widget build(BuildContext context) {
    final readText = MessageUiPolicy.readReceipt(
      isBusinessOwner: isBusinessOwner,
      readByCustomer: message.readByCustomer,
      readByBusiness: message.readByBusiness,
    );
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final bubbleColor = mine ? RxColors.primary : RxColors.surface;
    final textColor = mine ? Colors.white : RxColors.text;
    final metaColor = mine ? Colors.white70 : RxColors.muted;

    return GestureDetector(
      onLongPress: mine && !message.recalled ? onRecall : null,
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: RxSpace.sm),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          constraints: BoxConstraints(
            maxWidth: maxWidth.clamp(240.0, 420.0).toDouble(),
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 6),
              bottomRight: Radius.circular(mine ? 6 : 18),
            ),
            border: mine ? null : Border.all(color: RxColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                message.recalled ? 'Bu mesaj geri alındı' : message.text,
                style: TextStyle(
                  color: textColor,
                  height: 1.25,
                  fontWeight: message.recalled
                      ? FontWeight.w600
                      : FontWeight.w700,
                  fontStyle: message.recalled
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                mine ? readText : message.senderName,
                style: TextStyle(
                  color: metaColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages({required this.isBusinessOwner});

  final bool isBusinessOwner;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RxColors.surface,
        borderRadius: BorderRadius.circular(RxRadius.md),
        border: Border.all(color: RxColors.line),
      ),
      child: RxEmptyState(
        icon: isBusinessOwner
            ? Icons.support_agent_outlined
            : Icons.chat_bubble_outline,
        title: MessageUiPolicy.emptyInboxTitle(
          isBusinessOwner: isBusinessOwner,
        ),
        text: MessageUiPolicy.emptyInboxText(isBusinessOwner: isBusinessOwner),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFEE2E2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          error,
          style: const TextStyle(
            color: Color(0xFF991B1B),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
