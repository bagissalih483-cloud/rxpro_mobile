part of 'admin_moderation_page.dart';

class _ModerationFilterBar extends StatelessWidget {
  const _ModerationFilterBar({
    required this.controller,
    required this.statusFilter,
    required this.onQueryChanged,
    required this.onStatusChanged,
  });

  final TextEditingController controller;
  final String statusFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final search = TextField(
          controller: controller,
          onChanged: onQueryChanged,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'Ara',
            hintText: 'UID, isletme, sebep veya dokuman no',
            border: OutlineInputBorder(),
          ),
        );
        final status = DropdownButtonFormField<String>(
          initialValue: statusFilter,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.tune_rounded),
            labelText: 'Durum',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tum kayitlar')),
            DropdownMenuItem(value: 'open', child: Text('Acik')),
            DropdownMenuItem(value: 'pending', child: Text('Bekleyen')),
            DropdownMenuItem(value: 'needs_review', child: Text('Incelemede')),
            DropdownMenuItem(value: 'approved', child: Text('Onaylanan')),
            DropdownMenuItem(value: 'resolved', child: Text('Cozulen')),
            DropdownMenuItem(value: 'rejected', child: Text('Reddedilen')),
            DropdownMenuItem(value: 'active', child: Text('Aktif')),
          ],
          onChanged: onStatusChanged,
        );

        if (narrow) {
          return Column(children: [search, const SizedBox(height: 10), status]);
        }

        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            SizedBox(width: 220, child: status),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkQueueActions extends StatelessWidget {
  const _BulkQueueActions({
    required this.count,
    required this.label,
    required this.statuses,
    required this.onStatus,
  });

  final int count;
  final String label;
  final Map<String, String> statuses;
  final Future<void> Function(String status) onStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: $count kayit',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Toplu islem',
            onSelected: (value) async {
              final approved = await _confirmBulkAction(
                context: context,
                count: count,
                label: label,
                status: value,
              );
              if (!approved) return;

              await onStatus(value);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$count kayit guncellendi: $value')),
              );
            },
            itemBuilder: (context) => statuses.entries
                .map(
                  (entry) =>
                      PopupMenuItem(value: entry.key, child: Text(entry.value)),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirmBulkAction({
  required BuildContext context,
  required int count,
  required String label,
  required String status,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Toplu islem onayi'),
        content: Text(
          '$label kuyrugunda filtrelenen $count kayit "$status" durumuna alinacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Onayla'),
          ),
        ],
      );
    },
  );

  return result == true;
}

class _AdminAuditLogList extends StatelessWidget {
  const _AdminAuditLogList({
    required this.repository,
    required this.query,
    required this.statusFilter,
  });

  final AdminModerationRepository repository;
  final String query;
  final String statusFilter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.watchAdminAuditLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingTile();
        }
        final docs = _filterDocs(
          snapshot.data?.docs ??
              const <QueryDocumentSnapshot<Map<String, dynamic>>>[],
          query: query,
          statusFilter: statusFilter,
        );
        if (docs.isEmpty) {
          return const _EmptyTile(text: 'Admin denetim kaydı yok.');
        }
        return Column(
          children: docs.map((doc) => _AdminAuditLogTile(doc: doc)).toList(),
        );
      },
    );
  }
}

class _AdminAuditLogTile extends StatelessWidget {
  const _AdminAuditLogTile({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final action = _text(data['action'], '-');
    final actor = _text(data['actorUid'], '-');
    final targetCollection = _text(data['targetCollection'], '-');
    final targetId = _text(data['targetId'], '-');
    final metadata = data['metadata'];
    final note = metadata is Map ? _text(metadata['note']) : '';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.manage_search_rounded),
        title: Text(action),
        subtitle: Text(
          'Admin: $actor\nHedef: $targetCollection / $targetId'
          '${note.isEmpty ? '' : '\nNot: $note'}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({
    required this.statuses,
    required this.onStatus,
    this.onNote,
  });

  final Map<String, String> statuses;
  final Future<void> Function(String status) onStatus;
  final Future<void> Function(String note)? onNote;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'note') {
          final note = await _askSupportNote(context);
          if (note == null || note.trim().isEmpty || onNote == null) return;
          await onNote!(note);
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Destek notu eklendi.')));
          return;
        }

        await onStatus(value);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayit $value olarak isaretlendi.')),
        );
      },
      itemBuilder: (context) => [
        if (onNote != null)
          const PopupMenuItem(value: 'note', child: Text('Destek notu ekle')),
        ...statuses.entries.map(
          (entry) => PopupMenuItem(value: entry.key, child: Text(entry.value)),
        ),
      ],
    );
  }
}

class _SlaDot extends StatelessWidget {
  const _SlaDot({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final createdAt = _readDate(data['createdAt']);
    final reviewedAt = _readDate(data['reviewedAt']);
    final status = _text(
      data['status'],
      _text(data['reviewStatus']),
    ).toLowerCase();
    final isClosed =
        reviewedAt != null ||
        status == 'resolved' ||
        status == 'approved' ||
        status == 'rejected' ||
        status == 'inactive';
    final age = createdAt == null
        ? null
        : DateTime.now().difference(createdAt).inHours;

    final color = isClosed
        ? const Color(0xFF16A34A)
        : age == null
        ? const Color(0xFF64748B)
        : age >= 48
        ? const Color(0xFFDC2626)
        : age >= 24
        ? const Color(0xFFD97706)
        : const Color(0xFF2563EB);
    final label = isClosed
        ? 'Kapandi'
        : age == null
        ? 'Tarih yok'
        : age >= 48
        ? '${age}sa gecikti'
        : age >= 24
        ? '${age}sa bekliyor'
        : '${age}sa yeni';

    return Tooltip(
      message: label,
      child: CircleAvatar(
        radius: 12,
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(Icons.circle, size: 10, color: color),
      ),
    );
  }
}

Future<String?> _askSupportNote(BuildContext context) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Destek notu'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          maxLength: 1200,
          decoration: const InputDecoration(
            hintText: 'Karar gerekcesi, takip adimi veya destek notu',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Ekle'),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Yükleniyor'),
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(title: Text(text)));
  }
}

List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
  required String query,
  required String statusFilter,
}) {
  final cleanQuery = query.trim().toLowerCase();
  final cleanStatus = statusFilter.trim().toLowerCase();

  return docs
      .where((doc) {
        final data = doc.data();
        return AdminModerationFilterPolicy.matches(
          id: doc.id,
          data: data,
          query: cleanQuery,
          statusFilter: cleanStatus,
        );
      })
      .toList(growable: false);
}

String _text(Object? value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}
