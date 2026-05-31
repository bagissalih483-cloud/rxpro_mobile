part of 'business_services_manage_page.dart';

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

  late final BusinessServiceFormController _controller;

  final BusinessServicesRepository _servicesRepository =
      const BusinessServicesRepository();

  @override
  void initState() {
    super.initState();

    final data = widget.initialData ?? <String, dynamic>{};
    _controller = BusinessServiceFormController(initialData: data);

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
  }

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _description.dispose();
    _category.dispose();
    _sessionCount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    _controller.setSaving(true);

    try {
      final payload = BusinessServiceFormPolicy.buildPayload(
        businessId: widget.businessId,
        name: _name.text,
        price: _price.text,
        duration: _duration.text,
        description: _description.text,
        category: _category.text,
        type: _controller.type,
        sessionCount: _sessionCount.text,
        active: _controller.active,
      );

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

      _controller.setSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isEdit = widget.serviceId != null;
        final type = _controller.type;
        final active = _controller.active;
        final saving = _controller.saving;

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
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(saving ? 'Kaydediliyor...' : 'Kaydet'),
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
                initialValue: type,
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
                  _controller.selectType(value);
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
                    validator: BusinessServiceFormPolicy.validateName,
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
                          validator: BusinessServiceFormPolicy.validatePrice,
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
                          validator: BusinessServiceFormPolicy.validateDuration,
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
                  if (type == 'sessionPackage') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sessionCount,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Seans sayısı',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          BusinessServiceFormPolicy.validateSessionCount(
                            value,
                            type,
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
                    value: active,
                    onChanged: _controller.setActive,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}
