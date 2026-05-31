part of 'business_customer_models.dart';

class _AppointmentCustomerAggregate {
  _AppointmentCustomerAggregate({
    required this.key,
    required this.businessId,
    required this.customerUid,
    required this.name,
    required this.phone,
    required this.email,
  });

  final String key;
  String businessId;
  String customerUid;
  String name;
  String phone;
  String email;
  String lastServiceName = '';
  int appointmentCount = 0;
  int completedAppointmentCount = 0;
  int cancelledAppointmentCount = 0;
  int noShowCount = 0;
  DateTime? lastAppointmentAt;

  void add(Map<String, dynamic> data) {
    appointmentCount++;
    businessId = businessId.trim().isNotEmpty
        ? businessId
        : _firstString(data, const [FirestoreFields.businessId]);
    customerUid = customerUid.trim().isNotEmpty
        ? customerUid
        : _firstString(data, const [FirestoreFields.customerUid]);
    name = name.trim().isNotEmpty
        ? name
        : _firstString(data, const [FirestoreFields.customerName]);
    phone = phone.trim().isNotEmpty
        ? phone
        : _firstString(data, const [FirestoreFields.customerPhone]);
    email = email.trim().isNotEmpty
        ? email
        : _firstString(data, const [FirestoreFields.email, 'customerEmail']);

    final serviceName = _firstString(data, const [
      FirestoreFields.serviceName,
      FirestoreFields.service,
      'title',
    ]);

    final appointmentAt = _firstDate(data, const [
      FirestoreFields.startAt,
      FirestoreFields.startAtIso,
      FirestoreFields.appointmentDateIso,
      FirestoreFields.completedAt,
      'createdAtTs',
      FirestoreFields.createdAt,
    ]);

    final currentLast = lastAppointmentAt;
    if (appointmentAt != null &&
        (currentLast == null || appointmentAt.isAfter(currentLast))) {
      lastAppointmentAt = appointmentAt;
      lastServiceName = serviceName;
    } else if (lastServiceName.trim().isEmpty) {
      lastServiceName = serviceName;
    }

    if (_isCompleted(data)) completedAppointmentCount++;
    if (_isCancelled(data)) cancelledAppointmentCount++;
    if (_isNoShow(data)) noShowCount++;
  }

  BusinessCustomerRecord toRecord({DateTime? now}) {
    final segmentId = BusinessCustomerSegmentation.classify(
      appointmentCount: appointmentCount,
      completedAppointmentCount: completedAppointmentCount,
      noShowCount: noShowCount,
      lastAppointmentAt: lastAppointmentAt,
      now: now,
    );

    return BusinessCustomerRecord(
      id: 'appointment:$key',
      businessId: businessId,
      customerUid: customerUid,
      name: name,
      phone: phone,
      email: email,
      segmentId: segmentId,
      source: 'appointments',
      isManual: false,
      appointmentCount: appointmentCount,
      completedAppointmentCount: completedAppointmentCount,
      cancelledAppointmentCount: cancelledAppointmentCount,
      noShowCount: noShowCount,
      lastAppointmentAt: lastAppointmentAt,
      lastServiceName: lastServiceName,
      matchKey: key,
      campaignConsent: false,
    );
  }
}

String _firstString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key]?.toString().trim() ?? '';
    if (value.isNotEmpty && value != 'null') return value;
  }
  return '';
}

DateTime? _firstDate(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final parsed = _readDate(data[key]);
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);

  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _readBool(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is bool) return value;

    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'true' || text == '1' || text == 'yes' || text == 'evet') {
      return true;
    }
    if (text == 'false' || text == '0' || text == 'no' || text == 'hayır') {
      return false;
    }
  }
  return false;
}

String _matchKey({
  required String uid,
  required String phone,
  required String email,
  required String name,
}) {
  final normalizedUid = uid.trim().toLowerCase();
  if (normalizedUid.isNotEmpty) return 'uid:$normalizedUid';

  final normalizedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (normalizedPhone.isNotEmpty) return 'phone:$normalizedPhone';

  final normalizedEmail = email.trim().toLowerCase();
  if (normalizedEmail.isNotEmpty) return 'email:$normalizedEmail';

  final normalizedName = name.trim().toLowerCase().replaceAll(
    RegExp(r'\s+'),
    ' ',
  );
  if (normalizedName.isNotEmpty) return 'name:$normalizedName';

  return '';
}

String _statusOf(Map<String, dynamic> data) {
  return _firstString(data, const [
    FirestoreFields.status,
    FirestoreFields.appointmentStatus,
    FirestoreFields.state,
    FirestoreFields.bookingStatus,
  ]).toLowerCase();
}

bool _isCompleted(Map<String, dynamic> data) {
  final status = _statusOf(data);
  return status == 'completed' ||
      status == 'done' ||
      status == 'finished' ||
      status == 'tamamlandi' ||
      status == 'tamamlandı' ||
      data[FirestoreFields.isCompleted] == true ||
      data['completed'] == true;
}

bool _isCancelled(Map<String, dynamic> data) {
  final status = _statusOf(data);
  return status.contains('cancel') ||
      status.contains('iptal') ||
      data[FirestoreFields.isCancelled] == true;
}

bool _isNoShow(Map<String, dynamic> data) {
  final status = _statusOf(data);
  return data[FirestoreFields.noShow] == true ||
      status.contains('no_show') ||
      status.contains('no-show') ||
      status.contains('gelmedi');
}
