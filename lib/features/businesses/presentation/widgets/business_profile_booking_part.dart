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
  String? selectedServiceId;
  String? selectedServiceName;
  String? selectedStaffId;
  String? selectedStaffName;
  String? selectedStaffUid;
  String? selectedStaffEmail;
  List<String> selectedStaffServiceIds = const <String>[];
  int selectedServiceDurationMinutes = 30;
  String? selectedDateText;
  String? selectedTimeText;
  bool saving = false;
  int expandedBookingSection = 0;

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

  Stream<List<_InlineService>> _servicesStream() {
    return BusinessProfileRepository()
        .watchBusinessServices(businessId: widget.businessId)
        .map((rows) {
          final list = rows
              .where((data) {
                return data[FirestoreFields.bookingEnabled] != false &&
                    data[FirestoreFields.isActive] != false;
              })
              .map((data) {
                return _InlineService(
                  id: data[FirestoreFields.id]?.toString() ?? '',
                  name:
                      data[FirestoreFields.serviceName]?.toString() ??
                      data[FirestoreFields.name]?.toString() ??
                      'Hizmet',
                  price: data[FirestoreFields.price]?.toString() ?? '',
                  duration:
                      data[FirestoreFields.durationMinutes]?.toString() ??
                      data[FirestoreFields.duration]?.toString() ??
                      '',
                );
              })
              .toList();

          list.sort((a, b) => a.name.compareTo(b.name));
          return list;
        });
  }

  Stream<List<_InlineStaff>> _staffStream() {
    return BusinessProfileRepository()
        .watchBusinessStaff(businessId: widget.businessId)
        .map((rows) {
          final list = rows
              .where((data) {
                return data[FirestoreFields.isActive] != false;
              })
              .map((data) {
                final serviceIds = BusinessProfileBookingPolicy.stringList(
                  data[FirestoreFields.serviceIds] ??
                      data[FirestoreFields.staffServiceIds] ??
                      data[FirestoreFields.allowedServiceIds],
                );

                return _InlineStaff(
                  id: data[FirestoreFields.id]?.toString() ?? '',
                  name:
                      data[FirestoreFields.staffName]?.toString() ??
                      data[FirestoreFields.name]?.toString() ??
                      'Personel',
                  uid:
                      (data[FirestoreFields.linkedUid] ??
                              data[FirestoreFields.staffUid] ??
                              data[FirestoreFields.userUid] ??
                              '')
                          .toString(),
                  email:
                      (data[FirestoreFields.staffEmail] ??
                              data[FirestoreFields.targetEmail] ??
                              data[FirestoreFields.email] ??
                              '')
                          .toString(),
                  serviceIds: serviceIds,
                );
              })
              .toList();

          list.sort((a, b) => a.name.compareTo(b.name));
          return list;
        });
  }

  List<DateTime> _days() {
    return BusinessProfileBookingPolicy.upcomingDays(now: DateTime.now());
  }

  String _dateText(DateTime date) {
    return BusinessProfileBookingPolicy.dateText(date);
  }

  String _shortDay(DateTime date) {
    return BusinessProfileBookingPolicy.shortDay(date);
  }

  bool _selectedStaffCanProvideService(String serviceId) {
    if (selectedStaffId == null) return true;
    return BusinessProfileBookingPolicy.staffCanProvideService(
      serviceId: serviceId,
      staffServiceIds: selectedStaffServiceIds,
    );
  }

  List<_InlineService> _servicesForSelectedStaff(
    List<_InlineService> services,
  ) {
    if (selectedStaffId == null) return services;
    return services
        .where(
          (service) => BusinessProfileBookingPolicy.staffCanProvideService(
            serviceId: service.id,
            staffServiceIds: selectedStaffServiceIds,
          ),
        )
        .toList();
  }

  Future<void> _createAppointment() async {
    if (selectedServiceId == null ||
        selectedStaffId == null ||
        selectedDateText == null ||
        selectedTimeText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hizmet, personel, tarih ve saat secin.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final result = await _appointmentBookingService.createCustomerAppointment(
        AppointmentBookingRequest(
          businessId: widget.businessId,
          businessName: widget.businessName,
          category: widget.category,
          serviceId: selectedServiceId!,
          serviceName: selectedServiceName ?? 'Hizmet',
          businessStaffId: selectedStaffId!,
          staffName: selectedStaffName ?? 'Personel',
          staffUid: selectedStaffUid ?? '',
          staffEmail: selectedStaffEmail ?? '',
          staffServiceIdsAtBooking: selectedStaffServiceIds,
          durationMinutes: selectedServiceDurationMinutes,
          dateText: selectedDateText!,
          timeText: selectedTimeText!,
        ),
      );

      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Expanded(child: Text('Randevunuz olusturuldu')),
              ],
            ),
            content: Text(
              'Randevunuz basariyla kaydedildi.\n\n'
              'Hizmet: ${result.serviceName}\n'
              'Personel: ${result.staffName}\n'
              'Tarih: ${result.dateText}\n'
              'Saat: ${result.timeText}\n\n'
              'Randevu No: ${result.appointmentId}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      setState(() {
        selectedServiceId = null;
        selectedServiceName = null;
        selectedServiceDurationMinutes = 30;
        selectedStaffId = null;
        selectedStaffName = null;
        selectedStaffUid = null;
        selectedStaffEmail = null;
        selectedStaffServiceIds = const <String>[];
        selectedDateText = null;
        selectedTimeText = null;
        expandedBookingSection = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Randevu olusturulamadi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RxAccordionSection(
          title: 'Hizmet Sec',
          subtitle:
              selectedServiceName ?? 'Randevu almak istediginiz hizmeti secin',
          icon: Icons.spa_outlined,
          expanded: expandedBookingSection == 0,
          completed: selectedServiceId != null,
          onTap: () {
            setState(() {
              expandedBookingSection = expandedBookingSection == 0 ? -1 : 0;
            });
          },
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
                  text: selectedStaffId == null
                      ? 'Bu kurumsal kullanici henuz hizmet eklememis.'
                      : 'Secilen personelin verebildigi aktif hizmet bulunmuyor.',
                );
              }

              return Column(
                children: services.map((service) {
                  final selected = selectedServiceId == service.id;
                  final subtitleParts = <String>[
                    if (service.price.trim().isNotEmpty) '${service.price} TL',
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
                        setState(() {
                          selectedServiceId = service.id;
                          selectedServiceName = service.name;
                          selectedServiceDurationMinutes =
                              service.durationMinutes;

                          if (!_selectedStaffCanProvideService(service.id)) {
                            selectedStaffId = null;
                            selectedStaffName = null;
                            selectedStaffUid = null;
                            selectedStaffEmail = null;
                            selectedStaffServiceIds = const <String>[];
                          }

                          expandedBookingSection = selectedStaffId == null
                              ? 1
                              : 2;
                        });
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
              selectedStaffName ?? 'Randevu almak istediginiz personeli secin',
          icon: Icons.person_outline,
          expanded: expandedBookingSection == 1,
          completed: selectedStaffId != null,
          onTap: () {
            setState(() {
              expandedBookingSection = expandedBookingSection == 1 ? -1 : 1;
            });
          },
          child: StreamBuilder<List<_InlineStaff>>(
            stream: _cachedStaffStream,
            builder: (context, snapshot) {
              final allStaff = snapshot.data ?? [];
              final staff = selectedServiceId == null
                  ? allStaff
                  : allStaff
                        .where(
                          (person) =>
                              person.canProvideService(selectedServiceId!),
                        )
                        .toList();

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _MiniLoadingCard(text: 'Personel hazirlaniyor...');
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
                  final selected = selectedStaffId == person.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RxBookingOptionTile(
                      icon: Icons.person_outline,
                      title: person.name,
                      subtitle: 'Personel sec',
                      selected: selected,
                      onTap: () {
                        setState(() {
                          selectedStaffId = person.id;
                          selectedStaffName = person.name;
                          selectedStaffUid = person.uid;
                          selectedStaffEmail = person.email;
                          selectedStaffServiceIds = person.serviceIds;

                          if (selectedServiceId != null &&
                              !person.canProvideService(selectedServiceId!)) {
                            selectedServiceId = null;
                            selectedServiceName = null;
                            selectedServiceDurationMinutes = 30;
                          }

                          expandedBookingSection = selectedServiceId == null
                              ? 0
                              : 2;
                        });
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
          subtitle: selectedDateText ?? 'Randevu tarihini secin',
          icon: Icons.calendar_month_outlined,
          expanded: expandedBookingSection == 2,
          completed: selectedDateText != null,
          onTap: () {
            setState(() {
              expandedBookingSection = expandedBookingSection == 2 ? -1 : 2;
            });
          },
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _days().take(14).map((day) {
              final value = _dateText(day);
              final selected = selectedDateText == value;

              return _RxBookingDateTile(
                weekday: _shortDay(day),
                day: '${day.day}',
                month: '${day.month}',
                selected: selected,
                onTap: () {
                  setState(() {
                    selectedDateText = value;
                    expandedBookingSection = 3;
                  });
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        _RxAccordionSection(
          title: 'Saat Sec',
          subtitle: selectedTimeText ?? 'Uygun randevu saatini secin',
          icon: Icons.schedule_outlined,
          expanded: expandedBookingSection == 3,
          completed: selectedTimeText != null,
          onTap: () {
            setState(() {
              expandedBookingSection = expandedBookingSection == 3 ? -1 : 3;
            });
          },
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BusinessProfileBookingPolicy.defaultTimes.map((time) {
              final selected = selectedTimeText == time;

              return _RxBookingTimeTile(
                label: time,
                selected: selected,
                onTap: () {
                  setState(() {
                    selectedTimeText = time;
                    expandedBookingSection = -1;
                  });
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        _BookingSummaryCard(
          serviceName: selectedServiceName,
          staffName: selectedStaffName,
          dateText: selectedDateText,
          timeText: selectedTimeText,
        ),
        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: saving ? null : _createAppointment,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calendar_month_outlined),
            label: Text(saving ? 'Olusturuluyor...' : 'Randevu Olustur'),
          ),
        ),
      ],
    );
  }
}

class _InlineService {
  final String id;
  final String name;
  final String price;
  final String duration;

  const _InlineService({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
  });

  int get durationMinutes =>
      BusinessProfileBookingPolicy.durationMinutes(duration);
}

class _InlineStaff {
  final String id;
  final String name;
  final String uid;
  final String email;
  final List<String> serviceIds;

  const _InlineStaff({
    required this.id,
    required this.name,
    this.uid = '',
    this.email = '',
    this.serviceIds = const <String>[],
  });

  bool canProvideService(String serviceId) {
    return BusinessProfileBookingPolicy.staffCanProvideService(
      serviceId: serviceId,
      staffServiceIds: serviceIds,
    );
  }
}
