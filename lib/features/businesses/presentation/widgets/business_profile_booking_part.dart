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

  // 49B-A: AppointmentService derleme köprüsü.
  // 49B-B'de _createAppointment içindeki iş kuralları bu servise taşınacak.
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

  final times = const [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
  ];

  List<String> _stringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
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
                final serviceIds = _stringList(
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
    final now = DateTime.now();
    return List.generate(21, (index) {
      return DateTime(now.year, now.month, now.day).add(Duration(days: index));
    });
  }

  String _dateText(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String _shortDay(DateTime date) {
    const names = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return names[date.weekday - 1];
  }

  bool _selectedStaffCanProvideService(String serviceId) {
    if (selectedStaffId == null) return true;
    if (selectedStaffServiceIds.isEmpty) return true;
    return selectedStaffServiceIds.contains(serviceId);
  }

  List<_InlineService> _servicesForSelectedStaff(
    List<_InlineService> services,
  ) {
    if (selectedStaffId == null) return services;
    if (selectedStaffServiceIds.isEmpty) return services;
    return services
        .where((service) => selectedStaffServiceIds.contains(service.id))
        .toList();
  }

  Future<void> _createAppointment() async {
    if (selectedServiceId == null ||
        selectedStaffId == null ||
        selectedDateText == null ||
        selectedTimeText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hizmet, personel, tarih ve saat seçin.')),
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
                Expanded(child: Text('Randevunuz oluşturuldu')),
              ],
            ),
            content: Text(
              'Randevunuz başarıyla kaydedildi.\n\n'
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
        ).showSnackBar(SnackBar(content: Text('Randevu oluşturulamadı: $e')));
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
          title: 'Hizmet Seç',
          subtitle:
              selectedServiceName ?? 'Randevu almak istediğiniz hizmeti seçin',
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
                  text: 'Hizmetler hazırlanıyor...',
                );
              }

              if (services.isEmpty) {
                return _InfoCard(
                  icon: Icons.spa_outlined,
                  title: 'Uygun hizmet yok',
                  text: selectedStaffId == null
                      ? 'Bu kurumsal kullanıcı henüz hizmet eklememiş.'
                      : 'Seçilen personelin verebildiği aktif hizmet bulunmuyor.',
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
                      ? 'Hizmet seç'
                      : subtitleParts.join(' • ');

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
          title: 'Personel Seç',
          subtitle:
              selectedStaffName ?? 'Randevu almak istediğiniz personeli seçin',
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
                return const _MiniLoadingCard(text: 'Personel hazırlanıyor...');
              }

              if (staff.isEmpty) {
                return _InfoCard(
                  icon: Icons.people_alt_outlined,
                  title: 'Uygun personel yok',
                  text: selectedServiceId == null
                      ? 'Bu kurumsal kullanıcı henüz aktif personel eklememiş.'
                      : 'Seçilen hizmeti verebilen aktif personel bulunmuyor.',
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
                      subtitle: 'Personel seç',
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
          title: 'Tarih Seç',
          subtitle: selectedDateText ?? 'Randevu tarihini seçin',
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
          title: 'Saat Seç',
          subtitle: selectedTimeText ?? 'Uygun randevu saatini seçin',
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
            children: times.map((time) {
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
            label: Text(saving ? 'Oluşturuluyor...' : 'Randevu Oluştur'),
          ),
        ),
      ],
    );
  }
}

class _RxAccordionSection extends StatelessWidget {
  const _RxAccordionSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.expanded,
    required this.completed,
    required this.onTap,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool expanded;
  final bool completed;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: completed
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFEDE9FE),
                    child: Icon(
                      completed ? Icons.check_rounded : icon,
                      color: completed
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.serviceName,
    required this.staffName,
    required this.dateText,
    required this.timeText,
  });

  final String? serviceName;
  final String? staffName;
  final String? dateText;
  final String? timeText;

  @override
  Widget build(BuildContext context) {
    final complete =
        serviceName != null &&
        staffName != null &&
        dateText != null &&
        timeText != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: complete ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: complete ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: complete ? const Color(0xFF16A34A) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              complete
                  ? '$serviceName • $staffName • $dateText • $timeText'
                  : 'Randevu oluşturmak için hizmet, personel, tarih ve saat seçin.',
              style: TextStyle(
                color: complete
                    ? const Color(0xFF166534)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RxBookingOptionTile extends StatelessWidget {
  const _RxBookingOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEDE9FE) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFFE5E7EB),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: selected
                            ? const Color(0xFF5B21B6)
                            : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RxBookingDateTile extends StatelessWidget {
  const _RxBookingDateTile({
    required this.weekday,
    required this.day,
    required this.month,
    required this.selected,
    required this.onTap,
  });

  final String weekday;
  final String day;
  final String month;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7C3AED) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFFE5E7EB),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekday,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                day,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                month,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RxBookingTimeTile extends StatelessWidget {
  const _RxBookingTimeTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(76, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: selected ? const Color(0xFFEDE9FE) : Colors.white,
          foregroundColor: selected
              ? const Color(0xFF6D28D9)
              : const Color(0xFF111827),
          side: BorderSide(
            color: selected ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB),
            width: selected ? 1.4 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
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

  int get durationMinutes => int.tryParse(duration.trim()) ?? 30;
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
    if (serviceIds.isEmpty) return true;
    return serviceIds.contains(serviceId);
  }
}
