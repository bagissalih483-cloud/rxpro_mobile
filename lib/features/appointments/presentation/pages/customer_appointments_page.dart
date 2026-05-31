import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/app/app_routes.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';
import 'package:rxpro_mobile/features/appointments/services/customer_appointment_action_service.dart';
import 'package:rxpro_mobile/features/appointments/data/customer_appointment_repository.dart';
import 'package:rxpro_mobile/features/appointments/domain/customer_appointment_status_policy.dart';
import 'package:rxpro_mobile/features/appointments/presentation/controllers/customer_appointments_controller.dart';
import 'package:rxpro_mobile/features/appointments/presentation/widgets/customer_appointment_widgets.dart';

part 'customer_appointment_card_part.dart';
part 'customer_next_appointment_part.dart';
part 'customer_appointment_item_part.dart';

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
  final CustomerAppointmentsController _controller =
      CustomerAppointmentsController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Stream<List<_AppointmentItem>> _appointmentsStream(String uid) {
    return _appointmentRepository.watchMergedCustomerAppointments(uid: uid).map(
      (docs) {
        final items = docs
            .where(
              (doc) => CustomerAppointmentStatusPolicy.matchesCurrentUser(
                doc.data,
                uid,
              ),
            )
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
                  hintText: 'İşletmeye iletmek istediğiniz not',
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
          'Randevu iptal edildi ve işletmeye bildirim kaydı oluşturuldu.',
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

    Navigator.of(context).pushNamed(
      AppRoutes.businessProfile,
      arguments: BusinessProfileRouteArgs(
        businessId: bid,
        businessName: item.businessName.isEmpty
            ? 'Kurumsal Kullanıcı'
            : item.businessName,
        category: item.serviceName.isEmpty ? 'Genel' : item.serviceName,
      ),
    );
  }

  void _messageBusiness(BuildContext context, _AppointmentItem item) {
    if (item.businessId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj için işletme bilgisi bulunamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.messagesNewCustomer,
      arguments: NewCustomerMessageRouteArgs(
        initialBusinessId: item.businessId,
        initialBusinessName: item.businessName,
        initialBusinessCategory: item.serviceName,
      ),
    );
  }

  void _showComingSoon(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  _AppointmentItem? _nextAppointment(List<_AppointmentItem> active) {
    if (active.isEmpty) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final upcoming = active
        .where((item) => item.sortValue == 0 || item.sortValue >= now)
        .toList()
      ..sort((a, b) => a.sortValue.compareTo(b.sortValue));

    if (upcoming.isNotEmpty) return upcoming.first;

    final fallback = [...active]
      ..sort((a, b) => a.sortValue.compareTo(b.sortValue));
    return fallback.first;
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
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final selectedTab = _controller.selectedTab;

          return StreamBuilder<List<_AppointmentItem>>(
            key: ValueKey(
              'customer_appointments_${_controller.refreshVersion}',
            ),
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
          final nextAppointment = _nextAppointment(active);

          final selectedItems = selectedTab == 0
              ? active
              : selectedTab == 1
              ? postponed
              : selectedTab == 2
              ? past
              : cancelled;

          return RefreshIndicator(
            onRefresh: _controller.refresh,
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
                      onPressed: _controller.refresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (nextAppointment != null) ...[
                  _NextAppointmentCard(
                    item: nextAppointment,
                    onOpen: () => _openBusinessProfile(
                      context,
                      nextAppointment,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                CustomerAppointmentTabs(
                  selectedIndex: selectedTab,
                  activeCount: active.length,
                  postponedCount: postponed.length,
                  pastCount: past.length,
                  cancelledCount: cancelled.length,
                  onChanged: _controller.selectTab,
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
                        onOpenBusiness: () =>
                            _openBusinessProfile(context, item),
                        onMessage: () => _messageBusiness(context, item),
                        onAddToCalendar: () => _showComingSoon(
                          context,
                          'Takvime ekleme bu randevu için hazırlanıyor.',
                        ),
                        onReview: () => _showComingSoon(
                          context,
                          'DeĞerlendirme akıŞı yakında aÇılacak.',
                        ),
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
          );
        },
      ),
    );
  }
}
