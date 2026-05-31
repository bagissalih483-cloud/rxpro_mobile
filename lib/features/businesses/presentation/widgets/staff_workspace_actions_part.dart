part of '../../staff_workspace_page.dart';
extension _StaffWorkspacePageStateActions on _StaffWorkspacePageState {
  Future<void> _writeActivityLog({
    required String type,
    required String title,
    required String description,
    String? appointmentId,
    String? expenseId,
    Map<String, dynamic>? extra,
  }) async {
    await _workspaceRepository.writeActivityLog(
      businessId: _businessId,
      staffId: _staffId,
      staffName: _staffName,
      type: type,
      title: title,
      description: description,
      appointmentId: appointmentId,
      expenseId: expenseId,
      extra: extra,
    );
  }
}
