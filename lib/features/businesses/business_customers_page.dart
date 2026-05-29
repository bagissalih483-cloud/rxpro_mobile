import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import 'data/business_customer_repository.dart';
import 'domain/business_customer_action_policy.dart';
import 'presentation/widgets/business_customer_header_panel.dart';
import 'presentation/widgets/business_customer_widgets.dart';

class BusinessCustomersPage extends StatefulWidget {
  const BusinessCustomersPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  State<BusinessCustomersPage> createState() => _BusinessCustomersPageState();
}

class _BusinessCustomersPageState extends State<BusinessCustomersPage> {
  final BusinessCustomerRepository _repository = BusinessCustomerRepository();
  final TextEditingController _searchController = TextEditingController();

  late final Stream<List<BusinessCustomerRecord>> _customerStream;
  String _selectedSegmentId = BusinessCustomerSegments.all.id;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _customerStream = _repository.watchCustomersForBusiness(
      businessId: widget.businessId,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BusinessCustomerRecord> _visibleRecords(
    List<BusinessCustomerRecord> records,
  ) {
    return records
        .where((record) => record.matchesSegment(_selectedSegmentId))
        .where((record) => record.matchesQuery(_query))
        .toList();
  }

  Future<void> _openManualCustomerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualCustomerSheet(
        businessId: widget.businessId,
        repository: _repository,
      ),
    );
  }

  Future<void> _openClassificationSheet(BusinessCustomerRecord record) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ClassificationSheet(record: record, repository: _repository),
    );
  }

  void _openBulkMessage(List<BusinessCustomerRecord> visibleRecords) {
    if (visibleRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu filtrede toplu mesaj hedefi yok.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final segment = BusinessCustomerSegments.byId(_selectedSegmentId);
    final audience = BusinessCustomerActionPolicy.bulkAudienceLabel(
      selectedSegmentId: _selectedSegmentId,
      segmentLabel: segment.label,
    );
    final linkedCustomerCount = visibleRecords
        .where(
          (record) =>
              BusinessCustomerActionPolicy.canDirectMessage(record.customerUid),
        )
        .length;

    Navigator.of(context).pushNamed(
      AppRoutes.bulkMessageCreate,
      arguments: BusinessCampaignToolRouteArgs(
        businessId: widget.businessId,
        businessName: widget.businessName,
        initialAudience: audience,
        initialEstimatedTargetCount: visibleRecords.length,
        audienceMetadata: <String, dynamic>{
          'source': 'business_customers_page',
          'segmentId': _selectedSegmentId,
          'segmentLabel': segment.label,
          'filteredCount': visibleRecords.length,
          'linkedCustomerCount': linkedCustomerCount,
        },
      ),
    );
  }

  void _openDirectMessage(BusinessCustomerRecord record) {
    if (!BusinessCustomerActionPolicy.canDirectMessage(record.customerUid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            BusinessCustomerActionPolicy.directMessageUnavailableText(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.businessCustomerDirectMessage,
      arguments: BusinessCustomerDirectMessageRouteArgs(
        businessId: widget.businessId,
        businessName: widget.businessName,
        customerUid: record.customerUid,
        customerName: record.displayName,
        customerEmail: record.email,
        customerPhone: record.phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessId = widget.businessId.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Müşteri Defteri'),
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: businessId.isEmpty ? null : _openManualCustomerSheet,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Müşteri Ekle'),
      ),
      body: businessId.isEmpty
          ? const _EmptyState(
              icon: Icons.store_mall_directory_outlined,
              title: 'İşletme bağlantısı bulunamadı',
              text:
                  'Müşteri defteri için önce kurumsal hesabın işletme kimliği çözülmeli.',
            )
          : StreamBuilder<List<BusinessCustomerRecord>>(
              stream: _customerStream,
              builder: (context, snapshot) {
                final records =
                    snapshot.data ?? const <BusinessCustomerRecord>[];
                final visibleRecords = _visibleRecords(records);
                final stats = BusinessCustomerStats.fromRecords(records);

                if (snapshot.connectionState == ConnectionState.waiting &&
                    records.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                  children: [
                    BusinessCustomerHeaderPanel(
                      businessName: widget.businessName,
                      total: stats.total,
                      visible: visibleRecords.length,
                      onAddCustomer: _openManualCustomerSheet,
                      onBulkMessage: () => _openBulkMessage(visibleRecords),
                    ),
                    const SizedBox(height: 12),
                    _SearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 12),
                    _SegmentFilterBar(
                      selectedSegmentId: _selectedSegmentId,
                      stats: stats,
                      onSelected: (segmentId) {
                        setState(() => _selectedSegmentId = segmentId);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (records.isEmpty)
                      const _EmptyState(
                        icon: Icons.people_alt_outlined,
                        title: 'Henüz müşteri kaydı yok',
                        text:
                            'Randevu geldikçe müşteri geçmişi otomatik oluşur. İstersen ilk müşteriyi manuel ekleyebilirsin.',
                      )
                    else if (visibleRecords.isEmpty)
                      const _EmptyState(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'Bu filtrede müşteri yok',
                        text:
                            'Segmenti veya arama metnini değiştirerek müşteri defterini yeniden süzebilirsin.',
                      )
                    else
                      ...visibleRecords.map(
                        (record) => _CustomerCard(
                          record: record,
                          onClassify: () => _openClassificationSheet(record),
                          onMessage: () => _openDirectMessage(record),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Müşteri adı, telefon, not veya hizmet ara',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}

class _SegmentFilterBar extends StatelessWidget {
  const _SegmentFilterBar({
    required this.selectedSegmentId,
    required this.stats,
    required this.onSelected,
  });

  final String selectedSegmentId;
  final BusinessCustomerStats stats;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: BusinessCustomerSegments.values.map((segment) {
          final selected = selectedSegmentId == segment.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text('${segment.label} (${stats.countFor(segment.id)})'),
              onSelected: (_) => onSelected(segment.id),
              selectedColor: const Color(0xFFDDF4FF),
              side: BorderSide(
                color: selected
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.record,
    required this.onClassify,
    required this.onMessage,
  });

  final BusinessCustomerRecord record;
  final VoidCallback onClassify;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final segmentColor = businessCustomerSegmentColor(record.segmentId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: segmentColor.withValues(alpha: 0.12),
                child: Icon(
                  record.isManual
                      ? Icons.person_outline
                      : Icons.event_available_outlined,
                  color: segmentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _contactLine(record),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              BusinessCustomerSegmentBadge(segmentId: record.segmentId),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BusinessCustomerMetricPill(
                icon: Icons.event_note_outlined,
                text: '${record.appointmentCount} randevu',
              ),
              BusinessCustomerMetricPill(
                icon: Icons.check_circle_outline,
                text: '${record.completedAppointmentCount} tamamlanan',
              ),
              if (record.noShowCount > 0)
                BusinessCustomerMetricPill(
                  icon: Icons.warning_amber_rounded,
                  text: '${record.noShowCount} gelmedi',
                ),
              BusinessCustomerMetricPill(
                icon: Icons.schedule_outlined,
                text: _lastAppointmentLabel(record.lastAppointmentAt),
              ),
              if (record.canReceiveBulkMessage)
                const BusinessCustomerMetricPill(
                  icon: Icons.notifications_active_outlined,
                  text: 'toplu mesaja uygun',
                ),
            ],
          ),
          if (record.lastServiceName.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Son hizmet: ${record.lastServiceName}',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (record.note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              record.note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF334155)),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (BusinessCustomerActionPolicy.canDirectMessage(
                record.customerUid,
              ))
                FilledButton.tonalIcon(
                  onPressed: onMessage,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Mesaj'),
                ),
              OutlinedButton.icon(
                onPressed: onClassify,
                icon: const Icon(Icons.tune_outlined),
                label: const Text('Sınıflandır'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _contactLine(BusinessCustomerRecord record) {
    final parts = <String>[
      if (record.phone.trim().isNotEmpty) record.phone.trim(),
      if (record.email.trim().isNotEmpty) record.email.trim(),
      if (!record.hasContactInfo) 'Randevu geçmişinden türetildi',
    ];
    return parts.join(' • ');
  }
}

class _ManualCustomerSheet extends StatefulWidget {
  const _ManualCustomerSheet({
    required this.businessId,
    required this.repository,
  });

  final String businessId;
  final BusinessCustomerRepository repository;

  @override
  State<_ManualCustomerSheet> createState() => _ManualCustomerSheetState();
}

class _ManualCustomerSheetState extends State<_ManualCustomerSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();
  String _segmentId = BusinessCustomerSegments.manual.id;
  bool _campaignConsent = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final input = BusinessCustomerManualInput(
      businessId: widget.businessId,
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      note: _noteController.text,
      segmentId: _segmentId,
      campaignConsent: _campaignConsent,
    );

    if (!input.hasRequiredIdentity) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ad, telefon veya e-posta bilgilerinden biri gerekli.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.repository.createManualCustomer(input);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Müşteri kaydı eklendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Müşteri eklenemedi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Müşteri ekle',
      child: Column(
        children: [
          _SheetTextField(controller: _nameController, label: 'Ad soyad'),
          _SheetTextField(controller: _phoneController, label: 'Telefon'),
          _SheetTextField(controller: _emailController, label: 'E-posta'),
          _SegmentDropdown(
            value: _segmentId,
            onChanged: (value) => setState(() => _segmentId = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _campaignConsent,
            onChanged: (value) => setState(() => _campaignConsent = value),
            title: const Text('Toplu mesaj izni var'),
          ),
          _SheetTextField(
            controller: _noteController,
            label: 'İşletme notu',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Kaydediliyor' : 'Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassificationSheet extends StatefulWidget {
  const _ClassificationSheet({required this.record, required this.repository});

  final BusinessCustomerRecord record;
  final BusinessCustomerRepository repository;

  @override
  State<_ClassificationSheet> createState() => _ClassificationSheetState();
}

class _ClassificationSheetState extends State<_ClassificationSheet> {
  late String _segmentId = widget.record.segmentId;
  late bool _campaignConsent = widget.record.campaignConsent;
  late final TextEditingController _noteController = TextEditingController(
    text: widget.record.note,
  );
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await widget.repository.saveCustomerClassification(
        record: widget.record,
        segmentId: _segmentId,
        note: _noteController.text,
        campaignConsent: _campaignConsent,
      );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Müşteri sınıflandırması güncellendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Sınıflandırma kaydedilemedi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: widget.record.displayName,
      child: Column(
        children: [
          _SegmentDropdown(
            value: _segmentId,
            onChanged: (value) => setState(() => _segmentId = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _campaignConsent,
            onChanged: (value) => setState(() => _campaignConsent = value),
            title: const Text('Toplu mesaj izni var'),
          ),
          _SheetTextField(
            controller: _noteController,
            label: 'İşletme notu',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Kaydediliyor' : 'Sınıflandırmayı kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentDropdown extends StatelessWidget {
  const _SegmentDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: BusinessCustomerSegments.byId(value).id,
      decoration: const InputDecoration(
        labelText: 'Müşteri sınıfı',
        border: OutlineInputBorder(),
      ),
      items: BusinessCustomerSegments.editableValues
          .map(
            (segment) => DropdownMenuItem<String>(
              value: segment.id,
              child: Text(segment.label),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

String _lastAppointmentLabel(DateTime? value) {
  if (value == null) return 'randevu yok';
  final now = DateTime.now();
  final days = now.difference(value).inHours ~/ 24;
  if (days <= 0) return 'bugün';
  if (days == 1) return 'dün';
  if (days < 30) return '$days gün önce';
  if (days < 365) return '${days ~/ 30} ay önce';
  return '${days ~/ 365} yıl önce';
}
