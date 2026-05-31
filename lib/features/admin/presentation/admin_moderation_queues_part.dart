part of 'admin_moderation_page.dart';

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
          return const _EmptyTile(text: 'Kayıtlı güvenlik bildirimi yok.');
        }
        return Column(
          children: docs
              .map(
                (doc) => _AbuseLogTile(
                  doc: doc,
                  onBlock: (uid, reason) =>
                      repository.blockUser(uid: uid, reason: reason),
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

