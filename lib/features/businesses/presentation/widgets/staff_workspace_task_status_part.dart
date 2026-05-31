part of '../../staff_workspace_page.dart';

extension _StaffWorkspacePageStateTaskStatus on _StaffWorkspacePageState {
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
      final status = AppointmentStatusMapper.fromAny(
        data[FirestoreFields.status] ??
            data[FirestoreFields.appointmentStatus] ??
            data[FirestoreFields.state] ??
            data['cancelStatus'] ??
            data['cancellationStatus'] ??
            data['cancelReasonStatus'],
      );
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
          return bucket == TaskStatusBucket.queue &&
              status != AppointmentStatus.inProgress;
        case _StaffTaskTab.inProgress:
          return status == AppointmentStatus.inProgress;
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
}
