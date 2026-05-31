part of 'messages_inbox_page.dart';

class MessagesInboxPage extends StatefulWidget {
  const MessagesInboxPage({super.key});

  @override
  State<MessagesInboxPage> createState() => _MessagesInboxPageState();
}

class _MessagesInboxPageState extends State<MessagesInboxPage> {
  final MessagesRepository _repository = MessagesRepository();
  late final Stream<MessageUserContext?> _userContextStream;
  final Map<String, Stream<List<String>>> _ownedBusinessIdsStreams = {};
  final Map<String, Stream<List<MessageThreadItem>>> _customerThreadStreams =
      {};
  final Map<String, Stream<List<MessageThreadItem>>> _businessThreadStreams =
      {};

  @override
  void initState() {
    super.initState();
    _userContextStream = _repository.watchCurrentUserContext();
  }

  Stream<List<String>> _ownedBusinessIdsStream(String ownerUid) {
    return _ownedBusinessIdsStreams.putIfAbsent(
      ownerUid,
      () => _repository.watchOwnedBusinessIds(ownerUid),
    );
  }

  Stream<List<MessageThreadItem>> _customerThreadsStream(String customerUid) {
    return _customerThreadStreams.putIfAbsent(
      customerUid,
      () => _repository.watchCustomerThreads(customerUid),
    );
  }

  Stream<List<MessageThreadItem>> _businessThreadsStream(
    List<String> businessIds,
  ) {
    final sortedBusinessIds = [...businessIds]..sort();
    final cacheKey = sortedBusinessIds.join('|');
    return _businessThreadStreams.putIfAbsent(
      cacheKey,
      () => _repository.watchBusinessThreads(sortedBusinessIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MessageUserContext?>(
      stream: _userContextStream,
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
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.messagesNewCustomer);
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
                      Navigator.of(context).pushNamed(
                        AppRoutes.messageThread,
                        arguments: MessageThreadRouteArgs(
                          threadId: thread.id,
                          isBusinessOwner: isBusinessOwner,
                          currentUid: currentUid,
                          currentName: currentName,
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
