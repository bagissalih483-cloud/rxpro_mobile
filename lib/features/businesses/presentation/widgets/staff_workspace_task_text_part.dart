part of '../../staff_workspace_page.dart';

extension _StaffWorkspacePageStateTaskText on _StaffWorkspacePageState {
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
