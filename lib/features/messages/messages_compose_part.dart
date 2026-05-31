part of 'messages_inbox_page.dart';

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
  late final MessageComposeController _composeController;
  late final Stream<List<MessageBusinessItem>> _activeBusinessesStream;

  final topics = MessageUiPolicy.customerNewMessageTopics;

  @override
  void initState() {
    super.initState();
    _composeController = MessageComposeController(
      initialText: 'Merhaba, bilgi almak istiyorum.',
      initialTopic: 'request',
    );
    _activeBusinessesStream = _repository.watchActiveBusinesses(
      initialBusinessId: widget.initialBusinessId,
      initialBusinessName: widget.initialBusinessName,
      initialBusinessCategory: widget.initialBusinessCategory,
    );
  }

  @override
  void dispose() {
    _composeController.dispose();
    super.dispose();
  }

  Future<void> _sendFirstMessage(MessageBusinessItem business) async {
    final text = _composeController.trimmedText;

    if (!_composeController.canSend) {
      _showMessage('Mesaj boş olamaz.');
      return;
    }

    _composeController.setSending(true);

    try {
      final result = await _repository.sendFirstMessage(
        business: business,
        topic: _composeController.topic,
        text: text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.messageThread,
        arguments: MessageThreadRouteArgs(
          threadId: result.threadId,
          isBusinessOwner: false,
          currentUid: result.currentUid,
          currentName: result.currentName,
        ),
      );
    } catch (e) {
      _showMessage('Mesaj gönderilemedi: $e');
    } finally {
      if (mounted) {
        _composeController.setSending(false);
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

    return AnimatedBuilder(
      animation: _composeController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Yeni Mesaj')),
          body: StreamBuilder<List<MessageBusinessItem>>(
            stream: _activeBusinessesStream,
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
                initialValue: _composeController.topic,
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
                  if (value != null) _composeController.setTopic(value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _composeController.textController,
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
                      trailing: _composeController.sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      onTap: _composeController.sending
                          ? null
                          : () => _sendFirstMessage(business),
                    ),
                  ),
                ),
            ],
          );
            },
          ),
        );
      },
    );
  }
}
