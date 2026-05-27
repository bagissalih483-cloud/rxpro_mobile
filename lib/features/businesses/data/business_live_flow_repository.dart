import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class BusinessLiveFlowRepository {
  BusinessLiveFlowRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<BusinessLiveFlowAppointment>> watchAppointments({
    required String businessId,
  }) {
    return _firestore
        .collection(FirestoreCollections.appointments)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BusinessLiveFlowAppointment.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  Stream<List<BusinessLiveFlowStaff>> watchStaff({required String businessId}) {
    return _firestore
        .collection(FirestoreCollections.businessStaff)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BusinessLiveFlowStaff.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  Stream<List<BusinessLiveFlowActivityLog>> watchLogs({
    required String businessId,
  }) {
    return _firestore
        .collection(FirestoreCollections.businessActivityLogs)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BusinessLiveFlowActivityLog.fromMap(doc.data()))
              .toList(growable: false),
        );
  }
}

class BusinessLiveFlowAppointment {
  const BusinessLiveFlowAppointment({required this.isActive});

  final bool isActive;

  factory BusinessLiveFlowAppointment.fromMap(Map<String, dynamic> data) {
    final status =
        (data[FirestoreFields.status] ??
                data[FirestoreFields.appointmentStatus] ??
                data[FirestoreFields.state] ??
                '')
            .toString()
            .toLowerCase();

    return BusinessLiveFlowAppointment(
      isActive:
          status == 'active' ||
          status == 'inprogress' ||
          status == 'in_progress' ||
          status == 'started',
    );
  }
}

class BusinessLiveFlowStaff {
  const BusinessLiveFlowStaff({required this.isBusy});

  final bool isBusy;

  factory BusinessLiveFlowStaff.fromMap(Map<String, dynamic> data) {
    final status = (data['currentWorkStatus'] ?? data['workStatus'] ?? '')
        .toString()
        .toLowerCase();
    final available = data['isAvailable'];

    return BusinessLiveFlowStaff(
      isBusy: status == 'busy' || available == false,
    );
  }
}

class BusinessLiveFlowActivityLog {
  const BusinessLiveFlowActivityLog({required this.title});

  final String title;

  factory BusinessLiveFlowActivityLog.fromMap(Map<String, dynamic> data) {
    return BusinessLiveFlowActivityLog(
      title:
          (data[FirestoreFields.title] ??
                  data[FirestoreFields.type] ??
                  'Son hareket kaydi alindi.')
              .toString(),
    );
  }
}
