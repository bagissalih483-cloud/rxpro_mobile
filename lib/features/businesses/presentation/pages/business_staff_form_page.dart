import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/businesses/data/business_staff_repository.dart';
import 'package:rxpro_mobile/features/businesses/presentation/business_staff_form_controller.dart';
import 'package:rxpro_mobile/features/businesses/presentation/widgets/business_staff_manage_widgets.dart';

class StaffFormPage extends StatefulWidget {
  const StaffFormPage({
    super.key,
    required this.businessId,
    required this.businessAccessCode,
    this.staffId,
    this.initialData,
  });
  final String businessId;
  final String businessAccessCode;
  final String? staffId;
  final Map<String, dynamic>? initialData;
  @override
  State<StaffFormPage> createState() => _StaffFormPageState();
}

class _StaffFormPageState extends State<StaffFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final BusinessStaffFormController _controller;
  late final Future<List<BusinessStaffServiceOption>> _serviceOptionsFuture;

  // Randevu yetkileri ikiye ayrıldı:
  // 1) İşlerim: kendisine atanan randevuyu başlatma/bitirme.
  // 2) Randevu yönetimi: erteleme/iptal gibi akış değişiklikleri.
  final BusinessStaffRepository _staffFormRepository =
      BusinessStaffRepository();

  @override
  void initState() {
    super.initState();
    _serviceOptionsFuture = _loadServiceOptions();
    final d = widget.initialData ?? <String, dynamic>{};
    _controller = BusinessStaffFormController(
      staffId: widget.staffId,
      initialData: d,
    );

    _name = TextEditingController(
      text: (d[FirestoreFields.staffName] ?? d[FirestoreFields.name] ?? '')
          .toString(),
    );
    _email = TextEditingController(
      text: (d[FirestoreFields.staffEmail] ?? d[FirestoreFields.email] ?? '')
          .toString(),
    );

    // Eski kayıtlar için randevu yetkisi varsa iş başlat/bitir kapalı kalmasın.
    // Yeni personelde varsayılan olarak kendi işini başlat/bitir açık olsun.
    // Eski canManageAppointments artık erteleme/iptal anlamına da gelebilir; mevcut kayıtta açık ise koru.
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _inviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // 48F-C empty service match warning.
    // Randevu iş akışında kullanılacak personel için boş hizmet eşleşmesi risklidir.
    if (_controller.requiresServiceMatchWarning) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hizmet eşleşmesi eksik'),
          content: const Text(
            'Bu personel için hiçbir hizmet seçilmedi. Randevu iş akışında kullanılacak personellerde en az bir hizmet seçilmesi önerilir. Yine de kaydedilsin mi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hizmet Seçeceğim'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yine de Kaydet'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    _controller.setSaving(true);

    try {
      final invite = (widget.initialData?['inviteCode'] ?? _inviteCode())
          .toString();
      final normalizedEmail = _email.text.trim().toLowerCase();

      final existingPermissions =
          widget.initialData?[FirestoreFields.permissions];
      final accountingPermissions = _controller.accountingPermissionsPayload();

      final payload = <String, dynamic>{
        FirestoreFields.businessId: widget.businessId,
        FirestoreFields.businessAccessCode: widget.businessAccessCode,
        FirestoreFields.staffName: _name.text.trim(),
        FirestoreFields.name: _name.text.trim(),
        FirestoreFields.staffEmail: _email.text.trim(),
        FirestoreFields.email: _email.text.trim(),
        FirestoreFields.targetEmail: normalizedEmail,
        FirestoreFields.staffEmailLower: normalizedEmail,
        'emailLower': normalizedEmail,
        FirestoreFields.serviceIds: _controller.sortedAssignedServiceIds,
        FirestoreFields.staffServiceIds: _controller.sortedAssignedServiceIds,
        'allowedServiceIds': _controller.sortedAssignedServiceIds,
        'serviceMatchMode': _controller.serviceMatchMode,
        'serviceMatchWarning': _controller.requiresServiceMatchWarning,
        FirestoreFields.role: _controller.role,
        'inviteCode': invite,
        'isActive': _controller.active,
        FirestoreFields.staffLinkStatus:
            widget.initialData?[FirestoreFields.staffLinkStatus] ??
            ((widget.initialData?['linkedUid'] ??
                        widget.initialData?[FirestoreFields.staffUid] ??
                        '')
                    .toString()
                    .trim()
                    .isNotEmpty
                ? 'linked'
                : 'pending'),
        FirestoreFields.staffWorkStatus:
            widget.initialData?[FirestoreFields.staffWorkStatus] ?? 'inactive',
        'activeWorkSession': widget.initialData?['activeWorkSession'] ?? false,
        'requireVerifiedEmailForInvite':
            widget.initialData?['requireVerifiedEmailForInvite'] ?? false,

        // İşlerim / görev akışı: çoğu personelde açık olmalı.
        'canWorkAssignedAppointments': _controller.canWorkAssignedAppointments,
        'workAssignedAppointments': _controller.canWorkAssignedAppointments,
        'appointmentWork': _controller.canWorkAssignedAppointments,
        'appointmentStartFinish': _controller.canWorkAssignedAppointments,
        'completeAssignedAppointments': _controller.canWorkAssignedAppointments,
        'viewAppointments': _controller.canWorkAssignedAppointments,

        // Erteleme / iptal / genel randevu değişikliği: ayrı ve özel yetki.
        'canManageAppointments': _controller.canManageAppointmentChanges,
        'canManageAppointmentChanges': _controller.canManageAppointmentChanges,
        'manageAppointmentChanges': _controller.canManageAppointmentChanges,
        'canRescheduleAppointments': _controller.canManageAppointmentChanges,
        'canCancelAppointments': _controller.canManageAppointmentChanges,
        'appointmentManage': _controller.canManageAppointmentChanges,
        'appointmentReschedule': _controller.canManageAppointmentChanges,
        'appointmentCancel': _controller.canManageAppointmentChanges,
        'updateAppointments': _controller.canManageAppointmentChanges,
        'cancelAppointments': _controller.canManageAppointmentChanges,

        'canManageCampaigns': _controller.canManageCampaigns,

        // Geriye uyumluluk: eski masraf/gider field'i tek switch olan expenseWrite'a bağlanır.
        'canManageExpenses': _controller.expenseWrite,

        FirestoreFields.permissions: <String, dynamic>{
          if (existingPermissions is Map)
            ...Map<String, dynamic>.from(existingPermissions),

          // İşlerim / görev akışı.
          'canWorkAssignedAppointments':
              _controller.canWorkAssignedAppointments,
          'workAssignedAppointments': _controller.canWorkAssignedAppointments,
          'appointmentWork': _controller.canWorkAssignedAppointments,
          'appointmentStartFinish': _controller.canWorkAssignedAppointments,
          'completeAssignedAppointments':
              _controller.canWorkAssignedAppointments,
          'viewAppointments': _controller.canWorkAssignedAppointments,

          // Randevu değişiklik yönetimi.
          'canManageAppointments': _controller.canManageAppointmentChanges,
          'canManageAppointmentChanges':
              _controller.canManageAppointmentChanges,
          'manageAppointmentChanges': _controller.canManageAppointmentChanges,
          'canRescheduleAppointments': _controller.canManageAppointmentChanges,
          'canCancelAppointments': _controller.canManageAppointmentChanges,
          'appointmentManage': _controller.canManageAppointmentChanges,
          'appointmentReschedule': _controller.canManageAppointmentChanges,
          'appointmentCancel': _controller.canManageAppointmentChanges,
          'updateAppointments': _controller.canManageAppointmentChanges,
          'cancelAppointments': _controller.canManageAppointmentChanges,

          'canManageCampaigns': _controller.canManageCampaigns,

          // Muhasebe.
          ...accountingPermissions,
          'viewFinance': _controller.financeRead,
          'canViewFinance': _controller.financeRead,
          'canManageFinance': _controller.financeWrite,
          'paymentCollect':
              _controller.financeWrite || _controller.receivableManage,
          'enterExpenses': _controller.expenseWrite,
          'canManageExpenses': _controller.expenseWrite,
          'expenseManage': _controller.expenseWrite,
          'canManageReceivables': _controller.receivableManage,
          'receivableWrite': _controller.receivableManage,
          'canExportReports': _controller.reportExport,
          'financeExport': _controller.reportExport,
        },

        // Flat field muhasebe uyumluluğu.
        'viewFinance': _controller.financeRead,
        'canViewFinance': _controller.financeRead,
        'canManageFinance': _controller.financeWrite,
        'paymentCollect':
            _controller.financeWrite || _controller.receivableManage,
        'enterExpenses': _controller.expenseWrite,
        'expenseManage': _controller.expenseWrite,
        'canManageReceivables': _controller.receivableManage,
        'receivableWrite': _controller.receivableManage,
        'canExportReports': _controller.reportExport,
        'financeExport': _controller.reportExport,

        'isAvailable': widget.initialData?['isAvailable'] ?? true,
        'currentWorkStatus':
            widget.initialData?['currentWorkStatus'] ?? 'available',
      };

      await _staffFormRepository.upsertBusinessStaff(
        businessId: widget.businessId,
        staffId: widget.staffId,
        payload: payload,
      );

      await _staffFormRepository.addBusinessStaffActivityLog(
        businessId: widget.businessId,
        type: widget.staffId == null ? 'staff_created' : 'staff_updated',
        title: widget.staffId == null
            ? 'Personel eklendi'
            : 'Personel güncellendi',
        staffName: _name.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.staffId == null
                ? 'Personel eklendi. Kurumsal giriş kodu: $invite'
                : 'Personel güncellendi.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Personel kaydedilemedi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _controller.setSaving(false);
    }
  }

  Widget _permissionSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      activeThumbColor: const Color(0xFF10B981),
      onChanged: onChanged,
    );
  }

  Future<List<BusinessStaffServiceOption>> _loadServiceOptions() async {
    return _staffFormRepository.fetchActiveServiceOptions(
      businessId: widget.businessId,
    );
  }

  Widget _serviceMatchingCard() {
    return FutureBuilder<List<BusinessStaffServiceOption>>(
      future: _serviceOptionsFuture,
      builder: (context, snapshot) {
        final services = snapshot.data ?? const <BusinessStaffServiceOption>[];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }

        if (services.isEmpty) {
          return const Text(
            'Henüz aktif hizmet yok. Önce Hizmetler ve Paketler ekranından hizmet ekleyin.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu personelin verebildiği hizmetleri seçin. Seçim kaydedildikten sonra randevu ekranında bu hizmetlere göre personel filtrelenir.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            if (_controller.requiresServiceMatchWarning) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFF92400E)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hizmet eşleşmesi boş. Bu personel randevu iş akışında kullanılacaksa en az bir hizmet seçilmesi önerilir.',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
            ],
            ...services.map((service) {
              final checked = _controller.assignedServiceIds.contains(
                service.id,
              );

              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: checked,
                title: Text(
                  service.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  [
                    if (service.duration.trim().isNotEmpty)
                      '${service.duration} dk',
                    if (service.price.trim().isNotEmpty) '${service.price} TL',
                  ].join(' • '),
                ),
                onChanged: (v) =>
                    _controller.setServiceAssigned(service.id, v == true),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final edit = widget.staffId != null;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(edit ? 'Personeli Düzenle' : 'Personel Ekle'),
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: _controller.saving ? null : _save,
              icon: _controller.saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_controller.saving ? 'Kaydediliyor...' : 'Kaydet'),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                BusinessStaffCard(
                  title: 'Personelin kullanacağı işletme kodu',
                  child: Text(
                    widget.businessAccessCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                BusinessStaffCard(
                  title: 'Personel Bilgileri',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ad soyad gerekli'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'E-posta gerekli'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _controller.role,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'manager',
                            child: Text('Yönetici'),
                          ),
                          DropdownMenuItem(
                            value: 'staff',
                            child: Text('Personel'),
                          ),
                          DropdownMenuItem(
                            value: 'finance',
                            child: Text('Finans Yetkilisi'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          _controller.setRole(v);
                        },
                      ),
                      const SizedBox(height: 12),
                      _permissionSwitch(
                        title: _controller.active
                            ? 'Aktif personel'
                            : 'Pasif personel',
                        subtitle:
                            'Pasif personel randevu ve işlem akışında görünmez.',
                        value: _controller.active,
                        onChanged: _controller.setActive,
                      ),
                    ],
                  ),
                ),
                BusinessStaffCard(
                  title: 'Hizmet Eşleşmesi',
                  child: _serviceMatchingCard(),
                ),
                BusinessStaffCard(
                  title: 'Yetkiler',
                  child: Column(
                    children: [
                      _permissionSwitch(
                        title: 'Görevlerim / iş başlat-bitir',
                        subtitle:
                            'Personel kendisine atanan randevuyu başlatabilir ve işlemi bitirebilir. Performans ve ödeme takibi bu akıştan beslenecek.',
                        value: _controller.canWorkAssignedAppointments,
                        onChanged: _controller.setCanWorkAssignedAppointments,
                      ),
                      _permissionSwitch(
                        title: 'Randevu erteleme / iptal yönetimi',
                        subtitle:
                            'Randevu saatini değiştirme, erteleme veya iptal etme özel yetkidir.',
                        value: _controller.canManageAppointmentChanges,
                        onChanged: _controller.setCanManageAppointmentChanges,
                      ),
                      _permissionSwitch(
                        title: 'Kampanya yönetimi',
                        value: _controller.canManageCampaigns,
                        onChanged: _controller.setCanManageCampaigns,
                      ),
                      _permissionSwitch(
                        title: 'Muhasebe görüntüleme',
                        subtitle: 'financeRead',
                        value: _controller.financeRead,
                        onChanged: _controller.setFinanceRead,
                      ),
                      _permissionSwitch(
                        title: 'Satış ve tahsilat işlemleri',
                        subtitle: 'financeWrite',
                        value: _controller.financeWrite,
                        onChanged: _controller.setFinanceWrite,
                      ),
                      _permissionSwitch(
                        title: 'Gider / masraf işlemleri',
                        subtitle:
                            'expenseWrite. Masraf girişi ve gider işlemleri aynı yetkidir.',
                        value: _controller.expenseWrite,
                        onChanged: _controller.setExpenseWrite,
                      ),
                      _permissionSwitch(
                        title: 'Alacak ve vade yönetimi',
                        subtitle: 'receivableManage',
                        value: _controller.receivableManage,
                        onChanged: _controller.setReceivableManage,
                      ),
                      _permissionSwitch(
                        title: 'Rapor/PDF dışa aktarma',
                        subtitle: 'reportExport',
                        value: _controller.reportExport,
                        onChanged: _controller.setReportExport,
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
