import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';

import 'package:rxpro_mobile/features/notifications/data/customer_notification_repository.dart';

class CustomerNotificationsPage extends StatelessWidget {
  static final CustomerNotificationRepository _notificationRepository =
      CustomerNotificationRepository();
  static final AuthService _authService = AuthService();
  const CustomerNotificationsPage({super.key});

  Stream<List<_NotificationItem>> _notificationsStream(String uid) {
    return _notificationRepository.watchCustomerNotifications(uid: uid).map((
      items,
    ) {
      final list = items
          .map(
            (item) => _NotificationItem(
              id: item.id,
              title: item.title,
              body: item.body,
              type: item.type,
              businessName: item.businessName,
              read: item.read,
              createdAt: item.createdAt,
            ),
          )
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> _markRead(String id) async {
    await _notificationRepository.markCustomerNotificationRead(id);
  }

  Future<void> _markAllRead(List<_NotificationItem> items) async {
    final docs = items
        .map(
          (item) => CustomerNotificationDocument(
            id: item.id,
            title: item.title,
            body: item.body,
            type: item.type,
            businessName: item.businessName,
            read: item.read,
            createdAt: item.createdAt,
          ),
        )
        .toList();

    await _notificationRepository.markAllCustomerNotificationsRead(docs);
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bildirimler')),
        body: const Center(
          child: Text('Bildirimleri görmek için giriş yapın.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: StreamBuilder<List<_NotificationItem>>(
        stream: _notificationsStream(user.uid),
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? [];
          final unreadCount = notifications.where((e) => !e.read).length;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Bildirim Merkezi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () => _markAllRead(notifications),
                      child: const Text('Tümünü okundu yap'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                unreadCount == 0
                    ? 'Okunmamış bildiriminiz yok.'
                    : '$unreadCount okunmamış bildiriminiz var.',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              if (snapshot.hasError)
                _ErrorBox(error: snapshot.error.toString())
              else if (notifications.isEmpty)
                const _EmptyNotifications()
              else
                ...notifications.map(
                  (item) => _NotificationCard(
                    item: item,
                    onTap: () => _markRead(item.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final String businessName;
  final bool read;
  final String createdAt;

  const _NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.businessName,
    required this.read,
    required this.createdAt,
  });
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final _NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(item.type);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(_typeIcon(item.type), color: color),
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
                            item.title.isEmpty ? 'Bildirim' : item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: item.read
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!item.read)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF18B7C9),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (item.businessName.isNotEmpty)
                      Text(
                        item.businessName,
                        style: const TextStyle(
                          color: Color(0xFF18B7C9),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'bulkMessage':
        return Icons.campaign_outlined;
      case 'appointment':
        return Icons.calendar_month_outlined;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'bulkMessage':
        return const Color(0xFF8B5CF6);
      case 'appointment':
        return const Color(0xFF7C5CFF);
      case 'message':
        return const Color(0xFF0EA5E9);
      case 'system':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF18B7C9);
    }
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.notifications_none, size: 44, color: Color(0xFF6B7280)),
            SizedBox(height: 12),
            Text(
              'Henüz bildiriminiz yok.',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              'Toplu mesaj, randevu ve sistem bildirimleri burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFEE2E2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          error,
          style: const TextStyle(
            color: Color(0xFF991B1B),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
