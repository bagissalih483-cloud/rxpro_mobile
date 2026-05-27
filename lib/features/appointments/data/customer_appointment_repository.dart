import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAppointmentRepository {
  CustomerAppointmentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection(CustomerAppointmentCollections.appointments);

  Stream<List<CustomerAppointmentDocument>> watchCustomerAppointmentsByField({
    required String field,
    required String uid,
    int limit = 300,
    bool includeMetadataChanges = true,
  }) {
    if (uid.isEmpty) {
      return Stream.value(<CustomerAppointmentDocument>[]);
    }

    return _appointments
        .where(field, isEqualTo: uid)
        .limit(limit)
        .snapshots(includeMetadataChanges: includeMetadataChanges)
        .map(_documentsFromSnapshot);
  }

  Stream<List<CustomerAppointmentDocument>> watchMergedCustomerAppointments({
    required String uid,
    int limitPerField = 300,
    bool includeMetadataChanges = true,
  }) {
    if (uid.isEmpty) {
      return Stream.value(<CustomerAppointmentDocument>[]);
    }

    final controller = StreamController<List<CustomerAppointmentDocument>>();
    final merged = <String, CustomerAppointmentDocument>{};
    final buckets = <String, Map<String, CustomerAppointmentDocument>>{};
    final subscriptions =
        <StreamSubscription<List<CustomerAppointmentDocument>>>[];

    void emit() {
      if (controller.isClosed) return;

      merged
        ..clear()
        ..addAll(
          buckets.values.fold<Map<String, CustomerAppointmentDocument>>(
            <String, CustomerAppointmentDocument>{},
            (acc, bucket) {
              acc.addAll(bucket);
              return acc;
            },
          ),
        );

      final items = merged.values.toList(growable: false);
      controller.add(items);
    }

    void listenField(String field) {
      final subscription =
          watchCustomerAppointmentsByField(
            field: field,
            uid: uid,
            limit: limitPerField,
            includeMetadataChanges: includeMetadataChanges,
          ).listen((items) {
            buckets[field] = <String, CustomerAppointmentDocument>{
              for (final item in items) item.id: item,
            };
            emit();
          }, onError: (_) => emit());

      subscriptions.add(subscription);
    }

    listenField(CustomerAppointmentFields.customerUid);
    listenField(CustomerAppointmentFields.customerId);
    listenField(CustomerAppointmentFields.userId);
    listenField(CustomerAppointmentFields.uid);
    listenField(CustomerAppointmentFields.clientUid);

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  Future<CustomerAppointmentDocument?> fetchAppointmentById({
    required String appointmentId,
  }) async {
    if (appointmentId.isEmpty) return null;

    final doc = await _appointments.doc(appointmentId).get();
    final data = doc.data();

    if (data == null) return null;

    return CustomerAppointmentDocument(
      id: doc.id,
      data: <String, dynamic>{...data},
    );
  }

  Future<void> setAppointmentMerge({
    required String appointmentId,
    required Map<String, dynamic> data,
  }) async {
    if (appointmentId.isEmpty) {
      throw ArgumentError.value(
        appointmentId,
        'appointmentId',
        'appointmentId cannot be empty',
      );
    }

    await _appointments.doc(appointmentId).set(data, SetOptions(merge: true));
  }

  Future<void> cancelByCustomer({
    required String appointmentId,
    required String reason,
    required String cancelledByUid,
  }) async {
    await setAppointmentMerge(
      appointmentId: appointmentId,
      data: <String, dynamic>{
        CustomerAppointmentFields.status: 'cancelled',
        CustomerAppointmentFields.cancelReason: reason,
        CustomerAppointmentFields.cancelledByUid: cancelledByUid,
        CustomerAppointmentFields.cancelledAt: DateTime.now().toIso8601String(),
        CustomerAppointmentFields.updatedAt: DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> acceptPostponeByCustomer({required String appointmentId}) async {
    await setAppointmentMerge(
      appointmentId: appointmentId,
      data: <String, dynamic>{
        CustomerAppointmentFields.status: 'active',
        CustomerAppointmentFields.postponeStatus: 'accepted',
        CustomerAppointmentFields.updatedAt: DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> rejectPostponeAndCancelByCustomer({
    required String appointmentId,
    required String reason,
    required String cancelledByUid,
  }) async {
    await setAppointmentMerge(
      appointmentId: appointmentId,
      data: <String, dynamic>{
        CustomerAppointmentFields.status: 'cancelled',
        CustomerAppointmentFields.postponeStatus: 'rejected',
        CustomerAppointmentFields.cancelReason: reason,
        CustomerAppointmentFields.cancelledByUid: cancelledByUid,
        CustomerAppointmentFields.cancelledAt: DateTime.now().toIso8601String(),
        CustomerAppointmentFields.updatedAt: DateTime.now().toIso8601String(),
      },
    );
  }

  List<CustomerAppointmentDocument> _documentsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) {
          return CustomerAppointmentDocument(
            id: doc.id,
            data: <String, dynamic>{...doc.data()},
          );
        })
        .toList(growable: false);
  }
}

class CustomerAppointmentDocument {
  const CustomerAppointmentDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

class CustomerAppointmentCollections {
  const CustomerAppointmentCollections._();

  static const appointments = 'appointments';
}

class CustomerAppointmentFields {
  const CustomerAppointmentFields._();

  static const customerUid = 'customerUid';
  static const customerId = 'customerId';
  static const userId = 'userId';
  static const uid = 'uid';
  static const clientUid = 'clientUid';
  static const businessId = 'businessId';
  static const businessName = 'businessName';
  static const ownerUid = 'ownerUid';
  static const status = 'status';
  static const postponeStatus = 'postponeStatus';
  static const cancelReason = 'cancelReason';
  static const cancelledByUid = 'cancelledByUid';
  static const cancelledAt = 'cancelledAt';
  static const updatedAt = 'updatedAt';
}
