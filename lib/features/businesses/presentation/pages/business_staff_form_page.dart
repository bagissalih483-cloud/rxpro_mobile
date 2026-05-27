import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/accounting/data/accounting_permission_bridge.dart';
import 'package:rxpro_mobile/features/accounting/data/accounting_permissions.dart';
import 'package:rxpro_mobile/features/businesses/data/business_staff_repository.dart';
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
  final Set<String> _assignedServiceIds = <String>{};
  late final Future<List<BusinessStaffServiceOption>> _serviceOptionsFuture;

  String _role = 'staff';
  bool _active = true;

  // Randevu yetkileri ikiye ayrıldı:
  // 1) İşlerim: kendisine atanan randevuyu başlatma/bitirme.
  // 2) Randevu yönetimi: erteleme/iptal gibi akış değişiklikleri.
  bool _canWorkAssignedAppointments = true;
  bool _canManageAppointmentChanges = false;

  bool _canManageCampaigns = false;

  bool _financeRead = false;
  bool _financeWrite = false;
  bool _expenseWrite = false;
  bool _receivableManage = false;
  bool _reportExport = false;

  bool _saving = false;
  final BusinessStaffRepository _staffFormRepository =
      BusinessStaffRepository();

  @override
  void initState() {
    super.initState();
    _serviceOptionsFuture = _loadServiceOptions();
    final d = widget.initialData ?? <String, dynamic>{};

    _name = TextEditingController(
      text: (d[FirestoreFields.staffName] ?? d[FirestoreFields.name] ?? '')
          .toString(),
    );
    _email = TextEditingController(
      text: (d[FirestoreFields.staffEmail] ?? d[FirestoreFields.email] ?? '')
          .toString(),
    );

    final rawServiceIds =
        d[FirestoreFields.serviceIds] ??
        d[FirestoreFields.staffServiceIds] ??
        d[FirestoreFields.allowedServiceIds];
    if (rawServiceIds is Iterable) {
      _assignedServiceIds.addAll(
        rawServiceIds
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty),
      );
    }

    _role = (d[FirestoreFields.role] ?? 'staff').toString();
    _active = d['isActive'] != false;

    final rawPermissions = d[FirestoreFields.permissions];
    final permissions = rawPermissions is Map
        ? Map<String, dynamic>.from(rawPermissions)
        : Map<String, dynamic>.from(d);

    bool hasAny(List<String> keys) {
      for (final key in keys) {
        if (permissions[key] == true || d[key] == true) return true;
      }
      return false;
    }

    final legacyCanManageAppointments =
        d['canManageAppointments'] == true ||
        permissions['canManageAppointments'] == true;

    _canWorkAssignedAppointments = hasAny([
      'workAssignedAppointments',
      'completeAssignedAppointments',
      'appointmentWork',
      'appointmentStartFinish',
      'canWorkAssignedAppointments',
      'viewAppointments',
    ]);

    // Eski kayıtlar için randevu yetkisi varsa iş başlat/bitir kapalı kalmasın.
    if (!_canWorkAssignedAppointments && legacyCanManageAppointments) {
      _canWorkAssignedAppointments = true;
    }

    // Yeni personelde varsayılan olarak kendi işini başlat/bitir açık olsun.
    if (widget.staffId == null) {
      _canWorkAssignedAppointments = true;
    }

    _canManageAppointmentChanges = hasAny([
      'manageAppointmentChanges',
      'canManageAppointmentChanges',
      'appointmentManage',
      'appointmentReschedule',
      'appointmentCancel',
      'canRescheduleAppointments',
      'canCancelAppointments',
      'updateAppointments',
      'cancelAppointments',
    ]);

    // Eski canManageAppointments artık erteleme/iptal anlamına da gelebilir; mevcut kayıtta açık ise koru.
    if (!_canManageAppointmentChanges && legacyCanManageAppointments) {
      _canManageAppointmentChanges = true;
    }

    _canManageCampaigns =
        d['canManageCampaigns'] == true ||
        permissions['canManageCampaigns'] == true;

    final accountingPermissions = AccountingPermissionBridge.normalize(
      permissions,
    );

    final preset = _role == 'finance'
        ? AccountingPermissionBridge.accountingDefaults()
        : const <String, bool>{};

    bool readAccounting(String key) {
      return accountingPermissions[key] == true || preset[key] == true;
    }

    _financeRead = readAccounting(AccountingPermissionKeys.financeRead);
    _financeWrite = readAccounting(AccountingPermissionKeys.financeWrite);
    _expenseWrite =
        readAccounting(AccountingPermissionKeys.expenseWrite) ||
        d['canManageExpenses'] == true ||
        permissions['canManageExpenses'] == true;
    _receivableManage = readAccounting(
      AccountingPermissionKeys.receivableManage,
    );
    _reportExport = readAccounting(AccountingPermissionKeys.reportExport);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  String _inviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  Map<String, bool> _accountingPermissionsPayload() {
    return <String, bool>{
      AccountingPermissionKeys.financeRead: _financeRead,
      AccountingPermissionKeys.financeWrite: _financeWrite,
      AccountingPermissionKeys.expenseWrite: _expenseWrite,
      AccountingPermissionKeys.receivableManage: _receivableManage,
      AccountingPermissionKeys.reportExport: _reportExport,
    };
  }

  void _applyFinanceRoleDefaultsIfNeeded(String role) {
    if (role != 'finance') return;

    final values = AccountingPermissionBridge.accountingDefaults();
    _financeRead = values[AccountingPermissionKeys.financeRead] == true;
    _financeWrite = values[AccountingPermissionKeys.financeWrite] == true;
    _expenseWrite = values[AccountingPermissionKeys.expenseWrite] == true;
    _receivableManage =
        values[AccountingPermissionKeys.receivableManage] == true;
    _reportExport = values[AccountingPermissionKeys.reportExport] == true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // 48F-C empty service match warning.
    // Randevu iş akışında kullanılacak personel için boş hizmet eşleşmesi risklidir.
    if (_canWorkAssignedAppointments && _assignedServiceIds.isEmpty) {
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

    setState(() => _saving = true);

    try {
      final invite = (widget.initialData?['inviteCode'] ?? _inviteCode())
          .toString();
      final normalizedEmail = _email.text.trim().toLowerCase();

      final existingPermissions =
          widget.initialData?[FirestoreFields.permissions];
      final accountingPermissions = _accountingPermissionsPayload();

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
        FirestoreFields.serviceIds: (_assignedServiceIds.toList()..sort()),
        FirestoreFields.staffServiceIds: (_assignedServiceIds.toList()..sort()),
        'allowedServiceIds': (_assignedServiceIds.toList()..sort()),
        'serviceMatchMode': _assignedServiceIds.isEmpty
            ? 'all_legacy'
            : 'selected',
        'serviceMatchWarning':
            _canWorkAssignedAppointments && _assignedServiceIds.isEmpty,
        FirestoreFields.role: _role,
        'inviteCode': invite,
        'isActive': _active,
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
        'canWorkAssignedAppointments': _canWorkAssignedAppointments,
        'workAssignedAppointments': _canWorkAssignedAppointments,
        'appointmentWork': _canWorkAssignedAppointments,
        'appointmentStartFinish': _canWorkAssignedAppointments,
        'completeAssignedAppointments': _canWorkAssignedAppointments,
        'viewAppointments': _canWorkAssignedAppointments,

        // Erteleme / iptal / genel randevu değişikliği: ayrı ve özel yetki.
        'canManageAppointments': _canManageAppointmentChanges,
        'canManageAppointmentChanges': _canManageAppointmentChanges,
        'manageAppointmentChanges': _canManageAppointmentChanges,
        'canRescheduleAppointments': _canManageAppointmentChanges,
        'canCancelAppointments': _canManageAppointmentChanges,
        'appointmentManage': _canManageAppointmentChanges,
        'appointmentReschedule': _canManageAppointmentChanges,
        'appointmentCancel': _canManageAppointmentChanges,
        'updateAppointments': _canManageAppointmentChanges,
        'cancelAppointments': _canManageAppointmentChanges,

        'canManageCampaigns': _canManageCampaigns,

        // Geriye uyumluluk: eski masraf/gider field'i tek switch olan expenseWrite'a bağlanır.
        'canManageExpenses': _expenseWrite,

        FirestoreFields.permissions: <String, dynamic>{
          if (existingPermissions is Map)
            ...Map<String, dynamic>.from(existingPermissions),

          // İşlerim / görev akışı.
          'canWorkAssignedAppointments': _canWorkAssignedAppointments,
          'workAssignedAppointments': _canWorkAssignedAppointments,
          'appointmentWork': _canWorkAssignedAppointments,
          'appointmentStartFinish': _canWorkAssignedAppointments,
          'completeAssignedAppointments': _canWorkAssignedAppointments,
          'viewAppointments': _canWorkAssignedAppointments,

          // Randevu değişiklik yönetimi.
          'canManageAppointments': _canManageAppointmentChanges,
          'canManageAppointmentChanges': _canManageAppointmentChanges,
          'manageAppointmentChanges': _canManageAppointmentChanges,
          'canRescheduleAppointments': _canManageAppointmentChanges,
          'canCancelAppointments': _canManageAppointmentChanges,
          'appointmentManage': _canManageAppointmentChanges,
          'appointmentReschedule': _canManageAppointmentChanges,
          'appointmentCancel': _canManageAppointmentChanges,
          'updateAppointments': _canManageAppointmentChanges,
          'cancelAppointments': _canManageAppointmentChanges,

          'canManageCampaigns': _canManageCampaigns,

          // Muhasebe.
          ...accountingPermissions,
          'viewFinance': _financeRead,
          'canViewFinance': _financeRead,
          'canManageFinance': _financeWrite,
          'paymentCollect': _financeWrite || _receivableManage,
          'enterExpenses': _expenseWrite,
          'canManageExpenses': _expenseWrite,
          'expenseManage': _expenseWrite,
          'canManageReceivables': _receivableManage,
          'receivableWrite': _receivableManage,
          'canExportReports': _reportExport,
          'financeExport': _reportExport,
        },

        // Flat field muhasebe uyumluluğu.
        'viewFinance': _financeRead,
        'canViewFinance': _financeRead,
        'canManageFinance': _financeWrite,
        'paymentCollect': _financeWrite || _receivableManage,
        'enterExpenses': _expenseWrite,
        'expenseManage': _expenseWrite,
        'canManageReceivables': _receivableManage,
        'receivableWrite': _receivableManage,
        'canExportReports': _reportExport,
        'financeExport': _reportExport,

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
                ? 'Personel eklendi. Davet kodu: $invite'
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
      setState(() => _saving = false);
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
            if (_canWorkAssignedAppointments &&
                _assignedServiceIds.isEmpty) ...[
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
              final checked = _assignedServiceIds.contains(service.id);

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
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _assignedServiceIds.add(service.id);
                    } else {
                      _assignedServiceIds.remove(service.id);
                    }
                  });
                },
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
                    initialValue: _role,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'manager',
                        child: Text('Yönetici'),
                      ),
                      DropdownMenuItem(value: 'staff', child: Text('Personel')),
                      DropdownMenuItem(
                        value: 'finance',
                        child: Text('Finans Yetkilisi'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _role = v;
                        _applyFinanceRoleDefaultsIfNeeded(v);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _permissionSwitch(
                    title: _active ? 'Aktif personel' : 'Pasif personel',
                    subtitle:
                        'Pasif personel randevu ve işlem akışında görünmez.',
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
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
                    value: _canWorkAssignedAppointments,
                    onChanged: (v) =>
                        setState(() => _canWorkAssignedAppointments = v),
                  ),
                  _permissionSwitch(
                    title: 'Randevu erteleme / iptal yönetimi',
                    subtitle:
                        'Randevu saatini değiştirme, erteleme veya iptal etme özel yetkidir.',
                    value: _canManageAppointmentChanges,
                    onChanged: (v) =>
                        setState(() => _canManageAppointmentChanges = v),
                  ),
                  _permissionSwitch(
                    title: 'Kampanya yönetimi',
                    value: _canManageCampaigns,
                    onChanged: (v) => setState(() => _canManageCampaigns = v),
                  ),
                  _permissionSwitch(
                    title: 'Muhasebe görüntüleme',
                    subtitle: 'financeRead',
                    value: _financeRead,
                    onChanged: (v) => setState(() => _financeRead = v),
                  ),
                  _permissionSwitch(
                    title: 'Satış ve tahsilat işlemleri',
                    subtitle: 'financeWrite',
                    value: _financeWrite,
                    onChanged: (v) => setState(() => _financeWrite = v),
                  ),
                  _permissionSwitch(
                    title: 'Gider / masraf işlemleri',
                    subtitle:
                        'expenseWrite. Masraf girişi ve gider işlemleri aynı yetkidir.',
                    value: _expenseWrite,
                    onChanged: (v) => setState(() => _expenseWrite = v),
                  ),
                  _permissionSwitch(
                    title: 'Alacak ve vade yönetimi',
                    subtitle: 'receivableManage',
                    value: _receivableManage,
                    onChanged: (v) => setState(() => _receivableManage = v),
                  ),
                  _permissionSwitch(
                    title: 'Rapor/PDF dışa aktarma',
                    subtitle: 'reportExport',
                    value: _reportExport,
                    onChanged: (v) => setState(() => _reportExport = v),
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
