import 'dart:math' as math;

import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:flutter/material.dart';

import 'package:rxpro_mobile/core/session/app_role.dart';
import 'package:rxpro_mobile/core/session/session_role_gate.dart';

import 'package:rxpro_mobile/features/business_role/business_role_resolver.dart';
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
    final raw = widget.businessData[FirestoreFields.openingHour];
    if (raw is num) return raw.toInt().clamp(0, 23);
    return 9;
  }

  int get closingHour {
    final raw = widget.businessData[FirestoreFields.closingHour];
    if (raw is num) return raw.toInt().clamp(1, 24);
    return 20;
  }

  int get slotMinutes {
    final raw = widget.businessData[FirestoreFields.slotMinutes];
    if (raw is num) return raw.toInt().clamp(15, 120);
    return 30;
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

  DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime? _dateOf(Map<String, dynamic> data) {
    final startAt = data[FirestoreFields.startAt];
    if (startAt is DateTime) return startAt;

    final iso =
        (data[FirestoreFields.startAtIso] ??
                data[FirestoreFields.appointmentDateIso] ??
                '')
            .toString();
    if (iso.isNotEmpty) {
      try {
        return DateTime.parse(iso);
      } catch (_) {}
    }

    final dateText =
        (data[FirestoreFields.appointmentDate] ??
                data[FirestoreFields.dateText] ??
                '')
            .toString();
    final timeText =
        (data[FirestoreFields.appointmentTime] ??
                data[FirestoreFields.timeText] ??
                '09:00')
            .toString();
    final parsedDate = _parseTrDate(dateText);
    if (parsedDate == null) return null;

    final parts = timeText.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 9;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

    return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, h, m);
  }

  DateTime? _parseTrDate(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    final iso = DateTime.tryParse(clean);
    if (iso != null) return iso;

    final match = RegExp(
      r'(\d{1,2})[./-](\d{1,2})[./-](\d{4})',
    ).firstMatch(clean);
    if (match == null) return null;

    final d = int.tryParse(match.group(1) ?? '');
    final m = int.tryParse(match.group(2) ?? '');
    final y = int.tryParse(match.group(3) ?? '');
    if (d == null || m == null || y == null) return null;

    return DateTime(y, m, d);
  }

  String _clean(dynamic value) => value?.toString().trim() ?? '';

  bool _isCancelledOrPassive(Map<String, dynamic> data) {
    final status = _clean(
      data[FirestoreFields.status] ??
          data[FirestoreFields.appointmentStatus] ??
          data[FirestoreFields.state] ??
          data[FirestoreFields.bookingStatus],
    ).toLowerCase();

    return data[FirestoreFields.isCancelled] == true ||
        status.contains('cancel') ||
        status.contains('iptal') ||
        status.contains('passive') ||
        status.contains('pasif');
  }

  String _staffIdOf(Map<String, dynamic> data) {
    return _clean(
      data[FirestoreFields.staffId] ??
          data[FirestoreFields.staffUid] ??
          data[FirestoreFields.employeeId] ??
          data[FirestoreFields.personnelId],
    );
  }

  String _staffNameOf(Map<String, dynamic> data) {
    return _clean(
      data[FirestoreFields.staffName] ??
          data[FirestoreFields.employeeName] ??
          data[FirestoreFields.personnelName] ??
          data[FirestoreFields.workerName] ??
          'Personel',
    );
  }

  String _customerNameOf(Map<String, dynamic> data) {
    return _clean(
      data[FirestoreFields.customerName] ??
          data[FirestoreFields.clientName] ??
          data[FirestoreFields.userName] ??
          data[FirestoreFields.name] ??
          'Müşteri',
    );
  }

  String _serviceNameOf(Map<String, dynamic> data) {
    return _clean(
      data[FirestoreFields.serviceName] ??
          data[FirestoreFields.service] ??
          'Randevu',
    );
  }

  String _timeText(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dateTitle(DateTime value) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  int _capacityForDay(int staffCount) {
    final perStaff = (((closingHour - openingHour) * 60) / slotMinutes).floor();
    return math.max(1, perStaff * math.max(1, staffCount));
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
            final appointments = (appointmentSnapshot.data ?? [])
                .where((data) => !_isCancelledOrPassive(data))
                .where((data) {
                  final dt = _dateOf(data);
                  if (dt == null) return false;
                  return dt.year == visibleMonth.year &&
                      dt.month == visibleMonth.month;
                })
                .toList();

            final staff = (staffSnapshot.data ?? [])
                .map((data) {
                  final name = _clean(
                    data[FirestoreFields.staffName] ??
                        data[FirestoreFields.name] ??
                        data[FirestoreFields.displayName] ??
                        data[FirestoreFields.fullName] ??
                        'Personel',
                  );

                  return AppointmentStaffLite(
                    id: _clean(
                      data[FirestoreFields.staffId] ??
                          data[FirestoreFields.staffUid] ??
                          data[BusinessAppointmentDashboardFields.documentId],
                    ),
                    name: name,
                  );
                })
                .where((item) {
                  return item.name.trim().isNotEmpty;
                })
                .toList();

            if (staff.isEmpty) {
              final byAppointments = <String, AppointmentStaffLite>{};
              for (final data in appointments) {
                final id = _staffIdOf(data);
                final name = _staffNameOf(data);
                if (id.isNotEmpty || name.isNotEmpty) {
                  byAppointments[id.isEmpty ? name : id] = AppointmentStaffLite(
                    id: id.isEmpty ? name : id,
                    name: name.isEmpty ? 'Personel' : name,
                  );
                }
              }
              staff.addAll(byAppointments.values);
            }

            if (staff.isEmpty) {
              staff.add(
                const AppointmentStaffLite(id: 'default', name: 'Genel'),
              );
            }

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
