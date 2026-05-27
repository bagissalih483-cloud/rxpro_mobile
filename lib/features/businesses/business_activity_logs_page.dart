import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/businesses/data/business_staff_repository.dart';

class BusinessActivityLogsPage extends StatelessWidget {
  const BusinessActivityLogsPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  static final BusinessStaffRepository _staffRepository =
      BusinessStaffRepository();

  Stream<QuerySnapshot<Map<String, dynamic>>> _logsStream() {
    return _staffRepository.watchBusinessActivityLogs(
      businessId: businessId,
      limit: 50,
    );
  }

  String _timeText(dynamic raw) {
    DateTime? dt;

    if (raw is Timestamp) dt = raw.toDate();
    if (raw is String) dt = DateTime.tryParse(raw);

    if (dt == null) return '';

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$day.$month $hour:$minute';
  }

  String _durationText(Map<String, dynamic> data) {
    final extra = data['extra'];
    if (extra is Map) {
      final raw = extra['workDurationMinutes'];
      if (raw is num) return '${raw.toInt()} dk';
      if (raw is String && raw.trim().isNotEmpty) return '$raw dk';
    }

    final raw = data['workDurationMinutes'];
    if (raw is num) return '${raw.toInt()} dk';
    if (raw is String && raw.trim().isNotEmpty) return '$raw dk';

    return '';
  }

  IconData _iconFor(String type) {
    if (type.contains('completed')) return Icons.task_alt_rounded;
    if (type.contains('started')) return Icons.play_circle_outline_rounded;
    if (type.contains('expense')) return Icons.receipt_long_outlined;
    return Icons.history_rounded;
  }

  Color _colorFor(String type) {
    if (type.contains('completed')) return const Color(0xFF16A34A);
    if (type.contains('started')) return const Color(0xFF2563EB);
    if (type.contains('expense')) return const Color(0xFFC2410C);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Personel Hareketleri'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _logsStream(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          final sorted = docs.toList()
            ..sort((a, b) {
              final ad = a.data()['createdAt'];
              final bd = b.data()['createdAt'];

              DateTime? at;
              DateTime? bt;

              if (ad is Timestamp) at = ad.toDate();
              if (bd is Timestamp) bt = bd.toDate();

              if (at == null && bt == null) return 0;
              if (at == null) return 1;
              if (bt == null) return -1;

              return bt.compareTo(at);
            });

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              _HeaderCard(businessName: businessName, count: sorted.length),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (sorted.isEmpty)
                const _InfoBox(
                  text:
                      'Henüz personel hareketi yok. Personel işlem başlattıkça, bitirdikçe veya masraf girdikçe burada görünecek.',
                )
              else
                ...sorted.map((doc) {
                  final data = doc.data();
                  final type = (data['type'] ?? '').toString();
                  final duration = _durationText(data);

                  return _ActivityTile(
                    icon: _iconFor(type),
                    color: _colorFor(type),
                    title: (data['title'] ?? 'İşlem').toString(),
                    description: (data['description'] ?? '').toString(),
                    staffName: (data['staffName'] ?? '').toString(),
                    time: _timeText(data['createdAt']),
                    duration: duration,
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.businessName, required this.count});

  final String businessName;

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.history_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Son Personel Hareketleri',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count kayıt',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.staffName,
    required this.time,
    required this.duration,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String staffName;
  final String time;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (staffName.trim().isNotEmpty)
                      _MiniPill(icon: Icons.person_outline, text: staffName),
                    if (time.trim().isNotEmpty)
                      _MiniPill(icon: Icons.schedule_rounded, text: time),
                    if (duration.trim().isNotEmpty)
                      _MiniPill(icon: Icons.timer_outlined, text: duration),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF166534),
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}
