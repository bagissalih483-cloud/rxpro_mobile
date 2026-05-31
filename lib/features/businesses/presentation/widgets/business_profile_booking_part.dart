part of '../../business_profile_page.dart';

class _AppointmentTab extends StatefulWidget {
  const _AppointmentTab({
    required this.businessId,
    required this.businessName,
    required this.category,
  });

  final String businessId;
  final String businessName;
  final String category;

  @override
  State<_AppointmentTab> createState() => _AppointmentTabState();
}

class _AppointmentTabState extends State<_AppointmentTab>
    with AutomaticKeepAliveClientMixin<_AppointmentTab> {
  final BusinessProfileBookingController _controller =
      BusinessProfileBookingController();

  // 49B-A: AppointmentService derleme koprusu.
  // 49B-B'de _createAppointment icindeki is kurallari bu servise tasinacak.
  final AppointmentBookingService _appointmentBookingService =
      AppointmentBookingService();

  late final Stream<List<_InlineService>> _cachedServicesStream;
  late final Stream<List<_InlineStaff>> _cachedStaffStream;

  @override
  void initState() {
    super.initState();
    _cachedServicesStream = _servicesStream();
    _cachedStaffStream = _staffStream();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RxAccordionSection(
              title: 'Hizmet Sec',
              subtitle:
                  _controller.selectedServiceName ??
                  'Randevu almak istediginiz hizmeti secin',
              icon: Icons.spa_outlined,
              expanded: _controller.expandedBookingSection == 0,
              completed: _controller.selectedServiceId != null,
              onTap: () => _controller.toggleSection(0),
              child: StreamBuilder<List<_InlineService>>(
                stream: _cachedServicesStream,
                builder: (context, snapshot) {
                  final allServices = snapshot.data ?? [];
                  final services = _servicesForSelectedStaff(allServices);

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _MiniLoadingCard(
                      text: 'Hizmetler hazirlaniyor...',
                    );
                  }

                  if (services.isEmpty) {
                    return _InfoCard(
                      icon: Icons.spa_outlined,
                      title: 'Uygun hizmet yok',
                      text: _controller.selectedStaffId == null
                          ? 'Bu kurumsal kullanici henuz hizmet eklememis.'
                          : 'Secilen personelin verebildigi aktif hizmet bulunmuyor.',
                    );
                  }

                  return Column(
                    children: services.map((service) {
                      final selected =
                          _controller.selectedServiceId == service.id;
                      final subtitleParts = <String>[
                        if (service.price.trim().isNotEmpty)
                          '${service.price} TL',
                        '${service.durationMinutes} dk',
                      ];
                      final subtitle = subtitleParts.isEmpty
                          ? 'Hizmet sec'
                          : subtitleParts.join(' - ');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RxBookingOptionTile(
                          icon: Icons.spa_outlined,
                          title: service.name,
                          subtitle: subtitle,
                          selected: selected,
                          onTap: () {
                            _controller.selectService(
                              id: service.id,
                              name: service.name,
                              durationMinutes: service.durationMinutes,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            _RxAccordionSection(
              title: 'Personel Sec',
              subtitle:
                  _controller.selectedStaffName ??
                  'Randevu almak istediginiz personeli secin',
              icon: Icons.person_outline,
              expanded: _controller.expandedBookingSection == 1,
              completed: _controller.selectedStaffId != null,
              onTap: () => _controller.toggleSection(1),
              child: StreamBuilder<List<_InlineStaff>>(
                stream: _cachedStaffStream,
                builder: (context, snapshot) {
                  final allStaff = snapshot.data ?? [];
                  final selectedServiceId = _controller.selectedServiceId;
                  final staff = selectedServiceId == null
                      ? allStaff
                      : allStaff
                            .where(
                              (person) =>
                                  person.canProvideService(selectedServiceId),
                            )
                            .toList();

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _MiniLoadingCard(
                      text: 'Personel hazirlaniyor...',
                    );
                  }

                  if (staff.isEmpty) {
                    return _InfoCard(
                      icon: Icons.people_alt_outlined,
                      title: 'Uygun personel yok',
                      text: selectedServiceId == null
                          ? 'Bu kurumsal kullanici henuz aktif personel eklememis.'
                          : 'Secilen hizmeti verebilen aktif personel bulunmuyor.',
                    );
                  }

                  return Column(
                    children: staff.map((person) {
                      final selected = _controller.selectedStaffId == person.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RxBookingOptionTile(
                          icon: Icons.person_outline,
                          title: person.name,
                          subtitle: 'Personel sec',
                          selected: selected,
                          onTap: () {
                            _controller.selectStaff(
                              id: person.id,
                              name: person.name,
                              uid: person.uid,
                              email: person.email,
                              serviceIds: person.serviceIds,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            _RxAccordionSection(
              title: 'Tarih Sec',
              subtitle:
                  _controller.selectedDateText ?? 'Randevu tarihini secin',
              icon: Icons.calendar_month_outlined,
              expanded: _controller.expandedBookingSection == 2,
              completed: _controller.selectedDateText != null,
              onTap: () => _controller.toggleSection(2),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _days().take(14).map((day) {
                  final value = _dateText(day);
                  final selected = _controller.selectedDateText == value;

                  return _RxBookingDateTile(
                    weekday: _shortDay(day),
                    day: '${day.day}',
                    month: '${day.month}',
                    selected: selected,
                    onTap: () => _controller.selectDate(value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            _RxAccordionSection(
              title: 'Saat Sec',
              subtitle:
                  _controller.selectedTimeText ?? 'Uygun randevu saatini secin',
              icon: Icons.schedule_outlined,
              expanded: _controller.expandedBookingSection == 3,
              completed: _controller.selectedTimeText != null,
              onTap: () => _controller.toggleSection(3),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BusinessProfileBookingPolicy.defaultTimes.map((time) {
                  final selected = _controller.selectedTimeText == time;

                  return _RxBookingTimeTile(
                    label: time,
                    selected: selected,
                    onTap: () => _controller.selectTime(time),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            _BookingSummaryCard(
              serviceName: _controller.selectedServiceName,
              staffName: _controller.selectedStaffName,
              dateText: _controller.selectedDateText,
              timeText: _controller.selectedTimeText,
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _controller.saving ? null : _createAppointment,
                icon: _controller.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calendar_month_outlined),
                label: Text(
                  _controller.saving ? 'Olusturuluyor...' : 'Randevu Olustur',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
