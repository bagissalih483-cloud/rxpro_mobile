import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/businesses/data/business_customer_models.dart';

export 'package:rxpro_mobile/features/businesses/data/business_customer_models.dart';

class BusinessCustomerRepository {
  BusinessCustomerRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int _customerRealtimeWindowSize = 300;

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
            .limit(_customerRealtimeWindowSize)
            .snapshots(includeMetadataChanges: true)
            .listen((snapshot) {
              manualRecords = snapshot.docs
                  .map(BusinessCustomerRecord.fromManualDoc)
                  .toList();
              emit();
            }, onError: controller.addError);

        appointmentSub = _appointments
            .where(FirestoreFields.businessId, isEqualTo: id)
            .limit(_customerRealtimeWindowSize)
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
