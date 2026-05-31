part of '../../staff_workspace_page.dart';

extension _StaffWorkspacePageStateAssignment on _StaffWorkspacePageState {
  bool _isPrivilegedTaskViewer() {
    final role =
        (widget.memberData['role'] ??
                widget.memberData['roleLabel'] ??
                widget.memberData['accountType'] ??
                widget.memberData['userType'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();

    final uid = _norm(_currentUid);
    final linkedUid = _norm(
      widget.memberData['linkedUid'] ??
          widget.memberData['staffUid'] ??
          widget.memberData['userUid'],
    );

    final ownerSignal =
        widget.memberData['isOwner'] == true ||
        widget.memberData['owner'] == true ||
        widget.memberData['isBusinessOwner'] == true ||
        role.contains('owner') ||
        role.contains('admin') ||
        role.contains('kurucu') ||
        role.contains('sahip');

    final linkedStaffSignal =
        linkedUid.isNotEmpty && uid.isNotEmpty && linkedUid == uid;

    if (linkedStaffSignal && !ownerSignal) return false;

    return ownerSignal;
  }

  String _norm(dynamic value) => value == null
      ? ''
      : value.toString().trim().toLowerCase().replaceAll(' ', '');

  List<String> _valuesForKeys(Map<String, dynamic> data, List<String> keys) {
    final values = <String>[];

    for (final key in keys) {
      final raw = data[key];
      if (raw is List) {
        values.addAll(raw.map(_norm).where((v) => v.isNotEmpty));
      } else {
        final value = _norm(raw);
        if (value.isNotEmpty) values.add(value);
      }
    }

    final staffMap = data['staff'];
    if (staffMap is Map) {
      for (final key in keys) {
        final value = _norm(staffMap[key]);
        if (value.isNotEmpty) values.add(value);
      }
    }

    final assigneeMap = data['assignee'];
    if (assigneeMap is Map) {
      for (final key in keys) {
        final value = _norm(assigneeMap[key]);
        if (value.isNotEmpty) values.add(value);
      }
    }

    return values.toSet().toList();
  }

  bool _matchesAssignedStaff(Map<String, dynamic> data) {
    final uid = _norm(_currentUid);
    final staffId = _norm(_staffId);
    final staffName = _norm(_staffName);

    final staffIdValues = _valuesForKeys(data, const [
      'businessStaffId',
      'assignedStaffId',
      'staffDocId',
      'staffId',
      'assignedToStaffId',
      'linkedStaffId',
      'employeeId',
      'personnelId',
      'personelId',
      'workerId',
      'providerId',
      'serviceProviderId',
      'barberId',
    ]);

    final uidValues = _valuesForKeys(data, const [
      'staffUid',
      'assignedStaffUid',
      'assignedToUid',
      'assignedUserId',
      'staffUserId',
      'employeeUid',
      'personnelUid',
      'personelUid',
      'workerUid',
      'providerUid',
      'serviceProviderUid',
      'linkedUid',
    ]);

    final nameValues = _valuesForKeys(data, const [
      'staffName',
      'assignedStaffName',
      'employeeName',
      'personnelName',
      'personelName',
      'workerName',
      'providerName',
      'serviceProviderName',
      'barberName',
    ]);

    final hasIdMarker = staffIdValues.isNotEmpty;
    final hasUidMarker = uidValues.isNotEmpty;
    final hasNameMarker = nameValues.isNotEmpty;

    // 1) En guvenli eslesme: businessStaff dokuman ID'si.
    if (staffId.isNotEmpty && hasIdMarker) {
      return staffIdValues.contains(staffId);
    }

    // 2) Ikinci guvenli eslesme: Firebase UID.
    if (uid.isNotEmpty && hasUidMarker) {
      return uidValues.contains(uid);
    }

    // 3) Legacy fallback: sadece id/uid marker hic yoksa isimden eslestir.
    // Yeni kayitlarda bu alan sadece gorsel amaclidir.
    if (!hasIdMarker &&
        !hasUidMarker &&
        staffName.isNotEmpty &&
        hasNameMarker) {
      return nameValues.contains(staffName);
    }

    // Atama marker'i olmayan veya baskasina atanmis randevu linkedStaff'e dusmez.
    return false;
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _assignedAppointmentsStream() {
    return _workspaceRepository
        .watchBusinessAppointments(businessId: _businessId)
        .map((docs) {
          final privilegedViewer = _isPrivilegedTaskViewer();

          final items = docs.where((doc) {
            final data = doc.data();

            if (privilegedViewer) return true;

            return _matchesAssignedStaff(data);
          }).toList();

          items.sort((a, b) {
            final da = _dateValue(a.data());
            final db = _dateValue(b.data());

            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;

            return da.compareTo(db);
          });

          return items;
        });
  }
}
