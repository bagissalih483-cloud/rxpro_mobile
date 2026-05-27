import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class BusinessAppointmentDashboardRepository {
  BusinessAppointmentDashboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Map<String, dynamic>>> watchAppointments({
    required String businessId,
    int limit = 500,
    bool includeMetadataChanges = true,
  }) {
    if (businessId.trim().isEmpty) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }

    return _firestore
        .collection(FirestoreCollections.appointments)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .limit(limit)
        .snapshots(includeMetadataChanges: includeMetadataChanges)
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = <String, dynamic>{...doc.data()};
                final startAt = data[FirestoreFields.startAt];

                if (startAt is Timestamp) {
                  data[FirestoreFields.startAt] = startAt.toDate();
                }

                data[BusinessAppointmentDashboardFields.documentId] = doc.id;
                return data;
              })
              .toList(growable: false);
        });
  }

  Stream<List<Map<String, dynamic>>> watchStaff({
    required String businessId,
    int limit = 80,
    bool includeMetadataChanges = true,
  }) {
    if (businessId.trim().isEmpty) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }

    return _firestore
        .collection(FirestoreCollections.businessStaff)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .limit(limit)
        .snapshots(includeMetadataChanges: includeMetadataChanges)
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                return <String, dynamic>{
                  ...doc.data(),
                  BusinessAppointmentDashboardFields.documentId: doc.id,
                };
              })
              .toList(growable: false);
        });
  }
}

class BusinessAppointmentDashboardFields {
  const BusinessAppointmentDashboardFields._();

  static const documentId = '__docId';
}
