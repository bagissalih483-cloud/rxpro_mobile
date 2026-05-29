import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import 'data/notification_center_repository.dart';
import 'domain/notification_center_view_policy.dart';
import 'presentation/notification_center_controller.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key, this.businessId, this.businessName});

  final String? businessId;
  final String? businessName;

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

/// 50C-C: Notification center visibility and backend push behavior are unchanged.
/// 49D-E1 REV1: Eksik helper çağrıları top-level güvenli helper fonksiyonlara bağlandı.
/// 49D-E1: Bildirim merkezi rol/scope çözümü merkezi SessionRolePolicy'ye bağlandı.
/// FCM/backend/token gönderim çekirdeğine dokunulmadı.
class _NotificationCenterPageState extends State<NotificationCenterPage> {
  late final NotificationCenterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotificationCenterController(
      businessId: widget.businessId,
      businessName: widget.businessName,
    );
  }

  @override
  void didUpdateWidget(covariant NotificationCenterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessId != widget.businessId ||
        oldWidget.businessName != widget.businessName) {
      _controller.updateTarget(
        businessId: widget.businessId,
        businessName: widget.businessName,
      );
    }
  }

  void _refreshScopeIfNeeded() {
    _controller.refreshScopeIfNeeded();
  }

  Stream<List<NotificationCenterItem>> _notificationStream(
    NotificationCenterScope scope,
  ) {
    return _controller.watchNotifications(scope);
  }

  Future<void> _markAllRead(List<NotificationCenterItem> items) async {
    final count = await _controller.markAllRead(items);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count bildirim okundu işaretlendi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _refreshScopeIfNeeded();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Bildirimler'),
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: FutureBuilder<NotificationCenterScope>(
        future: _controller.scopeFuture,
        builder: (context, scopeSnapshot) {
          if (scopeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final scope =
              scopeSnapshot.data ?? const NotificationCenterScope.guest();

          if (!scope.isLoggedIn) {
            return const _EmptyNotificationState(
              icon: Icons.login_rounded,
              title: 'Giriş gerekli',
              body: 'Bildirimleri görmek için hesaba giriş yapılmalıdır.',
            );
          }

          return StreamBuilder<List<NotificationCenterItem>>(
            stream: _notificationStream(scope),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorNotificationState(error: snapshot.error);
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data ?? const <NotificationCenterItem>[];
              final summary = NotificationCenterViewPolicy.summary(
                scope: scope,
                items: docs,
              );

              if (docs.isEmpty) {
                final emptyCopy = NotificationCenterViewPolicy.emptyCopy(scope);
                return _EmptyNotificationState(
                  icon: Icons.notifications_none_rounded,
                  title: emptyCopy.title,
                  body: emptyCopy.body,
                );
              }

              return Column(
                children: [
                  _NotificationSummaryCard(
                    title: summary.title,
                    subtitle: summary.subtitle,
                    total: summary.total,
                    unread: summary.unread,
                    onMarkAllRead: summary.unread == 0
                        ? null
                        : () => _markAllRead(docs),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: docs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = docs[index];
                        return _NotificationTile(
                          item: item,
                          onTap: () async {
                            await _controller.markRead(item.id);

                            if (!context.mounted) return;

                            if (NotificationCenterViewPolicy
                                .opensCustomerAppointments(item)) {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.customerAppointments);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationCenterItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRead = item.isRead;
    final title = item.title;
    final body = item.body;
    final createdText = item.createdText;
    final icon = _iconForType(item.type);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFFF59E0B),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: isRead
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFFEF3C7),
              foregroundColor: isRead
                  ? const Color(0xFF475569)
                  : const Color(0xFF92400E),
              child: Icon(icon, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (body.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      body,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    createdText,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForType(String type) {
    final t = type.toLowerCase();

    if (t.contains('appointment') || t.contains('randevu')) {
      return Icons.calendar_month_outlined;
    }

    if (t.contains('campaign') || t.contains('kampanya')) {
      return Icons.campaign_outlined;
    }

    if (t.contains('message') || t.contains('mesaj')) {
      return Icons.chat_bubble_outline_rounded;
    }

    if (t.contains('finance') || t.contains('expense')) {
      return Icons.account_balance_wallet_outlined;
    }

    return Icons.notifications_none_rounded;
  }
}

class _NotificationSummaryCard extends StatelessWidget {
  const _NotificationSummaryCard({
    required this.title,
    required this.subtitle,
    required this.total,
    required this.unread,
    required this.onMarkAllRead,
  });

  final String title;
  final String subtitle;
  final int total;
  final int unread;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF1E293B),
            foregroundColor: Colors.white,
            child: Icon(Icons.notifications_active_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$subtitle • Toplam $total • Okunmamış $unread',
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onMarkAllRead, child: const Text('Tümünü oku')),
        ],
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorNotificationState extends StatelessWidget {
  const _ErrorNotificationState({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Text(
          'Bildirimler yüklenemedi.\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFB91C1C),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
