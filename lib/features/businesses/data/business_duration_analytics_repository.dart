import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class BusinessDurationAnalyticsRepository {
  BusinessDurationAnalyticsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<BusinessDurationAppointment>> watchCompletedAppointments({
    required String businessId,
  }) {
    return _firestore
        .collection(FirestoreCollections.appointments)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          final items = <BusinessDurationAppointment>[];

          for (final doc in snapshot.docs) {
            final item = BusinessDurationAppointment.fromMap(doc.data());
            if (item != null) items.add(item);
          }

          return items;
        });
  }
}

class BusinessDurationAppointment {
  const BusinessDurationAppointment({
    required this.serviceName,
    required this.staffName,
    required this.workDurationMinutes,
    required this.plannedDurationMinutes,
  });

  final String serviceName;
  final String staffName;
  final int workDurationMinutes;
  final int? plannedDurationMinutes;

  static BusinessDurationAppointment? fromMap(Map<String, dynamic> data) {
    final status =
        (data[FirestoreFields.status] ??
                data[FirestoreFields.appointmentStatus] ??
                data[FirestoreFields.state] ??
                '')
            .toString();

    final completed =
        status == 'completed' ||
        data[FirestoreFields.isCompleted] == true ||
        data[FirestoreFields.completedAt] != null;

    if (!completed) return null;

    final duration = _numValue(data[FirestoreFields.workDurationMinutes]);
    if (duration == null || duration <= 0) return null;

    final planned = _numValue(
      data[FirestoreFields.durationMinutes] ??
          data['serviceDurationMinutes'] ??
          data[FirestoreFields.duration],
    );

    return BusinessDurationAppointment(
      serviceName:
          (data[FirestoreFields.serviceName] ??
                  data[FirestoreFields.service] ??
                  'Hizmet')
              .toString(),
      staffName:
          (data[FirestoreFields.staffName] ??
                  data[FirestoreFields.completedByName] ??
                  'Personel')
              .toString(),
      workDurationMinutes: duration.round(),
      plannedDurationMinutes: planned?.round(),
    );
  }

  static num? _numValue(dynamic raw) {
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw.replaceAll(',', '.'));
    return null;
  }
}
