import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';
import 'package:rxpro_mobile/features/appointments/services/customer_appointment_action_service.dart';
import 'package:rxpro_mobile/features/businesses/business_profile_page.dart';
import 'package:rxpro_mobile/features/appointments/data/customer_appointment_repository.dart';
import 'package:rxpro_mobile/features/appointments/presentation/widgets/customer_appointment_widgets.dart';

class CustomerAppointmentsPage extends StatefulWidget {
  const CustomerAppointmentsPage({super.key});

  @override
  State<CustomerAppointmentsPage> createState() =>
      _CustomerAppointmentsPageState();
}

class _CustomerAppointmentsPageState extends State<CustomerAppointmentsPage>
    with AutomaticKeepAliveClientMixin<CustomerAppointmentsPage> {
  final CustomerAppointmentRepository _appointmentRepository =
      CustomerAppointmentRepository();
  final CustomerAppointmentActionService _actionService =
      CustomerAppointmentActionService();
  final AuthService _authService = AuthService();
  int selectedTab = 0;

  @override
  bool get wantKeepAlive => true;

  static String _clean(dynamic value) => value?.toString().trim() ?? '';

  static bool _matchesCurrentUser(Map<String, dynamic> data, String uid) {
    return [
      data['customerUid'],
      data['customerId'],
      data['userId'],
      data['uid'],
      data['clientUid'],
    ].map(_clean).contains(uid);
  }

  static String _statusOf(Map<String, dynamic> data) {
    return _clean(
      data['status'] ??
          data['appointmentStatus'] ??
          data['state'] ??
          data['bookingStatus'],
    ).toLowerCase();
  }

  static bool _isCancelled(Map<String, dynamic> data) {
    final status = _statusOf(data);
    if (status.contains('cancel')) return true;
    if (status.contains('iptal')) return true;
    if (data['isCancelled'] == true) return true;
    return false;
  }

  static bool _isPostponeRequested(Map<String, dynamic> data) {
    final status = _statusOf(data);
    final approval = _clean(
      data['customerApprovalStatus'] ?? data['postponeRequestStatus'],
    ).toLowerCase();

    return status == 'postpone_requested' ||
        status == 'reschedule_requested' ||
        approval == 'pending';
  }

  static bool _isPast(Map<String, dynamic> data) {
    final startAt = data['startAt'];
    if (startAt is Timestamp) {
      return startAt.toDate().isBefore(DateTime.now());
    }

    final iso = _clean(data['startAtIso']);
    final parsedIso = DateTime.tryParse(iso);
    if (parsedIso != null) return parsedIso.isBefore(DateTime.now());

    return false;
  }

  static bool _isActive(Map<String, dynamic> data) {
    if (_isCancelled(data)) return false;
    if (_isPostponeRequested(data)) return false;
    if (_isPast(data)) return false;

    final status = _statusOf(data);
    if (status.isEmpty) return true;

    return [
      'active',
      'pending',
      'approved',
      'confirmed',
      'onaylı',
      'onayli',
      'bekliyor',
    ].contains(status);
  }

  static bool _isCompleted(Map<String, dynamic> data) {
    if (_isCancelled(data)) return false;
    if (_isPostponeRequested(data)) return false;

    final status = _statusOf(data);
    if ([
      'done',
      'completed',
      'complete',
      'gecmis',
      'geçmiş',
      'tamamlandi',
      'tamamlandı',
    ].contains(status)) {
      return true;
    }

    return _isPast(data);
  }

  Stream<List<_AppointmentItem>> _appointmentsStream(String uid) {
    return _appointmentRepository.watchMergedCustomerAppointments(uid: uid).map(
      (docs) {
        final items = docs
            .where((doc) => _matchesCurrentUser(doc.data, uid))
            .map(_AppointmentItem.fromCustomerDocument)
            .toList();

        items.sort((a, b) => b.sortValue.compareTo(a.sortValue));
        return items;
      },
    );
  }

  // ignore: unused_element
  Future<void> _notifyBusiness({
    required _AppointmentItem item,
    required String type,
    required String title,
    required String body,
  }) async {
    await _actionService.notifyBusiness(
      target: item.toActionTarget(),
      type: type,
      title: title,
      body: body,
    );
  }

  Future<String?> _askReason(BuildContext context, String title) async {
    String reason = '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                key: ValueKey('customer-reason-$title'),
                maxLines: 4,
                onChanged: (value) {
                  reason = value.trim();
                  setDialogState(() {});
                },
                decoration: const InputDecoration(
                  hintText:
                      'Kurumsal kullanıcıya iletilecek gerekçeyi yazın.',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: reason.trim().isEmpty
                      ? null
                      : () => Navigator.of(dialogContext).pop(reason.trim()),
                  child: const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cancelByCustomer(
    BuildContext context,
    _AppointmentItem item,
  ) async {
    final reason = await _askReason(context, 'Randevu iptal gerekçesi');
    if (reason == null || reason.trim().isEmpty) return;

    await _actionService.cancelByCustomer(
      target: item.toActionTarget(),
      reason: reason,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Randevu iptal edildi ve kurumsal kullanıcıya bildirim kaydı oluşturuldu.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _acceptPostpone(
    BuildContext context,
    _AppointmentItem item,
  ) async {
    await _actionService.acceptPostpone(target: item.toActionTarget());

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Erteleme talebi kabul edildi. Randevu yeni tarihe alındı.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _rejectPostponeAndCancel(
    BuildContext context,
    _AppointmentItem item,
  ) async {
    final reason = await _askReason(
      context,
      'Erteleme reddi ve iptal gerekçesi',
    );
    if (reason == null || reason.trim().isEmpty) return;

    await _actionService.rejectPostponeAndCancel(
      target: item.toActionTarget(),
      reason: reason,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erteleme reddedildi ve randevu iptal edildi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openBusinessProfile(BuildContext context, _AppointmentItem item) {
    final bid = item.businessId.trim();

    if (bid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kurumsal profil bilgisi bulunamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessProfilePage(
          businessId: bid,
          businessName: item.businessName.isEmpty
              ? 'Kurumsal Kullanıcı'
              : item.businessName,
          category: item.serviceName.isEmpty ? 'Genel' : item.serviceName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Randevularım')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Randevularınızı görmek için bireysel kullanıcı hesabıyla giriş yapın.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Randevularım')),
      body: StreamBuilder<List<_AppointmentItem>>(
        stream: _appointmentsStream(user.uid),
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];

          final active = all
              .where((item) => item.isActive && !item.isPostponeRequested)
              .toList();
          final postponed = all
              .where(
                (item) =>
                    item.isPostponeRequested &&
                    item.customerApprovalStatus == 'pending',
              )
              .toList();
          final past = all.where((item) => item.isPast).toList();
          final cancelled = all.where((item) => item.isCancelled).toList();

          final selectedItems = selectedTab == 0
              ? active
              : selectedTab == 1
              ? postponed
              : selectedTab == 2
              ? past
              : cancelled;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${all.length} randevu var',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomerAppointmentTabs(
                  selectedIndex: selectedTab,
                  activeCount: active.length,
                  postponedCount: postponed.length,
                  pastCount: past.length,
                  cancelledCount: cancelled.length,
                  onChanged: (index) {
                    setState(() => selectedTab = index);
                  },
                ),
                const SizedBox(height: 14),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (selectedItems.isEmpty)
                  CustomerEmptyAppointments(tab: selectedTab)
                else
                  ...selectedItems.map(
                    (item) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openBusinessProfile(context, item),
                      child: _AppointmentCard(
                        item: item,
                        onCancel: () => _cancelByCustomer(context, item),
                        onPostponeApprove: () => _acceptPostpone(context, item),
                        onPostponeReject: () =>
                            _rejectPostponeAndCancel(context, item),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.item,
    required this.onCancel,
    required this.onPostponeApprove,
    required this.onPostponeReject,
  });

  final _AppointmentItem item;
  final VoidCallback onCancel;
  final VoidCallback onPostponeApprove;
  final VoidCallback onPostponeReject;

  Color get _bg {
    if (item.isPostponeRequested) return const Color(0xFFFFF7D6);
    if (item.isCancelled) return const Color(0xFFFFE4E6);
    if (item.isCompleted) return const Color(0xFFDCFCE7);
    return Colors.white;
  }

  Color get _accent {
    if (item.isPostponeRequested) return const Color(0xFFD97706);
    if (item.isCancelled) return const Color(0xFFDC2626);
    if (item.isCompleted) return const Color(0xFF16A34A);
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
              text: '${item.dateText} • ${item.timeText}',
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
                  'Kurumsal Kullanıcı bu randevu için erteleme talebi oluşturmuş. Uygunsa kabul edebilir veya reddedebilirsiniz.',
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
              onPostponeApprove: onPostponeApprove,
              onPostponeReject: onPostponeReject,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentItem {
  const _AppointmentItem({
    required this.id,
    required this.businessId,
    required this.businessOwnerUid,
    required this.businessName,
    required this.serviceName,
    required this.staffName,
    required this.dateText,
    required this.timeText,
    required this.status,
    required this.isActive,
    required this.isPast,
    required this.isCancelled,
    required this.isPostponeRequested,
    required this.customerApprovalStatus,
    required this.postponeDateKey,
    required this.postponeDateText,
    required this.postponeTimeText,
    required this.postponeStartAt,
    required this.postponeStartAtIso,
    required this.postponeRequestNote,
    required this.cancellationReason,
    required this.sortValue,
  });

  final String id;
  final String businessId;
  final String businessOwnerUid;
  final String businessName;
  final String serviceName;
  final String staffName;
  final String dateText;
  final String timeText;
  final String status;
  final bool isActive;
  final bool isPast;
  final bool isCancelled;
  final bool isPostponeRequested;
  final String customerApprovalStatus;
  final String postponeDateKey;
  final String postponeDateText;
  final String postponeTimeText;
  final Timestamp? postponeStartAt;
  final String postponeStartAtIso;
  final String postponeRequestNote;
  final String cancellationReason;
  final int sortValue;

  CustomerAppointmentActionTarget toActionTarget() {
    return CustomerAppointmentActionTarget(
      id: id,
      businessId: businessId,
      businessName: businessName,
      businessOwnerUid: businessOwnerUid,
      serviceName: serviceName,
      dateText: dateText,
      timeText: timeText,
      postponeDateKey: postponeDateKey,
      postponeDateText: postponeDateText,
      postponeTimeText: postponeTimeText,
      postponeStartAt: postponeStartAt,
      postponeStartAtIso: postponeStartAtIso,
    );
  }

  // ignore: unused_element
  factory _AppointmentItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final cancelled = _CustomerAppointmentsPageState._isCancelled(data);
    final active = _CustomerAppointmentsPageState._isActive(data);
    final past = _CustomerAppointmentsPageState._isCompleted(data);
    final postponed = _CustomerAppointmentsPageState._isPostponeRequested(data);
    final startAt = data['startAt'];

    int sort = 0;

    if (startAt is Timestamp) {
      sort = startAt.millisecondsSinceEpoch;
    } else {
      sort =
          DateTime.tryParse(
            _CustomerAppointmentsPageState._clean(data['startAtIso']),
          )?.millisecondsSinceEpoch ??
          DateTime.tryParse(
            _CustomerAppointmentsPageState._clean(data['createdAtLocalIso']),
          )?.millisecondsSinceEpoch ??
          0;
    }

    final postponeStartAtRaw = data['postponeRequestedStartAt'];
    final approval = _CustomerAppointmentsPageState._clean(
      data['customerApprovalStatus'] ?? data['postponeRequestStatus'],
    ).toLowerCase();

    return _AppointmentItem(
      id: doc.id,
      businessId: _CustomerAppointmentsPageState._clean(data['businessId']),
      businessOwnerUid: _CustomerAppointmentsPageState._clean(
        data['businessOwnerUid'] ?? data['ownerUid'] ?? data['providerUid'],
      ),
      businessName:
          _CustomerAppointmentsPageState._clean(data['businessName']).isEmpty
          ? 'Kurumsal Kullanıcı'
          : _CustomerAppointmentsPageState._clean(data['businessName']),
      serviceName:
          _CustomerAppointmentsPageState._clean(data['serviceName']).isEmpty
          ? 'Hizmet'
          : _CustomerAppointmentsPageState._clean(data['serviceName']),
      staffName:
          _CustomerAppointmentsPageState._clean(data['staffName']).isEmpty
          ? 'Personel'
          : _CustomerAppointmentsPageState._clean(data['staffName']),
      dateText:
          _CustomerAppointmentsPageState._clean(
            data['dateText'] ?? data['appointmentDate'],
          ).isEmpty
          ? '-'
          : _CustomerAppointmentsPageState._clean(
              data['dateText'] ?? data['appointmentDate'],
            ),
      timeText:
          _CustomerAppointmentsPageState._clean(
            data['timeText'] ?? data['appointmentTime'],
          ).isEmpty
          ? '-'
          : _CustomerAppointmentsPageState._clean(
              data['timeText'] ?? data['appointmentTime'],
            ),
      status: _CustomerAppointmentsPageState._statusOf(data),
      isActive: active,
      isPast: past,
      isCancelled: cancelled,
      isPostponeRequested: postponed,
      customerApprovalStatus: approval.isEmpty ? '-' : approval,
      postponeDateKey: _CustomerAppointmentsPageState._clean(
        data['postponeRequestedDateKey'],
      ),
      postponeDateText: _CustomerAppointmentsPageState._clean(
        data['postponeRequestedDateText'] ?? data['postponedDateText'],
      ),
      postponeTimeText: _CustomerAppointmentsPageState._clean(
        data['postponeRequestedTimeText'] ?? data['postponedTimeText'],
      ),
      postponeStartAt: postponeStartAtRaw is Timestamp
          ? postponeStartAtRaw
          : null,
      postponeStartAtIso: _CustomerAppointmentsPageState._clean(
        data['postponeRequestedStartAtIso'],
      ),
      postponeRequestNote: _CustomerAppointmentsPageState._clean(
        data['postponeRequestNote'] ?? data['postponedNote'],
      ),
      cancellationReason: _CustomerAppointmentsPageState._clean(
        data['cancellationReason'] ?? data['postponeRejectedReason'],
      ),
      sortValue: sort,
    );
  }
  factory _AppointmentItem.fromCustomerDocument(
    CustomerAppointmentDocument doc,
  ) {
    return _AppointmentItem.fromData(id: doc.id, data: doc.data);
  }

  factory _AppointmentItem.fromData({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final cancelled = _CustomerAppointmentsPageState._isCancelled(data);
    final active = _CustomerAppointmentsPageState._isActive(data);
    final past = _CustomerAppointmentsPageState._isCompleted(data);
    final postponed = _CustomerAppointmentsPageState._isPostponeRequested(data);
    final startAt = data['startAt'];

    int sort = 0;

    if (startAt is Timestamp) {
      sort = startAt.millisecondsSinceEpoch;
    } else {
      sort =
          DateTime.tryParse(
            _CustomerAppointmentsPageState._clean(data['startAtIso']),
          )?.millisecondsSinceEpoch ??
          DateTime.tryParse(
            _CustomerAppointmentsPageState._clean(data['createdAtLocalIso']),
          )?.millisecondsSinceEpoch ??
          0;
    }

    final postponeStartAtRaw = data['postponeRequestedStartAt'];
    final approval = _CustomerAppointmentsPageState._clean(
      data['customerApprovalStatus'] ?? data['postponeRequestStatus'],
    ).toLowerCase();

    return _AppointmentItem(
      id: id,
      businessId: _CustomerAppointmentsPageState._clean(data['businessId']),
      businessOwnerUid: _CustomerAppointmentsPageState._clean(
        data['businessOwnerUid'] ?? data['ownerUid'] ?? data['providerUid'],
      ),
      businessName:
          _CustomerAppointmentsPageState._clean(data['businessName']).isEmpty
          ? 'Kurumsal Kullanıcı'
          : _CustomerAppointmentsPageState._clean(data['businessName']),
      serviceName:
          _CustomerAppointmentsPageState._clean(data['serviceName']).isEmpty
          ? 'Hizmet'
          : _CustomerAppointmentsPageState._clean(data['serviceName']),
      staffName:
          _CustomerAppointmentsPageState._clean(data['staffName']).isEmpty
          ? 'Personel'
          : _CustomerAppointmentsPageState._clean(data['staffName']),
      dateText:
          _CustomerAppointmentsPageState._clean(
            data['dateText'] ?? data['appointmentDate'],
          ).isEmpty
          ? '-'
          : _CustomerAppointmentsPageState._clean(
              data['dateText'] ?? data['appointmentDate'],
            ),
      timeText:
          _CustomerAppointmentsPageState._clean(
            data['timeText'] ?? data['appointmentTime'],
          ).isEmpty
          ? '-'
          : _CustomerAppointmentsPageState._clean(
              data['timeText'] ?? data['appointmentTime'],
            ),
      status: _CustomerAppointmentsPageState._statusOf(data),
      isActive: active,
      isPast: past,
      isCancelled: cancelled,
      isPostponeRequested: postponed,
      customerApprovalStatus: approval.isEmpty ? '-' : approval,
      postponeDateKey: _CustomerAppointmentsPageState._clean(
        data['postponeRequestedDateKey'],
      ),
      postponeDateText: _CustomerAppointmentsPageState._clean(
        data['postponeRequestedDateText'] ?? data['postponedDateText'],
      ),
      postponeTimeText: _CustomerAppointmentsPageState._clean(
        data['postponeRequestedTimeText'] ?? data['postponedTimeText'],
      ),
      postponeStartAt: postponeStartAtRaw is Timestamp
          ? postponeStartAtRaw
          : null,
      postponeStartAtIso: _CustomerAppointmentsPageState._clean(
        data['postponeRequestedStartAtIso'],
      ),
      postponeRequestNote: _CustomerAppointmentsPageState._clean(
        data['postponeRequestNote'] ?? data['postponedNote'],
      ),
      cancellationReason: _CustomerAppointmentsPageState._clean(
        data['cancellationReason'] ?? data['postponeRejectedReason'],
      ),
      sortValue: sort,
    );
  }
}

extension _AppointmentItem37MDFix on _AppointmentItem {
  bool get isCompleted {
    final normalized = status.toLowerCase().trim();

    return normalized == 'completed' ||
        normalized == 'done' ||
        normalized == 'finished' ||
        normalized == 'tamamlandi' ||
        normalized == 'tamamlandı' ||
        normalized == 'sonuclandi' ||
        normalized == 'sonuçlandı' ||
        normalized == 'resulted' ||
        isPast;
  }

  String get appointmentNo => '';
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.item,
    required this.onCancel,
    required this.onPostponeApprove,
    required this.onPostponeReject,
  });

  final _AppointmentItem item;
  final VoidCallback onCancel;
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
      return const CustomerAppointmentStatusOnlyLine(
        icon: Icons.history_rounded,
        text: 'Bu randevu geçmiş randevular arasında.',
        color: Color(0xFF64748B),
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
      ],
    );
  }
}
