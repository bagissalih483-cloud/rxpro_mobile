part of 'business_customers_page.dart';

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Müşteri adı, telefon, not veya hizmet ara',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}

class _SegmentFilterBar extends StatelessWidget {
  const _SegmentFilterBar({
    required this.selectedSegmentId,
    required this.stats,
    required this.onSelected,
  });

  final String selectedSegmentId;
  final BusinessCustomerStats stats;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: BusinessCustomerSegments.values.map((segment) {
          final selected = selectedSegmentId == segment.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text('${segment.label} (${stats.countFor(segment.id)})'),
              onSelected: (_) => onSelected(segment.id),
              selectedColor: const Color(0xFFDDF4FF),
              side: BorderSide(
                color: selected
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.record,
    required this.onClassify,
    required this.onMessage,
  });

  final BusinessCustomerRecord record;
  final VoidCallback onClassify;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final segmentColor = businessCustomerSegmentColor(record.segmentId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: segmentColor.withValues(alpha: 0.12),
                child: Icon(
                  record.isManual
                      ? Icons.person_outline
                      : Icons.event_available_outlined,
                  color: segmentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _contactLine(record),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              BusinessCustomerSegmentBadge(segmentId: record.segmentId),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BusinessCustomerMetricPill(
                icon: Icons.event_note_outlined,
                text: '${record.appointmentCount} randevu',
              ),
              BusinessCustomerMetricPill(
                icon: Icons.check_circle_outline,
                text: '${record.completedAppointmentCount} tamamlanan',
              ),
              if (record.noShowCount > 0)
                BusinessCustomerMetricPill(
                  icon: Icons.warning_amber_rounded,
                  text: '${record.noShowCount} gelmedi',
                ),
              BusinessCustomerMetricPill(
                icon: Icons.schedule_outlined,
                text: _lastAppointmentLabel(record.lastAppointmentAt),
              ),
              if (record.canReceiveBulkMessage)
                const BusinessCustomerMetricPill(
                  icon: Icons.notifications_active_outlined,
                  text: 'toplu mesaja uygun',
                ),
            ],
          ),
          if (record.lastServiceName.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Son hizmet: ${record.lastServiceName}',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (record.note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              record.note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF334155)),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (BusinessCustomerActionPolicy.canDirectMessage(
                record.customerUid,
              ))
                FilledButton.tonalIcon(
                  onPressed: onMessage,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Mesaj'),
                ),
              OutlinedButton.icon(
                onPressed: onClassify,
                icon: const Icon(Icons.tune_outlined),
                label: const Text('Sınıflandır'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _contactLine(BusinessCustomerRecord record) {
    final parts = <String>[
      if (record.phone.trim().isNotEmpty) record.phone.trim(),
      if (record.email.trim().isNotEmpty) record.email.trim(),
      if (!record.hasContactInfo) 'Randevu geçmişinden türetildi',
    ];
    return parts.join(' • ');
  }
}
