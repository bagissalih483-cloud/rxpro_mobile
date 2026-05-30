import 'package:flutter/material.dart';

import 'package:rxpro_mobile/core/session/app_role.dart';
import 'package:rxpro_mobile/core/session/session_role_gate.dart';

import 'package:rxpro_mobile/features/business_role/business_role_resolver.dart';
import 'package:rxpro_mobile/features/appointments/domain/business_appointment_dashboard_policy.dart';
import 'package:rxpro_mobile/features/appointments/domain/business_manual_appointment_policy.dart';
import 'package:rxpro_mobile/features/appointments/presentation/models/appointment_dashboard_models.dart';
import 'package:rxpro_mobile/features/appointments/presentation/widgets/appointment_dashboard_views.dart';

import 'package:rxpro_mobile/features/appointments/data/business_appointment_dashboard_repository.dart';
import 'package:rxpro_mobile/features/appointments/presentation/pages/customer_appointments_page.dart';
import 'package:rxpro_mobile/features/appointments/service/business_manual_appointment_service.dart';

part 'appointment_entry_manual_sheet.dart';

/// 50C-H1: Appointment entry/dashboard UI behavior is unchanged.
class AppointmentEntryPage extends StatefulWidget {
  const AppointmentEntryPage({super.key});

  @override
  State<AppointmentEntryPage> createState() => _AppointmentEntryPageState();
}

class _AppointmentEntryPageState extends State<AppointmentEntryPage> {
  late Future<BusinessRoleResult> future;

  @override
  void initState() {
    super.initState();
    future = BusinessRoleResolver.resolveCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BusinessRoleResult>(
      future: future,
      builder: (context, snapshot) {
        final role = snapshot.data;

        if (role == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!role.isBusiness) {
          return const SessionRoleGate(
            allowedRoles: {AppRole.individual},
            title: 'Bireysel randevu alanı',
            description:
                'Randevularım sayfası sadece bireysel kullanıcı hesabıyla kullanılabilir.',
            child: CustomerAppointmentsPage(),
          );
        }

        return BusinessAppointmentDashboardPage(
          businessId: role.businessId,
          businessName: role.businessName,
          businessData: role.businessData,
        );
      },
    );
  }
}

class BusinessAppointmentDashboardPage extends StatefulWidget {
  const BusinessAppointmentDashboardPage({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.businessData,
  });

  final String businessId;
  final String businessName;
  final Map<String, dynamic> businessData;

  @override
  State<BusinessAppointmentDashboardPage> createState() =>
      _BusinessAppointmentDashboardPageState();
}

class _BusinessAppointmentDashboardPageState
    extends State<BusinessAppointmentDashboardPage>
    with AutomaticKeepAliveClientMixin {
  final BusinessAppointmentDashboardRepository _dashboardRepository =
      BusinessAppointmentDashboardRepository();
  final BusinessManualAppointmentService _manualAppointmentService =
      BusinessManualAppointmentService();
  int selectedMode = 0;
  DateTime selectedDay = DateTime.now();
  late DateTime visibleMonth;
  String? _appointmentsStreamKey;
  Stream<List<Map<String, dynamic>>>? _appointmentsStreamCache;
  String? _staffStreamKey;
  Stream<List<Map<String, dynamic>>>? _staffStreamCache;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    visibleMonth = DateTime(selectedDay.year, selectedDay.month, 1);
  }

  int get openingHour {
    return BusinessAppointmentDashboardPolicy.openingHour(widget.businessData);
  }

  int get closingHour {
    return BusinessAppointmentDashboardPolicy.closingHour(widget.businessData);
  }

  int get slotMinutes {
    return BusinessAppointmentDashboardPolicy.slotMinutes(widget.businessData);
  }

  Stream<List<Map<String, dynamic>>> _appointmentsStream() {
    if (_appointmentsStreamKey != widget.businessId ||
        _appointmentsStreamCache == null) {
      _appointmentsStreamKey = widget.businessId;
      _appointmentsStreamCache = _dashboardRepository.watchAppointments(
        businessId: widget.businessId,
      );
    }

    return _appointmentsStreamCache!;
  }

  Stream<List<Map<String, dynamic>>> _staffStream() {
    if (_staffStreamKey != widget.businessId || _staffStreamCache == null) {
      _staffStreamKey = widget.businessId;
      _staffStreamCache = _dashboardRepository.watchStaff(
        businessId: widget.businessId,
      );
    }

    return _staffStreamCache!;
  }

  DateTime _dayOnly(DateTime value) {
    return BusinessAppointmentDashboardPolicy.dayOnly(value);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return BusinessAppointmentDashboardPolicy.sameDay(a, b);
  }

  DateTime? _dateOf(Map<String, dynamic> data) {
    return BusinessAppointmentDashboardPolicy.dateOf(data);
  }

  String _staffIdOf(Map<String, dynamic> data) {
    return BusinessAppointmentDashboardPolicy.staffIdOf(data);
  }

  String _staffNameOf(Map<String, dynamic> data) {
    return BusinessAppointmentDashboardPolicy.staffNameOf(data);
  }

  String _customerNameOf(Map<String, dynamic> data) {
    return BusinessAppointmentDashboardPolicy.customerNameOf(data);
  }

  String _serviceNameOf(Map<String, dynamic> data) {
    return BusinessAppointmentDashboardPolicy.serviceNameOf(data);
  }

  String _timeText(DateTime value) {
    return BusinessAppointmentDashboardPolicy.timeText(value);
  }

  String _dateTitle(DateTime value) {
    return BusinessAppointmentDashboardPolicy.dateTitle(value);
  }

  int _capacityForDay(int staffCount) {
    return BusinessAppointmentDashboardPolicy.capacityForDay(
      openingHour: openingHour,
      closingHour: closingHour,
      slotMinutes: slotMinutes,
      staffCount: staffCount,
    );
  }

  Color _heatColor(double ratio) {
    final r = ratio.clamp(0.0, 1.0);
    if (r <= 0) return const Color(0xFFFFFFFF);
    if (r < 0.25) return const Color(0xFFFFE4E6);
    if (r < 0.50) return const Color(0xFFFCA5A5);
    if (r < 0.75) return const Color(0xFFEF4444);
    return const Color(0xFF991B1B);
  }

  Future<void> _openManualAppointmentSheet({
    required BuildContext context,
    required DateTime slot,
    required List<AppointmentStaffLite> staff,
    AppointmentStaffLite? initialStaff,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _BusinessManualAppointmentSheet(
          service: _manualAppointmentService,
          businessId: widget.businessId,
          businessName: widget.businessName,
          initialStartAt: slot,
          initialStaff: initialStaff,
          staff: staff,
        );
      },
    );

    if (created != true || !mounted) return;

    setState(() {
      selectedDay = DateTime(slot.year, slot.month, slot.day);
      visibleMonth = DateTime(slot.year, slot.month, 1);
      selectedMode = 0;
    });

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Manuel randevu oluşturuldu.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _appointmentsStream(),
      builder: (context, appointmentSnapshot) {
        if (appointmentSnapshot.hasError) {
          return AppointmentErrorCard(
            message: appointmentSnapshot.error.toString(),
          );
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _staffStream(),
          builder: (context, staffSnapshot) {
            final appointments =
                BusinessAppointmentDashboardPolicy.activeAppointmentsForMonth(
                  appointments: appointmentSnapshot.data ?? const [],
                  visibleMonth: visibleMonth,
                );

            final staff = BusinessAppointmentDashboardPolicy.staffOptions(
              staffRows: staffSnapshot.data ?? const [],
              appointments: appointments,
            )
                .map(
                  (item) => AppointmentStaffLite(id: item.id, name: item.name),
                )
                .toList(growable: false);

            final loading =
                appointmentSnapshot.connectionState ==
                    ConnectionState.waiting ||
                staffSnapshot.connectionState == ConnectionState.waiting;

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Center(
                              child: SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment(
                                    value: 0,
                                    label: Text('Günlük Akış'),
                                    icon: Icon(Icons.view_timeline_outlined),
                                  ),
                                  ButtonSegment(
                                    value: 1,
                                    label: Text('Aylık Doluluk'),
                                    icon: Icon(Icons.calendar_month_outlined),
                                  ),
                                ],
                                selected: {selectedMode},
                                showSelectedIcon: false,
                                style: ButtonStyle(
                                  minimumSize: WidgetStateProperty.all(
                                    const Size(128, 42),
                                  ),
                                  padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                  ),
                                  textStyle: WidgetStateProperty.all(
                                    const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                onSelectionChanged: (value) {
                                  setState(() => selectedMode = value.first);
                                },
                              ),
                            ),
                          ),
                          if (loading)
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: selectedMode == 0
                          ? AppointmentDailyFlowView(
                              selectedDay: selectedDay,
                              staff: staff,
                              appointments: appointments,
                              openingHour: openingHour,
                              closingHour: closingHour,
                              slotMinutes: slotMinutes,
                              sameDay: _sameDay,
                              dateOf: _dateOf,
                              timeText: _timeText,
                              dateTitle: _dateTitle,
                              staffIdOf: _staffIdOf,
                              staffNameOf: _staffNameOf,
                              customerNameOf: _customerNameOf,
                              serviceNameOf: _serviceNameOf,
                              onPreviousDay: () {
                                setState(() {
                                  selectedDay = selectedDay.subtract(
                                    const Duration(days: 1),
                                  );
                                  visibleMonth = DateTime(
                                    selectedDay.year,
                                    selectedDay.month,
                                    1,
                                  );
                                });
                              },
                              onNextDay: () {
                                setState(() {
                                  selectedDay = selectedDay.add(
                                    const Duration(days: 1),
                                  );
                                  visibleMonth = DateTime(
                                    selectedDay.year,
                                    selectedDay.month,
                                    1,
                                  );
                                });
                              },
                              onToday: () {
                                setState(() {
                                  selectedDay = DateTime.now();
                                  visibleMonth = DateTime(
                                    selectedDay.year,
                                    selectedDay.month,
                                    1,
                                  );
                                });
                              },
                              onCreateAppointment: (slot, selectedStaff) {
                                _openManualAppointmentSheet(
                                  context: context,
                                  slot: slot,
                                  staff: staff,
                                  initialStaff: selectedStaff,
                                );
                              },
                            )
                          : AppointmentMonthlyHeatView(
                              visibleMonth: visibleMonth,
                              selectedDay: selectedDay,
                              appointments: appointments,
                              staffCount: staff.length,
                              capacityForDay: _capacityForDay,
                              heatColor: _heatColor,
                              dayOnly: _dayOnly,
                              sameDay: _sameDay,
                              dateOf: _dateOf,
                              onPreviousMonth: () {
                                setState(() {
                                  visibleMonth = DateTime(
                                    visibleMonth.year,
                                    visibleMonth.month - 1,
                                    1,
                                  );
                                });
                              },
                              onNextMonth: () {
                                setState(() {
                                  visibleMonth = DateTime(
                                    visibleMonth.year,
                                    visibleMonth.month + 1,
                                    1,
                                  );
                                });
                              },
                              onSelectDay: (day) {
                                setState(() {
                                  selectedDay = day;
                                });
                              },
                              onCreateAppointment: (day) {
                                _openManualAppointmentSheet(
                                  context: context,
                                  slot: DateTime(
                                    day.year,
                                    day.month,
                                    day.day,
                                    openingHour,
                                  ),
                                  staff: staff,
                                  initialStaff: staff.isEmpty
                                      ? null
                                      : staff.first,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
