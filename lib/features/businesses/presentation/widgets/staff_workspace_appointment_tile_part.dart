part of '../../staff_workspace_page.dart';

class _AppointmentWorkTile extends StatelessWidget {
  const _AppointmentWorkTile({
    required this.title,
    required this.time,
    required this.status,
    required this.statusLabel,
    required this.isOverdue,
    required this.readOnly,
    required this.onStart,
    required this.onComplete,
    this.onCreateReminder,
    this.onCancelNoShow,
  });

  final String title;
  final String time;
  final String status;
  final String statusLabel;
  final bool isOverdue;
  final bool readOnly;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback? onCreateReminder;
  final VoidCallback? onCancelNoShow;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final inProgress =
        normalized == 'inprogress' || normalized == 'in_progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOverdue ? const Color(0xFFF97316) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isOverdue
                    ? const Color(0xFFFFEDD5)
                    : inProgress
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFEFF6FF),
                child: Icon(
                  isOverdue
                      ? Icons.warning_amber_rounded
                      : inProgress
                      ? Icons.timelapse_rounded
                      : Icons.event_available_outlined,
                  color: isOverdue
                      ? const Color(0xFFEA580C)
                      : inProgress
                      ? const Color(0xFFD97706)
                      : const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$time • $statusLabel',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!readOnly) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: inProgress ? null : onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('İşleme Başladım'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('İşlemi Bitirdim'),
                  ),
                ),
              ],
            ),
            if (isOverdue) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCreateReminder,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Uyarı oluştur'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancelNoShow,
                      icon: const Icon(Icons.event_busy_outlined),
                      label: const Text('İptal / gelmedi'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
