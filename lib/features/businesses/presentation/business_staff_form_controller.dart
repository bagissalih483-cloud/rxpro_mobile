import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/accounting/data/accounting_permission_bridge.dart';
import 'package:rxpro_mobile/features/accounting/data/accounting_permissions.dart';

class BusinessStaffFormController extends ChangeNotifier {
  BusinessStaffFormController({
    required String? staffId,
    Map<String, dynamic>? initialData,
  }) {
    _applyInitialData(staffId: staffId, data: initialData ?? const {});
  }

  final Set<String> _assignedServiceIds = <String>{};

  String _role = 'staff';
  bool _active = true;
  bool _canWorkAssignedAppointments = true;
  bool _canManageAppointmentChanges = false;
  bool _canManageCampaigns = false;
  bool _financeRead = false;
  bool _financeWrite = false;
  bool _expenseWrite = false;
  bool _receivableManage = false;
  bool _reportExport = false;
  bool _saving = false;

  UnmodifiableSetView<String> get assignedServiceIds {
    return UnmodifiableSetView(_assignedServiceIds);
  }

  List<String> get sortedAssignedServiceIds {
    return _assignedServiceIds.toList()..sort();
  }

  String get role => _role;
  bool get active => _active;
  bool get canWorkAssignedAppointments => _canWorkAssignedAppointments;
  bool get canManageAppointmentChanges => _canManageAppointmentChanges;
  bool get canManageCampaigns => _canManageCampaigns;
  bool get financeRead => _financeRead;
  bool get financeWrite => _financeWrite;
  bool get expenseWrite => _expenseWrite;
  bool get receivableManage => _receivableManage;
  bool get reportExport => _reportExport;
  bool get saving => _saving;

  bool get requiresServiceMatchWarning {
    return _canWorkAssignedAppointments && _assignedServiceIds.isEmpty;
  }

  String get serviceMatchMode {
    return _assignedServiceIds.isEmpty ? 'all_legacy' : 'selected';
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    _saving = value;
    notifyListeners();
  }

  void setRole(String value) {
    if (_role == value) return;
    _role = value;
    if (value == 'finance') {
      _applyFinanceRoleDefaults();
    }
    notifyListeners();
  }

  void setActive(bool value) {
    if (_active == value) return;
    _active = value;
    notifyListeners();
  }

  void setCanWorkAssignedAppointments(bool value) {
    if (_canWorkAssignedAppointments == value) return;
    _canWorkAssignedAppointments = value;
    notifyListeners();
  }

  void setCanManageAppointmentChanges(bool value) {
    if (_canManageAppointmentChanges == value) return;
    _canManageAppointmentChanges = value;
    notifyListeners();
  }

  void setCanManageCampaigns(bool value) {
    if (_canManageCampaigns == value) return;
    _canManageCampaigns = value;
    notifyListeners();
  }

  void setFinanceRead(bool value) {
    if (_financeRead == value) return;
    _financeRead = value;
    notifyListeners();
  }

  void setFinanceWrite(bool value) {
    if (_financeWrite == value) return;
    _financeWrite = value;
    notifyListeners();
  }

  void setExpenseWrite(bool value) {
    if (_expenseWrite == value) return;
    _expenseWrite = value;
    notifyListeners();
  }

  void setReceivableManage(bool value) {
    if (_receivableManage == value) return;
    _receivableManage = value;
    notifyListeners();
  }

  void setReportExport(bool value) {
    if (_reportExport == value) return;
    _reportExport = value;
    notifyListeners();
  }

  void setServiceAssigned(String serviceId, bool selected) {
    final normalized = serviceId.trim();
    if (normalized.isEmpty) return;

    final changed = selected
        ? _assignedServiceIds.add(normalized)
        : _assignedServiceIds.remove(normalized);
    if (changed) notifyListeners();
  }

  Map<String, bool> accountingPermissionsPayload() {
    return <String, bool>{
      AccountingPermissionKeys.financeRead: _financeRead,
      AccountingPermissionKeys.financeWrite: _financeWrite,
      AccountingPermissionKeys.expenseWrite: _expenseWrite,
      AccountingPermissionKeys.receivableManage: _receivableManage,
      AccountingPermissionKeys.reportExport: _reportExport,
    };
  }

  Map<String, dynamic> permissionsPayload(Object? existingPermissions) {
    final existing = existingPermissions is Map
        ? Map<String, dynamic>.from(existingPermissions)
        : const <String, dynamic>{};

    return <String, dynamic>{
      ...existing,
      'canWorkAssignedAppointments': _canWorkAssignedAppointments,
      'workAssignedAppointments': _canWorkAssignedAppointments,
      'appointmentWork': _canWorkAssignedAppointments,
      'appointmentStartFinish': _canWorkAssignedAppointments,
      'completeAssignedAppointments': _canWorkAssignedAppointments,
      'viewAppointments': _canWorkAssignedAppointments,
      'appointmentsRead':
          _canWorkAssignedAppointments || _canManageAppointmentChanges,
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
      'appointmentsWrite': _canManageAppointmentChanges,
      'canManageCampaigns': _canManageCampaigns,
      'campaignRead': _canManageCampaigns,
      'campaignWrite': _canManageCampaigns,
      'bulkMessage': _canManageCampaigns,
      ...accountingPermissionsPayload(),
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
      'staffManage':
          existing['staffManage'] == true || existing['manageStaff'] == true,
      'servicesManage':
          existing['servicesManage'] == true ||
          existing['manageServices'] == true,
      'productsManage':
          existing['productsManage'] == true ||
          existing['manageProducts'] == true,
    };
  }

  void _applyInitialData({
    required String? staffId,
    required Map<String, dynamic> data,
  }) {
    final rawServiceIds =
        data[FirestoreFields.serviceIds] ??
        data[FirestoreFields.staffServiceIds] ??
        data[FirestoreFields.allowedServiceIds];
    if (rawServiceIds is Iterable) {
      _assignedServiceIds.addAll(
        rawServiceIds
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty),
      );
    }

    _role = (data[FirestoreFields.role] ?? 'staff').toString();
    _active = data['isActive'] != false;

    final rawPermissions = data[FirestoreFields.permissions];
    final permissions = rawPermissions is Map
        ? Map<String, dynamic>.from(rawPermissions)
        : Map<String, dynamic>.from(data);

    bool hasAny(List<String> keys) {
      for (final key in keys) {
        if (permissions[key] == true || data[key] == true) return true;
      }
      return false;
    }

    final legacyCanManageAppointments =
        data['canManageAppointments'] == true ||
        permissions['canManageAppointments'] == true;

    _canWorkAssignedAppointments = hasAny([
      'workAssignedAppointments',
      'completeAssignedAppointments',
      'appointmentWork',
      'appointmentStartFinish',
      'canWorkAssignedAppointments',
      'viewAppointments',
    ]);

    if (!_canWorkAssignedAppointments && legacyCanManageAppointments) {
      _canWorkAssignedAppointments = true;
    }

    if (staffId == null) {
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

    if (!_canManageAppointmentChanges && legacyCanManageAppointments) {
      _canManageAppointmentChanges = true;
    }

    _canManageCampaigns =
        data['canManageCampaigns'] == true ||
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
        data['canManageExpenses'] == true ||
        permissions['canManageExpenses'] == true;
    _receivableManage = readAccounting(
      AccountingPermissionKeys.receivableManage,
    );
    _reportExport = readAccounting(AccountingPermissionKeys.reportExport);
  }

  void _applyFinanceRoleDefaults() {
    final values = AccountingPermissionBridge.accountingDefaults();
    _financeRead = values[AccountingPermissionKeys.financeRead] == true;
    _financeWrite = values[AccountingPermissionKeys.financeWrite] == true;
    _expenseWrite = values[AccountingPermissionKeys.expenseWrite] == true;
    _receivableManage =
        values[AccountingPermissionKeys.receivableManage] == true;
    _reportExport = values[AccountingPermissionKeys.reportExport] == true;
  }
}
