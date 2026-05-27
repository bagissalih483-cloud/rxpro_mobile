import 'package:flutter/material.dart';

import 'data/business_live_flow_repository.dart';
import 'staff_tasks_entry_page.dart';

class BusinessLiveFlowPage extends StatelessWidget {
  BusinessLiveFlowPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;
  final BusinessLiveFlowRepository _repository = BusinessLiveFlowRepository();

  Stream<List<BusinessLiveFlowAppointment>> _appointments() {
    return _repository.watchAppointments(businessId: businessId);
  }

  Stream<List<BusinessLiveFlowActivityLog>> _logs() {
    return _repository.watchLogs(businessId: businessId);
  }

  Stream<List<BusinessLiveFlowStaff>> _staff() {
    return _repository.watchStaff(businessId: businessId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Canlı Akış'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BusinessFlowInfoCard(
            icon: Icons.storefront_outlined,
            title: businessName,
            text:
                'Bugünkü randevular, personel durumu ve son işletme hareketleri.',
          ),
          const SizedBox(height: 12),
          _BusinessFlowActionCard(
            icon: Icons.task_alt_rounded,
            title: 'Görevlerim',
            text:
                'Sana atanan işleri başlat, bitir ve durumlarını Canlı Akıştan takip et.',
            actionText: 'Atanan işleri aç',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StaffTasksEntryPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<BusinessLiveFlowAppointment>>(
            stream: _appointments(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _BusinessFlowInfoCard(
                  icon: Icons.error_outline,
                  title: 'Randevu akışı okunamadı',
                  text: snapshot.error.toString(),
                );
              }

              final appointments = snapshot.data ?? [];
              final active = appointments.where((item) => item.isActive).length;

              return _BusinessFlowInfoCard(
                icon: Icons.event_available_outlined,
                title: 'Bugünkü / aktif randevu havuzu',
                text:
                    '${appointments.length} randevu kaydı dinleniyor. Aktif/işlemde görünen: $active',
              );
            },
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<BusinessLiveFlowStaff>>(
            stream: _staff(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _BusinessFlowInfoCard(
                  icon: Icons.error_outline,
                  title: 'Personel durumu okunamadı',
                  text: snapshot.error.toString(),
                );
              }

              final staff = snapshot.data ?? [];
              final busy = staff.where((item) => item.isBusy).length;

              return _BusinessFlowInfoCard(
                icon: Icons.groups_2_outlined,
                title: 'Personel durumu',
                text:
                    '${staff.length} personel kaydı dinleniyor. İşlemde görünen: $busy',
              );
            },
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<BusinessLiveFlowActivityLog>>(
            stream: _logs(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _BusinessFlowInfoCard(
                  icon: Icons.error_outline,
                  title: 'Hareket kayıtları okunamadı',
                  text: snapshot.error.toString(),
                );
              }

              final logs = snapshot.data ?? [];
              final latest = logs.isEmpty
                  ? 'Henüz hareket yok.'
                  : logs.first.title;

              return _BusinessFlowInfoCard(
                icon: Icons.timeline_outlined,
                title: 'Personel hareketleri',
                text: '${logs.length} hareket kaydı. Son hareket: $latest',
              );
            },
          ),
          const SizedBox(height: 12),
          const _BusinessFlowInfoCard(
            icon: Icons.speed_outlined,
            title: 'Sonraki yükseltme notu',
            text:
                'Personel işleme başlayınca müsaitlik kapanacak, bitirince tekrar açılacak. İş süresi otomatik süre analizine yazılacak.',
          ),
        ],
      ),
    );
  }
}

class _BusinessFlowActionCard extends StatelessWidget {
  const _BusinessFlowActionCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.actionText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String text;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF10B981)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(actionText),
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
}

class _BusinessFlowInfoCard extends StatelessWidget {
  const _BusinessFlowInfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      height: 1.35,
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
}
