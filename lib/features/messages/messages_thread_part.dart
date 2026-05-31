part of 'messages_inbox_page.dart';

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
  late final MessageThreadController _controller;
  late final Stream<MessageThreadDetails> _threadDetailsStream;
  late final Stream<List<MessageItem>> _messageItemsStream;

  @override
  void initState() {
    super.initState();
    _controller = MessageThreadController(
      threadId: widget.threadId,
      isBusinessOwner: widget.isBusinessOwner,
      currentUid: widget.currentUid,
      currentName: widget.currentName,
    );
    _threadDetailsStream = _controller.watchThread();
    _messageItemsStream = _controller.watchMessages();
    _controller.markThreadAsRead();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    try {
      await _controller.sendMessage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mesaj gönderilemedi: $e')));
      }
    }
  }

  Future<void> _confirmRecallMessage(MessageItem message) async {
    if (!_controller.canRecall(message)) return;

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

    await _controller.recallMessage(message);
  }

  Future<void> _closeThread() async {
    await _controller.closeThread();
  }

  Future<void> _openThread() async {
    await _controller.openThread();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return StreamBuilder<MessageThreadDetails>(
          stream: _threadDetailsStream,
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
                  stream: _messageItemsStream,
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? [];
                    _controller.markReadForMessageList(messages);

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
                  controller: _controller.composeController.textController,
                  isBusinessOwner: widget.isBusinessOwner,
                  sending: _controller.sending,
                  onSend: _sendMessage,
                ),
            ],
          ),
        );
          },
        );
      },
    );
  }
}
