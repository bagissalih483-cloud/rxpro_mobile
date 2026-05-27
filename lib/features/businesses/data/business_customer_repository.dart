import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

class BusinessCustomerSegment {
  const BusinessCustomerSegment({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

abstract final class BusinessCustomerSegments {
  BusinessCustomerSegments._();

  static const all = BusinessCustomerSegment(
    id: 'all',
    label: 'Tümü',
    description: 'İşletmenin bütün müşteri kayıtları.',
  );

  static const manual = BusinessCustomerSegment(
    id: 'manual',
    label: 'Manuel kayıt',
    description: 'İşletmenin elle eklediği müşteri.',
  );

  static const newCustomer = BusinessCustomerSegment(
    id: 'new_customer',
    label: 'Yeni müşteri',
    description: 'Yakın zamanda ilk randevusunu alan müşteri.',
  );

  static const active = BusinessCustomerSegment(
    id: 'active',
    label: 'Aktif müşteri',
    description: 'Son dönemde randevu veya işlem geçmişi olan müşteri.',
  );

  static const loyal = BusinessCustomerSegment(
    id: 'loyal',
    label: 'Sadık müşteri',
    description: 'Birden fazla tamamlanmış randevu geçmişi olan müşteri.',
  );

  static const inactive = BusinessCustomerSegment(
    id: 'inactive',
    label: 'Pasif müşteri',
    description: 'Uzun süredir randevu almayan müşteri.',
  );

  static const needsFollowUp = BusinessCustomerSegment(
    id: 'needs_follow_up',
    label: 'Takip gereken',
    description: 'Gelmedi, iptal veya özel takip gerektiren müşteri.',
  );

  static const values = <BusinessCustomerSegment>[
    all,
    manual,
    newCustomer,
    active,
    loyal,
    inactive,
    needsFollowUp,
  ];

  static const editableValues = <BusinessCustomerSegment>[
    manual,
    newCustomer,
    active,
    loyal,
    inactive,
    needsFollowUp,
  ];

  static BusinessCustomerSegment byId(String id) {
    final normalized = id.trim();
    for (final segment in values) {
      if (segment.id == normalized) return segment;
    }
    return manual;
  }

  static String labelOf(String id) => byId(id).label;
}

abstract final class BusinessCustomerSegmentation {
  BusinessCustomerSegmentation._();

  static String classify({
    required int appointmentCount,
    required int completedAppointmentCount,
    required int noShowCount,
    DateTime? lastAppointmentAt,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();

    if (noShowCount >= 2 ||
        (noShowCount > 0 && completedAppointmentCount == 0)) {
      return BusinessCustomerSegments.needsFollowUp.id;
    }

    if (completedAppointmentCount >= 3 || appointmentCount >= 4) {
      return BusinessCustomerSegments.loyal.id;
    }

    if (lastAppointmentAt == null) {
      return BusinessCustomerSegments.manual.id;
    }

    final daysSinceLast =
        reference.difference(lastAppointmentAt).inHours ~/ 24;

    if (appointmentCount <= 1 && daysSinceLast <= 60) {
      return BusinessCustomerSegments.newCustomer.id;
    }

    if (daysSinceLast <= 90) {
      return BusinessCustomerSegments.active.id;
    }

    return BusinessCustomerSegments.inactive.id;
  }
}

class BusinessCustomerRecord {
  const BusinessCustomerRecord({
    required this.id,
    required this.businessId,
    required this.name,
    this.customerUid = '',
    this.phone = '',
    this.email = '',
    this.note = '',
    this.segmentId = 'manual',
    this.source = 'manual',
    this.isManual = false,
    this.appointmentCount = 0,
    this.completedAppointmentCount = 0,
    this.cancelledAppointmentCount = 0,
    this.noShowCount = 0,
    this.lastAppointmentAt,
    this.lastServiceName = '',
    this.createdAt,
    this.updatedAt,
    this.raw = const <String, dynamic>{},
    this.matchKey = '',
    this.campaignConsent = false,
  });

  final String id;
  final String businessId;
  final String customerUid;
  final String name;
  final String phone;
  final String email;
  final String note;
  final String segmentId;
  final String source;
  final bool isManual;
  final int appointmentCount;
  final int completedAppointmentCount;
  final int cancelledAppointmentCount;
  final int noShowCount;
  final DateTime? lastAppointmentAt;
  final String lastServiceName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;
  final String matchKey;
  final bool campaignConsent;

  String get segmentLabel => BusinessCustomerSegments.labelOf(segmentId);

  String get displayName => name.trim().isEmpty ? 'İsimsiz müşteri' : name;

  bool get canReceiveBulkMessage =>
      customerUid.trim().isNotEmpty && campaignConsent;

  bool get hasContactInfo =>
      customerUid.trim().isNotEmpty ||
      phone.trim().isNotEmpty ||
      email.trim().isNotEmpty;

  bool matchesSegment(String selectedSegmentId) {
    return selectedSegmentId == BusinessCustomerSegments.all.id ||
        segmentId == selectedSegmentId;
  }

  bool matchesQuery(String query) {
    final needle = _normalize(query);
    if (needle.isEmpty) return true;

    return _normalize(name).contains(needle) ||
        _normalize(phone).contains(needle) ||
        _normalize(email).contains(needle) ||
        _normalize(note).contains(needle) ||
        _normalize(lastServiceName).contains(needle);
  }

  BusinessCustomerRecord mergeAppointmentHistory(
    BusinessCustomerRecord appointmentRecord,
  ) {
    final keepManualSegment =
        segmentId.trim().isNotEmpty &&
        segmentId != BusinessCustomerSegments.manual.id;

    return copyWith(
      customerUid: customerUid.trim().isNotEmpty
          ? customerUid
          : appointmentRecord.customerUid,
      name: name.trim().isNotEmpty ? name : appointmentRecord.name,
      phone: phone.trim().isNotEmpty ? phone : appointmentRecord.phone,
      email: email.trim().isNotEmpty ? email : appointmentRecord.email,
      segmentId: keepManualSegment ? segmentId : appointmentRecord.segmentId,
      source: source == appointmentRecord.source
          ? source
          : '$source+${appointmentRecord.source}',
      appointmentCount: appointmentRecord.appointmentCount,
      completedAppointmentCount: appointmentRecord.completedAppointmentCount,
      cancelledAppointmentCount: appointmentRecord.cancelledAppointmentCount,
      noShowCount: appointmentRecord.noShowCount,
      lastAppointmentAt: appointmentRecord.lastAppointmentAt,
      lastServiceName: appointmentRecord.lastServiceName,
      matchKey: matchKey.trim().isNotEmpty
          ? matchKey
          : appointmentRecord.matchKey,
      campaignConsent: campaignConsent || appointmentRecord.campaignConsent,
    );
  }

  BusinessCustomerRecord copyWith({
    String? id,
    String? businessId,
    String? customerUid,
    String? name,
    String? phone,
    String? email,
    String? note,
    String? segmentId,
    String? source,
    bool? isManual,
    int? appointmentCount,
    int? completedAppointmentCount,
    int? cancelledAppointmentCount,
    int? noShowCount,
    DateTime? lastAppointmentAt,
    String? lastServiceName,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? raw,
    String? matchKey,
    bool? campaignConsent,
  }) {
    return BusinessCustomerRecord(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerUid: customerUid ?? this.customerUid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      note: note ?? this.note,
      segmentId: segmentId ?? this.segmentId,
      source: source ?? this.source,
      isManual: isManual ?? this.isManual,
      appointmentCount: appointmentCount ?? this.appointmentCount,
      completedAppointmentCount:
          completedAppointmentCount ?? this.completedAppointmentCount,
      cancelledAppointmentCount:
          cancelledAppointmentCount ?? this.cancelledAppointmentCount,
      noShowCount: noShowCount ?? this.noShowCount,
      lastAppointmentAt: lastAppointmentAt ?? this.lastAppointmentAt,
      lastServiceName: lastServiceName ?? this.lastServiceName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      raw: raw ?? this.raw,
      matchKey: matchKey ?? this.matchKey,
      campaignConsent: campaignConsent ?? this.campaignConsent,
    );
  }

  factory BusinessCustomerRecord.fromManualDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final businessId = _firstString(data, const [
      FirestoreFields.businessId,
      'businessDocId',
      'companyId',
    ]);
    final customerUid = _firstString(data, const [
      FirestoreFields.customerUid,
      FirestoreFields.customerId,
      FirestoreFields.userId,
      FirestoreFields.uid,
      'clientUid',
    ]);
    final name = _firstString(data, const [
      FirestoreFields.customerName,
      FirestoreFields.clientName,
      FirestoreFields.displayName,
      FirestoreFields.fullName,
      FirestoreFields.name,
    ]);
    final phone = _firstString(data, const [
      FirestoreFields.customerPhone,
      FirestoreFields.phone,
      FirestoreFields.phoneNumber,
    ]);
    final email = _firstString(data, const [
      FirestoreFields.email,
      FirestoreFields.customerEmail,
      FirestoreFields.contactEmail,
    ]);
    final segmentId = _firstString(data, const [
      'segmentId',
      'customerSegment',
      'classification',
      'statusSegment',
    ]);

    return BusinessCustomerRecord(
      id: doc.id,
      businessId: businessId,
      customerUid: customerUid,
      name: name,
      phone: phone,
      email: email,
      note: _firstString(data, const [
        FirestoreFields.note,
        'customerNote',
        'internalNote',
      ]),
      segmentId: segmentId.isEmpty
          ? BusinessCustomerSegments.manual.id
          : BusinessCustomerSegments.byId(segmentId).id,
      source: _firstString(data, const [FirestoreFields.source, 'source']) ==
              ''
          ? 'manual'
          : _firstString(data, const [FirestoreFields.source, 'source']),
      isManual: true,
      appointmentCount: _readInt(data['appointmentCount']),
      completedAppointmentCount: _readInt(data['completedAppointmentCount']),
      cancelledAppointmentCount: _readInt(data['cancelledAppointmentCount']),
      noShowCount: _readInt(data['noShowCount']),
      lastAppointmentAt: _firstDate(data, const [
        'lastAppointmentAt',
        'lastVisitAt',
        'lastAppointmentDate',
      ]),
      lastServiceName: _firstString(data, const [
        'lastServiceName',
        FirestoreFields.serviceName,
      ]),
      createdAt: _firstDate(data, const [
        FirestoreFields.createdAt,
        FirestoreFields.createdAtIso,
        'createdAtLocalIso',
      ]),
      updatedAt: _firstDate(data, const [
        FirestoreFields.updatedAt,
        'updatedAtLocalIso',
      ]),
      raw: Map<String, dynamic>.from(data),
      matchKey: _matchKey(
        uid: customerUid,
        phone: phone,
        email: email,
        name: name,
      ),
      campaignConsent: _readBool(data, const [
        'bulkMessageConsent',
        'marketingConsent',
        'notificationConsent',
        'campaignConsent',
        'campaignPermission',
        'allowCampaignMessages',
      ]),
    );
  }

  static List<BusinessCustomerRecord> fromAppointmentDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    DateTime? now,
  }) {
    final aggregations = <String, _AppointmentCustomerAggregate>{};

    for (final doc in docs) {
      final data = doc.data();
      final customerUid = _firstString(data, const [
        FirestoreFields.customerUid,
        FirestoreFields.customerId,
        FirestoreFields.userId,
        FirestoreFields.uid,
        'clientUid',
      ]);
      final name = _firstString(data, const [
        FirestoreFields.customerName,
        FirestoreFields.clientName,
        FirestoreFields.displayName,
        FirestoreFields.userName,
        FirestoreFields.name,
      ]);
      final phone = _firstString(data, const [
        FirestoreFields.customerPhone,
        FirestoreFields.phone,
        FirestoreFields.phoneNumber,
      ]);
      final email = _firstString(data, const [
        FirestoreFields.email,
        FirestoreFields.customerEmail,
        'customerEmail',
      ]);
      final key = _matchKey(
        uid: customerUid,
        phone: phone,
        email: email,
        name: name,
      );
      if (key.isEmpty) continue;

      final aggregate = aggregations.putIfAbsent(
        key,
        () => _AppointmentCustomerAggregate(
          key: key,
          businessId: _firstString(data, const [
            FirestoreFields.businessId,
            'businessDocId',
          ]),
          customerUid: customerUid,
          name: name,
          phone: phone,
          email: email,
        ),
      );

      aggregate.add(data);
    }

    return aggregations.values
        .map((aggregate) => aggregate.toRecord(now: now))
        .where((record) => record.businessId.trim().isNotEmpty)
        .toList();
  }

  static List<BusinessCustomerRecord> mergeManualAndAppointmentRecords(
    List<BusinessCustomerRecord> manualRecords,
    List<BusinessCustomerRecord> appointmentRecords,
  ) {
    final byKey = <String, BusinessCustomerRecord>{};

    for (final appointment in appointmentRecords) {
      final key = appointment.matchKey.trim();
      if (key.isNotEmpty) byKey[key] = appointment;
    }

    final merged = <BusinessCustomerRecord>[];
    final consumedAppointmentKeys = <String>{};

    for (final manual in manualRecords) {
      final key = manual.matchKey.trim();
      final appointment = key.isEmpty ? null : byKey[key];
      if (appointment == null) {
        merged.add(manual);
      } else {
        consumedAppointmentKeys.add(key);
        merged.add(manual.mergeAppointmentHistory(appointment));
      }
    }

    for (final appointment in appointmentRecords) {
      if (!consumedAppointmentKeys.contains(appointment.matchKey)) {
        merged.add(appointment);
      }
    }

    merged.sort((a, b) {
      final aDate = a.lastAppointmentAt ?? a.updatedAt ?? a.createdAt;
      final bDate = b.lastAppointmentAt ?? b.updatedAt ?? b.createdAt;
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      if (aDate != null) return -1;
      if (bDate != null) return 1;
      return a.displayName.compareTo(b.displayName);
    });

    return merged;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class BusinessCustomerManualInput {
  const BusinessCustomerManualInput({
    required this.businessId,
    required this.name,
    this.phone = '',
    this.email = '',
    this.note = '',
    this.segmentId = 'manual',
    this.campaignConsent = false,
  });

  final String businessId;
  final String name;
  final String phone;
  final String email;
  final String note;
  final String segmentId;
  final bool campaignConsent;

  bool get hasRequiredIdentity =>
      name.trim().isNotEmpty ||
      phone.trim().isNotEmpty ||
      email.trim().isNotEmpty;
}

class BusinessCustomerStats {
  const BusinessCustomerStats({
    required this.total,
    required this.segmentCounts,
  });

  final int total;
  final Map<String, int> segmentCounts;

  int countFor(String segmentId) {
    if (segmentId == BusinessCustomerSegments.all.id) return total;
    return segmentCounts[segmentId] ?? 0;
  }

  factory BusinessCustomerStats.fromRecords(
    List<BusinessCustomerRecord> records,
  ) {
    final counts = <String, int>{};
    for (final record in records) {
      counts[record.segmentId] = (counts[record.segmentId] ?? 0) + 1;
    }
    return BusinessCustomerStats(
      total: records.length,
      segmentCounts: counts,
    );
  }
}

class BusinessCustomerRepository {
  BusinessCustomerRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _businessCustomers =>
      _firestore.collection(FirestoreCollections.businessCustomers);

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection(FirestoreCollections.appointments);

  Stream<List<BusinessCustomerRecord>> watchCustomersForBusiness({
    required String businessId,
  }) {
    final id = businessId.trim();
    if (id.isEmpty) return Stream.value(const <BusinessCustomerRecord>[]);

    late StreamController<List<BusinessCustomerRecord>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? manualSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? appointmentSub;
    var manualRecords = <BusinessCustomerRecord>[];
    var appointmentRecords = <BusinessCustomerRecord>[];

    void emit() {
      if (controller.isClosed) return;
      controller.add(
        BusinessCustomerRecord.mergeManualAndAppointmentRecords(
          manualRecords,
          appointmentRecords,
        ),
      );
    }

    controller = StreamController<List<BusinessCustomerRecord>>(
      onListen: () {
        manualSub = _businessCustomers
            .where(FirestoreFields.businessId, isEqualTo: id)
            .limit(500)
            .snapshots(includeMetadataChanges: true)
            .listen((snapshot) {
              manualRecords = snapshot.docs
                  .map(BusinessCustomerRecord.fromManualDoc)
                  .toList();
              emit();
            }, onError: controller.addError);

        appointmentSub = _appointments
            .where(FirestoreFields.businessId, isEqualTo: id)
            .limit(500)
            .snapshots(includeMetadataChanges: true)
            .listen((snapshot) {
              appointmentRecords = BusinessCustomerRecord.fromAppointmentDocs(
                snapshot.docs,
              );
              emit();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await manualSub?.cancel();
        await appointmentSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<DocumentReference<Map<String, dynamic>>> createManualCustomer(
    BusinessCustomerManualInput input,
  ) async {
    if (input.businessId.trim().isEmpty) {
      throw ArgumentError.value(input.businessId, 'businessId', 'required');
    }
    if (!input.hasRequiredIdentity) {
      throw ArgumentError(
        'Müşteri için ad, telefon veya e-posta bilgilerinden en az biri gerekli.',
      );
    }

    final segment = BusinessCustomerSegments.byId(input.segmentId);
    final nowIso = DateTime.now().toIso8601String();

    return _businessCustomers.add(<String, dynamic>{
      FirestoreFields.businessId: input.businessId.trim(),
      FirestoreFields.customerName: input.name.trim(),
      FirestoreFields.name: input.name.trim(),
      FirestoreFields.customerPhone: input.phone.trim(),
      FirestoreFields.phone: input.phone.trim(),
      FirestoreFields.email: input.email.trim(),
      FirestoreFields.note: input.note.trim(),
      'segmentId': segment.id,
      'segmentLabel': segment.label,
      'bulkMessageConsent': input.campaignConsent,
      'marketingConsent': input.campaignConsent,
      'notificationConsent': input.campaignConsent,
      'campaignConsent': input.campaignConsent,
      'allowCampaignMessages': input.campaignConsent,
      'isManual': true,
      'appointmentCount': 0,
      'completedAppointmentCount': 0,
      'cancelledAppointmentCount': 0,
      'noShowCount': 0,
      FirestoreFields.source: 'business_customer_manual_65V',
      FirestoreFields.sourceModule: 'business_customers_page',
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      'createdAtLocalIso': nowIso,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      'updatedAtLocalIso': nowIso,
    });
  }

  Future<void> saveCustomerClassification({
    required BusinessCustomerRecord record,
    required String segmentId,
    required String note,
    required bool campaignConsent,
  }) async {
    final segment = BusinessCustomerSegments.byId(segmentId);
    final nowIso = DateTime.now().toIso8601String();

    if (record.isManual) {
      await _businessCustomers.doc(record.id).set(<String, dynamic>{
        'segmentId': segment.id,
        'segmentLabel': segment.label,
        FirestoreFields.note: note.trim(),
        'bulkMessageConsent': campaignConsent,
        'marketingConsent': campaignConsent,
        'notificationConsent': campaignConsent,
        'campaignConsent': campaignConsent,
        'allowCampaignMessages': campaignConsent,
        'appointmentCount': record.appointmentCount,
        'completedAppointmentCount': record.completedAppointmentCount,
        'cancelledAppointmentCount': record.cancelledAppointmentCount,
        'noShowCount': record.noShowCount,
        if (record.lastAppointmentAt != null)
          'lastAppointmentAt': Timestamp.fromDate(record.lastAppointmentAt!),
        if (record.lastServiceName.trim().isNotEmpty)
          'lastServiceName': record.lastServiceName.trim(),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        'updatedAtLocalIso': nowIso,
      }, SetOptions(merge: true));
      return;
    }

    await _businessCustomers.add(<String, dynamic>{
      FirestoreFields.businessId: record.businessId.trim(),
      FirestoreFields.customerUid: record.customerUid.trim(),
      FirestoreFields.customerId: record.customerUid.trim(),
      FirestoreFields.customerName: record.name.trim(),
      FirestoreFields.name: record.name.trim(),
      FirestoreFields.customerPhone: record.phone.trim(),
      FirestoreFields.phone: record.phone.trim(),
      FirestoreFields.email: record.email.trim(),
      FirestoreFields.note: note.trim(),
      'segmentId': segment.id,
      'segmentLabel': segment.label,
      'bulkMessageConsent': campaignConsent,
      'marketingConsent': campaignConsent,
      'notificationConsent': campaignConsent,
      'campaignConsent': campaignConsent,
      'allowCampaignMessages': campaignConsent,
      'isManual': true,
      'derivedFromAppointments': true,
      'appointmentCount': record.appointmentCount,
      'completedAppointmentCount': record.completedAppointmentCount,
      'cancelledAppointmentCount': record.cancelledAppointmentCount,
      'noShowCount': record.noShowCount,
      if (record.lastAppointmentAt != null)
        'lastAppointmentAt': Timestamp.fromDate(record.lastAppointmentAt!),
      if (record.lastServiceName.trim().isNotEmpty)
        'lastServiceName': record.lastServiceName.trim(),
      FirestoreFields.source: 'business_customer_classification_65V',
      FirestoreFields.sourceModule: 'business_customers_page',
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      'createdAtLocalIso': nowIso,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      'updatedAtLocalIso': nowIso,
    });
  }
}

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
