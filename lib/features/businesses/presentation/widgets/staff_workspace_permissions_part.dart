part of '../../staff_workspace_page.dart';

extension _StaffWorkspacePageStatePermissions on _StaffWorkspacePageState {
  String get _currentUid => _workspaceRepository.currentUid;
  String get _currentEmail => _workspaceRepository.currentEmail;

  String get _businessId =>
      (widget.memberData[FirestoreFields.businessId] ?? '').toString();
  String get _staffId =>
      (widget.memberData[FirestoreFields.businessStaffId] ??
              widget.memberData['staffDocId'] ??
              widget.memberData[FirestoreFields.staffId] ??
              '')
          .toString();
  String get _staffName =>
      (widget.memberData[FirestoreFields.staffName] ?? '').toString();

  Map<String, bool> get _permissions {
    final raw = widget.memberData[FirestoreFields.permissions];
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value == true));
    }

    return <String, bool>{};
  }

  bool _rawCan(String key) => _permissions[key] == true;

  bool _can(String key) {
    if (_rawCan(key)) return true;

    final aliases = <String, List<String>>{
      'viewAppointments': [
        'workAssignedAppointments',
        'canWorkAssignedAppointments',
        'appointmentWork',
        'appointmentStartFinish',
        'completeAssignedAppointments',
        'canManageAppointments',
      ],
      'completeAssignedAppointments': [
        'workAssignedAppointments',
        'canWorkAssignedAppointments',
        'appointmentWork',
        'appointmentStartFinish',
        'canManageAppointments',
      ],
      'completeAnyAppointments': [
        'canCompleteAnyAppointments',
        'completeAllAppointments',
        'canCompleteAllAppointments',
        'appointmentCompleteAny',
      ],
      'updateAppointments': [
        'manageAppointmentChanges',
        'canManageAppointmentChanges',
        'appointmentManage',
        'appointmentReschedule',
        'canRescheduleAppointments',
      ],
      'cancelAppointments': [
        'manageAppointmentChanges',
        'canManageAppointmentChanges',
        'appointmentManage',
        'appointmentCancel',
        'canCancelAppointments',
      ],
      'enterExpenses': ['expenseWrite', 'canManageExpenses', 'expenseManage'],
      'viewFinance': ['financeRead', 'canViewFinance'],
      'manageFinance': ['financeWrite', 'canManageFinance', 'paymentCollect'],
      'manageReceivables': [
        'receivableManage',
        'canManageReceivables',
        'receivableWrite',
      ],
      'exportReports': ['reportExport', 'canExportReports', 'financeExport'],
      'manageCampaigns': ['canManageCampaigns'],
    };

    for (final alias in aliases[key] ?? const <String>[]) {
      if (_rawCan(alias)) return true;
    }

    return false;
  }
}
