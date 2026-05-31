part of 'admin_moderation_page.dart';

class _AbuseLogTile extends StatelessWidget {
  const _AbuseLogTile({required this.doc, required this.onBlock});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Future<void> Function(String uid, String reason) onBlock;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final functionName = _text(data['functionName'], 'function');
    final reason = _text(data['reason'], '-');
    final uid = _text(data['uid'], '-');
    final detail = _text(data['detail'], '');

    return Card(
      child: ListTile(
        title: Text(functionName),
        subtitle: Text('Sebep: $reason\nUID: $uid\n$detail'),
        isThreeLine: true,
        trailing: uid == '-'
            ? null
            : IconButton(
                tooltip: 'Kullanıcıyı engelle',
                onPressed: () async {
                  await onBlock(uid, reason);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$uid engellendi.')));
                },
                icon: const Icon(Icons.block_outlined),
              ),
      ),
    );
  }
}
