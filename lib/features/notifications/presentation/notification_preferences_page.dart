import 'package:flutter/material.dart';

import '../data/notification_preferences_repository.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  final NotificationPreferencesRepository _repository =
      NotificationPreferencesRepository();
  String _savingKey = '';

  Future<void> _save(
    NotificationPreferences next,
    String key,
  ) async {
    setState(() => _savingKey = key);
    try {
      await _repository.saveCurrentUserPreferences(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim tercihleri güncellendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tercihler kaydedilemedi: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingKey = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Bildirim Tercihleri')),
      body: StreamBuilder<NotificationPreferences>(
        stream: _repository.watchCurrentUserPreferences(),
        builder: (context, snapshot) {
          final preferences =
              snapshot.data ?? const NotificationPreferences.defaults();
          final loading = snapshot.connectionState == ConnectionState.waiting;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              if (loading) const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 10),
              _PreferenceCard(
                title: 'Anlık bildirimler',
                subtitle:
                    'Telefon bildirimi almak istemiyorsanız tamamını kapatabilirsiniz.',
                icon: Icons.notifications_active_outlined,
                value: preferences.pushEnabled,
                saving: _savingKey == 'pushEnabled',
                onChanged: (value) => _save(
                  preferences.copyWith(pushEnabled: value),
                  'pushEnabled',
                ),
              ),
              const SizedBox(height: 12),
              _PreferenceCard(
                title: 'Randevu hatırlatmaları',
                subtitle: 'Yaklaşan randevu, erteleme ve iptal uyarıları.',
                icon: Icons.event_available_outlined,
                value:
                    preferences.pushEnabled && preferences.appointmentReminders,
                enabled: preferences.pushEnabled,
                saving: _savingKey == 'appointmentReminders',
                onChanged: (value) => _save(
                  preferences.copyWith(appointmentReminders: value),
                  'appointmentReminders',
                ),
              ),
              const SizedBox(height: 12),
              _PreferenceCard(
                title: 'Mesaj bildirimleri',
                subtitle: 'İşletme veya müşteri mesajları için uyarılar.',
                icon: Icons.mark_chat_unread_outlined,
                value: preferences.pushEnabled && preferences.messages,
                enabled: preferences.pushEnabled,
                saving: _savingKey == 'messages',
                onChanged: (value) => _save(
                  preferences.copyWith(messages: value),
                  'messages',
                ),
              ),
              const SizedBox(height: 12),
              _PreferenceCard(
                title: 'Kampanya bildirimleri',
                subtitle: 'İndirim, duyuru ve toplu mesaj kampanyaları.',
                icon: Icons.local_offer_outlined,
                value: preferences.pushEnabled && preferences.campaigns,
                enabled: preferences.pushEnabled,
                saving: _savingKey == 'campaigns',
                onChanged: (value) => _save(
                  preferences.copyWith(campaigns: value),
                  'campaigns',
                ),
              ),
              const SizedBox(height: 12),
              _PreferenceCard(
                title: 'Sistem bildirimleri',
                subtitle: 'Güvenlik, hesap ve önemli uygulama uyarıları.',
                icon: Icons.verified_user_outlined,
                value: preferences.pushEnabled && preferences.system,
                enabled: preferences.pushEnabled,
                saving: _savingKey == 'system',
                onChanged: (value) => _save(
                  preferences.copyWith(system: value),
                  'system',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kritik güvenlik ve yasal zorunluluk içeren bilgilendirmeler uygulama içinde gösterilmeye devam edebilir.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.saving = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final bool enabled;
  final bool saving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: SwitchListTile(
        value: value,
        onChanged: enabled && !saving ? onChanged : null,
        secondary: saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: const Color(0xFF2563EB)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64748B), height: 1.25),
        ),
      ),
    );
  }
}
