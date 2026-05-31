part of 'customer_appointments_page.dart';

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({
    required this.item,
    required this.onOpen,
  });

  final _AppointmentItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFDBEAFE),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sıradaki Randevum',
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.serviceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            CustomerAppointmentInfoLine(
              icon: Icons.calendar_month_rounded,
              text: '${item.dateText} • ${item.timeText}',
            ),
            CustomerAppointmentInfoLine(
              icon: Icons.person_outline_rounded,
              text: 'Personel: ${item.staffName}',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.manage_search_rounded),
                label: const Text('Randevunu Yönet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
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

  @override
  Widget build(BuildContext context) {
    if (item.isCancelled) {
      return const CustomerAppointmentStatusOnlyLine(
        icon: Icons.cancel_outlined,
        text: 'Bu randevu iptal edildi.',
        color: Color(0xFFDC2626),
      );
    }

    if (item.isCompleted) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onOpenBusiness,
              icon: const Icon(Icons.event_repeat_rounded),
              label: const Text('Tekrar Randevu Al'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReview,
              icon: const Icon(Icons.star_outline_rounded),
              label: const Text('Değerlendir'),
            ),
          ),
        ],
      );
    }

    if (item.isPostponeRequested) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPostponeReject,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Reddet'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: onPostponeApprove,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Kabul Et'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('İptal Et'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: 'Mesaj',
          onPressed: onMessage,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: 'Takvime ekle',
          onPressed: onAddToCalendar,
          icon: const Icon(Icons.event_note_outlined),
        ),
      ],
    );
  }
}
