import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/theme/rx_ui.dart';
import 'package:rxpro_mobile/features/messages/domain/message_ui_policy.dart';

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
                label: '$threadCount gorusme',
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

class MessageClosedNotice extends StatelessWidget {
  const MessageClosedNotice({
    super.key,
    required this.isBusinessOwner,
  });

  final bool isBusinessOwner;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(RxSpace.md, 0, RxSpace.md, RxSpace.md),
        padding: const EdgeInsets.all(RxSpace.md),
        decoration: BoxDecoration(
          color: RxColors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(RxRadius.md),
          border: Border.all(color: RxColors.warning.withValues(alpha: 0.24)),
        ),
        child: Text(
          MessageUiPolicy.closedThreadNotice(isBusinessOwner: isBusinessOwner),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: RxColors.warning,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class MessageInputBar extends StatelessWidget {
  const MessageInputBar({
    super.key,
    required this.controller,
    required this.isBusinessOwner,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isBusinessOwner;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          RxSpace.md,
          RxSpace.sm,
          RxSpace.md,
          RxSpace.md,
        ),
        decoration: const BoxDecoration(
          color: RxColors.background,
          border: Border(top: BorderSide(color: RxColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: MessageUiPolicy.inputHint(
                    isBusinessOwner: isBusinessOwner,
                  ),
                  filled: true,
                  fillColor: RxColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: RxSpace.sm),
            SizedBox(
              width: 48,
              height: 48,
              child: FilledButton(
                onPressed: sending ? null : onSend,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
