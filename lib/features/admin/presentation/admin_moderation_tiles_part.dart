part of 'admin_moderation_page.dart';

class _ClaimTile extends StatelessWidget {
  const _ClaimTile({
    required this.doc,
    required this.onStatus,
    required this.onNote,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Future<void> Function(String status) onStatus;
  final Future<void> Function(String note) onNote;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final name = _text(data['businessName'], 'İşletme');
    final status = _text(data['status'], 'pending');
    final placeId = _text(data['placeId'], '-');
    final owner = _text(data['displayName'], _text(data['email'], '-'));

    return Card(
      child: ListTile(
        leading: _SlaDot(data: data),
        title: Text(name),
        subtitle: Text('Durum: $status\nTalep: $owner\nPlace: $placeId'),
        isThreeLine: true,
        trailing: _StatusMenu(
          statuses: const {
            'approved': 'Onayla',
            'rejected': 'Reddet',
            'needs_review': 'Incelemede',
          },
          onStatus: onStatus,
          onNote: onNote,
        ),
      ),
    );
  }
}

class _PostReportTile extends StatelessWidget {
  const _PostReportTile({
    required this.doc,
    required this.onStatus,
    required this.onNote,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Future<void> Function(String status) onStatus;
  final Future<void> Function(String note) onNote;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final postId = _text(data['postId'], '-');
    final uid = _text(data['uid'], '-');
    final reason = _text(data['reason'], '-');
    final status = _text(data['status'], 'open');

    return Card(
      child: ListTile(
        leading: _SlaDot(data: data),
        title: Text('Post: $postId'),
        subtitle: Text('Durum: $status\nŞikayet eden: $uid\nSebep: $reason'),
        isThreeLine: true,
        trailing: _StatusMenu(
          statuses: const {
            'resolved': 'Çözüldü',
            'rejected': 'Reddet',
            'needs_review': 'Incelemede',
          },
          onStatus: onStatus,
          onNote: onNote,
        ),
      ),
    );
  }
}

class _ModerationBlockTile extends StatelessWidget {
  const _ModerationBlockTile({required this.doc, required this.onUnblock});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Future<void> Function(String uid) onUnblock;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final uid = _text(data['uid'], _text(data['targetId'], '-'));
    final status = _text(data['status'], '-');
    final reason = _text(data['reason'], '-');

    return Card(
      child: ListTile(
        title: Text('Kullanıcı: $uid'),
        subtitle: Text('Durum: $status\nSebep: $reason'),
        trailing: status == 'active'
            ? IconButton(
                tooltip: 'Engeli kaldır',
                onPressed: () async {
                  await onUnblock(uid);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Engel kaldırıldı.')),
                  );
                },
                icon: const Icon(Icons.lock_open_outlined),
              )
            : null,
      ),
    );
  }
}

class _ReviewReportTile extends StatelessWidget {
  const _ReviewReportTile({
    required this.doc,
    required this.onStatus,
    required this.onNote,
    required this.onHide,
    required this.onRestore,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Future<void> Function(String status) onStatus;
  final Future<void> Function(String note) onNote;
  final Future<void> Function(String reviewId) onHide;
  final Future<void> Function(String reviewId) onRestore;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final reviewId = _text(data['reviewId'], '-');
    final uid = _text(data['uid'], '-');
    final reason = _text(data['reason'], '-');
    final status = _text(data['status'], 'open');

    return Card(
      child: ListTile(
        leading: _SlaDot(data: data),
        title: Text('Yorum: $reviewId'),
        subtitle: Text('Durum: $status\nŞikayet eden: $uid\nSebep: $reason'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'hide') {
              await onHide(reviewId);
            } else if (value == 'restore') {
              await onRestore(reviewId);
            } else if (value == 'note') {
              final note = await _askSupportNote(context);
              if (note == null || note.trim().isEmpty) return;
              await onNote(note);
            } else {
              await onStatus(value);
            }
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Yorum işlemi tamamlandı: $value')),
            );
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'note', child: Text('Destek notu ekle')),
            PopupMenuItem(value: 'hide', child: Text('Yorumu gizle')),
            PopupMenuItem(value: 'restore', child: Text('Yorumu geri ac')),
            PopupMenuItem(value: 'resolved', child: Text('Çözüldü')),
            PopupMenuItem(value: 'rejected', child: Text('Reddet')),
          ],
        ),
      ),
    );
  }
}

class _CampaignReportTile extends StatelessWidget {
  const _CampaignReportTile({
    required this.doc,
    required this.onStatus,
    required this.onNote,
    required this.onHide,
    required this.onRestore,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Future<void> Function(String status) onStatus;
  final Future<void> Function(String note) onNote;
  final Future<void> Function(String campaignId, String sourceCollection)
  onHide;
  final Future<void> Function(String campaignId, String sourceCollection)
  onRestore;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final campaignId = _text(data['campaignId'], '-');
    final collection = _text(data['sourceCollection'], 'businessCampaigns');
    final uid = _text(data['uid'], '-');
    final reason = _text(data['reason'], '-');
    final status = _text(data['status'], 'open');

    return Card(
      child: ListTile(
        leading: _SlaDot(data: data),
        title: Text('Kampanya: $campaignId'),
        subtitle: Text(
          'Durum: $status\nKaynak: $collection\nŞikayet eden: $uid\nSebep: $reason',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'hide') {
              await onHide(campaignId, collection);
            } else if (value == 'restore') {
              await onRestore(campaignId, collection);
            } else if (value == 'note') {
              final note = await _askSupportNote(context);
              if (note == null || note.trim().isEmpty) return;
              await onNote(note);
            } else {
              await onStatus(value);
            }
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kampanya işlemi tamamlandı: $value')),
            );
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'hide', child: Text('Kampanyayı gizle')),
            PopupMenuItem(value: 'restore', child: Text('Kampanyayı geri aç')),
            PopupMenuItem(value: 'resolved', child: Text('Çözüldü')),
            PopupMenuItem(value: 'rejected', child: Text('Reddet')),
          ],
        ),
      ),
    );
  }
}

