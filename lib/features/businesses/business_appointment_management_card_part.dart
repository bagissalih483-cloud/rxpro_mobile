part of 'business_appointment_management_page.dart';

extension _BusinessAppointmentManagementCard on BusinessAppointmentManagementPage {
  Widget _appointmentCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String tab,
  ) {
    final data = doc.data();

    final customer = _field(data, [
      'customerName',
      'clientName',
      'name',
    ], 'Bireysel Kullanıcı');

    final service = _field(data, ['serviceName', 'title'], 'Hizmet');
    final staff = _field(data, ['staffName', 'employeeName'], '');
    final date = _field(data, ['dateText', 'appointmentDate'], '-');
    final time = _field(data, ['timeText', 'appointmentTime'], '-');

    final cancelReason = _field(data, ['cancellationReason'], '');

    final postponeDate = _field(data, [
      'postponeRequestedDateText',
      'postponedDateText',
    ], '');

    final postponeTime = _field(data, [
      'postponeRequestedTimeText',
      'postponedTimeText',
    ], '');

    final postponeNote = _field(data, [
      'postponeRequestNote',
      'postponedNote',
    ], '');

    final bg = tab == 'postponed'
        ? const Color(0xFFFFF7D6)
        : tab == 'cancelled'
        ? const Color(0xFFFFE4E6)
        : tab == 'completed'
        ? const Color(0xFFDCFCE7)
        : Colors.white;

    final accent = tab == 'postponed'
        ? const Color(0xFFD97706)
        : tab == 'cancelled'
        ? const Color(0xFFDC2626)
        : tab == 'completed'
        ? const Color(0xFF16A34A)
        : const Color(0xFF2563EB);

    return Card(
      elevation: 0,
      color: bg,
      margin: const EdgeInsets.fromLTRB(16, 7, 16, 9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: accent,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => showBusinessCustomerQuickProfile(
                      context: context,
                      businessId: businessId,
                      businessName: businessName,
                      data: data,
                      customerName: customer,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        customer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                if (tab == 'completed')
                  const BusinessAppointmentStatusPill(
                    text: 'Sonuçlandı',
                    color: Color(0xFF16A34A),
                  )
                else if (tab == 'cancelled')
                  const BusinessAppointmentStatusPill(
                    text: 'İptal',
                    color: Color(0xFFDC2626),
                  )
                else if (tab == 'postponed')
                  const BusinessAppointmentStatusPill(
                    text: 'Bekliyor',
                    color: Color(0xFFD97706),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              service,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${date} • ${time}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (staff.isNotEmpty && staff != '-') ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    size: 15,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Personel: $staff',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (tab == 'postponed' &&
                postponeDate.isNotEmpty &&
                postponeDate != '-') ...[
              const SizedBox(height: 7),
              Text(
                'Erteleme talebi: $postponeDate ${postponeTime == '-' ? '' : postponeTime}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF92400E),
                  fontSize: 12,
                ),
              ),
              if (postponeNote.isNotEmpty && postponeNote != '-') ...[
                const SizedBox(height: 2),
                Text(
                  'Not: $postponeNote',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
            if (tab == 'cancelled' &&
                cancelReason.isNotEmpty &&
                cancelReason != '-') ...[
              const SizedBox(height: 7),
              Text(
                'İptal gerekçesi: ${cancelReason}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF991B1B),
                  fontSize: 12,
                ),
              ),
            ],
            if (tab == 'current') ...[
              const SizedBox(height: 10),
              _appointmentCardActions(context, doc),
            ],
          ],
        ),
      ),
    );
  }
}
