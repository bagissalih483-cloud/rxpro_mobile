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

  List<String> _valuesForKeys(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
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

  String _statusValue(Map<String, dynamic> data) {
    return AppointmentStatusMapper.fromAny(
      data[FirestoreFields.status] ??
          data[FirestoreFields.appointmentStatus] ??
          data[FirestoreFields.state] ??
          data['cancelStatus'] ??
          data['cancellationStatus'] ??
          data['cancelReasonStatus'] ??
          'pending',
    ).key;
  }

  // ignore: unused_element
  bool _isCompletedAppointment(Map<String, dynamic> data) {
    return TaskStatusFilter.bucketOf(
              data[FirestoreFields.status] ??
                  data[FirestoreFields.appointmentStatus] ??
                  data[FirestoreFields.state] ??
                  data['cancelStatus'] ??
                  data['cancellationStatus'] ??
                  data['cancelReasonStatus'],
            ) ==
            TaskStatusBucket.done ||
        data['isCompleted'] == true ||
        data[FirestoreFields.completedAt] != null;
  }

  bool _isCancelledAppointment(Map<String, dynamic> data) {
    return TaskStatusFilter.bucketOf(
              data[FirestoreFields.status] ??
                  data[FirestoreFields.appointmentStatus] ??
                  data[FirestoreFields.state] ??
                  data['cancelStatus'] ??
                  data['cancellationStatus'] ??
                  data['cancelReasonStatus'],
            ) ==
            TaskStatusBucket.cancelled ||
        data[FirestoreFields.isCancelled] == true ||
        data[FirestoreFields.cancelledAt] != null ||
        data['canceledAt'] != null ||
        data['noShow'] == true;
  }

  bool _isQueueAppointment(Map<String, dynamic> data) {
    return TaskStatusFilter.bucketOf(
          data[FirestoreFields.status] ??
              data[FirestoreFields.appointmentStatus] ??
              data[FirestoreFields.state] ??
              data['cancelStatus'] ??
              data['cancellationStatus'] ??
              data['cancelReasonStatus'],
        ) ==
        TaskStatusBucket.queue;
  }

  bool _isOverdueAppointment(Map<String, dynamic> data) {
    if (!_isQueueAppointment(data)) return false;

    final appointmentAt = _dateValue(data);
    if (appointmentAt == null) return false;

    return appointmentAt.isBefore(DateTime.now());
  }

  String _statusLabel(Map<String, dynamic> data) {
    if (_isOverdueAppointment(data)) {
      return 'Süresi geçti';
    }

    return AppointmentStatusMapper.labelOf(
      data[FirestoreFields.status] ??
          data[FirestoreFields.appointmentStatus] ??
          data[FirestoreFields.state] ??
          data['cancelStatus'] ??
          data['cancellationStatus'] ??
          data['cancelReasonStatus'] ??
          'pending',
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _taskDocsForTab(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    _StaffTaskTab tab,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      final bucket = TaskStatusFilter.bucketOf(
        data[FirestoreFields.status] ??
            data[FirestoreFields.appointmentStatus] ??
            data[FirestoreFields.state] ??
            data['cancelStatus'] ??
            data['cancellationStatus'] ??
            data['cancelReasonStatus'],
      );

      switch (tab) {
        case _StaffTaskTab.queue:
          if (_isCancelledAppointment(data)) return false;
          return bucket == TaskStatusBucket.queue;
        case _StaffTaskTab.completed:
          return bucket == TaskStatusBucket.done;
        case _StaffTaskTab.cancelled:
          return bucket == TaskStatusBucket.cancelled;
      }
    }).toList();
  }

  DateTime? _dateValue(Map<String, dynamic> data) {
    final raw =
        data['startAt'] ??
        data['startAtIso'] ??
        data['scheduledAt'] ??
        data['appointmentStartAt'] ??
        data['appointmentDateTime'] ??
        data['appointmentDate'] ??
        data['date'];

    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;

    if (raw is String) {
      final direct = DateTime.tryParse(raw);
      if (direct != null) return direct;

      final dateText = raw.trim();
      final timeText =
          (data['appointmentTime'] ??
                  data[FirestoreFields.timeText] ??
                  data['startTime'] ??
                  data['time'] ??
                  '')
              .toString()
              .trim();

      if (dateText.isNotEmpty && timeText.isNotEmpty) {
        final parsed = DateTime.tryParse('$dateText $timeText');
        if (parsed != null) return parsed;
      }
    }

    final dateText =
        (data[FirestoreFields.dateText] ?? data['appointmentDateText'] ?? '')
            .toString()
            .trim();
    final timeText =
        (data['appointmentTime'] ??
                data[FirestoreFields.timeText] ??
                data['startTime'] ??
                data['time'] ??
                '')
            .toString()
            .trim();

    if (dateText.isNotEmpty && timeText.isNotEmpty) {
      return DateTime.tryParse('$dateText $timeText');
    }

    return null;
  }

  String _appointmentTitle(Map<String, dynamic> data) {
    final service = (data[FirestoreFields.serviceName] ?? 'Hizmet').toString();
    final customer =
        (data[FirestoreFields.customerName] ?? 'Bireysel Kullanıcı').toString();

    return '$service • $customer';
  }

  DateTime? _readDateTimeValue(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  DateTime? _workStartCandidate(Map<String, dynamic> data) {
    return _readDateTimeValue(data[FirestoreFields.startedAt]) ??
        _readDateTimeValue(data[FirestoreFields.workStartedAt]) ??
        _readDateTimeValue(data[FirestoreFields.workStartedAtLocalIso]) ??
        _readDateTimeValue(data['startAt']) ??
        _readDateTimeValue(data['appointmentDate']);
  }

  int? _calculateWorkDurationMinutes(
    Map<String, dynamic> data,
    DateTime completedAt,
  ) {
    final startedAt = _workStartCandidate(data);
    if (startedAt == null) return null;

    final diff = completedAt.difference(startedAt).inMinutes;
    if (diff < 0) return null;

    return diff;
  }

  String _appointmentTime(Map<String, dynamic> data) {
    final dt = _dateValue(data);
    final timeText =
        (data[FirestoreFields.timeText] ?? data['appointmentTime'] ?? '')
            .toString();

    if (timeText.isNotEmpty) return timeText;

    if (dt == null) return 'Saat yok';

    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');

    return '$h:$m';
  }
}
