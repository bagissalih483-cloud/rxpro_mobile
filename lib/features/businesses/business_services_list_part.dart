part of 'business_services_manage_page.dart';

class _ServiceSection extends StatelessWidget {
  const _ServiceSection({
    required this.title,
    required this.subtitle,
    required this.docs,
    required this.businessId,
    required this.businessData,
    required this.emptyText,
  });

  final String title;
  final String subtitle;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final String businessId;
  final Map<String, dynamic> businessData;

  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          if (docs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                emptyText,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            )
          else
            RxResponsiveGrid(
              itemCount: docs.length,
              maxColumns: 2,
              itemBuilder: (context, index) {
                return _ServiceTile(
                  doc: docs[index],
                  businessId: businessId,
                  businessData: businessData,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.doc,
    required this.businessId,
    required this.businessData,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String businessId;
  final Map<String, dynamic> businessData;

  final BusinessServicesRepository _servicesRepository =
      const BusinessServicesRepository();

  @override
  Widget build(BuildContext context) {
    final data = doc.data();

    final name = BusinessServiceFormPolicy.serviceNameOf(data);
    final type = BusinessServiceFormPolicy.typeLabelOf(data);
    final price =
        data[FirestoreFields.price] ?? data[FirestoreFields.servicePrice] ?? 0;
    final duration = data[FirestoreFields.durationMinutes] ?? 0;
    final active = BusinessServiceFormPolicy.isActive(data);
    final category = BusinessServiceFormPolicy.categoryOf(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        leading: CircleAvatar(
          backgroundColor: active
              ? const Color(0xFFEFFDF5)
              : const Color(0xFFFFF1F2),
          child: Icon(
            active ? Icons.check_rounded : Icons.pause_rounded,
            color: active ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          '$category • $type • $duration dk • $price TL',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              Navigator.of(context).pushNamed(
                AppRoutes.businessServiceForm,
                arguments: BusinessServiceFormRouteArgs(
                  businessId: businessId,
                  businessData: businessData,
                  serviceId: doc.id,
                  initialData: data,
                ),
              );
              return;
            }

            if (value == 'toggle') {
              await _servicesRepository.setServiceBookingEnabled(
                serviceId: doc.id,
                enabled: !active,
              );
              return;
            }

            if (value == 'delete') {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Hizmeti sil'),
                  content: Text('$name silinsin mi?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Vazgeç'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sil'),
                    ),
                  ],
                ),
              );

              if (ok == true) {
                await _servicesRepository.deleteBusinessService(doc.id);
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(active ? 'Pasife Al' : 'Aktif Yap'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Sil')),
          ],
        ),
      ),
    );
  }
}
