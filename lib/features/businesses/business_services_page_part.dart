part of 'business_services_manage_page.dart';

class BusinessServicesManagePage extends StatelessWidget {
  const BusinessServicesManagePage({
    super.key,
    required this.businessId,
    this.businessData = const <String, dynamic>{},
  });

  final String businessId;
  final Map<String, dynamic> businessData;

  final BusinessServicesRepository _servicesRepository =
      const BusinessServicesRepository();

  void _openServiceForm(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.businessServiceForm,
      arguments: BusinessServiceFormRouteArgs(
        businessId: businessId,
        businessData: businessData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RxKeyboardShortcutScope(
      onCreate: () => _openServiceForm(context),
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hizmetler ve Paketler'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openServiceForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Hizmet Ekle'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _servicesRepository.watchBusinessServices(businessId),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          docs.sort(
            (a, b) => BusinessServiceFormPolicy.sortKey(
              a.data(),
            ).compareTo(BusinessServiceFormPolicy.sortKey(b.data())),
          );

          final activeDocs = docs.where((d) {
            return BusinessServiceFormPolicy.isActive(d.data());
          }).toList();

          final passiveDocs = docs.where((d) {
            return !BusinessServiceFormPolicy.isActive(d.data());
          }).toList();

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (docs.isEmpty) {
            return const _EmptyState(
              title: 'Henüz hizmet yok',
              text:
                  'Bireysel kullanıcının randevu alabilmesi için önce hizmet veya paket ekle.',
            );
          }

          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
            children: [
              _SummaryHeader(
                activeCount: activeDocs.length,
                passiveCount: passiveDocs.length,
              ),
              const SizedBox(height: 14),
              _ServiceSection(
                title: 'Aktif Hizmetler',
                subtitle:
                    'Bireysel kullanıcı tarafında randevuya açık hizmetler.',
                docs: activeDocs,
                businessId: businessId,
                businessData: businessData,
                emptyText: 'Aktif hizmet yok.',
              ),
              const SizedBox(height: 14),
              _ServiceSection(
                title: 'Pasif Hizmetler',
                subtitle:
                    'Randevuya kapalı, beklemeye alınmış veya geçici durdurulmuş hizmetler.',
                docs: passiveDocs,
                businessId: businessId,
                businessData: businessData,
                emptyText: 'Pasif hizmet yok.',
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
