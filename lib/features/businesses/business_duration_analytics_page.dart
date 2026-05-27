import 'package:flutter/material.dart';

import 'data/business_duration_analytics_repository.dart';

class BusinessDurationAnalyticsPage extends StatelessWidget {
  BusinessDurationAnalyticsPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;
  final BusinessDurationAnalyticsRepository _repository =
      BusinessDurationAnalyticsRepository();

  Stream<List<BusinessDurationAppointment>> _appointmentsStream() {
    return _repository.watchCompletedAppointments(businessId: businessId);
  }

  _DurationSummary _buildSummary(List<BusinessDurationAppointment> items) {
    final byService = <String, _DurationBucket>{};
    final byStaff = <String, _DurationBucket>{};

    for (final item in items) {
      byService.putIfAbsent(
        item.serviceName,
        () => _DurationBucket(label: item.serviceName),
      );
      byService[item.serviceName]!.add(item);

      byStaff.putIfAbsent(
        item.staffName,
        () => _DurationBucket(label: item.staffName),
      );
      byStaff[item.staffName]!.add(item);
    }

    final services = byService.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final staff = byStaff.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return _DurationSummary(
      totalCompleted: items.length,
      serviceBuckets: services,
      staffBuckets: staff,
    );
  }

  String _aiSuggestion(_DurationSummary summary) {
    if (summary.totalCompleted == 0) {
      return 'Henüz süre analizi için tamamlanmış işlem yok. Personeller “Başlattım” ve “İşlemi Bitirdim” kullandıkça burada öneriler oluşacak.';
    }

    final risky = summary.serviceBuckets.where((bucket) {
      final planned = bucket.averagePlanned;
      if (planned == null || planned <= 0) return false;
      return bucket.averageActual > planned + 10;
    }).toList();

    if (risky.isNotEmpty) {
      final first = risky.first;
      return '${first.label} hizmeti planlanandan uzun sürüyor. Planlanan ortalama ${first.averagePlanned!.round()} dk, gerçek ortalama ${first.averageActual.round()} dk. Randevu aralığını artırmak veya hizmet süresini güncellemek düşünülebilir.';
    }

    final fast = summary.serviceBuckets.where((bucket) {
      final planned = bucket.averagePlanned;
      if (planned == null || planned <= 0) return false;
      return bucket.averageActual + 10 < planned;
    }).toList();

    if (fast.isNotEmpty) {
      final first = fast.first;
      return '${first.label} hizmeti planlanandan daha kısa sürüyor. Bu hizmet için daha verimli randevu aralığı veya araya ek randevu alma stratejisi düşünülebilir.';
    }

    return 'Tamamlanan işlemlerin süreleri genel olarak planlanan sürelerle uyumlu görünüyor. Veri arttıkça hizmet ve personel bazlı daha net öneriler üretilebilir.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Süre Analizi'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: StreamBuilder<List<BusinessDurationAppointment>>(
        stream: _appointmentsStream(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final summary = _buildSummary(items);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              _HeaderCard(
                businessName: businessName,
                totalCompleted: summary.totalCompleted,
              ),
              const SizedBox(height: 12),
              _AiSuggestionCard(text: _aiSuggestion(summary)),
              const SizedBox(height: 12),

              _SectionCard(
                title: 'Hizmet Bazlı Süre',
                subtitle:
                    'Planlanan süre ile gerçek ortalama süre karşılaştırması',
                icon: Icons.spa_outlined,
                child: summary.serviceBuckets.isEmpty
                    ? const _InfoBox(
                        text:
                            'Henüz hizmet bazlı süre verisi yok. İşlem tamamlandıkça burada listelenecek.',
                      )
                    : Column(
                        children: summary.serviceBuckets
                            .map(
                              (bucket) => _DurationBucketTile(
                                label: bucket.label,
                                count: bucket.count,
                                averageActual: bucket.averageActual,
                                averagePlanned: bucket.averagePlanned,
                                type: 'Hizmet',
                              ),
                            )
                            .toList(),
                      ),
              ),

              _SectionCard(
                title: 'Personel Bazlı Süre',
                subtitle: 'Çalışanların ortalama işlem bitirme süreleri',
                icon: Icons.groups_outlined,
                child: summary.staffBuckets.isEmpty
                    ? const _InfoBox(
                        text:
                            'Henüz personel bazlı süre verisi yok. Personel işlem tamamladıkça burada listelenecek.',
                      )
                    : Column(
                        children: summary.staffBuckets
                            .map(
                              (bucket) => _DurationBucketTile(
                                label: bucket.label,
                                count: bucket.count,
                                averageActual: bucket.averageActual,
                                averagePlanned: bucket.averagePlanned,
                                type: 'Personel',
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DurationBucket {
  _DurationBucket({required this.label});

  final String label;
  int count = 0;
  int totalActual = 0;
  int totalPlanned = 0;
  int plannedCount = 0;

  void add(BusinessDurationAppointment item) {
    count++;
    totalActual += item.workDurationMinutes;

    final planned = item.plannedDurationMinutes;
    if (planned != null && planned > 0) {
      totalPlanned += planned;
      plannedCount++;
    }
  }

  double get averageActual => count == 0 ? 0 : totalActual / count;

  double? get averagePlanned =>
      plannedCount == 0 ? null : totalPlanned / plannedCount;
}

class _DurationSummary {
  const _DurationSummary({
    required this.totalCompleted,
    required this.serviceBuckets,
    required this.staffBuckets,
  });

  final int totalCompleted;
  final List<_DurationBucket> serviceBuckets;
  final List<_DurationBucket> staffBuckets;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.businessName, required this.totalCompleted});

  final String businessName;
  final int totalCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.timer_outlined, color: Colors.white, size: 30),
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
                  'İşlem Süresi Analizi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCompleted tamamlanmış işlem',
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

class _AiSuggestionCard extends StatelessWidget {
  const _AiSuggestionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF4F46E5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF3730A3),
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Icon(icon, color: const Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DurationBucketTile extends StatelessWidget {
  const _DurationBucketTile({
    required this.label,
    required this.count,
    required this.averageActual,
    required this.averagePlanned,
    required this.type,
  });

  final String label;
  final int count;
  final double averageActual;
  final double? averagePlanned;
  final String type;

  String get _differenceText {
    final planned = averagePlanned;
    if (planned == null || planned <= 0) return 'Planlanan süre yok';

    final diff = averageActual - planned;
    if (diff.abs() < 5) return 'Planla uyumlu';
    if (diff > 0) return '+${diff.round()} dk uzun';
    return '${diff.round()} dk kısa';
  }

  Color get _statusColor {
    final planned = averagePlanned;
    if (planned == null || planned <= 0) return const Color(0xFF64748B);

    final diff = averageActual - planned;
    if (diff.abs() < 5) return const Color(0xFF16A34A);
    if (diff > 0) return const Color(0xFFDC2626);
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    final plannedText = averagePlanned == null
        ? 'Plan yok'
        : '${averagePlanned!.round()} dk plan';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _statusColor.withValues(alpha: 0.12),
            child: Icon(Icons.timer_outlined, color: _statusColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$type • $count işlem',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _MiniPill(
                      icon: Icons.timer,
                      text: '${averageActual.round()} dk gerçek',
                    ),
                    _MiniPill(
                      icon: Icons.event_available_outlined,
                      text: plannedText,
                    ),
                    _MiniPill(
                      icon: Icons.insights_outlined,
                      text: _differenceText,
                    ),
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
        color: Colors.white,
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
