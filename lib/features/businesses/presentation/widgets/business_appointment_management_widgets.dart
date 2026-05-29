import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/app/app_routes.dart';

Future<void> showBusinessCustomerQuickProfile({
  required BuildContext context,
  required String businessId,
  required String businessName,
  required Map<String, dynamic> data,
  required String customerName,
}) async {
  final email = _field(data, ['customerEmail', 'email', 'clientEmail']);
  final phone = _field(data, ['customerPhone', 'phone', 'clientPhone']);
  final uid = _field(data, [
    'customerUid',
    'customerId',
    'userId',
    'uid',
    'clientUid',
  ]);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  _initialsOf(customerName),
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                customerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              if (email.isNotEmpty && email != '-')
                BusinessCustomerInfoLine(
                  icon: Icons.mail_outline_rounded,
                  text: email,
                ),
              if (phone.isNotEmpty && phone != '-')
                BusinessCustomerInfoLine(
                  icon: Icons.phone_outlined,
                  text: phone,
                ),
              if (uid.isNotEmpty && uid != '-')
                BusinessCustomerInfoLine(
                  icon: Icons.badge_outlined,
                  text: 'Kullanıcı ID: $uid',
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();

                    if (uid.isEmpty || uid == '-') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bireysel kullanıcı ID bilgisi bulunamadı.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pushNamed(
                      AppRoutes.businessCustomerDirectMessage,
                      arguments: BusinessCustomerDirectMessageRouteArgs(
                        businessId: businessId,
                        businessName: businessName,
                        customerUid: uid,
                        customerName: customerName,
                        customerEmail: email,
                        customerPhone: phone,
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Mesaj Gönder'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _field(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }

  return '';
}

String _initialsOf(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'M';
  final parts = trimmed
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

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

class BusinessAppointmentStatusPill extends StatelessWidget {
  const BusinessAppointmentStatusPill({
    super.key,
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class BusinessCustomerInfoLine extends StatelessWidget {
  const BusinessCustomerInfoLine({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
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
