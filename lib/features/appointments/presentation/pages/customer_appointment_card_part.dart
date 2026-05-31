part of 'customer_appointments_page.dart';

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.item,
    required this.onCancel,
    required this.onOpenBusiness,
    required this.onMessage,
    required this.onAddToCalendar,
    required this.onReview,
    required this.onPostponeApprove,
    required this.onPostponeReject,
  });

  final _AppointmentItem item;
  final VoidCallback onCancel;
  final VoidCallback onOpenBusiness;
  final VoidCallback onMessage;
  final VoidCallback onAddToCalendar;
  final VoidCallback onReview;
  final VoidCallback onPostponeApprove;
  final VoidCallback onPostponeReject;

  Color get _bg {
    if (item.isPostponeRequested) return const Color(0xFFFFF7D6);
    if (item.isCancelled) return const Color(0xFFFEE2E2);
    if (item.isCompleted) return const Color(0xFFF1F5F9);
    return Colors.white;
  }

  Color get _accent {
    if (item.isPostponeRequested) return const Color(0xFFD97706);
    if (item.isCancelled) return const Color(0xFFDC2626);
    if (item.isCompleted) return const Color(0xFF64748B);
    return const Color(0xFF2563EB);
  }

  String get _statusText {
    if (item.isPostponeRequested) return 'Erteleme bekliyor';
    if (item.isCancelled) return 'İptal edildi';
    if (item.isCompleted) return 'Geçmiş randevu';
    return 'Aktif randevu';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: _bg,
      margin: const EdgeInsets.fromLTRB(16, 7, 16, 9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: _accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _accent.withValues(alpha: 0.12),
                  child: Icon(Icons.event_available_rounded, color: _accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.businessName.isNotEmpty
                        ? item.businessName
                        : 'Randevu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusText,
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.serviceName.isNotEmpty ? item.serviceName : 'Hizmet',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 7),
            CustomerAppointmentInfoLine(
              icon: Icons.calendar_month_rounded,
              text: '${item.dateText} \u2022 ${item.timeText}',
            ),
            if (item.staffName.isNotEmpty)
              CustomerAppointmentInfoLine(
                icon: Icons.person_outline_rounded,
                text: 'Personel: ${item.staffName}',
              ),
            if (item.appointmentNo.isNotEmpty)
              CustomerAppointmentInfoLine(
                icon: Icons.tag_rounded,
                text: 'Randevu No: ${item.appointmentNo}',
              ),
            if (item.isPostponeRequested) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  'Kurumsal Kullanıcı bu randevu iÇin erteleme talebi oluŞturmuŞ. Uygunsa kabul edebilir veya reddedebilirsiniz.',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                    height: 1.3,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _ActionsRow(
              item: item,
              onCancel: onCancel,
              onOpenBusiness: onOpenBusiness,
              onMessage: onMessage,
              onAddToCalendar: onAddToCalendar,
              onReview: onReview,
              onPostponeApprove: onPostponeApprove,
              onPostponeReject: onPostponeReject,
            ),
          ],
        ),
      ),
    );
  }
}
