import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/theme/rx_ui.dart';
import 'package:rxpro_mobile/features/messages/domain/message_ui_policy.dart';
import 'package:rxpro_mobile/features/messages/presentation/widgets/messages_ui_widgets.dart';

import 'data/messages_repository.dart';

class MessagesInboxPage extends StatefulWidget {
  const MessagesInboxPage({super.key});

  @override
  State<MessagesInboxPage> createState() => _MessagesInboxPageState();
}

class _MessagesInboxPageState extends State<MessagesInboxPage> {
  final MessagesRepository _repository = MessagesRepository();

  Stream<List<String>> _ownedBusinessIdsStream(String ownerUid) {
    return _repository.watchOwnedBusinessIds(ownerUid);
  }

  Stream<List<MessageThreadItem>> _customerThreadsStream(String customerUid) {
    return _repository.watchCustomerThreads(customerUid);
  }

  Stream<List<MessageThreadItem>> _businessThreadsStream(
    List<String> businessIds,
  ) {
    return _repository.watchBusinessThreads(businessIds);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MessageUserContext?>(
      stream: _repository.watchCurrentUserContext(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;

        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mesajlar')),
            body: const Center(
              child: Text('Mesajları görmek için giriş yapın.'),
            ),
          );
        }

        if (user.isBusinessOwner) {
          return StreamBuilder<List<String>>(
            stream: _ownedBusinessIdsStream(user.uid),
            builder: (context, businessSnapshot) {
              final businessIds = businessSnapshot.data ?? [];

              return _InboxBody(
                title: 'İşletme Mesaj Kutusu',
                subtitle:
                    'Bireysel kullanıcılardan gelen soru, talep ve geri bildirimleri buradan yönetin.',
                isBusinessOwner: true,
                stream: _businessThreadsStream(businessIds),
                currentUid: user.uid,
                currentName: user.name,
              );
            },
          );
        }

        return _InboxBody(
          title: 'Mesajlarım',
          subtitle:
              'İşletmelerle yaptığınız görüşmeleri ve yanıtları buradan takip edin.',
          isBusinessOwner: false,
          stream: _customerThreadsStream(user.uid),
          currentUid: user.uid,
          currentName: user.name,
        );
      },
    );
  }
}

class _InboxBody extends StatelessWidget {
  const _InboxBody({
    required this.title,
    required this.subtitle,
    required this.isBusinessOwner,
    required this.stream,
    required this.currentUid,
    required this.currentName,
  });

  final String title;
  final String subtitle;
  final bool isBusinessOwner;
  final Stream<List<MessageThreadItem>> stream;
  final String currentUid;
  final String currentName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<MessageThreadItem>>(
        stream: stream,
        builder: (context, snapshot) {
          final threads = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              MessagesRoleHeader(
                title: title,
                subtitle: subtitle,
                isBusinessOwner: isBusinessOwner,
                threadCount: threads.length,
                onNewMessage: isBusinessOwner
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NewCustomerMessagePage(),
                          ),
                        );
                      },
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const MessagesLoadingList()
              else if (snapshot.hasError)
                _ErrorBox(error: snapshot.error.toString())
              else if (threads.isEmpty)
                _EmptyMessages(isBusinessOwner: isBusinessOwner)
              else
                ...threads.map(
                  (thread) => _ThreadCard(
                    thread: thread,
                    isBusinessOwner: isBusinessOwner,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MessageThreadPage(
                            threadId: thread.id,
                            isBusinessOwner: isBusinessOwner,
                            currentUid: currentUid,
                            currentName: currentName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class NewCustomerMessagePage extends StatefulWidget {
  const NewCustomerMessagePage({
    super.key,
    this.initialBusinessId,
    this.initialBusinessName,
    this.initialBusinessCategory,
  });

  final String? initialBusinessId;
  final String? initialBusinessName;
  final String? initialBusinessCategory;

  @override
  State<NewCustomerMessagePage> createState() => _NewCustomerMessagePageState();
}

class _NewCustomerMessagePageState extends State<NewCustomerMessagePage> {
  final MessagesRepository _repository = MessagesRepository();
  final messageController = TextEditingController(
    text: 'Merhaba, bilgi almak istiyorum.',
  );

  String topic = 'request';
  bool sending = false;

  final topics = MessageUiPolicy.customerNewMessageTopics;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Stream<List<MessageBusinessItem>> _businessesStream() {
    return _repository.watchActiveBusinesses(
      initialBusinessId: widget.initialBusinessId,
      initialBusinessName: widget.initialBusinessName,
      initialBusinessCategory: widget.initialBusinessCategory,
    );
  }

  Future<void> _sendFirstMessage(MessageBusinessItem business) async {
    final text = messageController.text.trim();

    if (text.isEmpty) {
      _showMessage('Mesaj boş olamaz.');
      return;
    }

    setState(() => sending = true);

    try {
      final result = await _repository.sendFirstMessage(
        business: business,
        topic: topic,
        text: text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MessageThreadPage(
            threadId: result.threadId,
            isBusinessOwner: false,
            currentUid: result.currentUid,
            currentName: result.currentName,
          ),
        ),
      );
    } catch (e) {
      _showMessage('Mesaj gönderilemedi: $e');
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final fixedBusiness = widget.initialBusinessId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Mesaj')),
      body: StreamBuilder<List<MessageBusinessItem>>(
        stream: _businessesStream(),
        builder: (context, snapshot) {
          final businesses = snapshot.data ?? [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'İşletmeye Mesaj Gönder',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                fixedBusiness
                    ? 'İncelediğiniz işletmeye doğrudan mesaj gönderin.'
                    : 'Soru, randevu talebi, öneri veya şikayetinizi işletmeye iletin.',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: topic,
                decoration: InputDecoration(
                  labelText: 'Mesaj konusu',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: topics.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => topic = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Mesajınız',
                  prefixIcon: const Icon(Icons.message_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'İşletme',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (businesses.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Kayıtlı aktif işletme bulunamadı.'),
                  ),
                )
              else
                ...businesses.map(
                  (business) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE0F7FA),
                        child: Icon(Icons.storefront, color: Color(0xFF18B7C9)),
                      ),
                      title: Text(business.name),
                      subtitle: Text(business.category),
                      trailing: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      onTap: sending ? null : () => _sendFirstMessage(business),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class MessageThreadPage extends StatefulWidget {
  const MessageThreadPage({
    super.key,
    required this.threadId,
    required this.isBusinessOwner,
    required this.currentUid,
    required this.currentName,
  });

  final String threadId;
  final bool isBusinessOwner;
  final String currentUid;
  final String currentName;

  @override
  State<MessageThreadPage> createState() => _MessageThreadPageState();
}

class _MessageThreadPageState extends State<MessageThreadPage> {
  final MessagesRepository _repository = MessagesRepository();
  final messageController = TextEditingController();

  bool sending = false;
  int _lastReadMessageCount = -1;

  @override
  void initState() {
    super.initState();
    _markThreadAsRead();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> _markThreadAsRead() async {
    await _repository.markThreadAsRead(
      threadId: widget.threadId,
      isBusinessOwner: widget.isBusinessOwner,
      currentUid: widget.currentUid,
    );
  }

  Stream<MessageThreadDetails> _threadStream() {
    return _repository.watchThread(widget.threadId);
  }

  Stream<List<MessageItem>> _messagesStream() {
    return _repository.watchMessages(widget.threadId);
  }

  Future<void> _sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || sending) return;

    setState(() => sending = true);

    try {
      await _repository.sendMessage(
        threadId: widget.threadId,
        isBusinessOwner: widget.isBusinessOwner,
        currentUid: widget.currentUid,
        currentName: widget.currentName,
        text: text,
      );

      messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mesaj gönderilemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _confirmRecallMessage(MessageItem message) async {
    if (message.senderUid != widget.currentUid || message.recalled) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mesajı geri al'),
          content: const Text(
            'Bu mesaj iki tarafta da "Bu mesaj geri alındı" olarak görünecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Geri Al'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    await _repository.recallMessage(
      threadId: widget.threadId,
      messageId: message.id,
    );
  }

  Future<void> _closeThread() async {
    await _repository.setThreadStatus(
      threadId: widget.threadId,
      status: 'closed',
    );
  }

  Future<void> _openThread() async {
    await _repository.setThreadStatus(
      threadId: widget.threadId,
      status: 'open',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MessageThreadDetails>(
      stream: _threadStream(),
      builder: (context, threadSnapshot) {
        final thread = threadSnapshot.data;
        final businessName = thread?.businessName ?? 'İşletme';
        final customerName = thread?.customerName ?? 'Bireysel kullanıcı';
        final status = thread?.status ?? 'open';
        final topic = thread?.topic ?? 'general';
        final closed = MessageUiPolicy.isClosed(status);
        final otherName = widget.isBusinessOwner ? customerName : businessName;

        return Scaffold(
          appBar: AppBar(
            title: Text(otherName),
            actions: [
              if (widget.isBusinessOwner)
                IconButton(
                  onPressed: closed ? _openThread : _closeThread,
                  icon: Icon(
                    closed ? Icons.lock_open : Icons.check_circle_outline,
                  ),
                  tooltip: closed ? 'Görüşmeyi aç' : 'Görüşmeyi kapat',
                ),
            ],
          ),
          body: Column(
            children: [
              MessageThreadContextPanel(
                name: otherName,
                topic: topic,
                status: status,
                isBusinessOwner: widget.isBusinessOwner,
              ),
              Expanded(
                child: StreamBuilder<List<MessageItem>>(
                  stream: _messagesStream(),
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? [];
                    if (messages.length != _lastReadMessageCount) {
                      _lastReadMessageCount = messages.length;
                      unawaited(_markThreadAsRead());
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(RxSpace.md),
                        child: MessagesLoadingList(),
                      );
                    }

                    if (messages.isEmpty) {
                      return const Center(
                        child: RxEmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: 'Henüz mesaj yok',
                          text: 'İlk yanıt geldiğinde görüşme burada görünür.',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final mine = message.senderUid == widget.currentUid;

                        return _MessageBubble(
                          message: message,
                          mine: mine,
                          isBusinessOwner: widget.isBusinessOwner,
                          onRecall: () => _confirmRecallMessage(message),
                        );
                      },
                    );
                  },
                ),
              ),
              if (closed)
                MessageClosedNotice(isBusinessOwner: widget.isBusinessOwner)
              else
                MessageInputBar(
                  controller: messageController,
                  isBusinessOwner: widget.isBusinessOwner,
                  sending: sending,
                  onSend: _sendMessage,
                ),
            ],
          ),
        );
      },
    );
  }
}

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
    final unread = isBusinessOwner
        ? thread.unreadForBusiness
        : thread.unreadForCustomer;
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
