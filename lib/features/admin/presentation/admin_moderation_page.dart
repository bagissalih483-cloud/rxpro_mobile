import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/admin/data/admin_moderation_repository.dart';
import 'package:rxpro_mobile/features/admin/domain/admin_moderation_filter_policy.dart';

part 'admin_moderation_playbook_part.dart';
part 'admin_moderation_support_part.dart';

class AdminModerationPage extends StatefulWidget {
  AdminModerationPage({super.key, AdminModerationRepository? repository})
    : _repository = repository ?? AdminModerationRepository();

  final AdminModerationRepository _repository;

  @override
  State<AdminModerationPage> createState() => _AdminModerationPageState();
}

class _AdminModerationPageState extends State<AdminModerationPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';

  AdminModerationRepository get _repository => widget._repository;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Moderasyon')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ModerationFilterBar(
            controller: _searchController,
            statusFilter: _statusFilter,
            onQueryChanged: (value) {
              setState(() => _query = value);
            },
            onStatusChanged: (value) {
              if (value == null) return;
              setState(() => _statusFilter = value);
            },
          ),
          const SizedBox(height: 18),
          const _ModerationPlaybookCard(),
          const SizedBox(height: 18),
          _SectionHeader(
            icon: Icons.verified_user_outlined,
            title: 'İşletme sahiplenme kuyruğu',
          ),
          _ClaimRequestList(
            repository: _repository,
            query: _query,
            statusFilter: _statusFilter,
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.report_gmailerrorred_outlined,
            title: 'İçerik şikayetleri',
          ),
          _PostReportList(
            repository: _repository,
            query: _query,
            statusFilter: _statusFilter,
          ),
          const SizedBox(height: 20),
          _SectionHeader(icon: Icons.rate_review_outlined, title: 'Yorum şikayetleri'),
          _ReviewReportList(
            repository: _repository,
            query: _query,
            statusFilter: _statusFilter,
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.local_offer_outlined,
            title: 'Kampanya şikayetleri',
          ),
          _CampaignReportList(
            repository: _repository,
            query: _query,
            statusFilter: _statusFilter,
          ),
          const SizedBox(height: 20),
          _SectionHeader(icon: Icons.policy_outlined, title: 'Abuse log'),
          _AbuseLogList(
            repository: _repository,
            query: _query,
            statusFilter: _statusFilter,
          ),
          const SizedBox(height: 20),
          _SectionHeader(icon: Icons.history_rounded, title: 'Admin audit log'),
          _AdminAuditLogList(
            repository: _repository,
            query: _query,
            statusFilter: _statusFilter,
          ),
          const SizedBox(height: 20),
          _SectionHeader(icon: Icons.block_outlined, title: 'Engelleme kayitlari'),
          _ModerationBlockList(
            repository: _repository,
            query: _query,
            statusFilter: _statusFilter,
          ),
        ],
      ),
    );
  }
}

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
          value: statusFilter,
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
          return Column(
            children: [
              search,
              const SizedBox(height: 10),
              status,
            ],
          );
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

class _ClaimRequestList extends StatelessWidget {
  const _ClaimRequestList({
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
      stream: repository.watchClaimRequests(),
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
          return const _EmptyTile(text: 'Bekleyen sahiplenme talebi yok.');
        }
        return Column(
          children: [
            _BulkQueueActions(
              count: docs.length,
              label: 'Sahiplenme',
              statuses: const {
                'needs_review': 'Toplu incelemeye al',
                'rejected': 'Toplu reddet',
              },
              onStatus: (status) async {
                for (final doc in docs) {
                  await repository.updateClaimStatus(
                    claimId: doc.id,
                    status: status,
                  );
                }
              },
            ),
            ...docs.map(
              (doc) => _ClaimTile(
                doc: doc,
                onStatus: (status) => repository.updateClaimStatus(
                  claimId: doc.id,
                  status: status,
                ),
                onNote: (note) => repository.addSupportNote(
                  targetCollection: 'businessClaimRequests',
                  targetId: doc.id,
                  note: note,
                  metadata: doc.data(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PostReportList extends StatelessWidget {
  const _PostReportList({
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
      stream: repository.watchPostReports(),
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
          return const _EmptyTile(text: 'Bekleyen içerik şikayeti yok.');
        }
        return Column(
          children: [
            _BulkQueueActions(
              count: docs.length,
              label: 'Post raporu',
              statuses: const {
                'needs_review': 'Toplu incelemeye al',
                'resolved': 'Toplu cozuldu',
                'rejected': 'Toplu reddet',
              },
              onStatus: (status) async {
                for (final doc in docs) {
                  await repository.updatePostReportStatus(
                    reportId: doc.id,
                    status: status,
                    currentData: doc.data(),
                  );
                }
              },
            ),
            ...docs.map(
              (doc) => _PostReportTile(
                doc: doc,
                onStatus: (status) => repository.updatePostReportStatus(
                  reportId: doc.id,
                  status: status,
                  currentData: doc.data(),
                ),
                onNote: (note) => repository.addSupportNote(
                  targetCollection: 'businessProfilePostReports',
                  targetId: doc.id,
                  note: note,
                  metadata: doc.data(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AbuseLogList extends StatelessWidget {
  const _AbuseLogList({
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
      stream: repository.watchAbuseLogs(),
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
          return const _EmptyTile(text: 'Kayitli abuse log yok.');
        }
        return Column(
          children: docs
              .map(
                (doc) => _AbuseLogTile(
                  doc: doc,
                  onBlock: (uid, reason) => repository.blockUser(
                    uid: uid,
                    reason: reason,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ReviewReportList extends StatelessWidget {
  const _ReviewReportList({
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
      stream: repository.watchReviewReports(),
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
          return const _EmptyTile(text: 'Bekleyen yorum şikayeti yok.');
        }
        return Column(
          children: [
            _BulkQueueActions(
              count: docs.length,
              label: 'Yorum raporu',
              statuses: const {
                'needs_review': 'Toplu incelemeye al',
                'resolved': 'Toplu cozuldu',
                'rejected': 'Toplu reddet',
              },
              onStatus: (status) async {
                for (final doc in docs) {
                  await repository.updateReviewReportStatus(
                    reportId: doc.id,
                    status: status,
                    currentData: doc.data(),
                  );
                }
              },
            ),
            ...docs.map(
              (doc) => _ReviewReportTile(
                  doc: doc,
                  onNote: (note) => repository.addSupportNote(
                    targetCollection: 'businessReviewReports',
                    targetId: doc.id,
                    note: note,
                    metadata: doc.data(),
                  ),
                  onStatus: (status) => repository.updateReviewReportStatus(
                    reportId: doc.id,
                    status: status,
                    currentData: doc.data(),
                  ),
                  onHide: (reviewId) => repository.setReviewHidden(
                    reviewId: reviewId,
                    hidden: true,
                    reason: 'review_report',
                  ),
                  onRestore: (reviewId) => repository.setReviewHidden(
                    reviewId: reviewId,
                    hidden: false,
                    reason: 'review_report_restored',
                  ),
                ),
            ),
          ],
        );
      },
    );
  }
}

class _CampaignReportList extends StatelessWidget {
  const _CampaignReportList({
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
      stream: repository.watchCampaignReports(),
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
          return const _EmptyTile(text: 'Bekleyen kampanya şikayeti yok.');
        }
        return Column(
          children: [
            _BulkQueueActions(
              count: docs.length,
              label: 'Kampanya raporu',
              statuses: const {
                'needs_review': 'Toplu incelemeye al',
                'resolved': 'Toplu cozuldu',
                'rejected': 'Toplu reddet',
              },
              onStatus: (status) async {
                for (final doc in docs) {
                  await repository.updateCampaignReportStatus(
                    reportId: doc.id,
                    status: status,
                    currentData: doc.data(),
                  );
                }
              },
            ),
            ...docs.map(
              (doc) => _CampaignReportTile(
                  doc: doc,
                  onNote: (note) => repository.addSupportNote(
                    targetCollection: 'campaignReports',
                    targetId: doc.id,
                    note: note,
                    metadata: doc.data(),
                  ),
                  onStatus: (status) => repository.updateCampaignReportStatus(
                    reportId: doc.id,
                    status: status,
                    currentData: doc.data(),
                  ),
                  onHide: (campaignId, sourceCollection) =>
                      repository.setCampaignHidden(
                        campaignId: campaignId,
                        sourceCollection: sourceCollection,
                        hidden: true,
                        reason: 'campaign_report',
                      ),
                  onRestore: (campaignId, sourceCollection) =>
                      repository.setCampaignHidden(
                        campaignId: campaignId,
                        sourceCollection: sourceCollection,
                        hidden: false,
                        reason: 'campaign_report_restored',
                      ),
                ),
            ),
          ],
        );
      },
    );
  }
}

class _ModerationBlockList extends StatelessWidget {
  const _ModerationBlockList({
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
      stream: repository.watchModerationBlocks(),
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
          return const _EmptyTile(text: 'Aktif engelleme kaydı yok.');
        }
        return Column(
          children: docs
              .map(
                (doc) => _ModerationBlockTile(
                  doc: doc,
                  onUnblock: (uid) => repository.unblockUser(uid: uid),
                ),
              )
              .toList(),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        title: Text('Kullanici: $uid'),
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
  final Future<void> Function(String campaignId, String sourceCollection) onHide;
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
                tooltip: 'Kullaniciyi engelle',
                onPressed: () async {
                  await onBlock(uid, reason);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$uid engellendi.')),
                  );
                },
                icon: const Icon(Icons.block_outlined),
              ),
      ),
    );
  }
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

  return docs.where((doc) {
    final data = doc.data();
    return AdminModerationFilterPolicy.matches(
      id: doc.id,
      data: data,
      query: cleanQuery,
      statusFilter: cleanStatus,
    );
  }).toList(growable: false);
}

String _text(Object? value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}
