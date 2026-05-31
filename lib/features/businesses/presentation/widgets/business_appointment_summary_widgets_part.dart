part of 'business_appointment_management_widgets.dart';

class BusinessAppointmentSummaryCard extends StatelessWidget {
  const BusinessAppointmentSummaryCard({
    super.key,
    required this.businessName,
    required this.stream,
  });

  final String businessName;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  String _clean(dynamic value) => value?.toString().trim() ?? '';

  String _statusOf(Map<String, dynamic> data) {
    return _clean(
      data['status'] ??
          data['appointmentStatus'] ??
          data['state'] ??
          data['bookingStatus'],
    ).toLowerCase();
  }

  bool _isCancelled(Map<String, dynamic> data) {
    final status = _statusOf(data);
    final approval = _clean(
      data['customerApprovalStatus'] ?? data['postponeRequestStatus'],
    ).toLowerCase();

    return status.contains('cancel') ||
        status.contains('iptal') ||
        status == 'postpone_rejected' ||
        status == 'reschedule_rejected' ||
        approval == 'rejected' ||
        approval == 'declined' ||
        data['isCancelled'] == true;
  }

  bool _hasPostpone(Map<String, dynamic> data) {
    final status = _statusOf(data);
    final approval = _clean(
      data['customerApprovalStatus'] ?? data['postponeRequestStatus'],
    ).toLowerCase();

    return status == 'postpone_requested' ||
        status == 'reschedule_requested' ||
        approval == 'pending';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final docs =
            snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        var current = 0;
        var cancelled = 0;
        var postponed = 0;

        for (final doc in docs) {
          final data = doc.data();

          if (_isCancelled(data)) {
            cancelled++;
          } else if (_hasPostpone(data)) {
            postponed++;
          } else {
            current++;
          }
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _BusinessSummaryChip(
                      label: 'Mevcut',
                      count: current,
                      fg: const Color(0xFF2563EB),
                      bg: const Color(0xFFEFF6FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BusinessSummaryChip(
                      label: 'İptal',
                      count: cancelled,
                      fg: const Color(0xFFDC2626),
                      bg: const Color(0xFFFFE4E6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _BusinessSummaryChip(
                      label: 'Erteleme',
                      count: postponed,
                      fg: const Color(0xFFD97706),
                      bg: const Color(0xFFFFF7D6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BusinessSummaryChip extends StatelessWidget {
  const _BusinessSummaryChip({
    required this.label,
    required this.count,
    required this.fg,
    required this.bg,
  });

  final String label;
  final int count;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: fg.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
