import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/app/app_routes.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:flutter/material.dart';

import 'data/business_services_repository.dart';

/// 50C-K2: Business services management Firestore collection/field literals use
/// FirestoreCollections/FirestoreFields constants. Service behavior is unchanged.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hizmetler ve Paketler'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(
            AppRoutes.businessServiceForm,
            arguments: BusinessServiceFormRouteArgs(
              businessId: businessId,
              businessData: businessData,
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Hizmet Ekle'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _servicesRepository.watchBusinessServices(businessId),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          docs.sort((a, b) {
            final an =
                (a.data()[FirestoreFields.serviceName] ??
                        a.data()[FirestoreFields.name] ??
                        '')
                    .toString();
            final bn =
                (b.data()[FirestoreFields.serviceName] ??
                        b.data()[FirestoreFields.name] ??
                        '')
                    .toString();
            return an.compareTo(bn);
          });

          final activeDocs = docs.where((d) {
            final data = d.data();
            return data[FirestoreFields.bookingEnabled] != false &&
                data[FirestoreFields.isActive] != false;
          }).toList();

          final passiveDocs = docs.where((d) {
            final data = d.data();
            return data[FirestoreFields.bookingEnabled] == false ||
                data[FirestoreFields.isActive] == false;
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
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.activeCount, required this.passiveCount});

  final int activeCount;
  final int passiveCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniMetric(
            title: 'Aktif',
            value: '$activeCount',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniMetric(
            title: 'Pasif',
            value: '$passiveCount',
            icon: Icons.pause_circle_outline_rounded,
            color: const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
            ...docs.map((doc) {
              return _ServiceTile(
                doc: doc,
                businessId: businessId,
                businessData: businessData,
              );
            }),
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

    final name =
        (data[FirestoreFields.serviceName] ??
                data[FirestoreFields.name] ??
                'Hizmet')
            .toString();
    final type =
        (data[FirestoreFields.serviceTypeLabel] ??
                data[FirestoreFields.serviceType] ??
                'Tekil Hizmet')
            .toString();
    final price =
        data[FirestoreFields.price] ?? data[FirestoreFields.servicePrice] ?? 0;
    final duration = data[FirestoreFields.durationMinutes] ?? 0;
    final active =
        data[FirestoreFields.bookingEnabled] != false &&
        data[FirestoreFields.isActive] != false;
    final category = (data[FirestoreFields.category] ?? 'Genel').toString();

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

class ServiceFormPage extends StatefulWidget {
  const ServiceFormPage({
    super.key,
    required this.businessId,
    this.businessData = const <String, dynamic>{},
    this.serviceId,
    this.initialData,
  });

  final String businessId;
  final Map<String, dynamic> businessData;

  final String? serviceId;
  final Map<String, dynamic>? initialData;

  @override
  State<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _sessionCount;

  String _type = 'single';
  bool _active = true;
  bool _saving = false;

  final BusinessServicesRepository _servicesRepository =
      const BusinessServicesRepository();

  @override
  void initState() {
    super.initState();

    final data = widget.initialData ?? <String, dynamic>{};

    _name = TextEditingController(
      text:
          (data[FirestoreFields.serviceName] ??
                  data[FirestoreFields.name] ??
                  '')
              .toString(),
    );
    _price = TextEditingController(
      text:
          (data[FirestoreFields.price] ??
                  data[FirestoreFields.servicePrice] ??
                  '')
              .toString(),
    );
    _duration = TextEditingController(
      text: (data[FirestoreFields.durationMinutes] ?? '45').toString(),
    );
    _description = TextEditingController(
      text: (data[FirestoreFields.description] ?? '').toString(),
    );
    _category = TextEditingController(
      text:
          (data[FirestoreFields.category] ??
                  widget.businessData['category'] ??
                  'Genel')
              .toString(),
    );
    _sessionCount = TextEditingController(
      text: (data[FirestoreFields.sessionCount] ?? '').toString(),
    );

    _type = (data[FirestoreFields.serviceType] ?? data['type'] ?? 'single')
        .toString();
    if (_type != 'single' && _type != 'package' && _type != 'sessionPackage') {
      _type = 'single';
    }

    _active =
        data[FirestoreFields.bookingEnabled] != false &&
        data[FirestoreFields.isActive] != false;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _description.dispose();
    _category.dispose();
    _sessionCount.dispose();
    super.dispose();
  }

  String get _typeLabel {
    switch (_type) {
      case 'package':
        return 'Paket Hizmet';
      case 'sessionPackage':
        return 'Seanslı Paket';
      default:
        return 'Tekil Hizmet';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _saving = true);

    try {
      final price =
          double.tryParse(_price.text.replaceAll(',', '.').trim()) ?? 0;
      final duration = int.tryParse(_duration.text.trim()) ?? 45;
      final sessionCount = int.tryParse(_sessionCount.text.trim());

      final payload = <String, dynamic>{
        FirestoreFields.businessId: widget.businessId,
        FirestoreFields.serviceName: _name.text.trim(),
        FirestoreFields.name: _name.text.trim(),
        FirestoreFields.price: price,
        FirestoreFields.servicePrice: price,
        FirestoreFields.durationMinutes: duration,
        FirestoreFields.description: _description.text.trim(),
        FirestoreFields.category: _category.text.trim().isEmpty
            ? 'Genel'
            : _category.text.trim(),
        'type': _type,
        FirestoreFields.serviceType: _type,
        FirestoreFields.serviceTypeLabel: _typeLabel,
        'isPackage': _type == 'package' || _type == 'sessionPackage',
        'isSessionPackage': _type == 'sessionPackage',
        FirestoreFields.sessionCount: _type == 'sessionPackage'
            ? (sessionCount ?? 1)
            : null,
        'remainingSessionDefault': _type == 'sessionPackage'
            ? (sessionCount ?? 1)
            : null,
        FirestoreFields.bookingEnabled: _active,
        FirestoreFields.isActive: _active,
      };

      await _servicesRepository.saveBusinessService(
        serviceId: widget.serviceId,
        payload: payload,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hizmet kaydedildi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hizmet kaydedilemedi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.serviceId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEdit ? 'Hizmeti Düzenle' : 'Hizmet Ekle'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _SectionCard(
              title: 'Hizmet Tipi',
              child: DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Hizmet tipi',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'single',
                    child: Text('Tekil Hizmet'),
                  ),
                  DropdownMenuItem(
                    value: 'package',
                    child: Text('Paket Hizmet'),
                  ),
                  DropdownMenuItem(
                    value: 'sessionPackage',
                    child: Text('Seanslı Paket'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _type = value);
                },
              ),
            ),
            _SectionCard(
              title: 'Temel Bilgiler',
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Hizmet / Paket adı',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Hizmet adı gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _price,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Fiyat',
                            suffixText: 'TL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _duration,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Süre',
                            suffixText: 'dk',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _category,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_type == 'sessionPackage') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sessionCount,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Seans sayısı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Hizmet aktif',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text(
                      'Aktif hizmetler bireysel kullanıcı randevu akışında kullanılabilir.',
                    ),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Text(
          '$title\n\n$text',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, height: 1.4),
        ),
      ),
    );
  }
}
